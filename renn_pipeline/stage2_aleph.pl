/*  stage2_aleph.pl -- Stage 2 with Aleph for the 15 negation networks.

    The input is found from the network's output (smallest input, and largest input); then Aleph
    learns each derived predicate with closed-world not_P/1 background predicates. The learned rules
    are compared with the original program (not_P expanded to obj(X), \+ P(X)) three ways: on the
    input, on every set of exceptions (all birds kept, every subset of the other facts), and on every
    subset of the original facts. Writes <RESULTS_DIR>/stage2_aleph_negation.json.
    swipl stage2_aleph.pl */
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).
:- use_module(datalog).
:- use_module(aleph).

:- initialization(main, main).

main :-
    path(exp, Exp), path(results, R), ensure_dir(R),
    atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    findall(Row, ( member(P, Pairs), get_dict(category, P, "negation/stratified"),
                   member(Mode, [smallest, largest]), once(run(Exp, P, Mode, Row)) ), Rows),
    atom_concat(R, '/stage2_aleph_negation.json', Out), write_json(Out, Rows),
    forall(member(Mode, [smallest, largest]),
           forall(member(K, [on_input, on_all_exception_sets, on_all_subsets]),
                  ( include({Mode, K}/[X]>>( get_dict(mode, X, Mode), get_dict(equal_on_all_subsets, X, E),
                                              is_dict(E), get_dict(K, E, true) ), Rows, Y),
                    include({Mode}/[X]>>get_dict(mode, X, Mode), Rows, All),
                    length(Y, NY), length(All, NA), format("~w ~w ~w of ~w~n", [Mode, K, NY, NA]) ))).

run(Exp, P, Mode, Row) :-
    get_dict(id, P, Id), format(atom(F), '~w/nets/~w/net.json', [Exp, Id]), net_load(F, Net),
    net_true_input(Net, True), forward(Net, True, Full), full_observation(Net, Full, Obs),
    net_atoms(Net, Atoms), exclude(is_edb(Net), Atoms, Idb),
    net_edb_atoms(Net, EA), findall(N, ( member(A, EA), functor(A, N, _) ), E0), sort(E0, Edb),
    findall(N, ( member(A, Idb), functor(A, N, _) ), I0), sort(I0, IdbP),
    ( Mode == largest -> Max = true ; Max = false ),
    invert(Net, Obs, [cap(1), maximize(Max)], Inv), get_dict(explanations, Inv, [Inp|_]),
    forward(Net, Inp, Model),
    findall(S, ( member(A, Atoms), compound(A), A =.. [_|Xs], member(X, Xs), show(X, S) ), C0), sort(C0, Consts),
    maplist(show, Inp, InpS),
    foldl(learn_one(Id, Mode, Edb, IdbP, Model, InpS, Consts), IdbP, []-[], Ths-Learned0),
    reverse(Learned0, LearnedAll), dict_pairs(ThD, _, Ths),
    (   LearnedAll == [] -> Same = null
    ;   compare_programs(P, LearnedAll, Consts, Same)
    ),
    Row = _{id:Id, mode:Mode, input:InpS, theory:ThD, equal_on_all_subsets:Same},
    format("~w ~w ~w ~p ~p~n", [Id, Mode, Inp, ThD, Same]), flush_output,
    net_unload(Net).

learn_one(Id, Mode, Edb, IdbP, Model, InpS, Consts, Tgt, Th0-L0, [Tgt-ThJ|Th0]-L) :-
    append(Edb, IdbP, AllP), exclude(==(Tgt), AllP, Others),
    findall(S, ( member(C, Consts), format(string(S), "~w(~w)", [Tgt, C]), term_string(T, S), memberchk(T, Model) ), Pos),
    findall(S, ( member(C, Consts), format(string(S), "~w(~w)", [Tgt, C]), term_string(T, S), \+ memberchk(T, Model) ), Neg),
    findall(S, ( member(A, Model), functor(A, N, _), memberchk(N, IdbP), N \== Tgt, show(A, S) ), BK2),
    findall(S, ( member(C, Consts), format(string(S), "obj(~w)", [C]) ), BK3),
    findall(S, ( member(E, Others), format(string(S), "not_~w(X) :- obj(X), \\+ ~w(X)", [E, E]) ), BK4),
    findall(S, ( member(E, Others), format(string(S), ":- dynamic ~w/1", [E]) ), BK5),
    append([InpS, BK2, BK3, BK4, BK5], BK),
    format(string(MH), "modeh(1, ~w(+obj))", [Tgt]),
    findall(S, ( member(E, Others), format(string(S), "modeb(1, ~w(+obj))", [E]) ), MB1),
    findall(S, ( member(E, Others), format(string(S), "modeb(1, not_~w(+obj))", [E]) ), MB2),
    append([[MH], MB1, MB2], Modes),
    findall(H-B, ( member(E, Others), format(string(H), "~w/1", [Tgt]), format(string(B), "~w/1", [E]) ), D1),
    findall(H-B, ( member(E, Others), format(string(H), "~w/1", [Tgt]), format(string(B), "not_~w/1", [E]) ), D2),
    append(D1, D2, Dets),
    format(atom(Name), 'neg_~w_~w_~w', [Id, Mode, Tgt]),
    (   Pos == [] -> Th = []
    ;   run_aleph(Name, BK, Pos, Neg, Modes, Dets, [minpos-1, i-2, clauselength-4], Th)
    ),
    ( Th == none -> ThJ = null ; ThJ = Th ),
    (   is_list(Th)
    ->  foldl([T0, A0, [T3|A0]]>>( ( sub_string(T0, 0, 1, _, "("), sub_string(T0, _, 1, 0, ")") -> sub_string(T0, 1, _, 1, T1) ; T1 = T0 ),
                                    re_replace("not_(\\w+)\\((\\w+)\\)"/g, "obj($2), \\\\+ $1($2)", T1, T3) ), Th, L0, L)
    ;   L = L0
    ).

compare_programs(P, LearnedAll, Consts, _{on_input:OI, on_all_exception_sets:OE, on_all_subsets:OA}) :-
    atomic_list_concat(LearnedAll, '.\n', LT), format(string(LText), "~w.~n", [LT]),
    parse_program(LText, Learned),
    parse_program(P.program, Orig0), include([_-B]>>(B \== []), Orig0, OrigRules),
    findall(H, member(H-[], Orig0), Facts0),
    findall(obj(C), ( member(CS, Consts), term_string(C, CS) ), Objs),
    ( agree(OrigRules, Learned, Objs, Facts0) -> OI = true ; OI = false ),
    partition([F]>>functor(F, bird, _), Facts0, Typed, Rest),
    ( forall(subset_of(Rest, S), ( append(Typed, S, In), agree(OrigRules, Learned, Objs, In) )) -> OE = true ; OE = false ),
    ( forall(subset_of(Facts0, S), agree(OrigRules, Learned, Objs, S)) -> OA = true ; OA = false ).

agree(Orig, Learned, Objs, Sub) :-
    least_model(Orig, Sub, M1), include([A]>>functor(A, flies, _), M1, F1),
    append(Sub, Objs, In2), least_model(Learned, In2, M2), include([A]>>functor(A, flies, _), M2, F2),
    sort(F1, S1), sort(F2, S2), S1 == S2.

subset_of([], []).
subset_of([X|Xs], [X|Ys]) :- subset_of(Xs, Ys).
subset_of([_|Xs], Ys) :- subset_of(Xs, Ys).
