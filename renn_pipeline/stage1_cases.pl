/*  stage1_cases.pl -- Stage 1b: trivial, edge and interesting inversion cases, each compiled from
    Prolog with pl2ann and inverted from the weights only. Writes <RESULTS_DIR>/stage1_cases.json.
    swipl stage1_cases.pl */
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).

:- initialization(main, main).

reach("reach(X, Y) :- edge(X, Y).\nreach(X, Y) :- edge(X, Z), reach(Z, Y).\n").
flies("flies(X) :- bird(X), \\+ penguin(X).\n").

% case(Name, Kind, ProgramParts, Observation, Note, Pl2annOptions)
%   Observation: lits([Atom-Bool]) as given, or full(TrueAtoms) = every output atom, true iff listed
case('T1_single_edge', trivial, ["edge(a, b).\n", reach], lits([reach(a,b)-true]), "one output, one input", []).
case('T2_and_gate', trivial, ["bit(0).\nbit(1).\nand(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.\n"],
     lits([and(1,1)-true]), "AND gate output needs bit(1) only", []).
case('E1_empty_output', edge, ["edge(a, b).\nedge(b, c).\n", reach], full([]), "nothing active: the empty input explains it", []).
case('E2_impossible_output', edge, ["edge(a, b).\nedge(b, c).\n", reach],
     lits([reach(a,b)-true, reach(b,c)-true, reach(a,c)-false]), "not transitively closed, so no input can produce it", []).
case('E3_self_loop', edge, ["edge(a, a).\nedge(b, c).\n", reach], full([reach(a,a), reach(b,c)]), "a self-reach needs a cycle", []).
case('E4_unknown_neuron', edge, ["edge(a, b).\n", reach], lits([reach(a,z)-true]),
     "observation names an atom the network has no neuron for", []).
case('E5_exception_hidden', edge, ["bird(tweety).\nbird(pingu).\npenguin(pingu).\n", flies],
     lits([flies(tweety)-true, flies(pingu)-false]), "negation: a silent exception is dropped by minimality", []).
case('E6_exception_revealed', edge, ["bird(tweety).\nbird(pingu).\npenguin(pingu).\n", flies],
     lits([flies(tweety)-true, flies(pingu)-false, bird(pingu)-true]), "observing one input forces the exception back", []).
case('E7_step_limited', edge, ["edge(a, b).\nedge(b, c).\n", reach], lits([reach(a,c)-true]),
     "network built with --step-limit 1; weights carry no step limit", ['--step-limit', '1']).
case('I1_shortcut_lost', interesting, ["edge(a, b).\nedge(b, c).\nedge(a, c).\n", reach],
     full([reach(a,b), reach(b,c), reach(a,c)]), "the shortcut edge is invisible in the output", []).
case('I2_cycle_ambiguity', interesting, ["edge(a, b).\nedge(b, c).\nedge(c, a).\n", reach], full(All),
     "a full closure has several minimal cycles", []) :-
    findall(reach(X, Y), ( member(X, [a,b,c]), member(Y, [a,b,c]) ), All).
case('I3_xor', interesting, ["bit(0).\nbit(1).\nsame(X, Y) :- bit(X), bit(Y), X = Y.\nxor(X, Y) :- bit(X), bit(Y), \\+ same(X, Y).\n"],
     lits([xor(0,1)-true]), "XOR true needs both bits present", []).
case('I4_grandparent', interesting, ["parent(ann, bob).\nparent(bob, cy).\nparent(ann, dee).\ngrandparent(X, Y) :- parent(X, Z), parent(Z, Y).\n"],
     full([grandparent(ann,cy)]), "the middle person must be invented", []).

main :-
    path(results, R), ensure_dir(R),
    findall(C, ( case(N, K, Parts, O, Note, Opts), once(run_case(N, K, Parts, O, Note, Opts, C)) ), Cs),
    atom_concat(R, '/stage1_cases.json', Out), write_json(Out, Cs),
    forall(member(C, Cs), print_case(C)).

part(reach, S) :- !, reach(S).
part(flies, S) :- !, flies(S).
part(S, S).

run_case(N, K, Parts, O, Note, Opts, C) :-
    maplist(part, Parts, Ss), atomic_list_concat(Ss, Prog),
    atom_concat('cases/', N, Name),
    compile_net(Name, Prog, none, Opts, _-Net),
    observation(Net, O, Obs),
    net_atoms(Net, Atoms),
    findall(S, ( member(A-_, Obs), \+ memberchk(A, Atoms), show(A, S) ), Missing),
    (   Missing \== []
    ->  C = _{case:N, kind:K, note:Note, status:"no such output neuron", missing:Missing}
    ;   net_true_input(Net, In), report(Net, Obs, In, 2000, Rep),
        findall(K-true, ( member(A-true, Obs), show(A, S), atom_string(K, S) ), TL), dict_pairs(TD, _, TL),
        length(Obs, NO), maplist(show, In, InS),
        C = Rep.put(_{case:N, kind:K, note:Note, observation:TD, n_obs:NO, original_input:InS})
    ),
    net_unload(Net).

observation(_, lits(L), L).
observation(Net, full(True), Obs) :-
    net_atoms(Net, Atoms), exclude(is_edb(Net), Atoms, Idb),
    findall(A-V, ( member(A, Idb), ( memberchk(A, True) -> V = true ; V = false ) ), Obs).

print_case(C) :-
    ( get_dict(status, C, St) -> true ; St = none ),
    ( get_dict(explanations, C, E) -> take(4, E, E4) ; E4 = [] ),
    findall(V, ( member(K, [min_size, n_explanations, orig_size, orig_is_minimal_explanation]),
                 ( get_dict(K, C, V) -> true ; V = none ) ), [Mi, Ne, Os, Om]),
    format("~w ~w min ~w n ~w orig ~w origMin ~w ~w~n", [C.case, St, Mi, Ne, Os, Om, E4]).
