/*  mnn_rules.pl -- run the full method on each MNN optimisation rule: S2A, Starlog, PID, loop2,
    PLOp, AlgebraPLOp, Detlog, Piglog2.

    For each rule: compile the ORIGINAL program with pl2ann; prove the net matches the Prolog; find
    the input from the net's output; let Popper learn code from that input and output; prove what
    Popper's code is equivalent to; then let Spec to Algorithm learn the rule's rewrite (original ->
    optimised) from two renamed examples and apply it to two unseen renamed programs, proving each
    result. Writes <RESULTS_DIR>/mnn_all.json (or mnn_<rules>.json for named rules).

    swipl mnn_rules.pl                  every rule
    swipl mnn_rules.pl pid loop2b       only these */
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).

:- initialization(main, main).

% rule(Key, Title, Domain, Targets, PopperRuns, Edb, Consts, RenamedPredicates, ExtraBK)
%   PopperRuns: [run(Label, Head/Arity, Body, BiasExtras)]
rule(s2a, "Spec to Algorithm: generalise examples into address mappings", none, [out1/2, out2/2],
     [run("out1", out1/2, ["in1/2", "in2/2"], "max_vars(2).\nmax_body(1).\n"),
      run("out2", out2/2, ["in1/2", "in2/2"], "max_vars(2).\nmax_body(1).\n")],
     ["in1/2", "in2/2"], [e1, e2], [in1, in2, out1, out2], []).
rule(starlog, "Starlog: nest single-use intermediate results", none, [r/2],
     [run("base predicates", r/2, ["f/2", "g/2", "h/2"], "max_vars(4).\nmax_body(3).\n")],
     ["f/2", "g/2", "h/2"], [a, b, c], [f, g, h, t1, t2, r], []).
rule(pid, "Prolog Inductive Debugger: drop no-progress recursion, recurse after progress", none, [path/2],
     [run("recursive", path/2, ["edge/2"], "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n")],
     ["edge/2"], [a, b, c], [edge, path], []).
rule(loop2b, "loop2: splice the generator into its caller", none, [col/1],
     [run("generator and wrapper available", col/1, ["colour/1", "q/1"], "max_vars(1).\nmax_body(1).\n"),
      run("generator only", col/1, ["colour/1"], "max_vars(1).\nmax_body(1).\n")],
     ["colour/1"], [red, blue, green], [colour, q, col], []).
rule(plop, "PLOp: unfold helpers and compute the shared call once", none, [report/2],
     [run("base predicates only", report/2, ["sub/2", "fin/2", "good/1", "lab/2"], "max_vars(4).\nmax_body(4).\n"),
      run("helpers also available", report/2, ["sub/2", "fin/2", "good/1", "lab/2", "exp/2", "row1/2", "row2/2"], "max_vars(4).\nmax_body(4).\n")],
     ["sub/2", "fin/2", "good/1", "lab/2"], [a, s1, v1], [sub, fin, good, lab, exp, row1, row2, report], []).
rule(algebraplop, "AlgebraPLOp: replace a recurrence by its closed form and inverse", "range(n,0,9).\n", [val/2, at/2],
     [run("val without arithmetic", val/2, ["pos/1"], "max_vars(3).\nmax_body(3).\n"),
      run("at from val", at/2, ["val/2", "pos/1"], "max_vars(2).\nmax_body(1).\n")],
     ["pos/1"], ['0', '1', '2'], [pos, val, at], []).
rule(detlog, "Detlog: turn the cut's otherwise-branch into an explicit guard", "range(n,-2,2).\n", [cls/2],
     [run("with comparison stand-ins gt0/le0", cls/2, ["num/1", "pos/1", "gt0/1", "le0/1", "lbl_pos/1", "lbl_nonpos/1"],
          "max_vars(2).\nmax_body(3).\nmax_clauses(2).\n")],
     ["num/1"], ['-2', '0', '2'], [num, pos, cls],
     ["lbl_pos(pos)", "lbl_nonpos(nonpos)", "gt0(1)", "gt0(2)", "le0(-2)", "le0(-1)", "le0(0)"]).
rule(piglog2, "Piglog2: group independent goals so they can run concurrently", none, [ok/1],
     [run("single rule", ok/1, ["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], "max_vars(3).\nmax_body(5).\n"),
      run("predicate invention on", ok/1, ["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], "enable_pi.\nmax_vars(3).\nmax_body(3).\nmax_clauses(3).\n")],
     ["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], [s1, w1, n1],
     [src, wcheck, wgood, nccheck, ngood, ok, words_ok, nums_ok], []).

main :-
    current_prolog_flag(argv, Argv), path(results, R), ensure_dir(R),
    (   Argv == [] -> findall(K, rule(K, _, _, _, _, _, _, _, _), Keys), F = 'mnn_all.json'
    ;   maplist([A, K]>>atom_string(K, A), Argv, Keys0), maplist(atom_string, Keys, Keys0),
        atomic_list_concat(Keys, '_', J), format(atom(F), 'mnn_~w.json', [J])
    ),
    format(atom(Out), '~w/~w', [R, F]),
    foldl({Out}/[K, A0, A]>>( once(run_rule(K, Res)), A = [K-Res|A0], reverse(A, Ls), dict_pairs(D, _, Ls), write_json(Out, D),
                              summary(K, Res) ), Keys, [], _).

summary(K, R) :-
    findall(L-C, ( member(P, R.popper), get_dict(label, P, L), get_dict(code, P, C) ), Pop),
    format("~w net ~p inverse ~w/~w/~w/~w popper ~p orig_vs_opt ~w~n",
           [K, R.net, R.inverse.n_minimal, R.inverse.min_size, R.inverse.orig_size, R.inverse.proof, Pop, R.proof_original_vs_optimised]),
    flush_output.

run_rule(Key, Res) :-
    rule(Key, Title, Domain, Targets, Runs, Edb, Consts, Names, ExtraBK),
    path(rules, RD),
    format(atom(OF), '~w/~w_orig.pl', [RD, Key]), format(atom(PF), '~w/~w_opt.pl', [RD, Key]),
    read_file_to_string(OF, OrigTxt, []), read_file_to_string(PF, OptTxt, []),
    rules_of(OrigTxt, OrigRules), rules_of(OptTxt, OptRules), clauses_of(OrigTxt, OrigAll),
    format(atom(NO), 'rule_~w_orig', [Key]), format(atom(NP), 'rule_~w_opt', [Key]),
    compile_net(NO, OrigTxt, Domain, [], D-Net), compile_net(NP, OptTxt, Domain, [], D2-Net2),
    net_info(Net, D, true, NI), net_info(Net2, D2, false, NI2),
    % stage 1: input from output
    full_obs(Net, Targets, Obs, _), net_true_input(Net, True), report(Net, Obs, True, 200, Inv),
    invert(Net, Obs, [cap(1)], I1), get_dict(explanations, I1, [Inp|_]),
    net_reproduces(D, Inp, Obs, Proof),
    findall(S, ( member(A-true, Obs), show(A, S) ), OT0), msort(OT0, OT), length(Obs, NObs),
    maplist(show, True, TrueS), maplist(show, Inp, InpS),
    Inverse = _{observed_true:OT, n_observed:NObs, original_input:TrueS, recovered:InpS,
                n_minimal:Inv.n_explanations, capped:Inv.capped, min_size:Inv.min_size, orig_size:Inv.orig_size,
                original_is_minimal:Inv.orig_is_minimal_explanation, proof:Proof},
    % stage 2: Popper
    findall(E, ( member(Run, Runs), member(Src-SrcIn, [recovered-Inp, original-True]),
                 once(popper_run(Key, Net, Run, Src, SrcIn, ExtraBK, E)) ), Pop0),
    % stage 3: equivalences proved by the prover
    findall(T, ( member(N/A, Targets), format(atom(T), '~w/~w', [N, A]) ), Tg),
    ( OrigRules == [] -> facts_of(OrigTxt, OA) ; OA = OrigRules ),
    equivalent(OA, OptRules, Tg, Edb, Consts, OvO),
    maplist(vs_optimised(OptRules, Edb, Consts), Pop0, Pop),
    % stage 4: S2A
    (   OrigRules == [] -> S2A = null
    ;   maplist({OrigRules, OptRules, Names}/[K, Tr]>>( rename(OrigRules, Names, K, O), rename(OptRules, Names, K, P), Tr = O-P ), [a, b], Train),
        maplist({OrigRules, Names}/[K, T]>>rename(OrigRules, Names, K, T), [c, d], Tests),
        maplist({OptRules, Names}/[K, T]>>rename(OptRules, Names, K, T), [c, d], Expect),
        findall(G-GD, ( member(G, [literal, flat]), once(s2a_grain(Key, Train, Tests, Expect, G, Targets, Edb, Consts, GD)) ), GL),
        dict_pairs(S2A, _, GL)
    ),
    Res = _{rule:Key, title:Title, original:OrigAll, optimised_rules:OptRules, net:NI, net_opt:NI2,
            inverse:Inverse, popper:Pop, proof_original_vs_optimised:OvO, s2a:S2A},
    net_unload(Net), net_unload(Net2).

net_info(Net, D, WithInputs, Info) :-
    net_atoms(Net, As), length(As, NA), net_hidden(Net, Hs), length(Hs, NH), net_edge_count(Net, NE),
    net_matches_program(D, M),
    (   WithInputs == true
    ->  net_edb_preds(Net, P0), findall(S, ( member(N/A, P0), format(string(S), "~w/~w", [N, A]) ), P1), msort(P1, Ps),
        Info = _{atoms:NA, hidden:NH, edges:NE, input_preds:Ps, match:M}
    ;   Info = _{atoms:NA, hidden:NH, edges:NE, match:M}
    ).

popper_run(Key, Net, run(Label, Tgt/Ar, Body, Extra), Src, SrcIn, ExtraBK, Ent) :-
    forward(Net, SrcIn, RM), closed_world(Net, Tgt, Ar, RM, Exs),
    findall(N/A, ( member(B, Body), split_string(B, "/", "", [NS, AS]), atom_string(N, NS), number_string(A, AS) ), BPs),
    findall(S, ( member(X, SrcIn), \+ functor(X, Tgt, Ar), show(X, S) ), B1),
    findall(S, ( member(X, RM), functor(X, N, A), memberchk(N/A, BPs), \+ is_edb(Net, X), show(X, S) ), B2),
    append([B1, B2, ExtraBK], BK0), sort(BK0, BK),
    format(atom(Name), 'rule_~w', [Key]),
    popper(Name, BK, Exs, Tgt-Ar, Body, Extra, Code),
    include([_-true]>>true, Exs, Pos), length(Pos, NP), length(Exs, NX), NN is NX - NP,
    format(string(H), "~w/~w", [Tgt, Ar]),
    Ent0 = _{label:Label, input:Src, head:H, body:Body, n_pos:NP, n_neg:NN},
    (   Code == none -> Ent = Ent0.put(code, null)
    ;   program_reproduces(Code, BK, Exs, R), Ent = Ent0.put(_{code:Code, reproduces_recovered:R})
    ).

vs_optimised(OptRules, Edb, Consts, E0, E) :-
    get_dict(code, E0, Code),
    (   Code == null -> E = E0
    ;   get_dict(head, E0, H), split_string(H, "/", "", [HN, _]),
        include({HN}/[C]>>pred_name(C, HN), OptRules, Same), exclude({HN}/[C]>>pred_name(C, HN), OptRules, Other),
        ( Same == [] -> A = OptRules ; A = Same ), append(Code, Other, B),
        atom_string(HA, H), equivalent(A, B, [HA], Edb, Consts, V), E = E0.put(vs_optimised, V)
    ).
pred_name(C, N) :- once(sub_string(C, P, _, _, "(")), sub_string(C, 0, P, _, N).

% the rule's predicate names get the suffix _K (longest names first, so t1 is not taken for t)
rename(Rules, Names, K, Out) :-
    maplist(atom_length, Names, Ls), pairs_keys_values(PL, Ls, Names), keysort(PL, S0), reverse(S0, S1),
    pairs_values(S1, Sorted), atomic_list_concat(Sorted, '|', Alt),
    format(string(Re), "\\b(~w)\\(", [Alt]), format(string(Rep), "$1_~w(", [K]),
    maplist({Re, Rep}/[C, D]>>re_replace(Re/g, Rep, C, D), Rules, Out).

s2a_grain(Key, Train, Tests, Expect, Grain, Targets, Edb, Consts, _{algorithm:AlgJ, tests:TL}) :-
    s2a_learn_and_apply(Key, Train, Tests, Grain, Alg-Outs), ( Alg == none -> AlgJ = null ; AlgJ = Alg ),
    findall(E, ( nth0(I, Tests, T), nth0(I, Expect, X), ( nth0(I, Outs, O) -> true ; O = none ),
                 once(s2a_test(T, O, X, Targets, Edb, Consts, E)) ), TL).

s2a_test(T, O, X, Targets, Edb, Consts, E) :-
    (   O == none -> OJ = null, Ex = false
    ;   OJ = O, maplist(strip_spaces, O, SO), maplist(strip_spaces, X, SX), ( SO == SX -> Ex = true ; Ex = false )
    ),
    E0 = _{input:T, output:OJ, expected:X, exact:Ex},
    (   O \== none, O \== []
    ->  T = [T1|_], pred_name(T1, PN), split_string(PN, "_", "", Parts), last(Parts, K),
        findall(S, ( member(N/A, Targets), format(atom(S), '~w_~w/~w', [N, K, A]) ), TT),
        findall(S, ( member(EB, Edb), split_string(EB, "/", "", [EN, EA]), format(atom(S), '~w_~w/~w', [EN, K, EA]) ), EE),
        equivalent(T, O, TT, EE, Consts, P), E = E0.put(proof, P)
    ;   E = E0
    ).
