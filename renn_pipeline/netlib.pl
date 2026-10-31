/*  netlib.pl -- a pl2ann network read from its weights only, and an independent forward simulator.

    Nothing here reads the source program, network_rule/4 facts or trace facts: only neurons,
    thresholds, weighted edges and recurrent links (the JSON weight export of pl2ann).

    net_load(+JsonFile, -Net)     loads a network; Net is a handle (the file name)
    net_unload(+Net)
    net_atoms(+Net, -Atoms)       every atom with a neuron, in file order
    net_hidden(+Net, -Hs)         hidden neuron ids, in file order
    net_edb_atoms(+Net, -As)      atoms of input predicates
    is_edb(+Net, +Atom)           Atom's predicate is an input predicate
    net_true_input(+Net, -As)     the input facts compiled into the network (sorted)
    forward(+Net, +Inputs, -Model)            least model from the weights (sorted)
    observation_from_queries(+Net, +Queries, -Obs)   Obs = [Atom-Bool], the dataset's answers
    full_observation(+Net, +Model, -Obs)      every non-input atom, true iff in Model
    show(+Term, -String)          Term as text with no spaces and no operators: edge(a,b), xor(1,0)
    pred_key(+Atom, -Name/Arity)
    json_file(+File, -Dict) / write_json(+File, +Term) / ensure_dir(+Dir) */
:- module(netlib, [net_load/2, net_unload/1, net_atoms/2, net_hidden/2, net_edb_atoms/2, is_edb/2,
                   net_edb_preds/2, net_true_input/2, net_bias/2, net_thr/3, net_hidden_inputs/3,
                   net_feeds/3, net_out_sources/3, net_edge_count/2,
                   forward/3, observation_from_queries/3, full_observation/3,
                   show/2, pred_key/2, json_file/2, write_json/2, ensure_dir/1, consts_of/2]).
:- if(exists_source(library(json))).
:- use_module(library(json)).
:- else.
:- use_module(library(http/json)).
:- endif.
:- use_module(library(assoc)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

:- dynamic n_atoms/2, n_hidden/2, n_thr/3, n_hin/4, n_out/4, n_feeds/4, n_bias/2, n_edb/2,
           n_stratum/3, n_true/2, n_edges/2.

% ---------------------------------------------------------------- text and JSON helpers
show(T, S) :- with_output_to(string(S), write_term(T, [quoted(true), ignore_ops(true)])).
parse_atom(S, T) :- term_string(T, S).
pred_key(A, N/Ar) :- functor(A, N, Ar).

json_file(F, D) :- setup_call_cleanup(open(F, read, In, [encoding(utf8)]),
                                      json_read_dict(In, D, [value_string_as(string)]), close(In)).
write_json(F, T) :- setup_call_cleanup(open(F, write, Out, [encoding(utf8)]),
                                       json_write_dict(Out, T, [width(0)]), close(Out)).
ensure_dir(D) :- ( exists_directory(D) -> true ; make_directory_path(D) ).

% neuron ids: in(A), out(A) or hidden(K), read as terms
nid(S, T) :- term_string(T, S).

% ---------------------------------------------------------------- loading
net_load(File, File) :-
    net_unload(File),
    json_file(File, D),
    maplist(parse_atom, D.atoms, Atoms),
    assertz(n_atoms(File, Atoms)),
    forall(member(N, D.neurons), ( nid(N.id, Id), assertz(n_thr(File, Id, N.threshold)) )),
    findall(Id, ( member(N, D.neurons), N.layer == "hidden", nid(N.id, Id) ), Hs),
    assertz(n_hidden(File, Hs)),
    length(D.edges, NE), assertz(n_edges(File, NE)),
    forall(member(E, D.edges),
           ( nid(E.from, F), nid(E.to, T), W = E.weight,
             (   T = hidden(_), F = in(B) -> assertz(n_hin(File, T, B, W))
             ;   T = out(A) -> assertz(n_out(File, A, F, W)),
                 ( F = hidden(_) -> assertz(n_feeds(File, F, A, W)) ; true )
             ;   true
             ) )),
    % bias units: hidden, no incoming edge, negative threshold (they hold the compiled facts)
    forall(( member(H, Hs), \+ n_hin(File, H, _, _), n_thr(File, H, Th), Th < 0 ), assertz(n_bias(File, H))),
    % an input (EDB) predicate: every hidden unit feeding any of its atoms is a bias unit
    findall(P, ( member(A, Atoms), pred_key(A, P) ), Ps0), sort(Ps0, Ps),
    forall(( member(P, Ps), \+ ( n_feeds(File, H, A, _), pred_key(A, P), \+ n_bias(File, H) ) ),
           assertz(n_edb(File, P))),
    findall(A, ( n_bias(File, H), n_feeds(File, H, A, _), is_edb(File, A) ), T0), sort(T0, True),
    assertz(n_true(File, True)),
    strata(File, Atoms).

net_unload(F) :-
    forall(member(P, [n_atoms/2, n_hidden/2, n_thr/3, n_hin/4, n_out/4, n_feeds/4, n_bias/2, n_edb/2,
                      n_stratum/3, n_true/2, n_edges/2]),
           ( P = Name/Ar, functor(G, Name, Ar), arg(1, G, F), retractall(G) )).

net_atoms(F, As) :- n_atoms(F, As).
net_hidden(F, Hs) :- n_hidden(F, Hs).
net_edb_preds(F, Ps) :- findall(P, n_edb(F, P), Ps).
is_edb(F, A) :- pred_key(A, P), n_edb(F, P), !.
net_edb_atoms(F, As) :- n_atoms(F, All), include(is_edb(F), All, As).
net_true_input(F, As) :- n_true(F, As).
net_bias(F, H) :- n_bias(F, H).
net_thr(F, Id, T) :- n_thr(F, Id, T).
net_hidden_inputs(F, H, BWs) :- findall(B-W, n_hin(F, H, B, W), BWs).
net_feeds(F, H, AWs) :- findall(A-W, n_feeds(F, H, A, W), AWs).
net_out_sources(F, A, HWs) :- findall(H-W, n_out(F, A, H, W), HWs).
net_edge_count(F, N) :- n_edges(F, N).

consts_of(F, Cs) :- n_atoms(F, As), findall(S, ( member(A, As), compound(A), A =.. [_|Xs], member(X, Xs), show(X, S) ), C0),
                    sort(C0, Cs).

% ---------------------------------------------------------------- strata
% an atom's stratum is at least its body atoms' strata, plus one through a negative weight
strata(F, Atoms) :-
    empty_assoc(E0), foldl([A, S0, S]>>put_assoc(A, S0, 0, S), Atoms, E0, S1),
    length(Atoms, NA), Limit is NA + 2,
    strata_loop(F, Limit, S1, S2),
    forall(member(A, Atoms), ( get_assoc(A, S2, St), assertz(n_stratum(F, A, St)) )).
strata_loop(_, 0, S, S) :- !.
strata_loop(F, K, S0, S) :-
    findall(H, n_feeds(F, H, _, _), H0), sort(H0, Hs),
    foldl(raise(F), Hs, S0-false, S1-Changed),
    (   Changed == true -> K1 is K - 1, strata_loop(F, K1, S1, S) ; S = S1 ).
raise(F, H, S0-C0, S-C) :-
    findall(B-W, n_hin(F, H, B, W), BWs),
    foldl({S0}/[B-W, N0, N]>>( get_assoc(B, S0, SB), ( W < 0 -> Need is SB + 1 ; Need = SB ), N is max(N0, Need) ),
          BWs, 0, Need),
    findall(A, n_feeds(F, H, A, _), As),
    foldl({Need}/[A, X0-Y0, X-Y]>>( get_assoc(A, X0, SA),
                                    ( SA < Need -> put_assoc(A, X0, Need, X), Y = true ; X = X0, Y = Y0 ) ),
          As, S0-C0, S-C).

% ---------------------------------------------------------------- forward simulation
% Least-model semantics from weights: clamp the input atoms, run each stratum to a fixpoint.
% Within a round every unit reads the activations of the previous round (as the network does).
forward(F, Inputs, Model) :-
    include(is_edb(F), Inputs, In0), list_to_assoc_set(In0, On0),
    n_atoms(F, Atoms), exclude(is_edb(F), Atoms, Idb),
    findall(S, n_stratum(F, _, S), Ss), max_list([0|Ss], Max),
    numlist(0, Max, Levels),
    foldl({F, Idb}/[L, O0, O]>>( include({F, L}/[A]>>n_stratum(F, A, L), Idb, Layer), fix(F, Layer, O0, O) ),
          Levels, On0, On),
    assoc_to_keys(On, Model).

list_to_assoc_set(L, A) :- empty_assoc(E), foldl([X, A0, A1]>>put_assoc(X, A0, true, A1), L, E, A).

fix(F, Layer, On0, On) :-
    include(fires(F, On0), Layer, Fire),
    exclude({On0}/[A]>>get_assoc(A, On0, _), Fire, New),
    (   New == [] -> On = On0
    ;   foldl([X, A0, A1]>>put_assoc(X, A0, true, A1), New, On0, On1), fix(F, Layer, On1, On)
    ).
fires(F, On, A) :-
    findall(W, ( n_out(F, A, H, W), hidden_active(F, On, H) ), Ws), sum_list(Ws, Tot),
    n_thr(F, out(A), T), Tot > T.
hidden_active(F, On, H) :-
    findall(W, ( n_hin(F, H, B, W), get_assoc(B, On, _) ), Ws), sum_list(Ws, S),
    n_thr(F, H, T), S > T.

% ---------------------------------------------------------------- observations
full_observation(F, Model, Obs) :-
    n_atoms(F, Atoms), exclude(is_edb(F), Atoms, Idb), list_to_assoc_set(Model, M),
    maplist({M}/[A, A-V]>>( get_assoc(A, M, _) -> V = true ; V = false ), Idb, Obs).

% The dataset's query answers as true/false literals over the network's atoms (later answers win).
observation_from_queries(F, Queries, Obs) :-
    n_atoms(F, Atoms), empty_assoc(E),
    foldl(query_lits(Atoms), Queries, E-[], _-Order),
    reverse(Order, Ks),
    foldl(query_lits(Atoms), Queries, E-[], A-_),
    findall(K-V, ( member(K, Ks), get_assoc(K, A, V) ), Obs).
query_lits(Atoms, Q, A0-O0, A-O) :-
    Ans = Q.answer,
    (   sub_string(Ans, 0, _, _, "error") -> A = A0, O = O0
    ;   term_string(Pat, Q.query),
        (   memberchk(Ans, ["true", "false"])
        ->  ( Ans == "true" -> V = true ; V = false ), put_lit(Pat-V, A0-O0, A-O)
        ;   term_string(Listed0, Ans), maplist(normal, Listed0, Listed),
            findall(At-V, ( member(At, Atoms), subsumes_term(Pat, At),
                            ( memberchk(At, Listed) -> V = true ; V = false ) ), L1),
            foldl(put_lit, L1, A0-O0, A1-O1),
            findall(L-true, member(L, Listed), L2),
            foldl(put_lit, L2, A1-O1, A-O)
        )
    ).
normal(T, N) :- show(T, S), term_string(N, S).
put_lit(K-V, A0-O0, A-O) :- ( get_assoc(K, A0, _) -> O = O0 ; O = [K|O0] ), put_assoc(K, A0, V, A).
