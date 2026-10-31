/*  stage2_aleph_mnn.pl -- Aleph on the two MNN rules Popper 2.1 could not do: AlgebraPLOp needs a
    formula, Detlog a comparison. Each learns from the input recovered from the network's weights
    (smallest and largest) and the network's output. Needs the networks mnn_rules.pl builds
    (<WORK_DIR>/rule_algebraplop_orig, rule_detlog_orig). Writes stage2_aleph_mnn.json.
    swipl stage2_aleph_mnn.pl */
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(aleph).

:- initialization(main, main).

main :-
    path(work, W), path(results, R), ensure_dir(R),
    format(atom(FA), '~w/rule_algebraplop_orig/net.json', [W]), net_load(FA, NA),
    findall(K-V, ( member(Mode, [smallest, largest]), once(algebraplop(NA, Mode, K, V)) ), L1),
    format(atom(FD), '~w/rule_detlog_orig/net.json', [W]), net_load(FD, ND),
    findall(K-V, ( member(Mode, [smallest, largest]), once(detlog(ND, Mode, K, V)) ), L2),
    append(L1, L2, L), dict_pairs(D, _, L),
    atom_concat(R, '/stage2_aleph_mnn.json', Out), write_json(Out, D).

input(Net, Preds, Mode, Inp, Model) :-
    net_true_input(Net, T), forward(Net, T, Full), net_atoms(Net, As),
    findall(A-V, ( member(A, As), functor(A, N, Ar), memberchk(N/Ar, Preds), ( memberchk(A, Full) -> V = true ; V = false ) ), Obs),
    ( Mode == largest -> M = true ; M = false ),
    invert(Net, Obs, [cap(1), maximize(M)], Inv), get_dict(explanations, Inv, [Inp|_]),
    forward(Net, Inp, Model).

% AlgebraPLOp: val(I,V) from pos/1 with arithmetic helpers
algebraplop(Net, Mode, K, _{input:InpS, theory:ThJ}) :-
    input(Net, [val/2, at/2], Mode, Inp, Model),
    findall(S, ( member(A, Model), functor(A, val, 2), show(A, S) ), P0), sort(P0, Pos),
    findall(S, ( between(0, 4, I), between(0, 9, V), \+ memberchk(val(I, V), Model), format(string(S), "val(~w,~w)", [I, V]) ), Neg),
    maplist(show, Inp, InpS),
    append(InpS, ["mul(X,C,Y) :- member(C,[1,2,3]), Y is X*C", "add(X,C,Y) :- member(C,[-1,0,1,2]), Y is X+C"], BK),
    format(atom(Name), 'algebraplop_~w', [Mode]),
    run_aleph(Name, BK, Pos, Neg,
              ["modeh(1, val(+int,-int))", "modeb(1, pos(+int))", "modeb(*, mul(+int,#int,-int))", "modeb(*, add(+int,#int,-int))"],
              ["val/2"-"pos/1", "val/2"-"mul/3", "val/2"-"add/3"], [minpos-2, i-3, clauselength-4], Th),
    ( Th == none -> ThJ = null ; ThJ = Th ), atom_concat('algebraplop_', Mode, K),
    format("algebraplop ~w ~w ~w~n", [Mode, InpS, ThJ]), flush_output.

% Detlog: cls(X,L) with comparison helpers and label constants
detlog(Net, Mode, K, _{input:InpS, theory:ThJ}) :-
    input(Net, [cls/2], Mode, Inp, Model),
    findall(S, ( member(A, Model), functor(A, cls, 2), show(A, S) ), P0), sort(P0, Pos),
    findall(S, ( member(N, [-2, -1, 0, 1, 2]), member(L, [pos, nonpos]), \+ memberchk(cls(N, L), Model),
                 format(string(S), "cls(~w,~w)", [N, L]) ), Neg),
    maplist(show, Inp, InpS),
    append(InpS, ["gt(X,C) :- member(C,[-1,0,1]), X > C", "le(X,C) :- member(C,[-1,0,1]), X =< C",
                  "lab(pos)", "lab(nonpos)", ":- dynamic num/1"], BK),
    format(atom(Name), 'detlog_~w', [Mode]),
    run_aleph(Name, BK, Pos, Neg,
              ["modeh(1, cls(+int,#lab))", "modeb(1, num(+int))", "modeb(*, gt(+int,#int))", "modeb(*, le(+int,#int))"],
              ["cls/2"-"num/1", "cls/2"-"gt/2", "cls/2"-"le/2"], [minpos-1, i-2, clauselength-3], Th),
    ( Th == none -> ThJ = null ; ThJ = Th ), atom_concat('detlog_', Mode, K),
    format("detlog ~w ~w ~w~n", [Mode, InpS, ThJ]), flush_output.
