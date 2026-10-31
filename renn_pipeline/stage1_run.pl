/*  stage1_run.pl -- Stage 1 over the dataset: find each network's input from its output.
    Regime Q observes the dataset's own query answers; regime F the whole output layer.
    Writes <RESULTS_DIR>/stage1.json.      swipl stage1_run.pl */
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).

:- initialization(main, main).

main :-
    path(exp, Exp), path(results, R), ensure_dir(R),
    atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    include([P]>>( get_dict(error, P, null), get_dict(network, P, N), get_dict(fixpoint, N, "true") ), Pairs, Ps),
    foldl(pair_rows(Exp), Ps, [], Rows0), reverse(Rows0, Rows),
    atom_concat(R, '/stage1.json', Out), write_json(Out, Rows).

pair_rows(Exp, P, R0, R) :-
    get_dict(id, P, Id), get_dict(category, P, Cat), get_dict(queries, P, Qs),
    format(atom(F), '~w/nets/~w/net.json', [Exp, Id]), net_load(F, Net),
    net_edb_atoms(Net, Edb),
    (   Edb == [] -> R = [_{id:Id, category:Cat, closed:true}|R0]
    ;   net_true_input(Net, In), forward(Net, In, Full), full_observation(Net, Full, ObsF),
        observation_from_queries(Net, Qs, ObsQ), length(Edb, NE),
        row(Net, In, Id, Cat, NE, "Q"-ObsQ, RQ), row(Net, In, Id, Cat, NE, "F"-ObsF, RF),
        R = [RF, RQ|R0],
        format("~w ~w ~w~n", [Id, Cat, [RQ.regime-RQ.status-RQ.min_size-RQ.orig_size-RQ.n_explanations,
                                        RF.regime-RF.status-RF.min_size-RF.orig_size-RF.n_explanations]]), flush_output
    ),
    net_unload(Net).

row(Net, In, Id, Cat, NE, Reg-Obs, Row) :-
    get_time(T0), report(Net, Obs, In, 500, Rep), get_time(T1), S is round((T1 - T0) * 1000) / 1000,
    length(Obs, NO),
    Row = Rep.put(_{id:Id, category:Cat, regime:Reg, n_obs:NO, n_edb_atoms:NE, seconds:S}).
