pos(0). pos(1). pos(2). pos(3). pos(4).
% Closed form 1+2*i (verified on samples, proven by induction on i)
val(I,V) :- pos(I), V is 1+2*I.
% Inverse (o-1)/2 with guards nonzero(2), divisible(o-1,2), plus domain guard
at(V,I) :- out(V), 0 =:= (V-1) mod 2, I is (V-1)//2, pos(I).
% out/1 = candidate output values, bounded
out(1). out(2). out(3). out(4). out(5). out(6). out(7). out(8). out(9).
