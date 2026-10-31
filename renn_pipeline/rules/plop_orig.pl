sub(a,s1). sub(b,s2). sub(c,s3).          % expensive_sub: functional in arg 1
fin(s1,v1). fin(s2,v2). fin(s3,v3).       % finish: functional in arg 1
good(v1). good(v3).
lab(v1,red). lab(v2,green). lab(v3,blue).
exp(X,A)  :- sub(X,S), fin(S,A).          % expensive
row1(X,A) :- exp(X,A), good(A).           % template1
row2(X,L) :- exp(X,A), lab(A,L).          % template2
report(X,L) :- row1(X,_), row2(X,L).      % exp(X,_) is computed twice
