/*  stage3_core.pl -- Stage 3 (core experiment): unoptimised originals -> network -> input -> Popper
    -> optimisation algorithm via Spec to Algorithm.

    Each base program is inflated with one known redundancy; the inflated program is the original
    algorithm. The network is compiled from it; the input is found from the network's output;
    Popper learns code; the prover checks Popper's code against the base program; and S2A learns,
    per redundancy, the rewrite that turns an inflated program into its optimised form, from two
    examples, then is tested on unseen programs (same shape renamed, and other shapes). A windowed
    driver slides the learned rewrite over clause windows, with and without the prover as a guard.
    Writes <RESULTS_DIR>/stage3_core.json.      swipl stage3_core.pl */
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).

:- initialization(main, main).

% base(Name, Facts, Rules, Head/Arity, Body, Edb, Recursive)
base(reach, "edge(a,b).\nedge(b,c).\nedge(c,d).\nedge(b,e).\n", ["reach(X,Y):-edge(X,Y)", "reach(X,Y):-edge(X,Z),reach(Z,Y)"],
     reach-2, ["edge/2"], ["edge/2"], true).
base(ancestor, "parent(ann,bob).\nparent(bob,cy).\nparent(cy,dee).\nparent(bob,eli).\n",
     ["ancestor(X,Y):-parent(X,Y)", "ancestor(X,Y):-parent(X,Z),ancestor(Z,Y)"], ancestor-2, ["parent/2"], ["parent/2"], true).
base(grandparent, "parent(ann,bob).\nparent(bob,cy).\nparent(ann,dee).\nparent(dee,eli).\n",
     ["grandparent(X,Y):-parent(X,Z),parent(Z,Y)"], grandparent-2, ["parent/2"], ["parent/2"], false).
base(sibling, "parent(ann,bob).\nparent(ann,cy).\nparent(bob,dee).\n", ["sibling(X,Y):-parent(P,X),parent(P,Y),X\\=Y"],
     sibling-2, ["parent/2", "neq/2"], ["parent/2"], false).

ops([dup_clause, dup_literal, subsumed_clause, unfolded_clause, dup_then_subsumed]).

inflate(Rules, Op, Head-_, Edbp, Out) :-
    Rules = [R0|Rest], sub_string(R0, B, _, A, ":-"), sub_string(R0, 0, B, _, H), sub_string(R0, _, A, 0, Bd),
    (   Op == dup_clause -> append(Rules, [R0], Out)
    ;   Op == dup_literal -> split_top(Bd, [L1|_]), format(string(C), "~w:-~w,~w", [H, Bd, L1]), Out = [C|Rest]
    ;   Op == subsumed_clause
    ->  ( sub_string(H, _, _, _, "X") -> format(string(E), "~w(Y,X)", [Edbp]) ; format(string(E), "~w(X,X)", [Edbp]) ),
        format(string(C), "~w:-~w,~w", [H, Bd, E]), append(Rules, [C], Out)
    ;   Op == unfolded_clause
    ->  format(string(C), "~w(X,Y):-~w(X,Z),~w(Z,Y)", [Head, Edbp, Edbp]), Out = [R0, C|Rest]
    ;   Op == dup_then_subsumed
    ->  inflate(Rules, dup_clause, Head-_, Edbp, R1), inflate(R1, subsumed_clause, Head-_, Edbp, Out)
    ).

bias(true, "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n").
bias(false, "max_vars(3).\nmax_body(3).\n").

main :-
    path(results, Res), ensure_dir(Res),
    ops(Ops),
    findall(Row, ( base(B, _, _, _, _, _, Rec), member(Op, Ops), \+ ( Op == unfolded_clause, Rec == false ),
                   once(case_row(B, Op, Row)) ), Rows),
    s2a_part(Rows, S2A),
    window_part(Rows, Win),
    atom_concat(Res, '/stage3_core.json', Out),
    write_json(Out, _{cases:Rows, s2a:S2A, s2a_windowed:Win}).

case_row(B, Op, Row) :-
    base(B, Facts, Rules, Head-Ar, Body, Edb, Rec),
    Edb = [E1|_], split_string(E1, "/", "", [Edbp, _]),
    inflate(Rules, Op, Head-Ar, Edbp, Orig),
    findall(L, ( member(C, Orig), format(string(L), "~w.~n", [C]) ), Ls), atomic_list_concat([Facts|Ls], Prog),
    format(atom(Name), 'core_~w_~w', [B, Op]),
    compile_net(Name, Prog, none, [], D-Net),
    net_hidden(Net, Hs), length(Hs, NH), net_matches_program(D, Match),
    full_obs(Net, [Head/Ar], Obs, _),
    net_true_input(Net, True), report(Net, Obs, True, 50, Inv),
    invert(Net, Obs, [cap(1)], I1), get_dict(explanations, I1, [Inp|_]),
    net_reproduces(D, Inp, Obs, Proof),
    maplist(show, Inp, InpS), maplist(show, True, TrueS),
    findall(X, ( member(A, TrueS), once(sub_string(A, P, _, _, "(")), P1 is P + 1, sub_string(A, P1, _, 0, R),
                 re_foldl([M, A0, [Y|A0]]>>get_dict(0, M, Y), "[a-z]\\w*", R, [], Ys, []), member(X, Ys) ), X1),
    sort(X1, Consts),
    bias(Rec, Bias),
    format(atom(T1), '~w/2', [Head]),
    findall(Src-Ent, ( member(Src-SrcIn, [recovered-InpS, original-TrueS]),
                       once(popper_entry(Name, Net, Src, SrcIn, Head-Ar, Body, Bias, Consts, Rules, T1, Edb, Ent)) ), Ents),
    memberchk(recovered-ER, Ents), memberchk(original-EO, Ents),
    equivalent(Orig, Rules, [T1], Edb, [a, b, c], OvO),
    get_dict(n_explanations, Inv, NMin),
    Row = _{base:B, op:Op, original:Orig, optimised:Rules, hidden:NH, match:Match,
            inverse:_{recovered:InpS, original_input:TrueS, n_minimal:NMin, proof:Proof},
            popper_recovered:ER, popper_original:EO, original_vs_optimised:OvO},
    format("~w ~w ~w ~w ~w ~w ~w~n", [B, Op, Match, Proof, ER.code, EO.code, OvO]), flush_output,
    net_unload(Net).

popper_entry(Name, Net, Src, SrcIn, Head-Ar, Body, Bias, Consts, Rules, T1, Edb, Ent) :-
    maplist([S, T]>>term_string(T, S), SrcIn, SrcT), forward(Net, SrcT, RM),
    closed_world(Net, Head, Ar, RM, Exs),
    (   memberchk("neq/2", Body)
    ->  findall(S, ( member(X, Consts), member(Y, Consts), X \== Y, format(string(S), "neq(~w,~w)", [X, Y]) ), NB)
    ;   NB = []
    ),
    append(SrcIn, NB, BK),
    format(atom(PN), '~w_~w', [Name, Src]),
    popper(PN, BK, Exs, Head-Ar, Body, Bias, Code),
    (   Code == none -> Ent = _{code:null}
    ;   equivalent(Rules, Code, [T1], Edb, [a, b, c], Vs),
        align(Code, Rules, Al), sorted_strings(Al, SA), sorted_strings(Rules, SR),
        ( SA == SR -> Ex = true ; Ex = false ),
        Ent = _{code:Code, vs_optimised:Vs, aligned_to_optimised:Al, exact_after_alignment:Ex}
    ).

% ---------------------------------------------------------------- S2A on whole programs
ren(Rs, A, B, Out) :-
    maplist({A, B}/[C, D]>>( re_replace("\\bedge\\("/g, "link(", C, C1), format(string(P), "\\b~w\\(", [A]),
                             format(string(Q), "~w(", [B]), re_replace(P/g, Q, C1, D) ), Rs, Out).

s2a_part(Rows, S2A) :-
    ops(Ops),
    findall(Op-G, ( member(Op, Ops), row(Rows, reach, Op, RR), row(Rows, ancestor, Op, RA),
                    Train = [RR.original-RR.optimised, RA.original-RA.optimised],
                    ren(RR.original, "reach", "path", T0), ren(RR.optimised, "reach", "path", X0),
                    findall(t(L, T, X), ( member(Oth, [grandparent, sibling]), row(Rows, Oth, Op, RO),
                                          format(string(L), "different shape: ~w", [Oth]), T = RO.original, X = RO.optimised ), Others),
                    Tests = [t("same shape, renamed", T0, X0)|Others],
                    findall(Gr-GD, ( member(Gr, [literal, flat]), once(s2a_grain(Op, Train, Tests, Gr, GD)) ), GL),
                    dict_pairs(G, _, GL) ), L),
    dict_pairs(S2A, _, L).
row(Rows, B, Op, R) :- member(R, Rows), get_dict(base, R, B), get_dict(op, R, Op), !.

s2a_grain(Op, Train, Tests, Grain, _{algorithm:AlgJ, tests:TL}) :-
    findall(T, member(t(_, T, _), Tests), Ins),
    format(atom(N), 'core_~w', [Op]),
    s2a_learn_and_apply(N, Train, Ins, Grain, Alg-Outs),
    ( Alg == none -> AlgJ = null ; AlgJ = Alg ),
    findall(E, ( nth0(I, Tests, t(Lab, T, X)), ( nth0(I, Outs, O) -> true ; O = none ), once(s2a_test(Lab, T, O, X, E)) ), TL),
    findall(Lab-Ex-Pr, ( member(E, TL), get_dict(test, E, Lab), get_dict(exact, E, Ex), ( get_dict(proof, E, Pr) -> true ; Pr = none ) ), Sum),
    format("S2A ~w ~w ~w~n", [Op, Grain, Sum]), flush_output.

s2a_test(Lab, T, O, X, E) :-
    ( O == none -> OJ = null, Ex = false ; OJ = O, sorted_strings(O, SO), sorted_strings(X, SX), ( SO == SX -> Ex = true ; Ex = false ) ),
    E0 = _{test:Lab, input:T, output:OJ, expected:X, exact:Ex},
    (   O \== none, O \== []
    ->  X = [X1|_], once(sub_string(X1, P, _, _, "(")), sub_string(X1, 0, P, _, HP),
        sub_string(X1, B, _, A, ":-"), B >= 0, sub_string(X1, _, A, 0, Bd), once(re_matchsub("(\\w+)\\(", Bd, M, [])),
        get_dict(1, M, EP), format(atom(TH), '~w/2', [HP]), format(atom(TE), '~w/2', [EP]),
        equivalent(T, O, [TH], [TE], [a, b, c], Pr), E = E0.put(proof, Pr)
    ;   E = E0
    ).

% ---------------------------------------------------------------- windowed S2A
wpairs(dup_literal, O, P, Ws) :- !, findall([A]-[B], ( nth0(I, O, A), nth0(I, P, B), A \== B ), Ws).
wpairs(_, O, P, [[Keep, R]-[Keep]]) :-
    findall(C, ( member(C, O), ( \+ memberchk(C, P) ; cnt(C, O, NO), cnt(C, P, NP), NO > NP ) ), Removed),
    last(Removed, R), head_of(R, HR), once(( member(Keep, P), head_of(Keep, HR) )).
cnt(X, L, N) :- include(==(X), L, L1), length(L1, N).
head_of(C, H) :- ( sub_string(C, B, _, _, ":-") -> sub_string(C, 0, B, _, H) ; H = C ).

window_part(Rows, Win) :-
    findall(Op-Es, ( member(Op, [dup_clause, dup_literal, subsumed_clause]),
                     findall(W, ( member(B, [reach, ancestor]), row(Rows, B, Op, R), wpairs(Op, R.original, R.optimised, W) ), TW0),
                     append(TW0, TW),
                     ( Op == dup_literal -> Size = 1 ; Size = 2 ), ( Op == dup_clause -> Grain = clause ; Grain = literal ),
                     findall(E, ( member(Oth, [grandparent, sibling]), row(Rows, Oth, Op, RO), once(window_case(Op, TW, RO, Oth, Size, Grain, E)) ), Es) ),
            L),
    dict_pairs(Win, _, L).

window_case(Op, TW, RO, Oth, Size, Grain, E) :-
    O = RO.original, X = RO.optimised, format(atom(TH), '~w/2', [Oth]),
    format(atom(N), 'win_~w', [Op]),
    s2a_window_optimise(N, TW, O, Size, Grain, 4, none, Out-Tr),
    s2a_window_optimise(N, TW, O, Size, Grain, 4, proved_equal(TH), OutC-TrC),
    sorted_strings(X, SX), sorted_strings(Out, SOut), sorted_strings(OutC, SOutC),
    ( SOut == SX -> Ex = true ; Ex = false ), ( SOutC == SX -> ExC = true ; ExC = false ),
    equivalent(O, Out, [TH], ['parent/2'], [a, b, c], Pr), equivalent(O, OutC, [TH], ['parent/2'], [a, b, c], PrC),
    E = _{test:Oth, grain:Grain, input:O, output:Out, expected:X, steps:Tr, exact:Ex, proof:Pr,
          with_prover_guard:_{output:OutC, steps:TrC, exact:ExC, proof:PrC}},
    sub_atom_head(Pr, 60, P60), sub_atom_head(PrC, 60, PC60),
    format("WINDOW ~w ~w ~w ~w | guarded: ~w ~w~n", [Op, Oth, Ex, P60, ExC, PC60]), flush_output.

proved_equal(TH, A, B) :- equivalent(A, B, [TH], ['parent/2'], [a, b, c], R), sub_string(R, 0, _, _, "proved").
sub_atom_head(S, N, H) :- string_length(S, L), ( L =< N -> H = S ; sub_string(S, 0, N, _, H) ).
