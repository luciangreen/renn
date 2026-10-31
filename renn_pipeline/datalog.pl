/*  datalog.pl -- a small bottom-up evaluator for the Datalog programs in this study (stratified \+,
    \=, =, and neq/2 as a test), used to compare learned programs with the original ones on random
    inputs. The random inputs come from a Mersenne Twister seeded exactly as Python's
    random.Random(seed), so the agreement figures match the earlier Python runs.

    parse_program(+Text, -Clauses)            Clauses: [Head-Body], Body a list of literals
    least_model(+Clauses, +Facts, -Model)     Facts and Model: lists of ground terms
    agreement(+Orig, +Learned, +EdbPreds, +Consts, +Targets, +Options, -Fraction)
        EdbPreds, Targets: [Name/Arity]; Consts: [Atom]; Options: trials(N), seed(S), density(D) */
:- module(datalog, [parse_program/2, least_model/3, agreement/7, mt_seed/2, mt_random/3]).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

% ---------------------------------------------------------------- reading programs
parse_program(Text, Clauses) :-
    setup_call_cleanup(open_string(Text, S), read_all(S, Ts), close(S)),
    maplist(to_clause, Ts, Clauses).
read_all(S, Ts) :- read_term(S, T, []), ( T == end_of_file -> Ts = [] ; Ts = [T|R], read_all(S, R) ).
to_clause((H :- B), H-Ls) :- !, conj_list(B, Ls).
to_clause(H, H-[]).
conj_list((A, B), L) :- !, conj_list(A, LA), conj_list(B, LB), append(LA, LB, L).
conj_list(A, [A]).

% ---------------------------------------------------------------- evaluation
% (classified first, then compared, so kind(L, pos) is false for a test or a negation)
kind(L, K) :- kind_(L, K0), K = K0.
kind_(\+ _, neg) :- !.
kind_(_ \= _, neq) :- !.
kind_(neq(_, _), neq) :- !.
kind_(_ = _, eq) :- !.
kind_(_, pos).

pkey(T, N/A) :- functor(T, N, A).

strata(Clauses, St) :-
    findall(K, ( member(H-_, Clauses), pkey(H, K) ), K0), sort(K0, Ks),
    findall(K-0, member(K, Ks), S0), length(Ks, NK), Lim is NK + 2,
    strata_loop(Lim, Clauses, S0, St).
strata_loop(0, _, S, S) :- !.
strata_loop(N, Cs, S0, S) :-
    foldl(raise, Cs, S0, S1), N1 is N - 1, strata_loop(N1, Cs, S1, S).
raise(H-Body, S0, S) :-
    pkey(H, KH),
    foldl({KH}/[L, A0, A]>>( kind(L, Kd), memberchk(Kd, [pos, neg]), ( Kd == neg -> L = (\+ G) ; G = L ), pkey(G, KG),
                              memberchk(KG-SG, A0)
                           -> ( Kd == neg -> Need is SG + 1 ; Need = SG ), memberchk(KH-SH, A0),
                              ( SH < Need -> selectchk(KH-SH, A0, KH-Need, A) ; A = A0 )
                           ;  A = A0 ), Body, S0, S).

least_model(Clauses, Facts, Model) :-
    strata(Clauses, St), findall(S, member(_-S, St), Ss), max_list([0|Ss], Max),
    sort(Facts, DB0), numlist(0, Max, Levels),
    foldl({Clauses, St}/[L, D0, D]>>( include({St, L}/[H-_]>>( pkey(H, K), memberchk(K-L, St) ), Clauses, Rules),
                                      fix(Rules, D0, D) ), Levels, DB0, Model).
fix(Rules, DB, Out) :-
    findall(G, ( member(R, Rules), copy_term(R, G-Body0), order(Body0, Body), solve(Body, DB), ground(G),
                 \+ memberchk(G, DB) ), New0), sort(New0, New),
    (   New == [] -> Out = DB ; ord_union(DB, New, DB1), fix(Rules, DB1, Out) ).
% bind variables before tests: positive literals first, otherwise in order
order(B, O) :- partition([L]>>kind(L, pos), B, P, N), append(P, N, O).
solve([], _).
solve([L|Ls], DB) :-
    kind(L, K),
    (   K == pos -> member(L, DB)
    ;   K == neg -> L = (\+ G), \+ ( member(F, DB), \+ \+ F = G )
    ;   K == neq -> ( L = (X \= Y) ; L = neq(X, Y) ), X \== Y
    ;   L = (X = Y), X = Y
    ),
    solve(Ls, DB).

% ---------------------------------------------------------------- random inputs
% Fraction of random inputs on which both programs give identical target relations.
agreement(Orig, Learned, Edb, Consts, Targets, Opts, Frac) :-
    opt(trials(T), Opts, 100), opt(seed(Seed), Opts, 0), opt(density(D), Opts, 0.3),
    mt_seed(Seed, MT),
    numlist(1, T, Ts),
    foldl({Orig, Learned, Edb, Consts, Targets, D, MT}/[_, S0, S]>>(
              random_facts(Edb, Consts, D, MT, Facts),
              least_model(Orig, Facts, M1), least_model(Learned, Facts, M2),
              include({Targets}/[A]>>( pkey(A, K), memberchk(K, Targets) ), M1, F1),
              include({Targets}/[A]>>( pkey(A, K), memberchk(K, Targets) ), M2, F2),
              ( F1 == F2 -> S is S0 + 1 ; S = S0 ) ), Ts, 0, Same),
    Frac is Same / T.
opt(O, Opts, D) :- ( memberchk(O, Opts) -> true ; arg(1, O, D) ).

% for each input predicate, every tuple of constants (in itertools.product order) is a fact with
% probability Density
random_facts(Edb, Consts, D, MT, Facts) :-
    findall(N/A-Tup, ( member(N/A, Edb), length(Tup, A), tuple(Tup, Consts) ), Cands),
    foldl({D, MT}/[N/A-Tup, F0, F]>>( mt_random(MT, R, _), ( R < D -> ( A =:= 0 -> G = N ; G =.. [N|Tup] ), F = [G|F0] ; F = F0 ) ),
          Cands, [], Rev), reverse(Rev, Facts).
tuple([], _).
tuple([X|Xs], Cs) :- member(X, Cs), tuple(Xs, Cs).

% ---------------------------------------------------------------- MT19937, as CPython's random
% The state is a mutable term mt(Index, Array) with Array = s(W0, ..., W623) (changed by setarg).
mt_seed(Seed, mt(I, A)) :-
    I = 624, functor(A, s, 624),
    init_genrand(A, 19650218),
    Key is abs(Seed), key_words(Key, Ws),
    init_by_array(A, Ws), nb_setarg(1, mt(I, A), 624).
key_words(0, [0]) :- !.
key_words(K, Ws) :- key_words_(K, Ws).
key_words_(0, []) :- !.
key_words_(K, [W|Ws]) :- W is K /\ 0xffffffff, K1 is K >> 32, key_words_(K1, Ws).

w(A, I, V) :- J is I + 1, arg(J, A, V).
w_set(A, I, V) :- J is I + 1, nb_setarg(J, A, V).

init_genrand(A, S) :-
    S0 is S /\ 0xffffffff, w_set(A, 0, S0),
    forall(between(1, 623, I), ( I1 is I - 1, w(A, I1, P),
                                 V is (1812433253 * (P xor (P >> 30)) + I) /\ 0xffffffff, w_set(A, I, V) )).
init_by_array(A, Key) :-
    length(Key, KL), K0 is max(624, KL),
    ba1(K0, 1, 0, A, Key, KL, I1),
    ba2(623, I1, A),
    w_set(A, 0, 0x80000000).
ba1(0, I, _, _, _, _, I) :- !.
ba1(K, I, J, A, Key, KL, IOut) :-
    I1 is I - 1, w(A, I, M), w(A, I1, P), nth0(J, Key, KJ),
    V is ((M xor ((P xor (P >> 30)) * 1664525)) + KJ + J) /\ 0xffffffff, w_set(A, I, V),
    I2 is I + 1, J2 is J + 1,
    ( I2 >= 624 -> w(A, 623, L), w_set(A, 0, L), I3 = 1 ; I3 = I2 ),
    ( J2 >= KL -> J3 = 0 ; J3 = J2 ),
    K1 is K - 1, ba1(K1, I3, J3, A, Key, KL, IOut).
ba2(0, _, _) :- !.
ba2(K, I, A) :-
    I1 is I - 1, w(A, I, M), w(A, I1, P),
    V is ((M xor ((P xor (P >> 30)) * 1566083941)) - I) /\ 0xffffffff, w_set(A, I, V),
    I2 is I + 1, ( I2 >= 624 -> w(A, 623, L), w_set(A, 0, L), I3 = 1 ; I3 = I2 ),
    K1 is K - 1, ba2(K1, I3, A).

genrand(MT, Y) :-
    MT = mt(I, A),
    ( I >= 624 -> twist(A), I0 = 0 ; I0 = I ),
    w(A, I0, Y0), I1 is I0 + 1, nb_setarg(1, MT, I1),
    Y1 is Y0 xor (Y0 >> 11),
    Y2 is Y1 xor ((Y1 << 7) /\ 0x9d2c5680),
    Y3 is Y2 xor ((Y2 << 15) /\ 0xefc60000),
    Y is (Y3 xor (Y3 >> 18)) /\ 0xffffffff.
twist(A) :-
    forall(between(0, 623, K),
           ( K1 is (K + 1) mod 624, K2 is (K + 397) mod 624,
             w(A, K, X), w(A, K1, X1), w(A, K2, X2),
             Y is (X /\ 0x80000000) \/ (X1 /\ 0x7fffffff),
             ( Y /\ 1 =:= 1 -> Mag = 0x9908b0df ; Mag = 0 ),
             V is X2 xor (Y >> 1) xor Mag, w_set(A, K, V) )).

% random() in [0, 1), 53 bits, as CPython
mt_random(MT, R, MT) :-
    genrand(MT, A0), genrand(MT, B0), A is A0 >> 5, B is B0 >> 6,
    R is (A * 67108864.0 + B) * (1.0 / 9007199254740992.0).
