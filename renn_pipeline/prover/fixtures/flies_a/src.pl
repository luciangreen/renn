bird(pingu).
bird(tweety).
bird(opus).
bird(polly).
bird(emu).
bird(robin).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).
