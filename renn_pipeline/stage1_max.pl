/*  stage1_max.pl -- Stage 1 again, choosing the LARGEST input consistent with the output
    instead of the smallest. Writes <RESULTS_DIR>/stage1_max.json.    swipl stage1_max.pl */
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).

:- initialization(main, main).

main :-
    path(exp, Exp), path(results, R), ensure_dir(R),
    atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    include([P]>>( get_dict(error, P, null), get_dict(network, P, N), get_dict(fixpoint, N, "true") ), Pairs, Ps),
    foldl(pair_rows(Exp), Ps, [], Rows0), reverse(Rows0, Rows),
    atom_concat(R, '/stage1_max.json', Out), write_json(Out, Rows),
    forall(member(Reg, ["Q", "F"]),
           ( include({Reg}/[X]>>get_dict(regime, X, Reg), Rows, S), length(S, N),
             count(unique, S, U), count(orig_among, S, A), count(verified, S, V),
             format("~w ~w unique ~w among ~w verified ~w~n", [Reg, N, U, A, V]) )).

count(K, Rows, N) :- include({K}/[X]>>get_dict(K, X, true), Rows, L), length(L, N).

pair_rows(Exp, P, R0, R) :-
    get_dict(id, P, Id), get_dict(category, P, Cat), get_dict(queries, P, Qs),
    format(atom(F), '~w/nets/~w/net.json', [Exp, Id]), net_load(F, Net),
    net_edb_atoms(Net, Edb),
    (   Edb == [] -> R = R0
    ;   net_true_input(Net, In), msort(In, Orig), length(Orig, OS),
        forward(Net, In, Full), full_observation(Net, Full, ObsF),
        observation_from_queries(Net, Qs, ObsQ),
        row(Net, Orig, OS, Id, Cat, "Q"-ObsQ, RQ), row(Net, Orig, OS, Id, Cat, "F"-ObsF, RF),
        R = [RF, RQ|R0]
    ),
    net_unload(Net).

row(Net, Orig, OS, Id, Cat, Reg-Obs, Row) :-
    get_time(T0), invert(Net, Obs, [cap(50), maximize(true), timeout(120)], Inv), get_time(T1),
    S is round((T1 - T0) * 100) / 100, get_dict(explanations, Inv, Es), length(Es, NE),
    ( Es == [Orig] -> U = true ; U = false ), ( memberchk(Orig, Es) -> Am = true ; Am = false ),
    (   forall(member(E, Es), ( forward(Net, E, M),
                                forall(member(A-V, Obs), ( memberchk(A, M) -> V == true ; V == false )) ))
    ->  Ok = true ; Ok = false ),
    ( Es = [E1|_] -> length(E1, MS) ; MS = null ),
    Row = _{id:Id, category:Cat, regime:Reg, status:Inv.status, n:NE, capped:Inv.capped, unique:U,
            orig_among:Am, verified:Ok, seconds:S, max_size:MS, orig_size:OS}.
