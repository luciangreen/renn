pos(0). pos(1). pos(2). pos(3). pos(4).
% Recurrence: base 1, step add 2 (AlgebraPLOp discover_recursive_formula)
val(0,1).
val(I,V) :- pos(I), I > 0, J is I-1, val(J,W), V is W+2.
% Inverse lookup by search over the generated table
at(V,I) :- val(I,V).
