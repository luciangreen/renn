/*  stage2_popper.pl -- Stage 2: Popper learns code from (recovered input, network output).

    Background knowledge = the smallest input recovered from the weights in Stage 1 (the first
    answer). Examples = the network's output on that input: regime F uses every tuple of the
    target predicate over the network's constants (true -> pos, false -> neg); regime Q uses only
    the dataset's own query answers. Writes <RESULTS_DIR>/stage2.json.

    swipl stage2_popper.pl            all networks of the five tasks
    swipl stage2_popper.pl 1,2,43     only these ids (writes stage2_probe.json) */
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).
:- use_module(datalog).
:- use_module(popper_tasks).

:- initialization(main, main).

main :-
    current_prolog_flag(argv, Argv),
    path(exp, Exp), path(results, R), ensure_dir(R),
    atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    (   Argv = [IdsA|_]
    ->  split_string(IdsA, ",", "", IS), maplist(number_string, Ids, IS), Out = 'stage2_probe.json'
    ;   findall(Id, ( member(P, Pairs), get_dict(error, P, null), task_of(P, _), get_dict(id, P, Id) ), Ids),
        Out = 'stage2.json'
    ),
    findall(Res, ( member(Id, Ids), member(Reg, ["F", "Q"]), member(P, Pairs), get_dict(id, P, Id),
                   once(one(Exp, P, Reg, Res)) ), Rows),
    format(atom(OF), '~w/~w', [R, Out]), write_json(OF, Rows).

one(Exp, P, Reg, Res) :-
    get_dict(id, P, Id), task_of(P, Tk), task(Tk, Target, Ar, Body, Extra),
    format(atom(F), '~w/nets/~w/net.json', [Exp, Id]), net_load(F, Net),
    net_true_input(Net, True), forward(Net, True, Full),
    (   Reg == "F" -> full_observation(Net, Full, Obs) ; observation_from_queries(Net, P.queries, Obs) ),
    invert(Net, Obs, [cap(1)], Inv), get_dict(explanations, Inv, [Inp|_]),
    forward(Net, Inp, Model),
    consts_of(Net, Cs),
    (   Reg == "F"
    ->  findall(S-V, ( length(Tup, Ar), maplist({Cs}/[X]>>member(X, Cs), Tup), atomic_list_concat(Tup, ',', J),
                       format(string(S), "~w(~w)", [Target, J]), term_string(T, S),
                       ( memberchk(T, Model) -> V = true ; V = false ) ), Exs0)
    ;   findall(S-V, ( member(A-V, Obs), functor(A, Target, Ar), show(A, S) ), Exs0)
    ),
    msort(Exs0, Exs),
    path(work, W), format(atom(D), '~w/popper/~w_~w', [W, Id, Reg]), ensure_dir(D),
    findall(L, ( member(A, Inp), show(A, S), format(string(L), "~w.", [S]) ), BK1),
    (   memberchk("neq/2", Body)
    ->  findall(L, ( member(X, Cs), member(Y, Cs), X \== Y, format(string(L), "neq(~w,~w).", [X, Y]) ), BK2)
    ;   BK2 = []
    ),
    findall(L, ( member(B, Body), format(string(L), ":- dynamic ~w.", [B]) ), BK3),
    append([BK1, BK2, BK3], BKL), lines(BKL, BKT), file(D, 'bk.pl', BKT),
    findall(L, ( member(S-V, Exs), ( V == true -> K = pos ; K = neg ), format(string(L), "~w(~w).", [K, S]) ), EL),
    lines(EL, ET), file(D, 'exs.pl', ET),
    findall(L, ( member(B, Body), split_string(B, "/", "", [BN, BA]), format(string(L), "body_pred(~w,~w).~n", [BN, BA]) ), BPs),
    atomic_list_concat(BPs, BPT), format(string(Bias), "head_pred(~w,~w).~n~w~w", [Target, Ar, BPT, Extra]),
    file(D, 'bias.pl', Bias),
    popper_dir(D, 120, Prog, Stats-Secs),
    include([_-true]>>true, Exs, Pos), length(Pos, NP), length(Exs, NX), NN is NX - NP,
    length(Inp, IS), length(True, OS),
    Res0 = _{id:Id, task:Tk, regime:Reg, n_pos:NP, n_neg:NN, input_size:IS, orig_input_size:OS,
             popper:Prog, stats:Stats, seconds:Secs},
    (   Prog == null -> Res = Res0, Repro = none, Agr = none
    ;   parse_program(P.program, OrigAll), include([_-B]>>(B \== []), OrigAll, Orig),
        parse_program(Prog, Learned),
        include({Target, Ar}/[A]>>functor(A, Target, Ar), Full, MNet0), sort(MNet0, MNet),
        least_model(Learned, True, ML0), include({Target, Ar}/[A]>>functor(A, Target, Ar), ML0, MLearn0), sort(MLearn0, MLearn),
        ( MNet == MLearn -> Repro = true ; Repro = false ),
        body_names(Body, Names),
        findall(K, ( net_edb_atoms(Net, EA), member(A, EA), functor(A, N, AA), memberchk(N, Names), K = N/AA ), E0),
        sort(E0, Edb),
        lower_consts(Net, LC), take(6, LC, C6),
        agreement(Orig, Learned, Edb, C6, [Target/Ar], [trials(100)], Agr),
        Res = Res0.put(_{reproduces_network_on_original_input:Repro, agreement_random_inputs:Agr})
    ),
    ( Prog == null -> PT = "NO SOLUTION" ; re_replace("\n"/g, " | ", Prog, PT) ),
    format("~w ~w ~w ~w ~w ~w ~w~n", [Id, Reg, Tk, PT, Repro, Agr, Secs]), flush_output,
    net_unload(Net).

body_names(Body, Names) :- findall(N, ( member(B, Body), B \== "neq/2", split_string(B, "/", "", [NS, _]), atom_string(N, NS) ), Names).
% constants that start with a lower-case letter, as the regular expression [a-z]\w* finds them
lower_consts(Net, Cs) :-
    net_atoms(Net, [A0|_]), compound(A0), !,
    net_atoms(Net, As),
    findall(C, ( member(A, As), show(A, S), once(sub_string(S, B, _, _, "(")), B1 is B + 1, sub_string(S, B1, _, 0, Rest),
                 re_foldl([M, X0, [X|X0]]>>get_dict(0, M, X), "[a-z]\\w*", Rest, [], L, []), member(X, L), atom_string(C, X) ), C0),
    sort(C0, Cs).
lower_consts(_, []).

lines(Ls, T) :- atomic_list_concat(Ls, '\n', J), format(string(T), "~w~n", [J]).
file(D, N, T) :- format(atom(F), '~w/~w', [D, N]), write_text(F, T).

