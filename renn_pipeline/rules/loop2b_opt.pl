colour(red). colour(blue).
q(X) :- colour(X).
% q spliced into the caller: generator called directly (holds for any colour/1 facts)
col(X) :- colour(X).
