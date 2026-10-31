in1(e1,1). in1(e2,3).
in2(e1,2). in2(e2,4).
% Generalised subterm-address mapping: out[1,1] <- in[1,2], out[1,2] <- in[1,1].
out1(E,V) :- in2(E,V).
out2(E,V) :- in1(E,V).
