parent(ann,bob). parent(bob,cy). parent(ann,dee). parent(dee,eli).
age(ann,70). age(eve,30).
person(X) :- parent(X,_).
person(Y) :- parent(_,Y).
grandparent(X,Z) :- parent(X,Y), parent(Y,Z).
adult(X) :- person(X), age(X,A), A >= 18.
