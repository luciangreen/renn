parent(ann,bob). parent(bob,cy). parent(ann,dee). parent(dee,eli).
age(ann,70). age(eve,30).
% proof/types: person/1 is the type of both parent/2 slots (projection rules)
person(X) :- parent(X,_).
person(Y) :- parent(_,Y).
% person(X) is implied: X stands at parent:1, which is proved to be contained in person:1
grandparent(X,Z) :- person(X), parent(X,Y), parent(Y,Z).
% person(X) is not implied: age:1 is not contained in person:1 (eve has an age but no parent link)
adult(X) :- person(X), age(X,A), A >= 18.
