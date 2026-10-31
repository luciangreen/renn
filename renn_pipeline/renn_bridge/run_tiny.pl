:- consult('ops.pl').   % run from RENN's build folder, e.g. build/tiny-mlp
:- use_module('renn_inverse.pl').
go :-
  invert('tiny-mlp', [-1.25], -5-5, R1), length(R1, N1), format("output -1.25: ~d regions~n", [N1]), forall(member(X, R1), (print(X), nl)),
  invert('tiny-mlp', [0.25], -5-5, R2), length(R2, N2), format("output 0.25: ~d regions~n", [N2]), forall(member(X, R2), (print(X), nl)),
  invert('tiny-mlp', [100.0], -5-5, R3), format("output 100 (outside the box's reach): ~w~n", [R3]),
  print_rules('tiny-mlp', -5-5),
  check_rules('tiny-mlp', -5-5, 40, C), format("check: ~w~n", [C]).
