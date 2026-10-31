edge(a,b). edge(b,c). edge(c,d).
% Left-recursive: the recursive call is first, makes no structural progress
% before recursing (PID: non-terminating under SLD, non-tail-recursive).
path(X,Y) :- edge(X,Y).
path(X,Y) :- path(X,Z), edge(Z,Y).
% No-progress clause (PID's count_forever pattern): adds nothing to the model.
path(X,Y) :- path(X,Y).
