# renn_pipeline: 200 input/output pairs

Each pair is a query to the RENN pipeline: the prover (equivalence of two programs for every input, least models, a network proved equal to its program from its weights alone), networks run forward from their weights, the inputs recovered from a network's whole output (smallest and largest, each checked by running the network forward), and the Datalog evaluator with its Python-compatible random numbers. Networks are the pl2ann builds in EXP_DIR (convert_all.pl). Every output was produced by running this repository's code with `io_pairs/generate.pl`; nothing was written by hand.

| Category | Pairs |
|---|---|
| `prover/equivalence` | 30 |
| `prover/least-model` | 10 |
| `prover/network` | 66 |
| `network/forward` | 34 |
| `inversion` | 50 |
| `datalog` | 10 |

## 1. reach: the original against the recursion on the left

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [(r(X,Y) :- e(X,Y)), (r(X,Y) :- r(X,Z), e(Z,Y))], [r/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 2. reach: the original against a duplicate clause added

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [r/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 3. reach: the original against the recursive clause dropped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [(r(X,Y) :- e(X,Y))], [r/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = refuted(input([e(a, a), e(a, b), e(b, a)]), only_in_a([r(b, b)]), only_in_b([]))
```

## 4. reach: the original against arguments swapped in the base case

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [(r(X,Y) :- e(Y,X)), (r(X,Y) :- e(X,Z), r(Z,Y))], [r/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = refuted(input([e(a, a), e(a, b), e(b, b)]), only_in_a([]), only_in_b([r(b, a)]))
```

## 5. reach: the original against a two-step clause added

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), e(Z,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [r/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 6. grandparent: the original against body order swapped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(g(X,Y) :- p(X,Z), p(Z,Y))], [(g(X,Y) :- p(Z,Y), p(X,Z))], [g/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(syntactic([]))
```

## 7. grandparent: the original against through a helper predicate

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(g(X,Y) :- p(X,Z), p(Z,Y))], [(c(X,Z) :- p(X,Z)), (g(X,Y) :- c(X,Z), p(Z,Y))], [g/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(exhaustive(512))
```

## 8. grandparent: the original against a duplicate literal

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(g(X,Y) :- p(X,Z), p(Z,Y))], [(g(X,Y) :- p(X,Z), p(Z,Y), p(X,Z))], [g/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(exhaustive(512))
```

## 9. grandparent: the original against one step only

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(g(X,Y) :- p(X,Z), p(Z,Y))], [(g(X,Y) :- p(X,Y))], [g/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = refuted(input([p(a, a), p(a, b), p(a, c), p(b, a), p(b, b), p(b, c), p(c, a), p(c, b)]), only_in_a([g(c, c)]), only_in_b([]))
```

## 10. grandparent: the original against the wrong direction

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(g(X,Y) :- p(X,Z), p(Z,Y))], [(g(X,Y) :- p(Z,X), p(Y,Z))], [g/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = refuted(input([p(a, a), p(a, b), p(a, c), p(b, a), p(b, b), p(b, c), p(c, c)]), only_in_a([g(a, c), g(b, c)]), only_in_b([g(c, a), g(c, b)]))
```

## 11. sibling: the original against the disequality first

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y)], [(s(X,Y) :- X \= Y, p(Z,X), p(Z,Y))], [s/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(syntactic([]))
```

## 12. sibling: the original against a subsumed clause added

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y)], [(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y), (s(X,Y) :- p(Z,X), p(Z,Y), p(Z,Z), X \= Y)], [s/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(exhaustive(512))
```

## 13. sibling: the original against without the disequality

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y)], [(s(X,Y) :- p(Z,X), p(Z,Y))], [s/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = refuted(input([p(a, a), p(a, b), p(a, c), p(b, a), p(b, b), p(b, c), p(c, a), p(c, b), p(c, c)]), only_in_a([]), only_in_b([s(a, a), s(b, b), s(c, c)]))
```

## 14. sibling: the original against Y and X swapped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y)], [(s(Y,X) :- p(Z,X), p(Z,Y), X \= Y)], [s/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = proved(exhaustive(512))
```

## 15. sibling: the original against parents must differ instead

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(s(X,Y) :- p(Z,X), p(Z,Y), X \= Y)], [(s(X,Y) :- p(Z,X), p(W,Y), Z \= W)], [s/2], edb([p/2],[a,b,c]), Result).
```

**Output**

```text
Result = refuted(input([p(a, a), p(a, b), p(a, c), p(b, a), p(b, b), p(b, c), p(c, a), p(c, b), p(c, c)]), only_in_a([]), only_in_b([s(a, a), s(b, b), s(c, c)]))
```

## 16. flies: the original against the negation first in the body after the binding

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(f(X) :- b(X), \+ q(X))], [(f(X) :- b(X), \+ q(X)), (f(X) :- b(X), \+ q(X))], [f/1], edb([b/1,q/1],[t,u]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 17. flies: the original against the guard dropped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(f(X) :- b(X), \+ q(X))], [(f(X) :- b(X))], [f/1], edb([b/1,q/1],[t,u]), Result).
```

**Output**

```text
Result = refuted(input([b(t), b(u), q(t), q(u)]), only_in_a([]), only_in_b([f(t), f(u)]))
```

## 18. flies: the original against through an abnormal predicate

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(f(X) :- b(X), \+ q(X))], [(ab(X) :- q(X)), (f(X) :- b(X), \+ ab(X))], [f/1], edb([b/1,q/1],[t,u]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 19. flies: the original against negation swapped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(f(X) :- b(X), \+ q(X))], [(f(X) :- q(X), \+ b(X))], [f/1], edb([b/1,q/1],[t,u]), Result).
```

**Output**

```text
Result = refuted(input([b(t), b(u), q(t)]), only_in_a([f(u)]), only_in_b([]))
```

## 20. flies: the original against a stronger guard

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(f(X) :- b(X), \+ q(X))], [(f(X) :- b(X), \+ q(X), \+ b(X))], [f/1], edb([b/1,q/1],[t,u]), Result).
```

**Output**

```text
Result = refuted(input([b(t), b(u), q(t)]), only_in_a([f(u)]), only_in_b([]))
```

## 21. path3: the original against split into two predicates

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))], [(two(X,W) :- e(X,Z), e(Z,W)), (t(X,Y) :- two(X,W), e(W,Y))], [t/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 22. path3: the original against a duplicate literal

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))], [(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y), e(Z,W))], [t/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 23. path3: the original against two steps only

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))], [(t(X,Y) :- e(X,Z), e(Z,Y))], [t/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = refuted(input([e(a, b), e(b, a)]), only_in_a([t(a, b), t(b, a)]), only_in_b([t(a, a), t(b, b)]))
```

## 24. path3: the original against renamed variables

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))], [(t(A,B) :- e(A,C), e(C,D), e(D,B))], [t/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = proved(syntactic([]))
```

## 25. path3: the original against the last step reversed

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(t(X,Y) :- e(X,Z), e(Z,W), e(W,Y))], [(t(X,Y) :- e(X,Z), e(Z,W), e(Y,W))], [t/2], edb([e/2],[a,b]), Result).
```

**Output**

```text
Result = refuted(input([e(a, a), e(a, b), e(b, b)]), only_in_a([]), only_in_b([t(b, a)]))
```

## 26. both: the original against the order swapped

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(c(X) :- a(X), b(X))], [(c(X) :- b(X), a(X))], [c/1], edb([a/1,b/1],[x,y]), Result).
```

**Output**

```text
Result = proved(syntactic([]))
```

## 27. both: the original against either instead of both

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(c(X) :- a(X), b(X))], [(c(X) :- a(X)), (c(X) :- b(X))], [c/1], edb([a/1,b/1],[x,y]), Result).
```

**Output**

```text
Result = refuted(input([a(x), a(y), b(x)]), only_in_a([]), only_in_b([c(y)]))
```

## 28. both: the original against a repeated literal

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(c(X) :- a(X), b(X))], [(c(X) :- a(X), a(X), b(X))], [c/1], edb([a/1,b/1],[x,y]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 29. both: the original against a subsumed clause added

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(c(X) :- a(X), b(X))], [(c(X) :- a(X), b(X)), (c(X) :- a(X), b(X), a(X))], [c/1], edb([a/1,b/1],[x,y]), Result).
```

**Output**

```text
Result = proved(exhaustive(16))
```

## 30. both: the original against only a

*Category:* `prover/equivalence`

**Input**

```prolog
?- equivalent([(c(X) :- a(X), b(X))], [(c(X) :- a(X))], [c/1], edb([a/1,b/1],[x,y]), Result).
```

**Output**

```text
Result = refuted(input([a(x), a(y), b(x)]), only_in_a([]), only_in_b([c(y)]))
```

## 31. Least model: transitive closure on a chain

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [e(1,2), e(2,3), e(3,4)], Model).
```

**Output**

```text
Model = [e(1, 2), e(2, 3), e(3, 4), r(1, 2), r(1, 3), r(1, 4), r(2, 3), r(2, 4), r(3, 4)]
```

## 32. Least model: transitive closure on a cycle

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(r(X,Y) :- e(X,Y)), (r(X,Y) :- e(X,Z), r(Z,Y))], [e(a,b), e(b,a)], Model).
```

**Output**

```text
Model = [e(a, b), e(b, a), r(a, a), r(a, b), r(b, a), r(b, b)]
```

## 33. Least model: same generation

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(sg(X,X) :- n(X)), (sg(X,Y) :- p(X,A), sg(A,B), p(Y,B))], [n(a), n(b), n(c), n(d), p(c,a), p(d,b)], Model).
```

**Output**

```text
Model = [n(a), n(b), n(c), n(d), p(c, a), p(d, b), sg(a, a), sg(b, b), sg(c, c), sg(d, d)]
```

## 34. Least model: default with an exception

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(fl(X) :- bird(X), \+ ab(X)), (ab(X) :- peng(X))], [bird(t), bird(p), peng(p)], Model).
```

**Output**

```text
Model = [ab(p), bird(p), bird(t), fl(t), peng(p)]
```

## 35. Least model: even and odd by mutual recursion

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(ev(0)), (ev(Y) :- od(X), nx(X,Y)), (od(Y) :- ev(X), nx(X,Y))], [nx(0,1), nx(1,2), nx(2,3), nx(3,4)], Model).
```

**Output**

```text
Model = [ev(0), ev(2), ev(4), od(1), od(3), nx(0, 1), nx(1, 2), nx(2, 3), nx(3, 4)]
```

## 36. Least model: disequality

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(dif(X,Y) :- c(X), c(Y), X \= Y)], [c(1), c(2), c(3)], Model).
```

**Output**

```text
Model = [c(1), c(2), c(3), dif(1, 2), dif(1, 3), dif(2, 1), dif(2, 3), dif(3, 1), dif(3, 2)]
```

## 37. Least model: grandparent

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(g(X,Y) :- p(X,Z), p(Z,Y))], [p(a,b), p(b,c), p(b,d), p(c,e)], Model).
```

**Output**

```text
Model = [g(a, c), g(a, d), g(b, e), p(a, b), p(b, c), p(b, d), p(c, e)]
```

## 38. Least model: two strata of negation

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(a(X) :- d(X), \+ b(X)), (b(X) :- d(X), \+ c(X))], [d(1), d(2), c(1)], Model).
```

**Output**

```text
Model = [a(1), b(2), c(1), d(1), d(2)]
```

## 39. Least model: reachable from a start node

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(rs(X) :- start(X)), (rs(Y) :- rs(X), e(X,Y))], [start(a), e(a,b), e(b,c), e(d,a)], Model).
```

**Output**

```text
Model = [rs(a), rs(b), rs(c), start(a), e(a, b), e(b, c), e(d, a)]
```

## 40. Least model: nodes with no outgoing edge

*Category:* `prover/least-model`

**Input**

```prolog
?- prover_least_model([(has(X) :- e(X,_)), (sink(X) :- n(X), \+ has(X))], [n(a), n(b), n(c), e(a,b), e(b,c)], Model).
```

**Output**

```text
Model = [has(a), has(b), n(a), n(b), n(c), sink(c), e(a, b), e(b, c)]
```

## 41. Network 1 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(1).
```

**Output**

```text
proved(same_ground_clauses(39))
```

## 42. Network 3 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, e).
edge(a, f).
edge(b, d).
edge(c, b).
edge(e, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(3).
```

**Output**

```text
proved(same_ground_clauses(257))
```

## 43. Network 6 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, c).
edge(b, d).
edge(c, b).
edge(d, c).
edge(e, b).
edge(e, c).
edge(e, d).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(6).
```

**Output**

```text
proved(same_ground_clauses(157))
```

## 44. Network 9 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, d).
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(9).
```

**Output**

```text
proved(same_ground_clauses(84))
```

## 45. Network 11 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(11).
```

**Output**

```text
proved(same_ground_clauses(83))
```

## 46. Network 14 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, f).
edge(b, f).
edge(c, e).
edge(c, f).
edge(f, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(14).
```

**Output**

```text
proved(same_ground_clauses(155))
```

## 47. Network 17 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, b).
edge(a, c).
edge(b, c).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(17).
```

**Output**

```text
proved(same_ground_clauses(86))
```

## 48. Network 19 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(19).
```

**Output**

```text
proved(same_ground_clauses(41))
```

## 49. Network 22 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, e).
edge(b, a).
edge(c, b).
edge(c, f).
edge(d, c).
edge(d, e).
edge(d, f).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(22).
```

**Output**

```text
proved(same_ground_clauses(259))
```

## 50. Network 25 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, d).
edge(b, c).
edge(c, b).
edge(c, d).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(25).
```

**Output**

```text
proved(same_ground_clauses(87))
```

## 51. Network 27 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(b, d).
edge(b, f).
edge(c, e).
edge(c, f).
edge(d, e).
edge(f, e).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(27).
```

**Output**

```text
proved(same_ground_clauses(156))
```

## 52. Network 30 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, c).
edge(a, d).
edge(c, b).
edge(e, b).
edge(e, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(30).
```

**Output**

```text
proved(same_ground_clauses(155))
```

## 53. Network 33 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(b, d).
edge(c, a).
edge(c, f).
edge(e, f).
edge(f, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(33).
```

**Output**

```text
proved(same_ground_clauses(257))
```

## 54. Network 35 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(b, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(35).
```

**Output**

```text
proved(same_ground_clauses(38))
```

## 55. Network 38 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, b).
edge(b, e).
edge(c, e).
edge(e, f).
edge(f, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(38).
```

**Output**

```text
proved(same_ground_clauses(155))
```

## 56. Network 41 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(fay, dee).
parent(dee, cy).
parent(fay, ann).
parent(cy, ivy).
parent(dee, jo).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_proof(41).
```

**Output**

```text
proved(same_ground_clauses(257))
```

## 57. Network 43 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(ann, cy).
parent(cy, gus).
parent(cy, fay).
parent(fay, dee).
parent(cy, jo).
parent(ann, hal).
parent(jo, ivy).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- net_proof(43).
```

**Output**

```text
proved(same_ground_clauses(455))
```

## 58. Network 46 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(gus, ivy).
parent(gus, jo).
parent(jo, ann).
parent(jo, bob).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- net_proof(46).
```

**Output**

```text
proved(same_ground_clauses(104))
```

## 59. Network 49 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(cy, ivy).
parent(ivy, gus).
parent(ivy, jo).
parent(jo, ann).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- net_proof(49).
```

**Output**

```text
proved(same_ground_clauses(104))
```

## 60. Network 51 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(fay, ivy).
parent(fay, cy).
parent(ivy, gus).
parent(cy, eli).
parent(gus, ann).
parent(ann, bob).
parent(ivy, dee).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_proof(51).
```

**Output**

```text
proved(same_ground_clauses(519))
```

## 61. Network 54 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(cy, ann).
parent(ann, fay).
parent(cy, hal).
parent(fay, ivy).
parent(ann, bob).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_proof(54).
```

**Output**

```text
proved(same_ground_clauses(221))
```

## 62. Network 57 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(ann, jo).
parent(ann, bob).
parent(ann, eli).
parent(eli, hal).
parent(bob, ivy).
parent(hal, fay).
parent(fay, cy).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_proof(57).
```

**Output**

```text
proved(same_ground_clauses(519))
```

## 63. Network 59 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(eli, cy).
parent(eli, jo).
parent(jo, hal).
parent(eli, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_proof(59).
```

**Output**

```text
proved(same_ground_clauses(154))
```

## 64. Network 62 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(gus, fay).
parent(fay, eli).
parent(gus, ivy).
parent(ivy, ann).
parent(gus, jo).
parent(jo, bob).
parent(jo, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_proof(62).
```

**Output**

```text
proved(same_ground_clauses(583))
```

## 65. Network 65 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(jo, ann).
parent(ann, gus).
parent(gus, dee).
parent(jo, eli).
parent(dee, ivy).
parent(jo, hal).
parent(gus, fay).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_proof(65).
```

**Output**

```text
proved(same_ground_clauses(583))
```

## 66. Network 67 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bit(0).
bit(1).

or(X, Y) :- bit(X), bit(Y), X = 1.
or(X, Y) :- bit(X), bit(Y), Y = 1.

?- net_proof(67).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 67. Network 70 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).

?- net_proof(70).
```

**Output**

```text
proved(same_ground_clauses(8))
```

## 68. Network 73 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bit(0).
bit(1).

or(X, Y) :- bit(X), bit(Y), X = 1.
or(X, Y) :- bit(X), bit(Y), Y = 1.

?- net_proof(73).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 69. Network 75 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bit(0).
bit(1).

any(X, Y) :- bit(X), bit(Y), X = 1.
any(X, Y) :- bit(X), bit(Y), Y = 1.
nor(X, Y) :- bit(X), bit(Y), \+ any(X, Y).

?- net_proof(75).
```

**Output**

```text
proved(same_ground_clauses(9))
```

## 70. Network 78 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(pingu).
bird(tweety).
bird(opus).
bird(polly).
bird(emu).
bird(robin).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).

?- net_proof(78).
```

**Output**

```text
proved(same_ground_clauses(13))
```

## 71. Network 81 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(opus).
bird(pingu).
bird(robin).
bird(emu).
bird(kiwi).
penguin(opus).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).

?- net_proof(81).
```

**Output**

```text
proved(same_ground_clauses(12))
```

## 72. Network 83 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(pingu).
bird(opus).
bird(robin).
penguin(opus).
penguin(pingu).

injured(robin).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- net_proof(83).
```

**Output**

```text
proved(same_ground_clauses(15))
```

## 73. Network 86 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(emu).
bird(kiwi).
bird(tweety).
bird(polly).
bird(robin).
bird(opus).
penguin(robin).

injured(opus).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- net_proof(86).
```

**Output**

```text
proved(same_ground_clauses(26))
```

## 74. Network 89 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(robin).
bird(kiwi).
bird(polly).
bird(opus).
bird(pingu).
bird(emu).
penguin(kiwi).

injured(robin).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- net_proof(89).
```

**Output**

```text
proved(same_ground_clauses(26))
```

## 75. Network 91 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(tweety).
bird(pingu).
bird(kiwi).
bird(opus).
bird(emu).
penguin(pingu).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).

?- net_proof(91).
```

**Output**

```text
proved(same_ground_clauses(12))
```

## 76. Network 94 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.

?- net_proof(94).
```

**Output**

```text
proved(same_ground_clauses(13))
```

## 77. Network 97 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.

?- net_proof(97).
```

**Output**

```text
proved(same_ground_clauses(25))
```

## 78. Network 99 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.

?- net_proof(99).
```

**Output**

```text
proved(same_ground_clauses(11))
```

## 79. Network 102 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.

?- net_proof(102).
```

**Output**

```text
proved(same_ground_clauses(20))
```

## 80. Network 105 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.

?- net_proof(105).
```

**Output**

```text
proved(same_ground_clauses(14))
```

## 81. Network 107 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.

?- net_proof(107).
```

**Output**

```text
proved(same_ground_clauses(24))
```

## 82. Network 110 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
num(X) :- X >= 1.
div4(X) :- num(X), 0 =:= X mod 4.

?- net_proof(110).
```

**Output**

```text
proved(same_ground_clauses(26))
```

## 83. Network 113 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 1.

?- net_proof(113).
```

**Output**

```text
proved(same_ground_clauses(21))
```

## 84. Network 115 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 3.

?- net_proof(115).
```

**Output**

```text
proved(same_ground_clauses(19))
```

## 85. Network 118 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
likes(bob, gold).
likes(hal, gold).
likes(fay, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_proof(118).
```

**Output**

```text
proved(same_ground_clauses(21))
```

## 86. Network 121 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
likes(eli, green).
likes(gus, green).
likes(cy, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_proof(121).
```

**Output**

```text
proved(same_ground_clauses(21))
```

## 87. Network 123 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
likes(ann, blue).
likes(hal, gold).
likes(eli, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_proof(123).
```

**Output**

```text
proved(same_ground_clauses(21))
```

## 88. Network 126 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
likes(ivy, gold).
likes(dee, gold).
likes(jo, red).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_proof(126).
```

**Output**

```text
proved(same_ground_clauses(21))
```

## 89. Network 129 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
nat(z).
nat(s(X)) :- nat(X).

?- net_proof(129).
```

**Output**

```text
proved(same_ground_clauses(3))
```

## 90. Network 131 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
p(a).
p(f(X)) :- p(X).

?- net_proof(131).
```

**Output**

```text
proved(same_ground_clauses(2))
```

## 91. Network 134 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
item(a).
item(b).
lst([]).
lst([H|T]) :- item(H), lst(T).

?- net_proof(134).
```

**Output**

```text
proved(same_ground_clauses(147))
```

## 92. Network 139 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_proof(139).
```

**Output**

```text
proved(same_ground_clauses(83))
```

## 93. Network 141 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
edge(a, b).
edge(b, c).
edge(c, a).
reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_proof(141).
```

**Output**

```text
proved(same_ground_clauses(39))
```

## 94. Network 144 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).
flies(X) :- bird(X), \+ penguin(X).

?- net_proof(144).
```

**Output**

```text
proved(same_ground_clauses(7))
```

## 95. Network 147 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).

?- net_proof(147).
```

**Output**

```text
proved(same_ground_clauses(9))
```

## 96. Network 149 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).

?- net_proof(149).
```

**Output**

```text
proved(same_ground_clauses(9))
```

## 97. Network 174 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
v.
u.
s :- u, v.
q :- u, v.
r :- s, \+ v.

?- net_proof(174).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 98. Network 177 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
w.
v.
p :- u, w.
s :- p.
u :- s.

?- net_proof(177).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 99. Network 179 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
q.
s.
t :- s, q.
t :- s.
v :- q, s.
p :- v.

?- net_proof(179).
```

**Output**

```text
proved(same_ground_clauses(6))
```

## 100. Network 182 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
t.
p.
r :- t, \+ p.
u :- t.
s :- t, \+ p.

?- net_proof(182).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 101. Network 185 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
v.
q.
s :- t.
t :- s.
u :- t.
u :- q.

?- net_proof(185).
```

**Output**

```text
proved(same_ground_clauses(6))
```

## 102. Network 187 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
v.
q.
u :- v.
p :- v.
p :- v.
r :- v, p.
r :- p.

?- net_proof(187).
```

**Output**

```text
proved(same_ground_clauses(6))
```

## 103. Network 190 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
t.
v.
r :- t.
p :- v, \+ r.
s :- \+ v.

?- net_proof(190).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 104. Network 193 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
r.
p.
q :- u, r.
v :- p.
u :- p.
u :- v.

?- net_proof(193).
```

**Output**

```text
proved(same_ground_clauses(6))
```

## 105. Network 195 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
u.
w.
t :- u, w.
p :- r, t.
r :- t, u.

?- net_proof(195).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 106. Network 198 equals its program, clause by clause, from the weights

*Category:* `prover/network`

**Input**

```prolog
s.
u.
q :- \+ u.
w :- u, \+ q.
p :- q, w.

?- net_proof(198).
```

**Output**

```text
proved(same_ground_clauses(5))
```

## 107. Network 2 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(2, reach/2).
```

**Output**

```text
input atoms clamped on: 3
reach/2 answers from the weights alone: [reach(a,b),reach(a,d),reach(c,b),reach(c,d),reach(d,b)]
```

## 108. Network 6 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, c).
edge(b, d).
edge(c, b).
edge(d, c).
edge(e, b).
edge(e, c).
edge(e, d).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(6, reach/2).
```

**Output**

```text
input atoms clamped on: 7
reach/2 answers from the weights alone: [reach(a,b),reach(a,c),reach(a,d),reach(b,b),reach(b,c),reach(b,d),reach(c,b),reach(c,c),reach(c,d),reach(d,b),reach(d,c),reach(d,d),reach(e,b),reach(e,c),reach(e,d)]
```

## 109. Network 10 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(b, a).
edge(b, c).
edge(c, d).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(10, reach/2).
```

**Output**

```text
input atoms clamped on: 4
reach/2 answers from the weights alone: [reach(b,a),reach(b,c),reach(b,d),reach(c,c),reach(c,d),reach(d,c),reach(d,d)]
```

## 110. Network 15 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(15, reach/2).
```

**Output**

```text
input atoms clamped on: 3
reach/2 answers from the weights alone: [reach(b,a),reach(b,b),reach(b,c),reach(c,a),reach(c,b),reach(c,c)]
```

## 111. Network 19 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(19, reach/2).
```

**Output**

```text
input atoms clamped on: 5
reach/2 answers from the weights alone: [reach(a,a),reach(a,b),reach(a,c),reach(b,a),reach(b,b),reach(b,c),reach(c,a),reach(c,b),reach(c,c)]
```

## 112. Network 23 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(23, reach/2).
```

**Output**

```text
input atoms clamped on: 1
reach/2 answers from the weights alone: [reach(a,c)]
```

## 113. Network 28 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(28, reach/2).
```

**Output**

```text
input atoms clamped on: 3
reach/2 answers from the weights alone: [reach(a,a),reach(a,d),reach(c,a),reach(c,d),reach(d,a),reach(d,d)]
```

## 114. Network 32 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(c, d).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(32, reach/2).
```

**Output**

```text
input atoms clamped on: 2
reach/2 answers from the weights alone: [reach(c,a),reach(c,d),reach(d,a)]
```

## 115. Network 37 run forward from its weights: reach/2

*Category:* `network/forward`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- net_answers(37, reach/2).
```

**Output**

```text
input atoms clamped on: 4
reach/2 answers from the weights alone: [reach(a,a),reach(a,c),reach(a,d),reach(c,a),reach(c,c),reach(c,d),reach(d,a),reach(d,c),reach(d,d)]
```

## 116. Network 41 run forward from its weights: ancestor/2

*Category:* `network/forward`

**Input**

```prolog
parent(fay, dee).
parent(dee, cy).
parent(fay, ann).
parent(cy, ivy).
parent(dee, jo).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_answers(41, ancestor/2).
```

**Output**

```text
input atoms clamped on: 5
ancestor/2 answers from the weights alone: [ancestor(cy,ivy),ancestor(dee,cy),ancestor(dee,ivy),ancestor(dee,jo),ancestor(fay,ann),ancestor(fay,cy),ancestor(fay,dee),ancestor(fay,ivy),ancestor(fay,jo)]
```

## 117. Network 45 run forward from its weights: grandparent/2

*Category:* `network/forward`

**Input**

```prolog
parent(dee, gus).
parent(dee, hal).
parent(hal, ann).
parent(ann, ivy).
parent(ann, cy).
parent(dee, eli).
parent(ann, fay).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_answers(45, grandparent/2).
```

**Output**

```text
input atoms clamped on: 7
grandparent/2 answers from the weights alone: [grandparent(dee,ann),grandparent(hal,cy),grandparent(hal,fay),grandparent(hal,ivy)]
```

## 118. Network 50 run forward from its weights: ancestor/2

*Category:* `network/forward`

**Input**

```prolog
parent(fay, dee).
parent(dee, ivy).
parent(ivy, jo).
parent(dee, hal).
parent(fay, cy).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_answers(50, ancestor/2).
```

**Output**

```text
input atoms clamped on: 5
ancestor/2 answers from the weights alone: [ancestor(dee,hal),ancestor(dee,ivy),ancestor(dee,jo),ancestor(fay,cy),ancestor(fay,dee),ancestor(fay,hal),ancestor(fay,ivy),ancestor(fay,jo),ancestor(ivy,jo)]
```

## 119. Network 54 run forward from its weights: grandparent/2

*Category:* `network/forward`

**Input**

```prolog
parent(cy, ann).
parent(ann, fay).
parent(cy, hal).
parent(fay, ivy).
parent(ann, bob).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_answers(54, grandparent/2).
```

**Output**

```text
input atoms clamped on: 5
grandparent/2 answers from the weights alone: [grandparent(ann,ivy),grandparent(cy,bob),grandparent(cy,fay)]
```

## 120. Network 58 run forward from its weights: sibling/2

*Category:* `network/forward`

**Input**

```prolog
parent(fay, cy).
parent(cy, dee).
parent(fay, eli).
parent(eli, hal).
parent(cy, ann).
parent(hal, bob).
parent(cy, jo).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- net_answers(58, sibling/2).
```

**Output**

```text
input atoms clamped on: 7
sibling/2 answers from the weights alone: [sibling(ann,dee),sibling(ann,jo),sibling(cy,eli),sibling(dee,ann),sibling(dee,jo),sibling(eli,cy),sibling(jo,ann),sibling(jo,dee)]
```

## 121. Network 63 run forward from its weights: grandparent/2

*Category:* `network/forward`

**Input**

```prolog
parent(gus, ann).
parent(ann, ivy).
parent(gus, hal).
parent(ann, eli).
parent(ivy, cy).
parent(eli, jo).
parent(eli, dee).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- net_answers(63, grandparent/2).
```

**Output**

```text
input atoms clamped on: 7
grandparent/2 answers from the weights alone: [grandparent(ann,cy),grandparent(ann,dee),grandparent(ann,jo),grandparent(gus,eli),grandparent(gus,ivy)]
```

## 122. Network 67 run forward from its weights: or/2

*Category:* `network/forward`

**Input**

```prolog
bit(0).
bit(1).

or(X, Y) :- bit(X), bit(Y), X = 1.
or(X, Y) :- bit(X), bit(Y), Y = 1.

?- net_answers(67, or/2).
```

**Output**

```text
input atoms clamped on: 2
or/2 answers from the weights alone: [or(0,1),or(1,0),or(1,1)]
```

## 123. Network 72 run forward from its weights: and/2

*Category:* `network/forward`

**Input**

```prolog
bit(0).
bit(1).

and(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.

?- net_answers(72, and/2).
```

**Output**

```text
input atoms clamped on: 2
and/2 answers from the weights alone: [and(1,1)]
```

## 124. Network 76 run forward from its weights: (xor)/2

*Category:* `network/forward`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).

?- net_answers(76, (xor)/2).
```

**Output**

```text
input atoms clamped on: 2
(xor)/2 answers from the weights alone: [0 xor 1,1 xor 0]
```

## 125. Network 80 run forward from its weights: flies/1

*Category:* `network/forward`

**Input**

```prolog
bird(opus).
bird(emu).
bird(tweety).
bird(polly).
penguin(polly).

injured(tweety).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- net_answers(80, flies/1).
```

**Output**

```text
input atoms clamped on: 6
flies/1 answers from the weights alone: [flies(emu),flies(opus)]
```

## 126. Network 85 run forward from its weights: flies/1

*Category:* `network/forward`

**Input**

```prolog
bird(robin).
bird(kiwi).
bird(polly).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).

?- net_answers(85, flies/1).
```

**Output**

```text
input atoms clamped on: 4
flies/1 answers from the weights alone: [flies(polly),flies(robin)]
```

## 127. Network 89 run forward from its weights: flies/1

*Category:* `network/forward`

**Input**

```prolog
bird(robin).
bird(kiwi).
bird(polly).
bird(opus).
bird(pingu).
bird(emu).
penguin(kiwi).

injured(robin).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- net_answers(89, flies/1).
```

**Output**

```text
input atoms clamped on: 8
flies/1 answers from the weights alone: [flies(emu),flies(opus),flies(pingu),flies(polly)]
```

## 128. Network 93 run forward from its weights: even/1

*Category:* `network/forward`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.

?- net_answers(93, even/1).
```

**Output**

```text
input atoms clamped on: 0
even/1 answers from the weights alone: [even(0),even(2),even(4)]
```

## 129. Network 98 run forward from its weights: square/2

*Category:* `network/forward`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.

?- net_answers(98, square/2).
```

**Output**

```text
input atoms clamped on: 6
square/2 answers from the weights alone: [square(0,0),square(1,1),square(2,4)]
```

## 130. Network 102 run forward from its weights: square/2

*Category:* `network/forward`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.

?- net_answers(102, square/2).
```

**Output**

```text
input atoms clamped on: 16
square/2 answers from the weights alone: [square(0,0),square(1,1),square(2,4),square(3,9)]
```

## 131. Network 107 run forward from its weights: pair/2

*Category:* `network/forward`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.

?- net_answers(107, pair/2).
```

**Output**

```text
input atoms clamped on: 21
pair/2 answers from the weights alone: [pair(0,6),pair(1,5),pair(2,4)]
```

## 132. Network 111 run forward from its weights: div5/1

*Category:* `network/forward`

**Input**

```prolog
num(X) :- X >= 1.
div5(X) :- num(X), 0 =:= X mod 5.

?- net_answers(111, div5/1).
```

**Output**

```text
input atoms clamped on: 20
div5/1 answers from the weights alone: [div5(5),div5(10),div5(15),div5(20)]
```

## 133. Network 115 run forward from its weights: count/1

*Category:* `network/forward`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 3.

?- net_answers(115, count/1).
```

**Output**

```text
input atoms clamped on: 0
count/1 answers from the weights alone: [count(0),count(3),count(6),count(9),count(12),count(15),count(18)]
```

## 134. Network 120 run forward from its weights: liked/1

*Category:* `network/forward`

**Input**

```prolog
likes(jo, gold).
likes(fay, green).
likes(gus, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_answers(120, liked/1).
```

**Output**

```text
input atoms clamped on: 6
liked/1 answers from the weights alone: [liked(gold),liked(green)]
```

## 135. Network 124 run forward from its weights: liked/1

*Category:* `network/forward`

**Input**

```prolog
likes(gus, gold).
likes(eli, gold).
likes(cy, gold).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- net_answers(124, liked/1).
```

**Output**

```text
input atoms clamped on: 6
liked/1 answers from the weights alone: [liked(gold)]
```

## 136. Network 128 run forward from its weights: nat/1

*Category:* `network/forward`

**Input**

```prolog
nat(z).
nat(s(X)) :- nat(X).

?- net_answers(128, nat/1).
```

**Output**

```text
input atoms clamped on: 0
nat/1 answers from the weights alone: [nat(z),nat(s(z))]
```

## 137. Network 133 run forward from its weights: p/1

*Category:* `network/forward`

**Input**

```prolog
p(a).
p(f(X)) :- p(X).

?- net_answers(133, p/1).
```

**Output**

```text
input atoms clamped on: 0
p/1 answers from the weights alone: [p(a),p(f(a)),p(f(f(a))),p(f(f(f(a))))]
```

## 138. Network 139 run forward from its weights: ancestor/2

*Category:* `network/forward`

**Input**

```prolog
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- net_answers(139, ancestor/2).
```

**Output**

```text
input atoms clamped on: 3
ancestor/2 answers from the weights alone: [ancestor(ann,bob),ancestor(ann,cy),ancestor(ann,dee),ancestor(bob,cy),ancestor(bob,dee),ancestor(cy,dee)]
```

## 139. Network 144 run forward from its weights: flies/1

*Category:* `network/forward`

**Input**

```prolog
bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).
flies(X) :- bird(X), \+ penguin(X).

?- net_answers(144, flies/1).
```

**Output**

```text
input atoms clamped on: 4
flies/1 answers from the weights alone: [flies(polly),flies(tweety)]
```

## 140. Network 148 run forward from its weights: ab/1

*Category:* `network/forward`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).

?- net_answers(148, ab/1).
```

**Output**

```text
input atoms clamped on: 3
ab/1 answers from the weights alone: [ab(1),ab(2)]
```

## 141. Network 1: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(1, smallest).
```

**Output**

```text
status: sat; original input (3 facts): [edge(a,b),edge(b,a),edge(c,a)]
2 smallest input(s) found:
  3 facts [edge(a,b),edge(b,a),edge(c,b)]  -> forward: same_output
  3 facts [edge(a,b),edge(b,a),edge(c,a)]  -> forward: same_output
```

## 142. Network 1: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(1, largest).
```

**Output**

```text
status: sat; original input (3 facts): [edge(a,b),edge(b,a),edge(c,a)]
1 largest input(s) found:
  6 facts [edge(a,a),edge(a,b),edge(b,a),edge(b,b),edge(c,a),edge(c,b)]  -> forward: same_output
```

## 143. Network 5: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, c).
edge(a, d).
edge(b, a).
edge(b, c).
edge(d, a).
edge(e, a).
edge(e, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(5, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [edge(a,c),edge(a,d),edge(b,a),edge(b,c),edge(d,a),edge(e,a),edge(e,c)]
5 smallest input(s) found:
  5 facts [edge(a,c),edge(a,d),edge(b,d),edge(d,a),edge(e,a)]  -> forward: same_output
  5 facts [edge(a,c),edge(a,d),edge(b,a),edge(d,a),edge(e,a)]  -> forward: same_output
  5 facts [edge(a,c),edge(a,d),edge(b,d),edge(d,a),edge(e,d)]  -> forward: same_output
  5 facts [edge(a,c),edge(a,d),edge(b,a),edge(d,a),edge(e,d)]  -> forward: same_output
  5 facts [edge(a,d),edge(b,d),edge(d,a),edge(d,c),edge(e,a)]  -> forward: same_output
```

## 144. Network 5: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, c).
edge(a, d).
edge(b, a).
edge(b, c).
edge(d, a).
edge(e, a).
edge(e, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(5, largest).
```

**Output**

```text
status: sat; original input (7 facts): [edge(a,c),edge(a,d),edge(b,a),edge(b,c),edge(d,a),edge(e,a),edge(e,c)]
1 largest input(s) found:
  12 facts [edge(a,a),edge(a,c),edge(a,d),edge(b,a),edge(b,c),edge(b,d),edge(d,a),edge(d,c),edge(d,d),edge(e,a),edge(e,c),edge(e,d)]  -> forward: same_output
```

## 145. Network 9: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(9, smallest).
```

**Output**

```text
status: sat; original input (4 facts): [edge(a,d),edge(b,a),edge(c,b),edge(d,a)]
2 smallest input(s) found:
  4 facts [edge(a,d),edge(b,a),edge(c,b),edge(d,a)]  -> forward: same_output
  4 facts [edge(a,d),edge(b,d),edge(c,b),edge(d,a)]  -> forward: same_output
```

## 146. Network 9: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(9, largest).
```

**Output**

```text
status: sat; original input (4 facts): [edge(a,d),edge(b,a),edge(c,b),edge(d,a)]
1 largest input(s) found:
  9 facts [edge(a,a),edge(a,d),edge(b,a),edge(b,d),edge(c,a),edge(c,b),edge(c,d),edge(d,a),edge(d,d)]  -> forward: same_output
```

## 147. Network 13: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, a).
edge(c, a).
edge(d, a).
edge(d, e).
edge(e, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(13, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(b,a),edge(c,a),edge(d,a),edge(d,e),edge(e,a)]
1 smallest input(s) found:
  4 facts [edge(b,a),edge(c,a),edge(d,e),edge(e,a)]  -> forward: same_output
```

## 148. Network 13: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, a).
edge(c, a).
edge(d, a).
edge(d, e).
edge(e, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(13, largest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(b,a),edge(c,a),edge(d,a),edge(d,e),edge(e,a)]
1 largest input(s) found:
  5 facts [edge(b,a),edge(c,a),edge(d,a),edge(d,e),edge(e,a)]  -> forward: same_output
```

## 149. Network 17: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, b).
edge(a, c).
edge(b, c).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(17, smallest).
```

**Output**

```text
status: sat; original input (6 facts): [edge(a,b),edge(a,c),edge(b,c),edge(d,a),edge(d,b),edge(d,c)]
1 smallest input(s) found:
  3 facts [edge(a,b),edge(b,c),edge(d,a)]  -> forward: same_output
```

## 150. Network 17: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, b).
edge(a, c).
edge(b, c).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(17, largest).
```

**Output**

```text
status: sat; original input (6 facts): [edge(a,b),edge(a,c),edge(b,c),edge(d,a),edge(d,b),edge(d,c)]
1 largest input(s) found:
  6 facts [edge(a,b),edge(a,c),edge(b,c),edge(d,a),edge(d,b),edge(d,c)]  -> forward: same_output
```

## 151. Network 21: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, c).
edge(b, d).
edge(b, e).
edge(c, b).
edge(c, f).
edge(d, e).
edge(f, a).
edge(f, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(21, smallest).
```

**Output**

```text
status: sat; original input (8 facts): [edge(b,c),edge(b,d),edge(b,e),edge(c,b),edge(c,f),edge(d,e),edge(f,a),edge(f,b)]
5 smallest input(s) found:
  6 facts [edge(b,f),edge(c,b),edge(d,e),edge(f,a),edge(f,c),edge(f,d)]  -> forward: same_output
  6 facts [edge(b,a),edge(b,f),edge(c,b),edge(d,e),edge(f,c),edge(f,d)]  -> forward: same_output
  6 facts [edge(b,f),edge(c,a),edge(c,b),edge(d,e),edge(f,c),edge(f,d)]  -> forward: same_output
  6 facts [edge(b,d),edge(b,f),edge(c,a),edge(c,b),edge(d,e),edge(f,c)]  -> forward: same_output
  6 facts [edge(b,d),edge(b,f),edge(c,b),edge(d,e),edge(f,a),edge(f,c)]  -> forward: same_output
```

## 152. Network 21: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, c).
edge(b, d).
edge(b, e).
edge(c, b).
edge(c, f).
edge(d, e).
edge(f, a).
edge(f, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(21, largest).
```

**Output**

```text
status: sat; original input (8 facts): [edge(b,c),edge(b,d),edge(b,e),edge(c,b),edge(c,f),edge(d,e),edge(f,a),edge(f,b)]
1 largest input(s) found:
  19 facts [edge(b,a),edge(b,b),edge(b,c),edge(b,d),edge(b,e),edge(b,f),edge(c,a),edge(c,b),edge(c,c),edge(c,d),edge(c,e),edge(c,f),edge(d,e),edge(f,a),edge(f,b),edge(f,c),edge(f,d),edge(f,e),edge(f,f)]  -> forward: same_output
```

## 153. Network 25: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(b, c).
edge(c, b).
edge(c, d).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(25, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [edge(a,d),edge(b,c),edge(c,b),edge(c,d),edge(d,a),edge(d,b),edge(d,c)]
5 smallest input(s) found:
  4 facts [edge(a,d),edge(b,a),edge(c,b),edge(d,c)]  -> forward: same_output
  4 facts [edge(a,c),edge(b,d),edge(c,b),edge(d,a)]  -> forward: same_output
  4 facts [edge(a,c),edge(b,a),edge(c,d),edge(d,b)]  -> forward: same_output
  4 facts [edge(a,d),edge(b,c),edge(c,a),edge(d,b)]  -> forward: same_output
  4 facts [edge(a,b),edge(b,d),edge(c,a),edge(d,c)]  -> forward: same_output
```

## 154. Network 25: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(b, c).
edge(c, b).
edge(c, d).
edge(d, a).
edge(d, b).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(25, largest).
```

**Output**

```text
status: sat; original input (7 facts): [edge(a,d),edge(b,c),edge(c,b),edge(c,d),edge(d,a),edge(d,b),edge(d,c)]
1 largest input(s) found:
  16 facts [edge(a,a),edge(a,b),edge(a,c),edge(a,d),edge(b,a),edge(b,b),edge(b,c),edge(b,d),edge(c,a),edge(c,b),edge(c,c),edge(c,d),edge(d,a),edge(d,b),edge(d,c),edge(d,d)]  -> forward: same_output
```

## 155. Network 29: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, c).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(29, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(a,c),edge(b,a),edge(b,c),edge(c,a),edge(c,b)]
2 smallest input(s) found:
  3 facts [edge(a,c),edge(b,a),edge(c,b)]  -> forward: same_output
  3 facts [edge(a,b),edge(b,c),edge(c,a)]  -> forward: same_output
```

## 156. Network 29: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, c).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(29, largest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(a,c),edge(b,a),edge(b,c),edge(c,a),edge(c,b)]
1 largest input(s) found:
  9 facts [edge(a,a),edge(a,b),edge(a,c),edge(b,a),edge(b,b),edge(b,c),edge(c,a),edge(c,b),edge(c,c)]  -> forward: same_output
```

## 157. Network 33: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, d).
edge(c, a).
edge(c, f).
edge(e, f).
edge(f, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(33, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(b,d),edge(c,a),edge(c,f),edge(e,f),edge(f,a)]
1 smallest input(s) found:
  4 facts [edge(b,d),edge(c,f),edge(e,f),edge(f,a)]  -> forward: same_output
```

## 158. Network 33: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(b, d).
edge(c, a).
edge(c, f).
edge(e, f).
edge(f, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(33, largest).
```

**Output**

```text
status: sat; original input (5 facts): [edge(b,d),edge(c,a),edge(c,f),edge(e,f),edge(f,a)]
1 largest input(s) found:
  6 facts [edge(b,d),edge(c,a),edge(c,f),edge(e,a),edge(e,f),edge(f,a)]  -> forward: same_output
```

## 159. Network 37: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(37, smallest).
```

**Output**

```text
status: sat; original input (4 facts): [edge(a,d),edge(c,d),edge(d,a),edge(d,c)]
2 smallest input(s) found:
  3 facts [edge(a,d),edge(c,a),edge(d,c)]  -> forward: same_output
  3 facts [edge(a,c),edge(c,d),edge(d,a)]  -> forward: same_output
```

## 160. Network 37: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).

?- invert_net(37, largest).
```

**Output**

```text
status: sat; original input (4 facts): [edge(a,d),edge(c,d),edge(d,a),edge(d,c)]
1 largest input(s) found:
  9 facts [edge(a,a),edge(a,c),edge(a,d),edge(c,a),edge(c,c),edge(c,d),edge(d,a),edge(d,c),edge(d,d)]  -> forward: same_output
```

## 161. Network 41: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(fay, dee).
parent(dee, cy).
parent(fay, ann).
parent(cy, ivy).
parent(dee, jo).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- invert_net(41, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [parent(cy,ivy),parent(dee,cy),parent(dee,jo),parent(fay,ann),parent(fay,dee)]
1 smallest input(s) found:
  5 facts [parent(cy,ivy),parent(dee,cy),parent(dee,jo),parent(fay,ann),parent(fay,dee)]  -> forward: same_output
```

## 162. Network 41: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(fay, dee).
parent(dee, cy).
parent(fay, ann).
parent(cy, ivy).
parent(dee, jo).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- invert_net(41, largest).
```

**Output**

```text
status: sat; original input (5 facts): [parent(cy,ivy),parent(dee,cy),parent(dee,jo),parent(fay,ann),parent(fay,dee)]
1 largest input(s) found:
  9 facts [parent(cy,ivy),parent(dee,cy),parent(dee,ivy),parent(dee,jo),parent(fay,ann),parent(fay,cy),parent(fay,dee),parent(fay,ivy),parent(fay,jo)]  -> forward: same_output
```

## 163. Network 45: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(dee, gus).
parent(dee, hal).
parent(hal, ann).
parent(ann, ivy).
parent(ann, cy).
parent(dee, eli).
parent(ann, fay).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- invert_net(45, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(ann,cy),parent(ann,fay),parent(ann,ivy),parent(dee,eli),parent(dee,gus),parent(dee,hal),parent(hal,ann)]
4 smallest input(s) found:
  5 facts [parent(ann,cy),parent(ann,fay),parent(ann,ivy),parent(dee,hal),parent(hal,ann)]  -> forward: same_output
  5 facts [parent(dee,cy),parent(dee,fay),parent(dee,ivy),parent(hal,dee),parent(ivy,ann)]  -> forward: same_output
  5 facts [parent(dee,cy),parent(dee,fay),parent(dee,ivy),parent(fay,ann),parent(hal,dee)]  -> forward: same_output
  5 facts [parent(cy,ann),parent(dee,cy),parent(dee,fay),parent(dee,ivy),parent(hal,dee)]  -> forward: same_output
```

## 164. Network 45: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(dee, gus).
parent(dee, hal).
parent(hal, ann).
parent(ann, ivy).
parent(ann, cy).
parent(dee, eli).
parent(ann, fay).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- invert_net(45, largest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(ann,cy),parent(ann,fay),parent(ann,ivy),parent(dee,eli),parent(dee,gus),parent(dee,hal),parent(hal,ann)]
5 largest input(s) found:
  14 facts [parent(dee,ann),parent(dee,cy),parent(dee,eli),parent(dee,fay),parent(dee,ivy),parent(eli,ann),parent(gus,cy),parent(gus,fay),parent(gus,ivy),parent(hal,ann),parent(hal,cy),parent(hal,fay),parent(hal,gus),parent(hal,ivy)]  -> forward: same_output
  14 facts [parent(dee,ann),parent(dee,cy),parent(dee,fay),parent(dee,gus),parent(dee,ivy),parent(eli,cy),parent(eli,fay),parent(eli,ivy),parent(gus,ann),parent(hal,ann),parent(hal,cy),parent(hal,eli),parent(hal,fay),parent(hal,ivy)]  -> forward: same_output
  14 facts [parent(ann,cy),parent(ann,fay),parent(ann,ivy),parent(dee,cy),parent(dee,fay),parent(dee,hal),parent(dee,ivy),parent(eli,cy),parent(eli,fay),parent(eli,ivy),parent(gus,cy),parent(gus,fay),parent(gus,ivy),parent(hal,ann)]  -> forward: same_output
  14 facts [parent(cy,ann),parent(dee,cy),parent(dee,fay),parent(dee,ivy),parent(eli,ann),parent(eli,fay),parent(eli,ivy),parent(gus,fay),parent(gus,ivy),parent(hal,ann),parent(hal,dee),parent(hal,fay),parent(hal,gus),parent(hal,ivy)]  -> forward: same_output
  14 facts [parent(cy,ann),parent(dee,cy),parent(dee,fay),parent(dee,ivy),parent(eli,ann),parent(eli,fay),parent(eli,ivy),parent(gus,ann),parent(gus,fay),parent(gus,ivy),parent(hal,ann),parent(hal,dee),parent(hal,fay),parent(hal,ivy)]  -> forward: same_output
```

## 165. Network 49: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(cy, ivy).
parent(ivy, gus).
parent(ivy, jo).
parent(jo, ann).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- invert_net(49, smallest).
```

**Output**

```text
status: sat; original input (4 facts): [parent(cy,ivy),parent(ivy,gus),parent(ivy,jo),parent(jo,ann)]
5 smallest input(s) found:
  2 facts [parent(ann,gus),parent(ann,jo)]  -> forward: same_output
  2 facts [parent(gus,gus),parent(gus,jo)]  -> forward: same_output
  2 facts [parent(ivy,gus),parent(ivy,jo)]  -> forward: same_output
  2 facts [parent(cy,gus),parent(cy,jo)]  -> forward: same_output
  2 facts [parent(jo,gus),parent(jo,jo)]  -> forward: same_output
```

## 166. Network 49: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(cy, ivy).
parent(ivy, gus).
parent(ivy, jo).
parent(jo, ann).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- invert_net(49, largest).
```

**Output**

```text
status: sat; original input (4 facts): [parent(cy,ivy),parent(ivy,gus),parent(ivy,jo),parent(jo,ann)]
1 largest input(s) found:
  10 facts [parent(ann,gus),parent(ann,jo),parent(cy,gus),parent(cy,jo),parent(gus,gus),parent(gus,jo),parent(ivy,gus),parent(ivy,jo),parent(jo,gus),parent(jo,jo)]  -> forward: same_output
```

## 167. Network 54: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(cy, ann).
parent(ann, fay).
parent(cy, hal).
parent(fay, ivy).
parent(ann, bob).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- invert_net(54, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [parent(ann,bob),parent(ann,fay),parent(cy,ann),parent(cy,hal),parent(fay,ivy)]
3 smallest input(s) found:
  4 facts [parent(ann,cy),parent(cy,ivy),parent(ivy,bob),parent(ivy,fay)]  -> forward: same_output
  4 facts [parent(ann,bob),parent(ann,fay),parent(cy,ann),parent(fay,ivy)]  -> forward: same_output
  4 facts [parent(ann,bob),parent(ann,fay),parent(bob,ivy),parent(cy,ann)]  -> forward: same_output
```

## 168. Network 54: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(cy, ann).
parent(ann, fay).
parent(cy, hal).
parent(fay, ivy).
parent(ann, bob).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).

?- invert_net(54, largest).
```

**Output**

```text
status: sat; original input (5 facts): [parent(ann,bob),parent(ann,fay),parent(cy,ann),parent(cy,hal),parent(fay,ivy)]
5 largest input(s) found:
  8 facts [parent(ann,bob),parent(ann,cy),parent(ann,fay),parent(cy,ivy),parent(hal,bob),parent(hal,fay),parent(ivy,bob),parent(ivy,fay)]  -> forward: same_output
  8 facts [parent(ann,bob),parent(ann,fay),parent(bob,ivy),parent(cy,ann),parent(cy,fay),parent(cy,hal),parent(cy,ivy),parent(hal,fay)]  -> forward: same_output
  8 facts [parent(ann,bob),parent(ann,fay),parent(cy,ann),parent(cy,bob),parent(cy,hal),parent(cy,ivy),parent(fay,ivy),parent(hal,bob)]  -> forward: same_output
  8 facts [parent(ann,bob),parent(ann,fay),parent(bob,ivy),parent(cy,ann),parent(cy,fay),parent(cy,ivy),parent(hal,fay),parent(hal,ivy)]  -> forward: same_output
  8 facts [parent(ann,bob),parent(ann,fay),parent(cy,ann),parent(cy,bob),parent(cy,ivy),parent(fay,ivy),parent(hal,bob),parent(hal,ivy)]  -> forward: same_output
```

## 169. Network 58: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(fay, cy).
parent(cy, dee).
parent(fay, eli).
parent(eli, hal).
parent(cy, ann).
parent(hal, bob).
parent(cy, jo).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- invert_net(58, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(eli,hal),parent(fay,cy),parent(fay,eli),parent(hal,bob)]
5 smallest input(s) found:
  5 facts [parent(cy,cy),parent(cy,eli),parent(eli,ann),parent(eli,dee),parent(eli,jo)]  -> forward: same_output
  5 facts [parent(cy,cy),parent(cy,eli),parent(fay,ann),parent(fay,dee),parent(fay,jo)]  -> forward: same_output
  5 facts [parent(ann,ann),parent(ann,dee),parent(ann,jo),parent(cy,cy),parent(cy,eli)]  -> forward: same_output
  5 facts [parent(cy,cy),parent(cy,eli),parent(dee,ann),parent(dee,dee),parent(dee,jo)]  -> forward: same_output
  5 facts [parent(cy,cy),parent(cy,eli),parent(hal,ann),parent(hal,dee),parent(hal,jo)]  -> forward: same_output
```

## 170. Network 58: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(fay, cy).
parent(cy, dee).
parent(fay, eli).
parent(eli, hal).
parent(cy, ann).
parent(hal, bob).
parent(cy, jo).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.

?- invert_net(58, largest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(eli,hal),parent(fay,cy),parent(fay,eli),parent(hal,bob)]
5 largest input(s) found:
  23 facts [parent(ann,ann),parent(ann,dee),parent(ann,jo),parent(bob,ann),parent(bob,dee),parent(bob,jo),parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(dee,ann),parent(dee,dee),parent(dee,jo),parent(eli,ann),parent(eli,dee),parent(eli,jo),parent(fay,cy),parent(fay,eli),parent(hal,ann),parent(hal,dee),parent(hal,jo),parent(jo,ann),parent(jo,dee),parent(jo,jo)]  -> forward: same_output
  23 facts [parent(ann,ann),parent(ann,dee),parent(ann,jo),parent(bob,ann),parent(bob,dee),parent(bob,jo),parent(cy,cy),parent(cy,eli),parent(dee,ann),parent(dee,dee),parent(dee,jo),parent(eli,ann),parent(eli,dee),parent(eli,jo),parent(fay,ann),parent(fay,dee),parent(fay,jo),parent(hal,ann),parent(hal,dee),parent(hal,jo),parent(jo,ann),parent(jo,dee),parent(jo,jo)]  -> forward: same_output
  23 facts [parent(ann,ann),parent(ann,dee),parent(ann,jo),parent(bob,ann),parent(bob,dee),parent(bob,jo),parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(dee,ann),parent(dee,dee),parent(dee,jo),parent(eli,ann),parent(eli,dee),parent(eli,jo),parent(fay,ann),parent(fay,dee),parent(fay,jo),parent(hal,ann),parent(hal,dee),parent(hal,jo),parent(jo,cy),parent(jo,eli)]  -> forward: same_output
  23 facts [parent(ann,ann),parent(ann,dee),parent(ann,jo),parent(bob,ann),parent(bob,dee),parent(bob,jo),parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(dee,ann),parent(dee,dee),parent(dee,jo),parent(eli,cy),parent(eli,eli),parent(fay,ann),parent(fay,dee),parent(fay,jo),parent(hal,ann),parent(hal,dee),parent(hal,jo),parent(jo,ann),parent(jo,dee),parent(jo,jo)]  -> forward: same_output
  23 facts [parent(ann,cy),parent(ann,eli),parent(bob,ann),parent(bob,dee),parent(bob,jo),parent(cy,ann),parent(cy,dee),parent(cy,jo),parent(dee,ann),parent(dee,dee),parent(dee,jo),parent(eli,ann),parent(eli,dee),parent(eli,jo),parent(fay,ann),parent(fay,dee),parent(fay,jo),parent(hal,ann),parent(hal,dee),parent(hal,jo),parent(jo,ann),parent(jo,dee),parent(jo,jo)]  -> forward: same_output
```

## 171. Network 62: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(gus, fay).
parent(fay, eli).
parent(gus, ivy).
parent(ivy, ann).
parent(gus, jo).
parent(jo, bob).
parent(jo, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- invert_net(62, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(fay,eli),parent(gus,fay),parent(gus,ivy),parent(gus,jo),parent(ivy,ann),parent(jo,bob),parent(jo,dee)]
1 smallest input(s) found:
  7 facts [parent(fay,eli),parent(gus,fay),parent(gus,ivy),parent(gus,jo),parent(ivy,ann),parent(jo,bob),parent(jo,dee)]  -> forward: same_output
```

## 172. Network 62: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
parent(gus, fay).
parent(fay, eli).
parent(gus, ivy).
parent(ivy, ann).
parent(gus, jo).
parent(jo, bob).
parent(jo, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

?- invert_net(62, largest).
```

**Output**

```text
status: sat; original input (7 facts): [parent(fay,eli),parent(gus,fay),parent(gus,ivy),parent(gus,jo),parent(ivy,ann),parent(jo,bob),parent(jo,dee)]
1 largest input(s) found:
  11 facts [parent(fay,eli),parent(gus,ann),parent(gus,bob),parent(gus,dee),parent(gus,eli),parent(gus,fay),parent(gus,ivy),parent(gus,jo),parent(ivy,ann),parent(jo,bob),parent(jo,dee)]  -> forward: same_output
```

## 173. Network 66: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

and(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.

?- invert_net(66, smallest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 smallest input(s) found:
  1 facts [bit(1)]  -> forward: same_output
```

## 174. Network 66: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

and(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.

?- invert_net(66, largest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 largest input(s) found:
  2 facts [bit(0),bit(1)]  -> forward: same_output
```

## 175. Network 70: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).

?- invert_net(70, smallest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 smallest input(s) found:
  2 facts [bit(0),bit(1)]  -> forward: same_output
```

## 176. Network 70: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).

?- invert_net(70, largest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 largest input(s) found:
  2 facts [bit(0),bit(1)]  -> forward: same_output
```

## 177. Network 74: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

both(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
nand(X, Y) :- bit(X), bit(Y), \+ both(X, Y).

?- invert_net(74, smallest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 smallest input(s) found:
  2 facts [bit(0),bit(1)]  -> forward: same_output
```

## 178. Network 74: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bit(0).
bit(1).

both(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
nand(X, Y) :- bit(X), bit(Y), \+ both(X, Y).

?- invert_net(74, largest).
```

**Output**

```text
status: sat; original input (2 facts): [bit(0),bit(1)]
1 largest input(s) found:
  2 facts [bit(0),bit(1)]  -> forward: same_output
```

## 179. Network 78: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(pingu).
bird(tweety).
bird(opus).
bird(polly).
bird(emu).
bird(robin).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(78, smallest).
```

**Output**

```text
status: sat; original input (7 facts): [bird(emu),bird(opus),bird(pingu),bird(polly),bird(robin),bird(tweety),penguin(emu)]
1 smallest input(s) found:
  5 facts [bird(opus),bird(pingu),bird(polly),bird(robin),bird(tweety)]  -> forward: same_output
```

## 180. Network 78: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(pingu).
bird(tweety).
bird(opus).
bird(polly).
bird(emu).
bird(robin).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(78, largest).
```

**Output**

```text
status: sat; original input (7 facts): [bird(emu),bird(opus),bird(pingu),bird(polly),bird(robin),bird(tweety),penguin(emu)]
1 largest input(s) found:
  7 facts [bird(emu),bird(opus),bird(pingu),bird(polly),bird(robin),bird(tweety),penguin(emu)]  -> forward: same_output
```

## 181. Network 82: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(tweety).
bird(pingu).
bird(robin).
bird(kiwi).
bird(emu).
penguin(tweety).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(82, smallest).
```

**Output**

```text
status: sat; original input (6 facts): [bird(emu),bird(kiwi),bird(pingu),bird(robin),bird(tweety),penguin(tweety)]
1 smallest input(s) found:
  4 facts [bird(emu),bird(kiwi),bird(pingu),bird(robin)]  -> forward: same_output
```

## 182. Network 82: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(tweety).
bird(pingu).
bird(robin).
bird(kiwi).
bird(emu).
penguin(tweety).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(82, largest).
```

**Output**

```text
status: sat; original input (6 facts): [bird(emu),bird(kiwi),bird(pingu),bird(robin),bird(tweety),penguin(tweety)]
1 largest input(s) found:
  6 facts [bird(emu),bird(kiwi),bird(pingu),bird(robin),bird(tweety),penguin(tweety)]  -> forward: same_output
```

## 183. Network 86: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(emu).
bird(kiwi).
bird(tweety).
bird(polly).
bird(robin).
bird(opus).
penguin(robin).

injured(opus).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- invert_net(86, smallest).
```

**Output**

```text
status: sat; original input (8 facts): [bird(emu),bird(kiwi),bird(opus),bird(polly),bird(robin),bird(tweety),injured(opus),penguin(robin)]
4 smallest input(s) found:
  6 facts [bird(emu),bird(kiwi),bird(polly),bird(tweety),injured(opus),penguin(robin)]  -> forward: same_output
  6 facts [bird(emu),bird(kiwi),bird(polly),bird(tweety),penguin(opus),penguin(robin)]  -> forward: same_output
  6 facts [bird(emu),bird(kiwi),bird(polly),bird(tweety),injured(opus),injured(robin)]  -> forward: same_output
  6 facts [bird(emu),bird(kiwi),bird(polly),bird(tweety),injured(robin),penguin(opus)]  -> forward: same_output
```

## 184. Network 86: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(emu).
bird(kiwi).
bird(tweety).
bird(polly).
bird(robin).
bird(opus).
penguin(robin).

injured(opus).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).

?- invert_net(86, largest).
```

**Output**

```text
status: sat; original input (8 facts): [bird(emu),bird(kiwi),bird(opus),bird(polly),bird(robin),bird(tweety),injured(opus),penguin(robin)]
1 largest input(s) found:
  10 facts [bird(emu),bird(kiwi),bird(opus),bird(polly),bird(robin),bird(tweety),injured(opus),injured(robin),penguin(opus),penguin(robin)]  -> forward: same_output
```

## 185. Network 90: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(kiwi).
bird(emu).
bird(pingu).
penguin(emu).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(90, smallest).
```

**Output**

```text
status: sat; original input (5 facts): [bird(emu),bird(kiwi),bird(pingu),penguin(emu),penguin(kiwi)]
1 smallest input(s) found:
  1 facts [bird(pingu)]  -> forward: same_output
```

## 186. Network 90: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
bird(kiwi).
bird(emu).
bird(pingu).
penguin(emu).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).

?- invert_net(90, largest).
```

**Output**

```text
status: sat; original input (5 facts): [bird(emu),bird(kiwi),bird(pingu),penguin(emu),penguin(kiwi)]
1 largest input(s) found:
  5 facts [bird(emu),bird(kiwi),bird(pingu),penguin(emu),penguin(kiwi)]  -> forward: same_output
```

## 187. Network 119: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
likes(fay, red).
likes(cy, blue).
likes(bob, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- invert_net(119, smallest).
```

**Output**

```text
status: sat; original input (6 facts): [colour(blue),colour(purple),colour(red),likes(bob,blue),likes(cy,blue),likes(fay,red)]
5 smallest input(s) found:
  3 facts [colour(purple),likes(jo,blue),likes(jo,red)]  -> forward: same_output
  3 facts [colour(purple),likes(fay,blue),likes(jo,red)]  -> forward: same_output
  3 facts [colour(purple),likes(fay,red),likes(jo,blue)]  -> forward: same_output
  3 facts [colour(purple),likes(fay,blue),likes(fay,red)]  -> forward: same_output
  3 facts [colour(purple),likes(cy,red),likes(fay,blue)]  -> forward: same_output
```

## 188. Network 119: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
likes(fay, red).
likes(cy, blue).
likes(bob, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- invert_net(119, largest).
```

**Output**

```text
status: sat; original input (6 facts): [colour(blue),colour(purple),colour(red),likes(bob,blue),likes(cy,blue),likes(fay,red)]
1 largest input(s) found:
  11 facts [colour(blue),colour(purple),colour(red),likes(bob,blue),likes(bob,red),likes(cy,blue),likes(cy,red),likes(fay,blue),likes(fay,red),likes(jo,blue),likes(jo,red)]  -> forward: same_output
```

## 189. Network 123: the smallest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
likes(ann, blue).
likes(hal, gold).
likes(eli, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- invert_net(123, smallest).
```

**Output**

```text
status: sat; original input (6 facts): [colour(blue),colour(gold),colour(purple),likes(ann,blue),likes(eli,blue),likes(hal,gold)]
5 smallest input(s) found:
  3 facts [colour(purple),likes(hal,blue),likes(hal,gold)]  -> forward: same_output
  3 facts [colour(purple),likes(eli,blue),likes(hal,gold)]  -> forward: same_output
  3 facts [colour(purple),likes(eli,gold),likes(hal,blue)]  -> forward: same_output
  3 facts [colour(purple),likes(eli,blue),likes(eli,gold)]  -> forward: same_output
  3 facts [colour(purple),likes(dee,gold),likes(eli,blue)]  -> forward: same_output
```

## 190. Network 123: the largest input that gives its whole output

*Category:* `inversion`

**Input**

```prolog
likes(ann, blue).
likes(hal, gold).
likes(eli, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.

?- invert_net(123, largest).
```

**Output**

```text
status: sat; original input (6 facts): [colour(blue),colour(gold),colour(purple),likes(ann,blue),likes(eli,blue),likes(hal,gold)]
1 largest input(s) found:
  11 facts [colour(blue),colour(gold),colour(purple),likes(ann,blue),likes(ann,gold),likes(dee,blue),likes(dee,gold),likes(eli,blue),likes(eli,gold),likes(hal,blue),likes(hal,gold)]  -> forward: same_output
```

## 191. Mersenne Twister seeded like Python's random.Random(0)

*Category:* `datalog`

**Input**

```prolog
?- mt_seed(0, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _).
```

**Output**

```text
R1 = 0.8444218515250481
R2 = 0.7579544029403025
R3 = 0.420571580830845
```

## 192. Mersenne Twister seeded like Python's random.Random(1)

*Category:* `datalog`

**Input**

```prolog
?- mt_seed(1, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _).
```

**Output**

```text
R1 = 0.13436424411240122
R2 = 0.8474337369372327
R3 = 0.763774618976614
```

## 193. Mersenne Twister seeded like Python's random.Random(2)

*Category:* `datalog`

**Input**

```prolog
?- mt_seed(2, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _).
```

**Output**

```text
R1 = 0.9560342718892494
R2 = 0.9478274870593494
R3 = 0.05655136772680869
```

## 194. Mersenne Twister seeded like Python's random.Random(7)

*Category:* `datalog`

**Input**

```prolog
?- mt_seed(7, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _).
```

**Output**

```text
R1 = 0.32383276483316237
R2 = 0.15084917392450192
R3 = 0.6509344730398537
```

## 195. Mersenne Twister seeded like Python's random.Random(42)

*Category:* `datalog`

**Input**

```prolog
?- mt_seed(42, _M0), mt_random(_M0, R1, _M1), mt_random(_M1, R2, _M2), mt_random(_M2, R3, _).
```

**Output**

```text
R1 = 0.6394267984578837
R2 = 0.025010755222666936
R3 = 0.27502931836911926
```

## 196. Agreement with transitive closure on 200 random inputs: left recursion

*Category:* `datalog`

**Input**

```prolog
?- parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).", _O), parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- r(X,Z), e(Z,Y)).", _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction).
```

**Output**

```text
Fraction = 1
```

## 197. Agreement with transitive closure on 200 random inputs: no recursion

*Category:* `datalog`

**Input**

```prolog
?- parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).", _O), parse_program("(r(X,Y) :- e(X,Y)).", _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction).
```

**Output**

```text
Fraction = 0.6
```

## 198. Agreement with transitive closure on 200 random inputs: two steps at most

*Category:* `datalog`

**Input**

```prolog
?- parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).", _O), parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), e(Z,Y)).", _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction).
```

**Output**

```text
Fraction = 0.97
```

## 199. Agreement with transitive closure on 200 random inputs: symmetric instead of transitive

*Category:* `datalog`

**Input**

```prolog
?- parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).", _O), parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(Y,X)).", _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction).
```

**Output**

```text
Fraction = 0.105
```

## 200. Agreement with transitive closure on 200 random inputs: clauses reordered

*Category:* `datalog`

**Input**

```prolog
?- parse_program("(r(X,Y) :- e(X,Y)). (r(X,Y) :- e(X,Z), r(Z,Y)).", _O), parse_program("(r(X,Y) :- e(X,Z), r(Z,Y)). (r(X,Y) :- e(X,Y)).", _L), agreement(_O, _L, [e/2], [a,b,c], [r/2], [trials(200), seed(3)], Fraction).
```

**Output**

```text
Fraction = 1
```

