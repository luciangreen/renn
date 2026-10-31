num(-2). num(-1). num(0). num(1). num(2).
pos(X) :- num(X), X > 0.
% Explicit decision: exhaustive, mutually exclusive guards; no negation.
cls(X,pos)    :- pos(X).
cls(X,nonpos) :- num(X), X =< 0.
