src(s1). src(s2). src(s3).
wcheck(s1,w1). wcheck(s2,w2). wcheck(s3,w3).
nccheck(s1,n1). nccheck(s2,n1). nccheck(s3,n3).
wgood(w1). wgood(w3).
ngood(n1).
% One sequential body: word analysis then number analysis then combine.
ok(S) :- src(S), wcheck(S,W), wgood(W), nccheck(S,N), ngood(N).
