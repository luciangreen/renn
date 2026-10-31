% S2A spec as data: in1(E,V)/in2(E,V) = value at input address [1,1]/[1,2] of example E
% (spec: [1,2] -> [2,1] and [3,4] -> [4,3]).
in1(e1,1). in1(e2,3).
in2(e1,2). in2(e2,4).
% Original: output kept as a per-example lookup table (S2A allow_table(true) form).
out1(e1,2). out1(e2,4).
out2(e1,1). out2(e2,3).
