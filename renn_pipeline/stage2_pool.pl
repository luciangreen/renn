/*  stage2_pool.pl -- Stage 2b: pool the recovered inputs and outputs of all networks that share a
    program shape, then learn once. Each network's constants are renamed apart (g<id>_<const>) so
    graphs do not merge. Writes <RESULTS_DIR>/stage2_pool.json.     swipl stage2_pool.pl */
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).
:- use_module(datalog).
:- use_module(popper_tasks).

:- initialization(main, main).

main :-
    path(exp, Exp), path(results, R), ensure_dir(R),
    atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    findall(Res, ( member(T, ["recursion/reachability", "relations/family:ancestor", "relations/family:sibling",
                              "relations/family:grandparent", "negation/stratified"]),
                   member(Reg, ["F", "Q"]), once(pooled(Exp, Pairs, T, Reg, Res)) ), Rows),
    atom_concat(R, '/stage2_pool.json', Out), write_json(Out, Rows).

rename(S, Id, T) :- format(string(Rep), "g~w_$1", [Id]), re_replace("(?<=[(,])([a-z]\\w*)"/g, Rep, S, T).

pooled(Exp, Pairs, Tk, Reg, Res) :-
    task(Tk, Target, Ar, Body, Extra),
    findall(P, ( member(P, Pairs), get_dict(error, P, null), task_of(P, Tk) ), Ps),
    foldl(net_part(Exp, Tk, Reg), Ps, []-[], BK0-Ex0),
    sort(BK0, BK1), findall(L, ( member(B, Body), format(string(L), ":- dynamic ~w.", [B]) ), Dyn),
    append(BK1, Dyn, BKL),
    sort(Ex0, Exs),                                   % renamed apart, so no clashes; by text
    path(work, W), re_replace("[/:]"/g, "_", Tk, TkF), format(atom(D), '~w/popper/pool_~w_~w', [W, TkF, Reg]), ensure_dir(D),
    lines(BKL, BKT), file(D, 'bk.pl', BKT),
    findall(L, ( member(S-V, Exs), ( V == true -> K = pos ; K = neg ), format(string(L), "~w(~w).", [K, S]) ), EL),
    lines(EL, ET), file(D, 'exs.pl', ET),
    findall(L, ( member(B, Body), split_string(B, "/", "", [BN, BA]), format(string(L), "body_pred(~w,~w).~n", [BN, BA]) ), BPs),
    atomic_list_concat(BPs, BPT), format(string(Bias), "head_pred(~w,~w).~n~w~w", [Target, Ar, BPT, Extra]),
    file(D, 'bias.pl', Bias),
    popper_dir(D, 300, Prog, Stats-Secs),
    length(Ps, NN), include([_-true]>>true, Exs, Pos), length(Pos, NP), length(Exs, NX), NNeg is NX - NP,
    Res0 = _{task:Tk, regime:Reg, networks:NN, n_pos:NP, n_neg:NNeg, popper:Prog, stats:Stats, seconds:Secs},
    (   Prog == null -> Res = Res0, Agr = none
    ;   Ps = [P1|_], parse_program(P1.program, OrigAll), include([_-B]>>(B \== []), OrigAll, Orig),
        parse_program(Prog, Learned),
        findall(N/A, ( member(B, Body), B \== "neq/2", split_string(B, "/", "", [NS, AS]), atom_string(N, NS), number_string(A, AS) ), Edb),
        agreement(Orig, Learned, Edb, [a, b, c, d, e], [Target/Ar], [trials(200)], Agr),
        Res = Res0.put(agreement_random_inputs, Agr)
    ),
    ( Prog == null -> PT = "NONE" ; re_replace("\n"/g, " | ", Prog, PT) ),
    format("~w ~w ~w ~w ~w~n", [Tk, Reg, PT, Agr, Secs]), flush_output.

net_part(Exp, Tk, Reg, P, BK0-Ex0, BK-Ex) :-
    task(Tk, Target, Ar, Body, _), get_dict(id, P, Id),
    format(atom(F), '~w/nets/~w/net.json', [Exp, Id]), net_load(F, Net),
    net_true_input(Net, True), forward(Net, True, Full),
    (   Reg == "F" -> full_observation(Net, Full, Obs) ; observation_from_queries(Net, P.queries, Obs) ),
    invert(Net, Obs, [cap(1)], Inv), get_dict(explanations, Inv, [Inp|_]), forward(Net, Inp, Model),
    consts_of(Net, Cs),
    (   Reg == "F"
    ->  findall(S-V, ( length(Tup, Ar), maplist({Cs}/[X]>>member(X, Cs), Tup), atomic_list_concat(Tup, ',', J),
                       format(string(S), "~w(~w)", [Target, J]), term_string(T, S),
                       ( memberchk(T, Model) -> V = true ; V = false ) ), E)
    ;   findall(S-V, ( member(A-V, Obs), functor(A, Target, Ar), show(A, S) ), E)
    ),
    findall(L, ( member(A, Inp), show(A, S), rename(S, Id, S1), format(string(L), "~w.", [S1]) ), B1),
    (   memberchk("neq/2", Body)
    ->  findall(L, ( member(X, Cs), member(Y, Cs), X \== Y, format(string(L), "neq(g~w_~w,g~w_~w).", [Id, X, Id, Y]) ), B2)
    ;   B2 = []
    ),
    findall(S1-V, ( member(S-V, E), rename(S, Id, S1) ), ER),
    append([BK0, B1, B2], BK), append(Ex0, ER, Ex),
    net_unload(Net).

lines(Ls, T) :- atomic_list_concat(Ls, '\n', J), format(string(T), "~w~n", [J]).
file(D, N, T) :- format(atom(F), '~w/~w', [D, N]), write_text(F, T).
