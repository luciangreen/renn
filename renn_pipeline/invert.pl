/*  invert.pl -- given only a network's weights and an observed output, find the inputs that produce it.

    The weights are compiled into an answer-set program: every hidden unit fires when its weighted
    input sum exceeds its threshold; every output atom fires when an incoming hidden unit fires;
    recurrent links feed outputs back as inputs. Input atoms are free choices. Stable-model
    semantics gives the least fixpoint, so recursive cycles cannot support themselves (a plain SAT
    encoding would let reach(a,a) "prove itself"). Observed literals become constraints, and
    #minimize (or #maximize) asks for the fewest (or most) input facts. clingo enumerates every
    optimal answer set (--opt-mode=optN, -q1 prints only proven-optimal ones), up to a cap.

    encode(+Net, +Obs, +Opt, -Text)              Opt = minimize | maximize | none
    invert(+Net, +Obs, +Options, -Result)        Options: cap(N), timeout(S), maximize(Bool)
        Result = _{status: sat|unsat|timeout, explanations: [[Atom]], capped: Bool}
    report(+Net, +Obs, +Original, +Cap, -Dict)   invert, then check every answer by forward simulation */
:- module(invert, [encode/4, invert/4, report/5]).
:- use_module(library(process)).
:- use_module(library(readutil)).
:- if(exists_source(library(json))).
:- use_module(library(json)).
:- else.
:- use_module(library(http/json)).
:- endif.
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).
:- use_module(config).
:- use_module(netlib).

scale(1000).

q(A, S) :- show(A, T),
    atomic_list_concat(P1, '\\', T), atomic_list_concat(P1, '\\\\', T1),
    atomic_list_concat(P2, '"', T1), atomic_list_concat(P2, '\\"', T2),
    format(string(S), '"~w"', [T2]).
w(X, I) :- scale(K), I is round(X * K).

encode(Net, Obs, Opt, Text) :-
    net_edb_atoms(Net, Edb), net_hidden(Net, Hs), net_atoms(Net, Atoms),
    findall(L, ( member(A, Edb), q(A, Q), format(string(L), "{ on(~w) }.", [Q]) ), L1),
    findall(L, ( nth0(I, Hs, H), net_feeds(Net, H, Outs), Outs \== [],
                 \+ ( net_bias(Net, H), forall(member(A-_, Outs), is_edb(Net, A)) ),
                 net_hidden_inputs(Net, H, BWs),
                 findall(E, ( nth0(J, BWs, B-Wt), w(Wt, Wi), q(B, QB),
                              format(string(E), "~w,~w,~w : on(~w)", [Wi, QB, J, QB]) ), Es),
                 atomic_list_concat(Es, '; ', ES), net_thr(Net, H, T), w(T, Ti),
                 format(string(L), "h(~w) :- #sum{ ~w } > ~w.", [I, ES, Ti]) ), L2),
    findall(H-I, nth0(I, Hs, H), HI), list_to_assoc(HI, HIx),
    findall(L, ( member(A, Atoms), \+ is_edb(Net, A), net_out_sources(Net, A, Srcs), Srcs \== [],
                 findall(E, ( nth0(J, Srcs, H-Wt), w(Wt, Wi), get_assoc(H, HIx, I),
                              format(string(E), "~w,~w,~w : h(~w)", [Wi, I, J, I]) ), Es),
                 atomic_list_concat(Es, '; ', ES), net_thr(Net, out(A), T), w(T, Ti), q(A, QA),
                 format(string(L), "on(~w) :- #sum{ ~w } > ~w.", [QA, ES, Ti]) ), L3),
    findall(L, ( member(A-V, Obs), q(A, QA), ( V == true -> N = "not " ; N = "" ),
                 format(string(L), ":- ~won(~w).", [N, QA]) ), L4),
    findall(L, ( member(A, Edb), q(A, QA), format(string(L), "in(~w) :- on(~w).", [QA, QA]) ), L5),
    (   Opt == minimize -> L6 = ["#minimize { 1,A : in(A) }."]
    ;   Opt == maximize -> L6 = ["#maximize { 1,A : in(A) }."]
    ;   L6 = []
    ),
    append([L1, L2, L3, L4, L5, L6, ["#show in/1."]], Ls),
    atomic_list_concat(Ls, '\n', Text).

invert(Net, Obs, Options, Result) :-
    option_(cap(Cap), Options, 2000), option_(timeout(TO), Options, 60),
    option_(maximize(Max), Options, false),
    ( Max == true -> Opt = maximize ; Opt = minimize ),
    encode(Net, Obs, Opt, Text),
    tmp_file_stream(text, F, S), write(S, Text), close(S),
    path(clingo, Clingo),
    format(atom(TL), '--time-limit=~w', [TO]), atom_number(CapA, Cap),
    process_create(path(Clingo), [F, '--opt-mode=optN', '--opt-strategy=usc', CapA, '--warn=none',
                                  '-q1', '--outf=2', TL],
                   [stdout(pipe(Out)), stderr(null), process(Pid)]),
    read_string(Out, _, JS), close(Out), process_wait(Pid, _),
    delete_file(F),
    atom_json_dict(JS, D, [value_string_as(string)]),
    get_dict('Result', D, R),
    findall(E, ( get_dict('Call', D, Calls), member(C, Calls), get_dict('Witnesses', C, Ws), member(W, Ws),
                 get_dict('Value', W, Vs), maplist(shown_atom, Vs, E0), msort(E0, E) ), Es),
    length(Es, NE),
    (   R == "UNSATISFIABLE" -> Result = _{status:unsat, explanations:[], capped:false}
    ;   get_dict('Models', D, M), get_dict('Optimum', M, "yes")
    ->  ( NE >= Cap -> Capped = true ; Capped = false ),
        Result = _{status:sat, explanations:Es, capped:Capped}
    ;   Result = _{status:timeout, explanations:Es, capped:true}
    ).

shown_atom(V, A) :- term_string(in(S), V), term_string(A, S).
option_(O, Opts, D) :- ( memberchk(O, Opts) -> true ; arg(1, O, D) ).

report(Net, Obs, Original, Cap, Out) :-
    invert(Net, Obs, [cap(Cap)], R),
    Es = R.explanations, length(Es, N),
    ( Es = [E1|_] -> length(E1, Min) ; Min = null ),
    take(20, Es, E20), maplist(maplist(show), E20, E20s),
    (   forall(member(E, Es), reproduces(Net, E, Obs)) -> Ok = true ; Ok = false ),
    Out0 = _{status:R.status, n_explanations:N, capped:R.capped, min_size:Min, explanations:E20s,
             all_verified_forward:Ok},
    (   Original == none -> Out = Out0
    ;   msort(Original, Orig), length(Orig, OS),
        ( memberchk(Orig, Es) -> IsMin = true ; IsMin = false ),
        ( Es == [Orig] -> Uniq = true ; Uniq = false ),
        ( reproduces(Net, Orig, Obs) -> Cons = true ; Cons = false ),
        Out = Out0.put(_{orig_size:OS, orig_is_minimal_explanation:IsMin, orig_unique:Uniq, orig_consistent:Cons})
    ).

reproduces(Net, In, Obs) :-
    forward(Net, In, M),
    forall(member(A-V, Obs), ( memberchk(A, M) -> V == true ; V == false )).

take(N, L, T) :- length(L, Len), ( Len =< N -> T = L ; length(T, N), append(T, _, L) ).
