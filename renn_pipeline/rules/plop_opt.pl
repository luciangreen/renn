sub(a,s1). sub(b,s2). sub(c,s3).
fin(s1,v1). fin(s2,v2). fin(s3,v3).
good(v1). good(v3).
lab(v1,red). lab(v2,green). lab(v3,blue).
exp(X,A)  :- sub(X,S), fin(S,A).
row1(X,A) :- exp(X,A), good(A).
row2(X,L) :- exp(X,A), lab(A,L).
% unfold row1,row2,exp; memoise the duplicate exp(X,_) (sound because sub
% and fin are functional); shared dependency hoisted and computed once.
report(X,L) :- sub(X,S), fin(S,A), good(A), lab(A,L).
