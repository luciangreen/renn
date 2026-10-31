num(-2). num(-1). num(0). num(1). num(2).
pos(X) :- num(X), X > 0.
% Prolog source:  cls(X,pos) :- X > 0, !.   cls(_,nonpos).
% Datalog analogue of the cut's "otherwise" branch: stratified negation.
cls(X,pos)    :- pos(X).
cls(X,nonpos) :- num(X), \+ pos(X).
