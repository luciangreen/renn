f(a,b). f(b,c). f(c,d).
g(b,x). g(c,y). g(d,z).
h(x,ok). h(z,ok).
% Decompressed (Prolog-style) view: every intermediate result gets its own name.
t1(X,Y) :- f(X,Y).            % T1 is f(X)
t2(X,Z) :- t1(X,Y), g(Y,Z).   % T2 is g(T1)
r(X,W)  :- t2(X,Z), h(Z,W).   % R  is h(T2)
