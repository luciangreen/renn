src(s1). src(s2). src(s3).
wcheck(s1,w1). wcheck(s2,w2). wcheck(s3,w3).
nccheck(s1,n1). nccheck(s2,n1). nccheck(s3,n3).
wgood(w1). wgood(w3).
ngood(n1).
% Independent sections (share only the input S; outputs W and N are
% disjoint and existential) grouped into separate predicates that have no
% dependency on each other, so they can be evaluated concurrently, then joined.
words_ok(S) :- wcheck(S,W), wgood(W).
nums_ok(S)  :- nccheck(S,N), ngood(N).
ok(S) :- src(S), words_ok(S), nums_ok(S).
