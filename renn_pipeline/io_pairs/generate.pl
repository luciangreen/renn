/*  generate.pl -- 200 input/output pairs for renn_pipeline, each produced by running the code.
    Needs the networks built by convert_all.pl (EXP_DIR, see config.pl) and clingo. From
    renn_pipeline/:
        swipl -q -g main -t halt io_pairs/generate.pl
    writes io_pairs/pairs.jsonl and io_pairs/io_pairs.md. */
:- prolog_load_context(directory, D), assertz(user:io_dir(D)).
:- use_module(harness).
:- use_module(to_markdown).
:- use_module('../config').
:- use_module('../netlib').
:- use_module('../invert').
:- use_module('../datalog', [parse_program/2, agreement/7, mt_seed/2, mt_random/3]).
:- use_module('../prover/prover', [equivalent/5, program_reproduces/4, net_matches_program/3, read_program/2]).
:- use_module('../prover/prover', [least_model/3 as prover_least_model]).
:- style_check(-singleton).

% networks: proved equal to their programs, run forward (with the predicate asked about), inverted
proof_id(1).
proof_id(3).
proof_id(6).
proof_id(9).
proof_id(11).
proof_id(14).
proof_id(17).
proof_id(19).
proof_id(22).
proof_id(25).
proof_id(27).
proof_id(30).
proof_id(33).
proof_id(35).
proof_id(38).
proof_id(41).
proof_id(43).
proof_id(46).
proof_id(49).
proof_id(51).
proof_id(54).
proof_id(57).
proof_id(59).
proof_id(62).
proof_id(65).
proof_id(67).
proof_id(70).
proof_id(73).
proof_id(75).
proof_id(78).
proof_id(81).
proof_id(83).
proof_id(86).
proof_id(89).
proof_id(91).
proof_id(94).
proof_id(97).
proof_id(99).
proof_id(102).
proof_id(105).
proof_id(107).
proof_id(110).
proof_id(113).
proof_id(115).
proof_id(118).
proof_id(121).
proof_id(123).
proof_id(126).
proof_id(129).
proof_id(131).
proof_id(134).
proof_id(139).
proof_id(141).
proof_id(144).
proof_id(147).
proof_id(149).
proof_id(174).
proof_id(177).
proof_id(179).
proof_id(182).
proof_id(185).
proof_id(187).
proof_id(190).
proof_id(193).
proof_id(195).
proof_id(198).
fwd_id(2, reach/2).
fwd_id(6, reach/2).
fwd_id(10, reach/2).
fwd_id(15, reach/2).
fwd_id(19, reach/2).
fwd_id(23, reach/2).
fwd_id(28, reach/2).
fwd_id(32, reach/2).
fwd_id(37, reach/2).
fwd_id(41, ancestor/2).
fwd_id(45, grandparent/2).
fwd_id(50, ancestor/2).
fwd_id(54, grandparent/2).
fwd_id(58, sibling/2).
fwd_id(63, grandparent/2).
fwd_id(67, or/2).
fwd_id(72, and/2).
fwd_id(76, xor/2).
fwd_id(80, flies/1).
fwd_id(85, flies/1).
fwd_id(89, flies/1).
fwd_id(93, even/1).
fwd_id(98, square/2).
fwd_id(102, square/2).
fwd_id(107, pair/2).
fwd_id(111, div5/1).
fwd_id(115, count/1).
fwd_id(120, liked/1).
fwd_id(124, liked/1).
fwd_id(128, nat/1).
fwd_id(133, p/1).
fwd_id(139, ancestor/2).
fwd_id(144, flies/1).
fwd_id(148, ab/1).
inv_id(1).
inv_id(5).
inv_id(9).
inv_id(13).
inv_id(17).
inv_id(21).
inv_id(25).
inv_id(29).
inv_id(33).
inv_id(37).
inv_id(41).
inv_id(45).
inv_id(49).
inv_id(54).
inv_id(58).
inv_id(62).
inv_id(66).
inv_id(70).
inv_id(74).
inv_id(78).
inv_id(82).
inv_id(86).
inv_id(90).
inv_id(119).
inv_id(123).


src(Id, Text) :- path(exp, E), format(atom(F), '~w/nets/~w/src.pl', [E, Id]), read_file_to_string(F, Text, []).
netfile(Id, json, F) :- path(exp, E), format(atom(F), '~w/nets/~w/net.json', [E, Id]).
netfile(Id, pl, F) :- path(exp, E), format(atom(F), '~w/nets/~w/net.pl', [E, Id]).

% find the input from the whole output layer, smallest or largest, and check each answer by
% running the network forward
invert_net(Id, Mode) :-
    netfile(Id, json, F), net_load(F, Net), net_true_input(Net, In), forward(Net, In, Full),
    full_observation(Net, Full, Obs), ( Mode == largest -> M = true ; M = false ),
    invert(Net, Obs, [cap(5), maximize(M)], R),
    get_dict(status, R, St), get_dict(explanations, R, Ex), length(Ex, NEx),
    msort(In, InS), length(InS, NIn), format("status: ~w; original input (~w facts): ~w~n", [St, NIn, InS]),
    format("~w ~w input(s) found:~n", [NEx, Mode]),
    exclude(is_edb(Net), Full, Out0), msort(Out0, OutS),
    forall(member(E, Ex), ( msort(E, Es), length(Es, L), forward(Net, Es, Fe), exclude(is_edb(Net), Fe, Fo), msort(Fo, FoS),
                            ( FoS == OutS -> Ok = same_output ; Ok = different_output ),
                            format("  ~w facts ~w  -> forward: ~w~n", [L, Es, Ok]) )),
    net_unload(Net).

net_proof(Id) :-
    netfile(Id, pl, F), path(exp, E), format(atom(S), '~w/nets/~w/src.pl', [E, Id]),
    read_program(S, P), net_matches_program(F, P, R), format("~q~n", [R]).

net_answers(Id, Pred) :-
    netfile(Id, json, F), net_load(F, Net), net_true_input(Net, In), forward(Net, In, Full),
    include([A]>>( functor(A, N, Ar), N/Ar == Pred ), Full, As), msort(As, S),
    length(In, NI), format("input atoms clamped on: ~w~n~w answers from the weights alone: ~w~n", [NI, Pred, S]), net_unload(Net).


% base programs and variants: Name, EDB spec, targets, original, [VariantName-Variant]
base(reach, edb([e/2], [a,b]), [r/2], "(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))",
     [ "the recursion on the left" - "(r(X,Y) :- e(X,Y)), (r(X,Y) :- r(X,Z), e(Z,Y))",
       "a duplicate clause added" - "(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))",
       "the recursive clause dropped" - "(r(X,Y) :- e(X,Y))",
       "arguments swapped in the base case" - "(r(X,Y) :- e(Y,X)), (r(X,Y) :- e(X,Z), r(Z,Y))",
       "a two-step clause added" - "(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), e(Z,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))" ]).
base(grandparent, edb([p/2], [a,b,c]), [g/2], "(g(X,Y) :- p(X,Z), p(Z,Y))",
     [ "body order swapped" - "(g(X,Y) :- p(Z,Y), p(X,Z))",
       "through a helper predicate" - "(c(X,Z) :- p(X,Z)), (g(X,Y) :- c(X,Z), p(Z,Y))",
       "a duplicate literal" - "(g(X,Y) :- p(X,Z), p(Z,Y), p(X,Z))",
       "one step only" - "(g(X,Y) :- p(X,Y))",
       "the wrong direction" - "(g(X,Y) :- p(Z,X), p(Y,Z))" ]).
base(sibling, edb([p/2], [a,b,c]), [s/2], "(s(X,Y) :- p(Z,X), p(Z,Y), X \\= Y)",
     [ "the disequality first" - "(s(X,Y) :- X \\= Y, p(Z,X), p(Z,Y))",
       "a subsumed clause added" - "(s(X,Y) :- p(Z,X), p(Z,Y), X \\= Y), (s(X,Y) :- p(Z,X), p(Z,Y), p(Z,Z), X \\= Y)",
       "without the disequality" - "(s(X,Y) :- p(Z,X), p(Z,Y))",
       "Y and X swapped" - "(s(Y,X) :- p(Z,X), p(Z,Y), X \\= Y)",
       "parents must differ instead" - "(s(X,Y) :- p(Z,X), p(W,Y), Z \\= W)" ]).
base(flies, edb([b/1, q/1], [t, u]), [f/1], "(f(X) :- b(X), \\+ q(X))",
     [ "the negation first in the body after the binding" - "(f(X) :- b(X), \\+ q(X)), (f(X) :- b(X), \\+ q(X))",
       "the guard dropped" - "(f(X) :- b(X))",
       "through an abnormal predicate" - "(ab(X) :- q(X)), (f(X) :- b(X), \\+ ab(X))",
       "negation swapped" - "(f(X) :- q(X), \\+ b(X))",
       "a stronger guard" - "(f(X) :- b(X), \\+ q(X), \\+ b(X))" ]).
base(path3, edb([e/2], [a,b]), [t/2], "(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))",
     [ "split into two predicates" - "(two(X,W) :- e(X,Z), e(Z,W)), (t(X,Y) :- two(X,W), e(W,Y))",
       "a duplicate literal" - "(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y), e(Z,W))",
       "two steps only" - "(t(X,Y) :- e(X,Z), e(Z,Y))",
       "renamed variables" - "(t(A,B) :- e(A,C), e(C,D), e(D,B))",
       "the last step reversed" - "(t(X,Y) :- e(X,Z), e(Z,W), e(Y,W))" ]).
base(both, edb([a/1, b/1], [x, y]), [c/1], "(c(X) :- a(X), b(X))",
     [ "the order swapped" - "(c(X) :- b(X), a(X))",
       "either instead of both" - "(c(X) :- a(X)), (c(X) :- b(X))",
       "a repeated literal" - "(c(X) :- a(X), a(X), b(X))",
       "a subsumed clause added" - "(c(X) :- a(X), b(X)), (c(X) :- a(X), b(X), a(X))",
       "only a" - "(c(X) :- a(X))" ]).

lm(Name, Clauses, Facts) :- true.
lms([ "transitive closure on a chain" - "[(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))]" - "[e(1,2), e(2,3), e(3,4)]",
      "transitive closure on a cycle" - "[(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))]" - "[e(a,b), e(b,a)]",
      "same generation" - "[(sg(X,X) :- n(X)), (sg(X,Y) :- p(X,A), sg(A,B), p(Y,B))]" - "[n(a), n(b), n(c), n(d), p(c,a), p(d,b)]",
      "default with an exception" - "[(fl(X) :- bird(X), \\+ ab(X)), (ab(X) :- peng(X))]" - "[bird(t), bird(p), peng(p)]",
      "even and odd by mutual recursion" - "[(ev(0)), (ev(Y) :- od(X), nx(X,Y)), (od(Y) :- ev(X), nx(X,Y))]" - "[nx(0,1), nx(1,2), nx(2,3), nx(3,4)]",
      "disequality" - "[(dif(X,Y) :- c(X), c(Y), X \\= Y)]" - "[c(1), c(2), c(3)]",
      "grandparent" - "[(g(X,Y) :- p(X,Z), p(Z,Y))]" - "[p(a,b), p(b,c), p(b,d), p(c,e)]",
      "two strata of negation" - "[(a(X) :- d(X), \\+ b(X)), (b(X) :- d(X), \\+ c(X))]" - "[d(1), d(2), c(1)]",
      "reachable from a start node" - "[(rs(X) :- start(X)), (rs(Y) :- rs(X), e(X,Y))]" - "[start(a), e(a,b), e(b,c), e(d,a)]",
      "nodes with no outgoing edge" - "[(has(X) :- e(X,_)), (sink(X) :- n(X), \\+ has(X))]" - "[n(a), n(b), n(c), e(a,b), e(b,c)]" ]).

main :-
    set_limit(240),
    io_dir(IO), atom_concat(IO, '/pairs.jsonl', PF), open_pairs(PF),
    forall(base(B, Edb, T, O, Vs), forall(member(VN-V, Vs),
        ( format(string(Q), "equivalent([~s], [~s], ~q, ~q, Result)", [O, V, T, Edb]),
          format(string(Ti), "~w: the original against ~s", [B, VN]), pair('prover/equivalence', Ti, Q) ))),
    lms(LMs), forall(member(N-C-F, LMs), ( format(string(Q), "prover_least_model(~s, ~s, Model)", [C, F]),
                                         format(string(Ti), "Least model: ~s", [N]), pair('prover/least-model', Ti, Q) )),
    forall(proof_id(Id), ( src(Id, T), format(string(Q), "net_proof(~w)", [Id]),
                           format(string(Ti), "Network ~w equals its program, clause by clause, from the weights", [Id]), pair('prover/network', Ti, T, Q) )),
    forall(fwd_id(Id, P), ( src(Id, T), format(string(Q), "net_answers(~w, ~q)", [Id, P]),
                            format(string(Ti), "Network ~w run forward from its weights: ~q", [Id, P]), pair('network/forward', Ti, T, Q) )),
    forall(( inv_id(Id), member(M, [smallest, largest]) ), ( src(Id, T), format(string(Q), "invert_net(~w, ~w)", [Id, M]),
                            format(string(Ti), "Network ~w: the ~w input that gives its whole output", [Id, M]), pair('inversion', Ti, T, Q) )),
    forall(member(S, [0, 1, 2, 7, 42]), ( format(string(Q), "mt_seed(~w, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _)", [S]),
                                          format(string(Ti), "Mersenne Twister seeded like Python's random.Random(~w)", [S]), pair('datalog', Ti, Q) )),
    forall(member(L-D, ["(r(X,Y) :- e(X,Y)). (r(X,Y) :- r(X,Z), e(Z,Y))."-"left recursion",
                        "(r(X,Y) :- e(X,Y))."-"no recursion",
                        "(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), e(Z,Y))."-"two steps at most",
                        "(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(Y,X))."-"symmetric instead of transitive",
                        "(r(X,Y) :- e(X,Z), r(Z,Y)). (r(X,Y) :- e(X,Y))."-"clauses reordered"]),
           ( format(string(Q), "parse_program(\"(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).\", _O), parse_program(~q, _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction)", [L]),
             format(string(Ti), "Agreement with transitive closure on 200 random inputs: ~s", [D]), pair('datalog', Ti, Q) )),
    close_pairs,
    atom_concat(IO, '/io_pairs.md', MF),
    to_markdown(PF, MF, "renn_pipeline",
        "Each pair is a query to the RENN pipeline: the prover (equivalence of two programs for every input, least models, a network proved equal to its program from its weights alone), networks run forward from their weights, the inputs recovered from a network's whole output (smallest and largest, each checked by running the network forward), and the Datalog evaluator with its Python-compatible random numbers. Networks are the pl2ann builds in EXP_DIR (convert_all.pl). Every output was produced by running this repository's code with `io_pairs/generate.pl`; nothing was written by hand.").
