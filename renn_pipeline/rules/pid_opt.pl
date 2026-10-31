edge(a,b). edge(b,c). edge(c,d).
% Right-recursive / tail form: consume an edge (measure decreases), recurse last.
path(X,Y) :- edge(X,Y).
path(X,Y) :- edge(X,Z), path(Z,Y).
