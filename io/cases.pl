% The predicates whose inputs and outputs are recorded in io/ios.txt (see io/ios_engine.pl).
:- ios_engine:load_repo('renn_pipeline/datalog').
:- ios_engine:load_repo('renn_pipeline/pipeline').

io_title('renn (Prolog pipeline)').

io_cases([least_model, mt_random, clauses_of, canon_clause, split_top, strip_spaces, take]).

programs([
  "reach(X,Y) :- edge(X,Y).\nreach(X,Z) :- edge(X,Y), reach(Y,Z).",
  "ancestor(X,Y) :- parent(X,Y).\nancestor(X,Z) :- parent(X,Y), ancestor(Y,Z).",
  "flies(X) :- bird(X), \\+ penguin(X).",
  "sibling(X,Y) :- parent(P,X), parent(P,Y), X \\= Y.",
  "even(X) :- zero(X).\neven(Y) :- succ2(X,Y), even(X).",
  "both(X) :- a(X), b(X).\neither(X) :- a(X).\neither(X) :- b(X)."
]).
facts_for(1, K, Fs) :- pick_n(K, 1, 5, [edge(a,b), edge(b,c), edge(c,d), edge(d,a), edge(b,e), edge(e,f)], Fs0), sort(Fs0, Fs).
facts_for(2, K, Fs) :- pick_n(K, 2, 5, [parent(ann,bob), parent(bob,cal), parent(cal,dee), parent(ann,eve), parent(eve,fay)], Fs0), sort(Fs0, Fs).
facts_for(3, K, Fs) :- pick_n(K, 3, 5, [bird(tweety), bird(pingu), penguin(pingu), bird(robin), penguin(opus), bird(opus)], Fs0), sort(Fs0, Fs).
facts_for(4, K, Fs) :- pick_n(K, 4, 4, [parent(ann,bob), parent(ann,cal), parent(dan,eve), parent(dan,fay), parent(ann,gus)], Fs0), sort(Fs0, Fs).
facts_for(5, K, Fs) :- pick_n(K, 5, 4, [zero(n0), succ2(n0,n2), succ2(n2,n4), succ2(n4,n6), succ2(n1,n3)], Fs0), sort(Fs0, Fs).
facts_for(6, K, Fs) :- pick_n(K, 6, 4, [a(x), a(y), b(y), b(z), a(w)], Fs0), sort(Fs0, Fs).

clause_texts(["p(X) :- q(X), r(X,Y)", "edge(a,b)", "reach(Foo,Bar) :- edge(Foo,Baz), reach(Baz,Bar)", "f(_,X) :- g(X,_)", "q(A,B,C) :- r(C,B,A)", "s(X) :- \\+ t(X)"]).
texts(["a(1). b(2).", "% comment\np(X) :- q(X).\nq(1).", "x :- y, z.\ny.\nz.", "", "f(a.b, c). g(3.14).", "only one clause"]).
tops(["a,b,c", "f(x,y),g(z)", "[1,2],3", "p(q(r,s),t),u", "\"a,b\",c", "single"]).

io_input(least_model, K, [Program, Facts]) :- programs(Ps), length(Ps, L), I is (K - 1) mod L + 1, nth1(I, Ps, Program), facts_for(I, K, Facts).
io_input(mt_random, K, [Seed, 3]) :- num(K, 1, 0, 999, Seed).
io_input(clauses_of, K, [T]) :- texts(Ts), pick(K, 2, Ts, T).
io_input(canon_clause, K, [C]) :- clause_texts(Cs), pick(K, 3, Cs, C).
io_input(split_top, K, [S]) :- tops(Ts), pick(K, 4, Ts, S).
io_input(strip_spaces, K, [S]) :- pick(K, 5, ["a b c", " lead", "trail ", "no-spaces", "p(X, Y) :- q(X)", "  "], S).
io_input(take, K, [N, L]) :- num(K, 6, 0, 6, N), num(K, 7, 0, 5, Len), ( Len =:= 0 -> L = [] ; numlist(1, Len, L) ).

io_run(least_model, [Program, Facts], Model) :- parse_program(Program, Cs), least_model(Cs, Facts, M0), sort(M0, Model).
% the first N numbers from Python's random.Random(Seed), rounded to 9 places
io_run(mt_random, [Seed, N], Rs) :- mt_seed(Seed, MT), numlist(1, N, Is), foldl([_, R, M0, M]>>(mt_random(M0, R0, M), R is round(R0 * 1.0e9) / 1.0e9), Is, Rs, MT, _).
io_run(clauses_of, [T], Cs) :- clauses_of(T, Cs).
io_run(canon_clause, [C], K) :- canon_clause(C, K).
io_run(split_top, [S], Ps) :- split_top(S, Ps).
io_run(strip_spaces, [S], T) :- strip_spaces(S, T).
io_run(take, [N, L], T) :- take(N, L, T).
