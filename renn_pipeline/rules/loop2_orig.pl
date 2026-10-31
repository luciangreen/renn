num(1). num(2). num(3).
pair(a,1). pair(b,2). pair(a,3).
colour(red). colour(blue).
% findall(X,(num(X),X>1),R): generator + filter
big(X) :- num(X), X > 1.
% findall(Y,pair(a,Y),R): bound generator argument acts as a filter
aval(Y) :- pair(a,Y).
% findall(Z,q(Z),R) with q a one-clause predicate over a fact generator
q(X) :- colour(X).
col(X) :- q(X).
