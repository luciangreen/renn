:- use_module(prover).
/*  The prover's 14 tests. The network files are built from fixtures/*/src.pl by
    run_tests.sh (pl2ann convert); NETS_DIR names the folder they were built into.
    Exits 0 when all 14 pass, 1 otherwise. */
:- dynamic failed/1, passed/1.

net(Name, File) :-
    ( getenv('NETS_DIR', D) -> true ; D = 'build' ),
    format(atom(File), '~w/~w/net.pl', [D, Name]).

t(Name, G) :-
    (   catch(G, E, (print_message(error, E), fail))
    ->  format("~w: ok~n", [Name]), assertz(passed(Name))
    ;   format("~w: FAILED~n", [Name]), assertz(failed(Name))
    ).

main :-
    run, run2,
    aggregate_all(count, passed(_), P), aggregate_all(count, failed(_), F),
    format("~d passed, ~d failed~n", [P, F]),
    ( F =:= 0, P =:= 14 -> halt(0) ; halt(1) ).

run :-
  net(reach, Reach1), net(flies_a, FliesA),
  Reach = [(reach(X,Y) :- edge(X,Y)), (reach(X1,Y1) :- edge(X1,Z1), reach(Z1,Y1))],
  t(lm, (least_model(Reach, [edge(a,b),edge(b,c)], M), memberchk(reach(a,c), M))),
  t(repro, program_reproduces(Reach, [edge(a,b),edge(b,c)], [true(reach(a,c)), false(reach(c,a))], proved(_))),
  t(refute, program_reproduces(Reach, [edge(a,b)], [true(reach(a,c))], refuted(_))),
  Dup = [(reach(X2,Y2) :- edge(X2,Y2), edge(X2,Y2)) | Reach],
  t(syntactic, (equivalent(Dup, Reach, [reach/2], edb([edge/2],[a,b,c]), R1), writeln(R1), R1 = proved(syntactic(_)))),
  Left = [(reach(X3,Y3) :- edge(X3,Y3)), (reach(X4,Y4) :- reach(X4,Z4), edge(Z4,Y4))],
  t(exhaustive, (equivalent(Reach, Left, [reach/2], edb([edge/2],[a,b,c]), R2), writeln(R2), R2 = proved(exhaustive(512)))),
  Wrong = [(reach(X5,Y5) :- edge(X5,Y5)), (reach(X6,Y6) :- edge(Y6,Z6), reach(X6,Z6))],
  t(counterexample, (equivalent(Reach, Wrong, [reach/2], edb([edge/2],[a,b,c]), R3), writeln(R3), R3 = refuted(_,_,_))),
  t(net, (net_reproduces(Reach1, [edge(a,b),edge(b,a),edge(c,a)],
          [true(reach(a,a)), true(reach(c,b)), false(reach(a,c))], R4), writeln(R4), R4 = proved(_))),
  t(net_refute, (net_reproduces(Reach1, [edge(a,b)], [true(reach(a,a))], R5), writeln(R5), R5 = refuted(_))),
  t(net_negation, (net_reproduces(FliesA, [bird(tweety),bird(emu),penguin(emu)],
          [true(flies(tweety)), false(flies(emu))], R6), writeln(R6), R6 = proved(_))).
run2 :-
  net(reach, Reach1), net(flies_a, FliesA), net(flies_b, FliesB),
  Reach = [(reach(X,Y) :- edge(X,Y)), (reach(X1,Y1) :- edge(X1,Z1), reach(Z1,Y1))],
  t(struct_match, (net_matches_program(Reach1, [edge(a,b),edge(b,a),edge(c,a)|Reach], R1), writeln(R1), R1 = proved(_))),
  Left = [(reach(X3,Y3) :- edge(X3,Y3)), (reach(X4,Y4) :- reach(X4,Z4), edge(Z4,Y4))],
  t(struct_mismatch, (net_matches_program(Reach1, [edge(a,b),edge(b,a),edge(c,a)|Left], R2), R2 = refuted(_,_), writeln(struct_left_differs))),
  t(behaviour_all_inputs, (net_equivalent_program(Reach1, Left, [reach/2], 9, R3), writeln(R3), R3 = proved(_))),
  Fl = [(flies(X5) :- bird(X5), \+ penguin(X5))],
  t(struct_negation, (net_matches_program(FliesA, [bird(pingu),bird(tweety),bird(opus),bird(polly),bird(emu),bird(robin),penguin(emu)|Fl], R4), writeln(R4), R4 = proved(_))),
  t(behaviour_negation, (net_equivalent_program(FliesB, Fl, [flies/1], 12, R5), writeln(R5), R5 = proved(_))).
