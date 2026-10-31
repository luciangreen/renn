:- encoding(utf8).
/*  types.pl -- proof/types: use proofs to find that one type is the same as, contained in, or
    related to another, because the program's variables tie their argument positions together.

    A type here is the set of values at an argument position (a slot), written P/N:I. The program
    is prog(Facts, Rules) with Rules = [Head-BodyList] (the S2A2 representation).

    Three proof rules give inclusions A ⊆ B that hold for EVERY input (every set of input facts):

      flow       P/N:I ⊆ B  when P is defined by rules only and, in every clause of P, the head's
                 I-th argument is a variable that also stands at B in a positive body literal, or
                 at a slot Y of a rule-defined predicate with Y ⊆ B (assumed for recursive calls:
                 sound by induction on the height of derivations).
                 e.g. reach(X,Y) :- edge(X,Y).  reach(X,Y) :- edge(X,Z), reach(Z,Y).
                      proves reach:1 ⊆ edge:1 and reach:2 ⊆ edge:2.
      cover      Q/M:J ⊆ T/K:L  when a clause of T is a projection T(..V..) :- Q(..V..) whose body is
                 one positive literal with distinct variables: every Q tuple gives a T tuple.
                 e.g. person(X) :- parent(X, _).  proves parent:1 ⊆ person:1.
      chain      the transitive closure of flow and cover (both are sound, so their composition is).

    From these:
      same type    A ⊆ B and B ⊆ A
      related      A and B hold the same variable somewhere (union-find over shared variables):
                   they must have the same sort, even when neither contains the other
      refinement   a template  Q:J --[Conditions]--> T:K  for T(V) :- Q(..V..), V > 0, ...
      conversion   a template  Q:J --[W is f(V)]--> T:K  for T(..W..) :- Q(..V..), W is f(V)
      dimensions   with unit declarations, products multiply units and sums require equal units

    Every inclusion can also be checked semantically on all inputs over a small domain
    (check_inclusion/6), which confirms it or returns a counter-example input.

    Type templates are memoised: a clause is abstracted (predicate names and variables replaced
    by placeholders) and the templates found for that shape are stored, so a later program with
    the same clause shape reuses them instead of deriving them again (memo_stats/2 counts hits). */
:- module(types, [infer_types/2, includes/4, same_type/4, type_classes/2, templates/2,
                  implied_guard/4, check_inclusion/6, dimensions/3, memo_reset/0, memo_stats/2,
                  show_types/1]).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).
:- use_module(library(ordsets)).
:- use_module(library(pairs)).

:- dynamic memo/2, memo_hits/1, memo_misses/1.
memo_hits(0). memo_misses(0).

% ---------------------------------------------------------------- program helpers
key(G, P/N) :- functor(G, P, N).
cmp(G) :- functor(G, F, 2), memberchk(F, [<, >, =<, >=, =:=, =\=, \=, neq]).
arith(G) :- functor(G, is, 2).
user_pos(G) :- callable(G), \+ G = (\+ _), \+ cmp(G), \+ arith(G), \+ G = (_ = _).

rule_preds(prog(_, Rs), Ks) :- findall(K, ( member(H-_, Rs), key(H, K) ), K0), sort(K0, Ks).
fact_preds(prog(Fs, _), Ks) :- findall(K, ( member(F, Fs), key(F, K) ), K0), sort(K0, Ks).
% defined by rules only: its values come from the rules, whatever the input
rules_only(P, K) :- rule_preds(P, RK), memberchk(K, RK), fact_preds(P, FK), \+ memberchk(K, FK).

slots_of(Prog, Slots) :-
    Prog = prog(Fs, Rs),
    findall(K:I, ( ( member(G, Fs) ; member(H-B, Rs), ( G = H ; member(G0, B), ( G0 = (\+ G) -> true ; G = G0 ) ) ),
                   user_pos(G), key(G, K), K = _/N, between(1, N, I) ), S0),
    sort(S0, Slots).

% the slots where variable V stands in the positive user literals of a body
occurs(V, B, Slots) :-
    findall(K:I, ( member(G, B), user_pos(G), key(G, K), arg(I, G, A), A == V ), S0), sort(S0, Slots).

% ---------------------------------------------------------------- flow (greatest fixpoint)
flow(Prog, F) :-
    Prog = prog(_, Rs), slots_of(Prog, All),
    findall(A-B, ( member(A, All), A = K:_, rules_only(Prog, K), member(B, All), A \== B ), C0),
    sort(C0, Cands),
    flow_fix(Prog, Rs, Cands, F).
flow_fix(Prog, Rs, R0, R) :-
    include(flow_ok(Prog, Rs, R0), R0, R1),
    ( R1 == R0 -> R = R0 ; flow_fix(Prog, Rs, R1, R) ).
flow_ok(Prog, Rs, R, (P/N:I)-B) :-
    forall(( member(H-Bd, Rs), key(H, P/N) ),
           ( arg(I, H, V), var(V), occurs(V, Bd, Ys),
             member(Y, Ys), ( Y == B -> true ; Y = KY:_, rules_only(Prog, KY), memberchk(Y-B, R) ) )).

% ---------------------------------------------------------------- cover (projection clauses)
cover(prog(_, Rs), Cov) :-
    findall((Q:J)-(T:L), ( member(H-[G], Rs), user_pos(G), projection(H, G),
                           key(G, Q), key(H, T), arg(L, H, V), arg(J, G, A), A == V ), C0),
    sort(C0, Cov).
projection(H, G) :-
    G =.. [_|As], maplist(var, As), sort(As, S), length(As, N), length(S, N),   % distinct variables
    H =.. [_|Hs], maplist(var, Hs), forall(member(X, Hs), ( member(Y, As), Y == X )).

% ---------------------------------------------------------------- inclusions, same type
infer_types(Prog, types(Incl, Same, Classes, Templates)) :-
    memo_templates(Prog, Templates),
    flow(Prog, F), cover(Prog, C), append(F, C, E0), sort(E0, E),
    closure(E, Incl0), exclude([A-A]>>true, Incl0, Incl),
    findall(A=B, ( member(A-B, Incl), A @< B, memberchk(B-A, Incl) ), Same),
    type_classes(Prog, Classes).

closure(E, C) :-
    findall(A-Z, ( member(A-B, E), member(B-Z, E) ), New), append(E, New, E1), sort(E1, E2),
    ( E2 == E -> C = E ; closure(E2, C) ).

% includes(+Prog, +A, +B, -Proof): A ⊆ B for every input, with the proof
includes(Prog, A, B, Proof) :-
    infer_types(Prog, types(Incl, _, _, _)), memberchk(A-B, Incl),
    flow(Prog, F), cover(Prog, C), append(F, C, E0), sort(E0, E),
    once(path(E, A, B, [A], Steps)),
    maplist(justify(Prog, F, C), Steps, Proof).
path(E, A, B, _, [A-B]) :- memberchk(A-B, E).
path(E, A, B, Seen, [A-X|Rest]) :- member(A-X, E), X \== B, \+ memberchk(X, Seen), path(E, X, B, [X|Seen], Rest).
justify(Prog, _F, C, A-B, cover(A, B, Clause)) :- memberchk(A-B, C), !,
    Prog = prog(_, Rs), A = Q:J, B = T:L, member(H-[G], Rs), key(H, T), key(G, Q), arg(L, H, V), arg(J, G, X), X == V, !,
    copy_term(H-[G], Clause0), numbervars(Clause0, 0, _), Clause = Clause0.
justify(_, _, _, A-B, flow(A, B)).

same_type(Prog, A, B, Proof) :-
    includes(Prog, A, B, P1), includes(Prog, B, A, P2), Proof = both(P1, P2).

% ---------------------------------------------------------------- related slots (shared variables)
% union-find over slots: two slots are related when a variable stands in both in one clause
% (in a positive or negated literal, or tied by a comparison or an arithmetic goal)
type_classes(prog(Fs, Rs), Classes) :-
    slots_of(prog(Fs, Rs), All),
    findall(S1-S2, ( member(H-B, Rs), term_variables(H-B, Vs), member(V, Vs),
                     findall(S, var_slot(V, [H|B], S), Ss0), sort(Ss0, Ss), Ss = [S1|Rest], member(S2, Rest) ), L1),
    % X \= Y: the two sides are of the same sort (but not necessarily numbers)
    findall(S1-S2, ( member(H-B, Rs), member(G, B), ( G = (X \= Y) ; G = neq(X, Y) ), var(X), var(Y),
                     var_slot(X, [H|B], S1), var_slot(Y, [H|B], S2) ), L2),
    append(L1, L2, Links),
    findall(S-[S], member(S, All), Init),
    foldl(union_link, Links, Init, Groups),
    findall(C, member(_-C, Groups), C0), maplist(sort, C0, C1), sort(C1, Classes).
var_slot(V, Gs, S) :-
    member(G0, Gs), ( G0 = (\+ G) -> true ; G = G0 ),
    (   user_pos(G) -> key(G, K), arg(I, G, A), A == V, S = K:I
    ;   ( cmp(G), \+ G = (_ \= _), \+ G = neq(_, _) ; arith(G) ), term_variables(G, GV), member(X, GV), X == V, S = number
    ).
union_link(A-B, G0, G) :-
    group_of(A, G0, KA-CA), group_of(B, G0, KB-CB),
    (   KA == KB -> G = G0
    ;   append(CA, CB, C), exclude({KA, KB}/[K-_]>>( K == KA ; K == KB ), G0, G1), G = [KA-C|G1]
    ).
group_of(S, G, K-C) :- ( member(K-C, G), memberchk(S, C) -> true ; K = S, C = [S] ).

% ---------------------------------------------------------------- templates (refinement, conversion)
templates(prog(_, Rs), Ts) :- findall(T, ( member(R, Rs), clause_template(R, T) ), T0), sort(T0, Ts).
% T(..V..) :- Q(..V..), Conditions on V  gives  Q:J --[Conditions]--> T:L
clause_template(H-B, refine(Q:J, Conds, T:L)) :-
    partition(user_pos, B, [G], Rest), Rest \== [], maplist(cmp, Rest),
    key(G, Q), key(H, T), arg(L, H, V), var(V), arg(J, G, X), X == V,
    forall(member(C, Rest), ( term_variables(C, CV), forall(member(W, CV), W == V) )),
    copy_term(V-Rest, 'X'-Conds0), Conds = Conds0.
% T(..W..) :- Q(..V..), W is f(V)  gives  Q:J --[W is f(V)]--> T:L
clause_template(H-B, convert(Q:J, Formula, T:L)) :-
    partition(user_pos, B, [G], Rest), Rest = [W is E], var(W),
    key(G, Q), key(H, T), arg(L, H, X0), X0 == W, term_variables(E, [V]), arg(J, G, Y), Y == V,
    copy_term(V-(W is E), 'X'-F0), F0 = ('Y' is FE), Formula = ('Y' is FE).

% memoised templates: the clause shape (names and variables abstracted) is the key
memo_reset :- retractall(memo(_, _)), retractall(memo_hits(_)), retractall(memo_misses(_)),
              assertz(memo_hits(0)), assertz(memo_misses(0)).
memo_stats(H, M) :- memo_hits(H), memo_misses(M).
memo_templates(prog(_, Rs), Ts) :-
    foldl(memo_rule, Rs, [], T0), sort(T0, Ts).
memo_rule(R, A0, A) :-
    shape(R, Shape, Names),
    (   memo(Shape, Schema) -> bump(memo_hits)
    ;   ( clause_template(R, T) -> abstract_t(T, Names, Schema) ; Schema = none ), assertz(memo(Shape, Schema)), bump(memo_misses)
    ),
    ( Schema == none -> A = A0 ; instantiate(Schema, Names, T1), A = [T1|A0] ).
bump(C) :- G =.. [C, N], retract(G), N1 is N + 1, G1 =.. [C, N1], assertz(G1).
% shape: predicate names become p0, p1, ... in order of appearance; variables numbered
shape(H-B, Shape, Names) :-
    copy_term(H-B, H1-B1), numbervars(H1-B1, 0, _),
    foldl(name_lit, [H1|B1], []-[], Names0-Lits), reverse(Names0, Names), reverse(Lits, Shape).
name_lit(G, N0-L0, N-[G1|L0]) :-
    (   user_pos(G) -> G =.. [F|As], ( nth0(I, N0, F) -> N = N0 ; length(N0, I), N = [F|N0] ),
        length(N, Len), J is Len - 1 - I, format(atom(P), 'p~w', [J]), G1 =.. [P|As]
    ;   N = N0, G1 = G
    ).
abstract_t(T, Names, S) :- T =.. [F|As], maplist(abs_arg(Names), As, Bs), S =.. [F|Bs].
abs_arg(Names, (P/N):I, (X/N):I) :- !, nth0(J, Names, P), format(atom(X), 'p~w', [J]).
abs_arg(_, A, A).
instantiate(S, Names, T) :- S =.. [F|As], maplist(inst_arg(Names), As, Bs), T =.. [F|Bs].
inst_arg(Names, (X/N):I, (P/N):I) :- atom(X), atom_concat(p, JA, X), atom_number(JA, J), !, nth0(J, Names, P).
inst_arg(_, A, A).

% ---------------------------------------------------------------- the optimisation
% implied_guard(+Prog, +RuleIndex, +LitIndex, -Proof): the J-th body literal of rule I is a unary
% guard t(V) that is implied for every input, because V also stands at a slot S of another
% positive literal of the same body and S ⊆ t:1 is proved.
implied_guard(Prog, I, J, implied(V, by(S), Proof)) :-
    Prog = prog(_, Rs), nth1(I, Rs, _-B), nth1(J, B, G), user_pos(G), key(G, T/1), arg(1, G, V), var(V),
    nth1(J2, B, G2), J2 \== J, user_pos(G2), key(G2, K2), arg(I2, G2, A), A == V, S = K2:I2,
    S \== (T/1):1,
    includes(Prog, S, (T/1):1, Proof), !.
implied_guard(Prog, I, J, implied(V, by(G2), same_literal)) :-       % a repeated guard implies itself
    Prog = prog(_, Rs), nth1(I, Rs, _-B), nth1(J, B, G), user_pos(G), key(G, _/1),
    nth1(J2, B, G2), J2 \== J, G2 == G, arg(1, G, V), !.

% ---------------------------------------------------------------- semantic check
% check_inclusion(+Prog, +A, +B, +EdbPreds, +Consts, -Result): A ⊆ B on every set of input facts
% over the given predicates and constants (the program's own facts are dropped).
check_inclusion(prog(_, Rs), A, B, Edb, Consts, Result) :-
    findall(G, ( member(P/N, Edb), length(Args, N), maplist({Consts}/[X]>>member(X, Consts), Args), G =.. [P|Args] ), Atoms),
    length(Atoms, NA),
    (   NA > 18 -> Result = too_many_inputs(NA)
    ;   findall((H :- Bd), ( member(H-L, Rs), list_conj(L, Bd) ), Cs),
        (   subset_of(Atoms, Sub), prover:least_model(Cs, Sub, M),
            values(M, A, VA), values(M, B, VB), member(V, VA), \+ memberchk(V, VB)
        ->  Result = refuted(input(Sub), value(V))
        ;   Total is 2 ** NA, Result = proved(all_inputs(Total))
        )
    ).
values(M, (P/N):I, Vs) :- findall(V, ( member(G, M), functor(G, P, N), arg(I, G, V) ), V0), sort(V0, Vs).
list_conj([], true).
list_conj([G], G) :- !.
list_conj([G|Gs], (G, B)) :- list_conj(Gs, B).
subset_of([], []).
subset_of([X|Xs], [X|Ys]) :- subset_of(Xs, Ys).
subset_of([_|Xs], Ys) :- subset_of(Xs, Ys).

% ---------------------------------------------------------------- dimensions
% dimensions(+Prog, +Decls, -Result): Decls = [(Slot)-Units] (bracket the slot: ':' binds more loosely than '-'), Units = [Base-Exponent] (e.g.
% [kg-1, m-1, s-(-2)]). Units flow along shared variables; W is A*B multiplies, W is A/B divides,
% W is A+B and W is A-B (and comparisons) need equal units. Result: ok(SlotUnits) or
% refuted(Clause, Reason).
dimensions(prog(_, Rs), Decls, Result) :-
    (   member(H-B, Rs), \+ clause_dims(H-B, Decls, _)
    ->  copy_term(H-B, C), numbervars(C, 0, _), clause_dims_reason(H-B, Decls, Why), Result = refuted(C, Why)
    ;   findall(S-U, ( member(R, Rs), clause_dims(R, Decls, Env), R = H-_, key(H, K), arg(I, H, V),
                        member(X-U, Env), X == V, S = K:I ), SU0), sort(SU0, SU), Result = ok(SU)
    ).
clause_dims(H-B, Decls, Env) :-
    % not findall: it would copy the variables, and the units must stay on the clause's own ones
    foldl(lit_decls(Decls), [H|B], [], E0),
    consistent(E0, [], Env0),
    foldl(arith_dims, B, Env0, Env).
lit_decls(Decls, G, A0, A) :-
    (   user_pos(G) -> key(G, K), K = _/N, numlist(1, N, Is) ; Is = [] ),
    foldl({G, K, Decls}/[I, B0, B1]>>( arg(I, G, V), var(V), memberchk((K:I)-U, Decls) -> B1 = [V-U|B0] ; B1 = B0 ), Is, A0, A).
consistent([], E, E).
consistent([V-U|R], E0, E) :- norm(U, N), ( member(X-U0, E0), X == V -> U0 == N, E1 = E0 ; E1 = [V-N|E0] ), consistent(R, E1, E).
arith_dims(W is Ex, E0, E) :- !, dim_of(Ex, E0, U), ( member(X-U0, E0), X == W -> U0 == U, E = E0 ; E = [W-U|E0] ).
arith_dims(G, E0, E0) :- cmp(G), !, G =.. [_, A, B], ( dim_of(A, E0, UA), dim_of(B, E0, UB) -> ( UA == UB ; UA == [] ; UB == [] ) ; true ).
arith_dims(_, E, E).
dim_of(X, E, U) :- var(X), !, member(Y-U, E), Y == X, !.
dim_of(X, _, []) :- number(X), !.
dim_of(A*B, E, U) :- !, dim_of(A, E, UA), dim_of(B, E, UB), add_units(UA, UB, 1, U).
dim_of(A/B, E, U) :- !, dim_of(A, E, UA), dim_of(B, E, UB), add_units(UA, UB, -1, U).
dim_of(A+B, E, U) :- !, dim_of(A, E, U), dim_of(B, E, U2), U == U2.
dim_of(A-B, E, U) :- !, dim_of(A, E, U), dim_of(B, E, U2), U == U2.
add_units(A, B, S, U) :- findall(K-X, ( member(K-X0, B), X is S * X0 ), B1), append(A, B1, AB), norm(AB, U).
norm(U, N) :- msort(U, S), merge_units(S, N).
merge_units([], []).
merge_units([K-X, K-Y|R], N) :- !, Z is X + Y, merge_units([K-Z|R], N).
merge_units([_-0|R], N) :- !, merge_units(R, N).
merge_units([P|R], [P|N]) :- merge_units(R, N).
clause_dims_reason(H-B, Decls, Why) :-
    (   member(Ex, B), Ex = (_ is E), E =.. [Op, _, _], memberchk(Op, [+, -])
    ->  copy_term(Ex, Ex1), numbervars(Ex1, 0, _), format(atom(Why), 'sum of quantities with different units in ~w', [Ex1])
    ;   Why = units_disagree
    ), ignore(H = H), ignore(Decls = Decls).

% ---------------------------------------------------------------- printing
show_types(Prog) :-
    infer_types(Prog, types(Incl, Same, Classes, Ts)),
    format("inclusions (every input):~n"), forall(member(A-B, Incl), format("  ~w ⊆ ~w~n", [A, B])),
    format("same type:~n"), forall(member(A=B, Same), format("  ~w = ~w~n", [A, B])),
    format("related (shared variables):~n"), forall(( member(C, Classes), C = [_, _|_] ), format("  ~w~n", [C])),
    format("templates:~n"), forall(member(T, Ts), format("  ~w~n", [T])).
