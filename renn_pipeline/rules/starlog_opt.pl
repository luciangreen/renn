f(a,b). f(b,c). f(c,d).
g(b,x). g(c,y). g(d,z).
h(x,ok). h(z,ok).
% Compressed view: R is h(g(f(X))) -- single-use intermediates nested away.
r(X,W) :- f(X,Y), g(Y,Z), h(Z,W).
