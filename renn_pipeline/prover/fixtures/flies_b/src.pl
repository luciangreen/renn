bird(robin).
bird(kiwi).
bird(polly).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).
