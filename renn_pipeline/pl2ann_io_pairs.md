# pl2ann (prolog2ann): 200 input/output pairs

Each pair is a source program (plus optional domain file and conversion options) and the queries put to the generated network. Every output was produced by running the repository's own `convert_file/3`, loading the emitted network module, calling its `ann_run/3`, `ann_query/2` and `ann_query_all/2`, and checking it with `ann_verify/3,4` against the source least model. Error outputs are the converter's real rejections.

| Category | Pairs |
|---|---|
| recursion/reachability | 40 |
| relations/family | 25 |
| logic/gates | 12 |
| negation/stratified | 15 |
| arithmetic/mutual-recursion | 5 |
| arithmetic/bounded-is | 5 |
| arithmetic/comparison | 5 |
| arithmetic/modulo | 5 |
| arithmetic/chain | 5 |
| domains/typed | 10 |
| terms/bounded-depth | 6 |
| terms/lists | 2 |
| terms/explicit-domain | 1 |
| terms/depth-overflow | 1 |
| modes/activation | 12 |
| errors/rejection | 18 |
| errors/limits | 4 |
| propositional/random | 29 |

## 1. Transitive closure over a 3-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`, `reach(a, a)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b)]
?- reach(b, a)  =>  true
?- reach(a, b)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 2. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 8 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,d)]
?- reach(b, a)  =>  false
?- reach(a, b)  =>  true
verify against source least model: equivalent
```

## 3. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, e).
edge(a, f).
edge(b, d).
edge(c, b).
edge(e, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, f)`, `reach(f, b)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 14 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,d),reach(a,e),reach(a,f)]
?- reach(b, f)  =>  false
?- reach(f, b)  =>  false
verify against source least model: equivalent
```

## 4. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, d).
edge(b, f).
edge(c, d).
edge(c, f).
edge(f, d).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, a)`, `reach(a, c)`

**Output**

```text
network: 32 atoms, 85 hidden (clause) neurons, 229 weighted edges, 1 strata; run: 10 active atoms after 3 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(c, a)  =>  false
?- reach(a, c)  =>  false
verify against source least model: equivalent
```

## 5. Transitive closure over a 5-node directed graph with a cycle

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, e)`, `reach(e, a)`, `reach(a, a)`

**Output**

```text
network: 50 atoms, 157 hidden (clause) neurons, 432 weighted edges, 1 strata; run: 19 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,c),reach(a,d)]
?- reach(a, e)  =>  false
?- reach(e, a)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 6. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, a)`, `reach(a, d)`

**Output**

```text
network: 50 atoms, 157 hidden (clause) neurons, 432 weighted edges, 1 strata; run: 22 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,c),reach(a,d)]
?- reach(d, a)  =>  false
?- reach(a, d)  =>  true
verify against source least model: equivalent
```

## 7. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, e).
edge(b, c).
edge(b, d).
edge(e, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, d)`, `reach(d, c)`

**Output**

```text
network: 50 atoms, 154 hidden (clause) neurons, 429 weighted edges, 1 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,e)]
?- reach(c, d)  =>  false
?- reach(d, c)  =>  false
verify against source least model: equivalent
```

## 8. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, d).
edge(b, e).
edge(c, a).
edge(d, a).
edge(e, a).
edge(e, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, b)`, `reach(b, c)`

**Output**

```text
network: 50 atoms, 157 hidden (clause) neurons, 432 weighted edges, 1 strata; run: 32 active atoms after 6 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c),reach(a,d),reach(a,e)]
?- reach(c, b)  =>  true
?- reach(b, c)  =>  true
verify against source least model: equivalent
```

## 9. Transitive closure over a 4-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, b)`, `reach(b, a)`, `reach(a, a)`

**Output**

```text
network: 32 atoms, 84 hidden (clause) neurons, 228 weighted edges, 1 strata; run: 13 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,d)]
?- reach(a, b)  =>  false
?- reach(b, a)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 10. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, a).
edge(b, c).
edge(c, d).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, b)`, `reach(b, d)`

**Output**

```text
network: 32 atoms, 84 hidden (clause) neurons, 228 weighted edges, 1 strata; run: 11 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(d, b)  =>  false
?- reach(b, d)  =>  true
verify against source least model: equivalent
```

## 11. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, a).
edge(c, b).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, a)`, `reach(a, d)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 7 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(d, a)  =>  true
?- reach(a, d)  =>  false
verify against source least model: equivalent
```

## 12. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(e, a).
edge(f, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, e)`, `reach(e, d)`

**Output**

```text
network: 72 atoms, 256 hidden (clause) neurons, 724 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,d)]
?- reach(d, e)  =>  false
?- reach(e, d)  =>  true
verify against source least model: equivalent
```

## 13. Transitive closure over a 5-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, a).
edge(c, a).
edge(d, a).
edge(d, e).
edge(e, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, c)`, `reach(c, d)`, `reach(a, a)`

**Output**

```text
network: 50 atoms, 155 hidden (clause) neurons, 430 weighted edges, 1 strata; run: 10 active atoms after 3 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(d, c)  =>  false
?- reach(c, d)  =>  false
?- reach(a, a)  =>  false
verify against source least model: equivalent
```

## 14. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, f).
edge(b, f).
edge(c, e).
edge(c, f).
edge(f, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, e)`, `reach(e, d)`

**Output**

```text
network: 50 atoms, 155 hidden (clause) neurons, 430 weighted edges, 1 strata; run: 17 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,c),reach(a,e),reach(a,f)]
?- reach(d, e)  =>  false
?- reach(e, d)  =>  false
verify against source least model: equivalent
```

## 15. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, c)`, `reach(c, b)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(b, c)  =>  true
?- reach(c, b)  =>  true
verify against source least model: equivalent
```

## 16. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, e).
edge(c, a).
edge(c, b).
edge(c, f).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(e, b)`, `reach(b, e)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 15 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(e, b)  =>  false
?- reach(b, e)  =>  true
verify against source least model: equivalent
```

## 17. Transitive closure over a 4-node directed graph with a cycle

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, d)`, `reach(d, c)`, `reach(a, a)`

**Output**

```text
network: 32 atoms, 86 hidden (clause) neurons, 230 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,c)]
?- reach(c, d)  =>  false
?- reach(d, c)  =>  true
?- reach(a, a)  =>  false
verify against source least model: equivalent
```

## 18. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, c).
edge(a, d).
edge(c, e).
edge(d, b).
edge(e, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, d)`, `reach(d, c)`

**Output**

```text
network: 50 atoms, 155 hidden (clause) neurons, 430 weighted edges, 1 strata; run: 21 active atoms after 6 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c),reach(a,d),reach(a,e)]
?- reach(c, d)  =>  true
?- reach(d, c)  =>  false
verify against source least model: equivalent
```

## 19. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, b)`, `reach(b, a)`

**Output**

```text
network: 18 atoms, 41 hidden (clause) neurons, 104 weighted edges, 1 strata; run: 14 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c)]
?- reach(a, b)  =>  true
?- reach(b, a)  =>  true
verify against source least model: equivalent
```

## 20. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, d).
edge(c, a).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, d)`, `reach(d, a)`

**Output**

```text
network: 32 atoms, 84 hidden (clause) neurons, 228 weighted edges, 1 strata; run: 16 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,d)]
?- reach(a, d)  =>  true
?- reach(d, a)  =>  true
verify against source least model: equivalent
```

## 21. Transitive closure over a 6-node directed graph with a cycle

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(f, b)`, `reach(b, f)`, `reach(a, a)`

**Output**

```text
network: 72 atoms, 260 hidden (clause) neurons, 728 weighted edges, 1 strata; run: 27 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(f, b)  =>  true
?- reach(b, f)  =>  true
?- reach(a, a)  =>  false
verify against source least model: equivalent
```

## 22. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(f, b)`, `reach(b, f)`

**Output**

```text
network: 72 atoms, 259 hidden (clause) neurons, 727 weighted edges, 1 strata; run: 19 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,e)]
?- reach(f, b)  =>  false
?- reach(b, f)  =>  false
verify against source least model: equivalent
```

## 23. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, c)`, `reach(c, b)`

**Output**

```text
network: 8 atoms, 13 hidden (clause) neurons, 33 weighted edges, 1 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,c)]
?- reach(b, c)  =>  false
?- reach(c, b)  =>  false
verify against source least model: equivalent
```

## 24. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, c).
edge(c, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`

**Output**

```text
network: 8 atoms, 14 hidden (clause) neurons, 34 weighted edges, 1 strata; run: 6 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,c)]
?- reach(b, a)  =>  false
?- reach(a, b)  =>  false
verify against source least model: equivalent
```

## 25. Transitive closure over a 4-node directed graph with a cycle

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, b)`, `reach(b, d)`, `reach(a, a)`

**Output**

```text
network: 32 atoms, 87 hidden (clause) neurons, 231 weighted edges, 1 strata; run: 23 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c),reach(a,d)]
?- reach(d, b)  =>  true
?- reach(b, d)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 26. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, e).
edge(b, e).
edge(d, a).
edge(e, d).
edge(f, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, b)`, `reach(b, d)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 18 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,d),reach(a,e)]
?- reach(d, b)  =>  false
?- reach(b, d)  =>  true
verify against source least model: equivalent
```

## 27. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(e, d)`, `reach(d, e)`

**Output**

```text
network: 50 atoms, 156 hidden (clause) neurons, 431 weighted edges, 1 strata; run: 13 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(e, d)  =>  false
?- reach(d, e)  =>  true
verify against source least model: equivalent
```

## 28. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, a)`, `reach(a, c)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,d)]
?- reach(c, a)  =>  true
?- reach(a, c)  =>  false
verify against source least model: equivalent
```

## 29. Transitive closure over a 3-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, c).
edge(b, a).
edge(b, c).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`, `reach(a, a)`

**Output**

```text
network: 18 atoms, 41 hidden (clause) neurons, 104 weighted edges, 1 strata; run: 14 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c)]
?- reach(b, a)  =>  true
?- reach(a, b)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 30. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, c).
edge(a, d).
edge(c, b).
edge(e, b).
edge(e, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, c)`, `reach(c, b)`

**Output**

```text
network: 50 atoms, 155 hidden (clause) neurons, 430 weighted edges, 1 strata; run: 11 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,c),reach(a,d)]
?- reach(b, c)  =>  false
?- reach(c, b)  =>  true
verify against source least model: equivalent
```

## 31. Transitive closure over a 5-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(b, a).
edge(c, b).
edge(e, d).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, b)`, `reach(b, c)`

**Output**

```text
network: 50 atoms, 154 hidden (clause) neurons, 429 weighted edges, 1 strata; run: 11 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,d)]
?- reach(c, b)  =>  true
?- reach(b, c)  =>  false
verify against source least model: equivalent
```

## 32. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(c, d).
edge(d, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, d)`, `reach(d, a)`

**Output**

```text
network: 18 atoms, 38 hidden (clause) neurons, 101 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(a, d)  =>  false
?- reach(d, a)  =>  true
verify against source least model: equivalent
```

## 33. Transitive closure over a 6-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, d).
edge(c, a).
edge(c, f).
edge(e, f).
edge(f, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(a, c)`, `reach(c, a)`, `reach(a, a)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 11 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(a, c)  =>  false
?- reach(c, a)  =>  true
?- reach(a, a)  =>  false
verify against source least model: equivalent
```

## 34. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(a, d).
edge(b, a).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, a)`, `reach(a, c)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,d)]
?- reach(c, a)  =>  false
?- reach(a, c)  =>  false
verify against source least model: equivalent
```

## 35. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(b, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, b)`, `reach(b, c)`

**Output**

```text
network: 18 atoms, 38 hidden (clause) neurons, 101 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  []
?- reach(c, b)  =>  true
?- reach(b, c)  =>  false
verify against source least model: equivalent
```

## 36. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, c).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(d, a)`, `reach(a, d)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 7 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,c)]
?- reach(d, a)  =>  false
?- reach(a, d)  =>  false
verify against source least model: equivalent
```

## 37. Transitive closure over a 4-node directed graph with a cycle

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, a).
edge(d, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(c, a)`, `reach(a, c)`, `reach(a, a)`

**Output**

```text
network: 18 atoms, 40 hidden (clause) neurons, 103 weighted edges, 1 strata; run: 13 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,c),reach(a,d)]
?- reach(c, a)  =>  true
?- reach(a, c)  =>  true
?- reach(a, a)  =>  true
verify against source least model: equivalent
```

## 38. Transitive closure over a 6-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(b, e).
edge(c, e).
edge(e, f).
edge(f, c).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(e, f)`, `reach(f, e)`

**Output**

```text
network: 50 atoms, 155 hidden (clause) neurons, 430 weighted edges, 1 strata; run: 21 active atoms after 6 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,c),reach(a,e),reach(a,f)]
?- reach(e, f)  =>  true
?- reach(f, e)  =>  true
verify against source least model: equivalent
```

## 39. Transitive closure over a 3-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, b).
edge(c, a).
edge(c, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 6 active atoms after 3 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b)]
?- reach(b, a)  =>  false
?- reach(a, b)  =>  true
verify against source least model: equivalent
```

## 40. Transitive closure over a 4-node directed graph

*Category:* `recursion/reachability`

**Input**

```prolog
edge(a, d).
edge(c, d).
edge(d, b).

reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `reach(a, X)`, `reach(b, a)`, `reach(a, b)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 8 active atoms after 4 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,b),reach(a,d)]
?- reach(b, a)  =>  false
?- reach(a, b)  =>  true
verify against source least model: equivalent
```

## 41. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(fay, dee).
parent(dee, cy).
parent(fay, ann).
parent(cy, ivy).
parent(dee, jo).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(fay, X)`, `ancestor(X, jo)`, `ancestor(jo, fay)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 14 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(fay, X)  =>  [ancestor(fay,ann),ancestor(fay,cy),ancestor(fay,dee),ancestor(fay,ivy),ancestor(fay,jo)]
?- ancestor(X, jo)  =>  [ancestor(dee,jo),ancestor(fay,jo)]
?- ancestor(jo, fay)  =>  false
verify against source least model: equivalent
```

## 42. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

**Input**

```prolog
parent(fay, ivy).
parent(ivy, gus).
parent(fay, ann).
parent(fay, jo).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(fay, jo)`

**Output**

```text
network: 50 atoms, 129 hidden (clause) neurons, 379 weighted edges, 1 strata; run: 5 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(fay,gus)]
?- grandparent(fay, jo)  =>  false
verify against source least model: equivalent
```

## 43. Family tree: sibling relation with disequality

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(cy, gus)`

**Output**

```text
network: 120 atoms, 455 hidden (clause) neurons, 1351 weighted edges, 1 strata; run: 15 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(cy,hal),sibling(fay,gus),sibling(fay,jo),sibling(gus,fay),sibling(gus,jo),sibling(hal,cy),sibling(jo,fay),sibling(jo,gus)]
?- sibling(cy, gus)  =>  false
verify against source least model: equivalent
```

## 44. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(hal, bob).
parent(hal, gus).
parent(bob, cy).
parent(cy, ivy).
parent(cy, ann).
parent(cy, eli).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(hal, X)`, `ancestor(X, eli)`, `ancestor(eli, hal)`

**Output**

```text
network: 98 atoms, 398 hidden (clause) neurons, 1133 weighted edges, 1 strata; run: 19 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(hal, X)  =>  [ancestor(hal,ann),ancestor(hal,bob),ancestor(hal,cy),ancestor(hal,eli),ancestor(hal,gus),ancestor(hal,ivy)]
?- ancestor(X, eli)  =>  [ancestor(bob,eli),ancestor(cy,eli),ancestor(hal,eli)]
?- ancestor(eli, hal)  =>  false
verify against source least model: equivalent
```

## 45. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(dee, fay)`

**Output**

```text
network: 128 atoms, 519 hidden (clause) neurons, 1543 weighted edges, 1 strata; run: 11 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(dee,ann),grandparent(hal,cy),grandparent(hal,fay),grandparent(hal,ivy)]
?- grandparent(dee, fay)  =>  false
verify against source least model: equivalent
```

## 46. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(gus, ivy).
parent(gus, jo).
parent(jo, ann).
parent(jo, bob).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(ivy, jo)`

**Output**

```text
network: 45 atoms, 104 hidden (clause) neurons, 304 weighted edges, 1 strata; run: 8 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(ann,bob),sibling(bob,ann),sibling(ivy,jo),sibling(jo,ivy)]
?- sibling(ivy, jo)  =>  true
verify against source least model: equivalent
```

## 47. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(ann, cy).
parent(cy, ivy).
parent(cy, fay).
parent(ann, hal).
parent(ivy, gus).
parent(cy, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(ann, X)`, `ancestor(X, dee)`, `ancestor(dee, ann)`

**Output**

```text
network: 98 atoms, 398 hidden (clause) neurons, 1133 weighted edges, 1 strata; run: 17 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(ann, X)  =>  [ancestor(ann,cy),ancestor(ann,dee),ancestor(ann,fay),ancestor(ann,gus),ancestor(ann,hal),ancestor(ann,ivy)]
?- ancestor(X, dee)  =>  [ancestor(ann,dee),ancestor(cy,dee)]
?- ancestor(dee, ann)  =>  false
verify against source least model: equivalent
```

## 48. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

**Input**

```prolog
parent(dee, ann).
parent(dee, hal).
parent(ann, bob).
parent(ann, jo).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(dee, jo)`

**Output**

```text
network: 50 atoms, 129 hidden (clause) neurons, 379 weighted edges, 1 strata; run: 6 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(dee,bob),grandparent(dee,jo)]
?- grandparent(dee, jo)  =>  true
verify against source least model: equivalent
```

## 49. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(cy, ivy).
parent(ivy, gus).
parent(ivy, jo).
parent(jo, ann).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(ivy, gus)`

**Output**

```text
network: 45 atoms, 104 hidden (clause) neurons, 304 weighted edges, 1 strata; run: 6 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(gus,jo),sibling(jo,gus)]
?- sibling(ivy, gus)  =>  false
verify against source least model: equivalent
```

## 50. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(fay, dee).
parent(dee, ivy).
parent(ivy, jo).
parent(dee, hal).
parent(fay, cy).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(fay, X)`, `ancestor(X, cy)`, `ancestor(cy, fay)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 14 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(fay, X)  =>  [ancestor(fay,cy),ancestor(fay,dee),ancestor(fay,hal),ancestor(fay,ivy),ancestor(fay,jo)]
?- ancestor(X, cy)  =>  [ancestor(fay,cy)]
?- ancestor(cy, fay)  =>  false
verify against source least model: equivalent
```

## 51. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(fay, dee)`

**Output**

```text
network: 128 atoms, 519 hidden (clause) neurons, 1543 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(fay,dee),grandparent(fay,eli),grandparent(fay,gus),grandparent(gus,bob),grandparent(ivy,ann)]
?- grandparent(fay, dee)  =>  true
verify against source least model: equivalent
```

## 52. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(ann, dee).
parent(dee, cy).
parent(ann, hal).
parent(hal, jo).
parent(cy, fay).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(dee, cy)`

**Output**

```text
network: 66 atoms, 185 hidden (clause) neurons, 545 weighted edges, 1 strata; run: 7 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(dee,hal),sibling(hal,dee)]
?- sibling(dee, cy)  =>  false
verify against source least model: equivalent
```

## 53. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(dee, ivy).
parent(ivy, hal).
parent(ivy, bob).
parent(hal, jo).
parent(hal, eli).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(dee, X)`, `ancestor(X, eli)`, `ancestor(eli, dee)`

**Output**

```text
network: 72 atoms, 257 hidden (clause) neurons, 725 weighted edges, 1 strata; run: 16 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(dee, X)  =>  [ancestor(dee,bob),ancestor(dee,eli),ancestor(dee,hal),ancestor(dee,ivy),ancestor(dee,jo)]
?- ancestor(X, eli)  =>  [ancestor(dee,eli),ancestor(hal,eli),ancestor(ivy,eli)]
?- ancestor(eli, dee)  =>  false
verify against source least model: equivalent
```

## 54. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

**Input**

```prolog
parent(cy, ann).
parent(ann, fay).
parent(cy, hal).
parent(fay, ivy).
parent(ann, bob).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(cy, bob)`

**Output**

```text
network: 72 atoms, 221 hidden (clause) neurons, 653 weighted edges, 1 strata; run: 8 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(ann,ivy),grandparent(cy,bob),grandparent(cy,fay)]
?- grandparent(cy, bob)  =>  true
verify against source least model: equivalent
```

## 55. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(ann, eli).
parent(ann, ivy).
parent(ivy, gus).
parent(ivy, jo).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(eli, ivy)`

**Output**

```text
network: 45 atoms, 104 hidden (clause) neurons, 304 weighted edges, 1 strata; run: 8 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(eli,ivy),sibling(gus,jo),sibling(ivy,eli),sibling(jo,gus)]
?- sibling(eli, ivy)  =>  true
verify against source least model: equivalent
```

## 56. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(gus, hal).
parent(hal, ann).
parent(ann, fay).
parent(ann, jo).
parent(fay, ivy).
parent(jo, cy).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(gus, X)`, `ancestor(X, cy)`, `ancestor(cy, gus)`

**Output**

```text
network: 98 atoms, 398 hidden (clause) neurons, 1133 weighted edges, 1 strata; run: 23 active atoms after 6 rounds, fixpoint reached = true
?- ancestor(gus, X)  =>  [ancestor(gus,ann),ancestor(gus,cy),ancestor(gus,fay),ancestor(gus,hal),ancestor(gus,ivy),ancestor(gus,jo)]
?- ancestor(X, cy)  =>  [ancestor(ann,cy),ancestor(gus,cy),ancestor(hal,cy),ancestor(jo,cy)]
?- ancestor(cy, gus)  =>  false
verify against source least model: equivalent
```

## 57. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(ann, cy)`

**Output**

```text
network: 128 atoms, 519 hidden (clause) neurons, 1543 weighted edges, 1 strata; run: 11 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(ann,hal),grandparent(ann,ivy),grandparent(eli,fay),grandparent(hal,cy)]
?- grandparent(ann, cy)  =>  false
verify against source least model: equivalent
```

## 58. Family tree: sibling relation with disequality

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(cy, dee)`

**Output**

```text
network: 120 atoms, 455 hidden (clause) neurons, 1351 weighted edges, 1 strata; run: 15 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(ann,dee),sibling(ann,jo),sibling(cy,eli),sibling(dee,ann),sibling(dee,jo),sibling(eli,cy),sibling(jo,ann),sibling(jo,dee)]
?- sibling(cy, dee)  =>  false
verify against source least model: equivalent
```

## 59. Family tree: recursive ancestor relation

*Category:* `relations/family`

**Input**

```prolog
parent(eli, cy).
parent(eli, jo).
parent(jo, hal).
parent(eli, dee).

ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(eli, X)`, `ancestor(X, dee)`, `ancestor(dee, eli)`

**Output**

```text
network: 50 atoms, 154 hidden (clause) neurons, 429 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- ancestor(eli, X)  =>  [ancestor(eli,cy),ancestor(eli,dee),ancestor(eli,hal),ancestor(eli,jo)]
?- ancestor(X, dee)  =>  [ancestor(eli,dee)]
?- ancestor(dee, eli)  =>  false
verify against source least model: equivalent
```

## 60. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

**Input**

```prolog
parent(ivy, gus).
parent(gus, dee).
parent(gus, hal).
parent(dee, fay).
parent(ivy, cy).
parent(dee, bob).
parent(hal, eli).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(ivy, eli)`

**Output**

```text
network: 128 atoms, 519 hidden (clause) neurons, 1543 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(gus,bob),grandparent(gus,eli),grandparent(gus,fay),grandparent(ivy,dee),grandparent(ivy,hal)]
?- grandparent(ivy, eli)  =>  false
verify against source least model: equivalent
```

## 61. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(bob, dee).
parent(dee, ann).
parent(ann, cy).
parent(dee, hal).
parent(bob, ivy).
parent(ann, gus).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(dee, ann)`

**Output**

```text
network: 91 atoms, 300 hidden (clause) neurons, 888 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(ann,hal),sibling(cy,gus),sibling(dee,ivy),sibling(gus,cy),sibling(hal,ann),sibling(ivy,dee)]
?- sibling(dee, ann)  =>  false
verify against source least model: equivalent
```

## 62. Family tree: recursive ancestor relation

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(gus, X)`, `ancestor(X, dee)`, `ancestor(dee, gus)`

**Output**

```text
network: 128 atoms, 583 hidden (clause) neurons, 1671 weighted edges, 1 strata; run: 18 active atoms after 4 rounds, fixpoint reached = true
?- ancestor(gus, X)  =>  [ancestor(gus,ann),ancestor(gus,bob),ancestor(gus,dee),ancestor(gus,eli),ancestor(gus,fay),ancestor(gus,ivy),ancestor(gus,jo)]
?- ancestor(X, dee)  =>  [ancestor(gus,dee),ancestor(jo,dee)]
?- ancestor(dee, gus)  =>  false
verify against source least model: equivalent
```

## 63. Family tree: grandparent relation (two-step join)

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `grandparent(X, Y)`, `grandparent(gus, dee)`

**Output**

```text
network: 128 atoms, 519 hidden (clause) neurons, 1543 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- grandparent(X, Y)  =>  [grandparent(ann,cy),grandparent(ann,dee),grandparent(ann,jo),grandparent(gus,eli),grandparent(gus,ivy)]
?- grandparent(gus, dee)  =>  false
verify against source least model: equivalent
```

## 64. Family tree: sibling relation with disequality

*Category:* `relations/family`

**Input**

```prolog
parent(hal, jo).
parent(hal, cy).
parent(cy, fay).
parent(hal, bob).
parent(cy, gus).

sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
```

Convert options: `(defaults: --mode step)`  
Queries: `sibling(X, Y)`, `sibling(jo, cy)`

**Output**

```text
network: 66 atoms, 185 hidden (clause) neurons, 545 weighted edges, 1 strata; run: 13 active atoms after 3 rounds, fixpoint reached = true
?- sibling(X, Y)  =>  [sibling(bob,cy),sibling(bob,jo),sibling(cy,bob),sibling(cy,jo),sibling(fay,gus),sibling(gus,fay),sibling(jo,bob),sibling(jo,cy)]
?- sibling(jo, cy)  =>  true
verify against source least model: equivalent
```

## 65. Family tree: recursive ancestor relation

*Category:* `relations/family`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `ancestor(jo, X)`, `ancestor(X, fay)`, `ancestor(fay, jo)`

**Output**

```text
network: 128 atoms, 583 hidden (clause) neurons, 1671 weighted edges, 1 strata; run: 22 active atoms after 6 rounds, fixpoint reached = true
?- ancestor(jo, X)  =>  [ancestor(jo,ann),ancestor(jo,dee),ancestor(jo,eli),ancestor(jo,fay),ancestor(jo,gus),ancestor(jo,hal),ancestor(jo,ivy)]
?- ancestor(X, fay)  =>  [ancestor(ann,fay),ancestor(gus,fay),ancestor(jo,fay)]
?- ancestor(fay, jo)  =>  false
verify against source least model: equivalent
```

## 66. AND gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

and(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
```

Convert options: `--mode step`  
Queries: `and(X, Y)`, `and(1, 1)`, `and(0, 1)`

**Output**

```text
network: 3 atoms, 3 hidden (clause) neurons, 5 weighted edges, 1 strata; run: 3 active atoms after 3 rounds, fixpoint reached = true
?- and(X, Y)  =>  [and(1,1)]
?- and(1, 1)  =>  true
?- and(0, 1)  =>  false
verify against source least model: equivalent
```

## 67. OR gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

or(X, Y) :- bit(X), bit(Y), X = 1.
or(X, Y) :- bit(X), bit(Y), Y = 1.
```

Convert options: `--mode step`  
Queries: `or(X, Y)`, `or(1, 1)`, `or(0, 1)`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 14 weighted edges, 1 strata; run: 5 active atoms after 3 rounds, fixpoint reached = true
?- or(X, Y)  =>  [or(0,1),or(1,0),or(1,1)]
?- or(1, 1)  =>  true
?- or(0, 1)  =>  true
verify against source least model: equivalent
```

## 68. NAND gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

both(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
nand(X, Y) :- bit(X), bit(Y), \+ both(X, Y).
```

Convert options: `--mode step`  
Queries: `nand(X, Y)`, `nand(1, 1)`, `nand(0, 1)`

**Output**

```text
network: 10 atoms, 7 hidden (clause) neurons, 21 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- nand(X, Y)  =>  [nand(0,0),nand(0,1),nand(1,0)]
?- nand(1, 1)  =>  false
?- nand(0, 1)  =>  true
verify against source least model: equivalent
```

## 69. NOR gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

any(X, Y) :- bit(X), bit(Y), X = 1.
any(X, Y) :- bit(X), bit(Y), Y = 1.
nor(X, Y) :- bit(X), bit(Y), \+ any(X, Y).
```

Convert options: `--mode step`  
Queries: `nor(X, Y)`, `nor(1, 1)`, `nor(0, 1)`

**Output**

```text
network: 10 atoms, 10 hidden (clause) neurons, 30 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- nor(X, Y)  =>  [nor(0,0)]
?- nor(1, 1)  =>  false
?- nor(0, 1)  =>  false
verify against source least model: equivalent
```

## 70. XOR gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).
```

Convert options: `--mode step`  
Queries: `xor(X, Y)`, `xor(1, 1)`, `xor(0, 1)`

**Output**

```text
network: 10 atoms, 8 hidden (clause) neurons, 24 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- xor(X, Y)  =>  [xor(0,1),xor(1,0)]
?- xor(1, 1)  =>  false
?- xor(0, 1)  =>  true
verify against source least model: equivalent
```

## 71. XNOR gate as a step network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

xnor(X, Y) :- bit(X), bit(Y), X = Y.
```

Convert options: `--mode step`  
Queries: `xnor(X, Y)`, `xnor(1, 1)`, `xnor(0, 1)`

**Output**

```text
network: 4 atoms, 4 hidden (clause) neurons, 8 weighted edges, 1 strata; run: 4 active atoms after 3 rounds, fixpoint reached = true
?- xnor(X, Y)  =>  [xnor(0,0),xnor(1,1)]
?- xnor(1, 1)  =>  true
?- xnor(0, 1)  =>  false
verify against source least model: equivalent
```

## 72. AND gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

and(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `and(X, Y)`, `and(1, 1)`, `and(0, 1)`

**Output**

```text
network: 3 atoms, 3 hidden (clause) neurons, 5 weighted edges, 1 strata; run: 3 active atoms after 3 rounds, fixpoint reached = true
?- and(X, Y)  =>  [and(1,1)]
?- and(1, 1)  =>  true
?- and(0, 1)  =>  false
verify against source least model: equivalent
```

## 73. OR gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

or(X, Y) :- bit(X), bit(Y), X = 1.
or(X, Y) :- bit(X), bit(Y), Y = 1.
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `or(X, Y)`, `or(1, 1)`, `or(0, 1)`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 14 weighted edges, 1 strata; run: 5 active atoms after 3 rounds, fixpoint reached = true
?- or(X, Y)  =>  [or(0,1),or(1,0),or(1,1)]
?- or(1, 1)  =>  true
?- or(0, 1)  =>  true
verify against source least model: equivalent
```

## 74. NAND gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

both(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.
nand(X, Y) :- bit(X), bit(Y), \+ both(X, Y).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `nand(X, Y)`, `nand(1, 1)`, `nand(0, 1)`

**Output**

```text
network: 10 atoms, 7 hidden (clause) neurons, 21 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- nand(X, Y)  =>  [nand(0,0),nand(0,1),nand(1,0)]
?- nand(1, 1)  =>  false
?- nand(0, 1)  =>  true
verify against source least model: equivalent
```

## 75. NOR gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

any(X, Y) :- bit(X), bit(Y), X = 1.
any(X, Y) :- bit(X), bit(Y), Y = 1.
nor(X, Y) :- bit(X), bit(Y), \+ any(X, Y).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `nor(X, Y)`, `nor(1, 1)`, `nor(0, 1)`

**Output**

```text
network: 10 atoms, 10 hidden (clause) neurons, 30 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- nor(X, Y)  =>  [nor(0,0)]
?- nor(1, 1)  =>  false
?- nor(0, 1)  =>  false
verify against source least model: equivalent
```

## 76. XOR gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

same(X, Y) :- bit(X), bit(Y), X = Y.
xor(X, Y) :- bit(X), bit(Y), \+ same(X, Y).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `xor(X, Y)`, `xor(1, 1)`, `xor(0, 1)`

**Output**

```text
network: 10 atoms, 8 hidden (clause) neurons, 24 weighted edges, 2 strata; run: 6 active atoms after 5 rounds, fixpoint reached = true
?- xor(X, Y)  =>  [xor(0,1),xor(1,0)]
?- xor(1, 1)  =>  false
?- xor(0, 1)  =>  true
verify against source least model: equivalent
```

## 77. XNOR gate as a sigmoid network

*Category:* `logic/gates`

**Input**

```prolog
bit(0).
bit(1).

xnor(X, Y) :- bit(X), bit(Y), X = Y.
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `xnor(X, Y)`, `xnor(1, 1)`, `xnor(0, 1)`

**Output**

```text
network: 4 atoms, 4 hidden (clause) neurons, 8 weighted edges, 1 strata; run: 4 active atoms after 3 rounds, fixpoint reached = true
?- xnor(X, Y)  =>  [xnor(0,0),xnor(1,1)]
?- xnor(1, 1)  =>  true
?- xnor(0, 1)  =>  false
verify against source least model: equivalent
```

## 78. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(emu)`

**Output**

```text
network: 18 atoms, 13 hidden (clause) neurons, 25 weighted edges, 2 strata; run: 12 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(opus),flies(pingu),flies(polly),flies(robin),flies(tweety)]
?- flies(emu)  =>  false
verify against source least model: equivalent
```

## 79. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(tweety).
bird(robin).
bird(opus).
bird(emu).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(emu)`

**Output**

```text
network: 12 atoms, 9 hidden (clause) neurons, 17 weighted edges, 2 strata; run: 8 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(opus),flies(robin),flies(tweety)]
?- flies(emu)  =>  false
verify against source least model: equivalent
```

## 80. Stratified negation: two exceptions (penguin, injured) via an abnormal/1 stratum

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(polly)`

**Output**

```text
network: 20 atoms, 18 hidden (clause) neurons, 34 weighted edges, 2 strata; run: 10 active atoms after 5 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(opus)]
?- flies(polly)  =>  false
verify against source least model: equivalent
```

## 81. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(opus)`

**Output**

```text
network: 15 atoms, 12 hidden (clause) neurons, 22 weighted edges, 2 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(kiwi),flies(pingu),flies(robin)]
?- flies(opus)  =>  false
verify against source least model: equivalent
```

## 82. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(tweety).
bird(pingu).
bird(robin).
bird(kiwi).
bird(emu).
penguin(tweety).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(tweety)`

**Output**

```text
network: 15 atoms, 11 hidden (clause) neurons, 21 weighted edges, 2 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(kiwi),flies(pingu),flies(robin)]
?- flies(tweety)  =>  false
verify against source least model: equivalent
```

## 83. Stratified negation: two exceptions (penguin, injured) via an abnormal/1 stratum

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(opus)`

**Output**

```text
network: 15 atoms, 15 hidden (clause) neurons, 27 weighted edges, 2 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  []
?- flies(opus)  =>  false
verify against source least model: equivalent
```

## 84. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(tweety).
bird(emu).
bird(kiwi).
bird(robin).
penguin(tweety).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(tweety)`

**Output**

```text
network: 12 atoms, 9 hidden (clause) neurons, 17 weighted edges, 2 strata; run: 8 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(kiwi),flies(robin)]
?- flies(tweety)  =>  false
verify against source least model: equivalent
```

## 85. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(robin).
bird(kiwi).
bird(polly).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(kiwi)`

**Output**

```text
network: 9 atoms, 7 hidden (clause) neurons, 13 weighted edges, 2 strata; run: 6 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(polly),flies(robin)]
?- flies(kiwi)  =>  false
verify against source least model: equivalent
```

## 86. Stratified negation: two exceptions (penguin, injured) via an abnormal/1 stratum

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(robin)`

**Output**

```text
network: 30 atoms, 26 hidden (clause) neurons, 50 weighted edges, 2 strata; run: 14 active atoms after 5 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(kiwi),flies(polly),flies(tweety)]
?- flies(robin)  =>  false
verify against source least model: equivalent
```

## 87. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(opus).
bird(tweety).
bird(polly).
bird(emu).
bird(robin).
penguin(polly).
penguin(emu).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(polly)`

**Output**

```text
network: 15 atoms, 12 hidden (clause) neurons, 22 weighted edges, 2 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(opus),flies(robin),flies(tweety)]
?- flies(polly)  =>  false
verify against source least model: equivalent
```

## 88. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(kiwi).
bird(tweety).
bird(opus).
bird(emu).
bird(pingu).
penguin(pingu).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(pingu)`

**Output**

```text
network: 15 atoms, 11 hidden (clause) neurons, 21 weighted edges, 2 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(kiwi),flies(opus),flies(tweety)]
?- flies(pingu)  =>  false
verify against source least model: equivalent
```

## 89. Stratified negation: two exceptions (penguin, injured) via an abnormal/1 stratum

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(kiwi)`

**Output**

```text
network: 30 atoms, 26 hidden (clause) neurons, 50 weighted edges, 2 strata; run: 14 active atoms after 5 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(opus),flies(pingu),flies(polly)]
?- flies(kiwi)  =>  false
verify against source least model: equivalent
```

## 90. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

**Input**

```prolog
bird(kiwi).
bird(emu).
bird(pingu).
penguin(emu).
penguin(kiwi).

flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(emu)`

**Output**

```text
network: 9 atoms, 8 hidden (clause) neurons, 14 weighted edges, 2 strata; run: 6 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(pingu)]
?- flies(emu)  =>  false
verify against source least model: equivalent
```

## 91. Stratified negation: default rule with one exception

*Category:* `negation/stratified`

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
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(pingu)`

**Output**

```text
network: 15 atoms, 12 hidden (clause) neurons, 22 weighted edges, 2 strata; run: 10 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(kiwi),flies(opus),flies(tweety)]
?- flies(pingu)  =>  false
verify against source least model: equivalent
```

## 92. Stratified negation: two exceptions (penguin, injured) via an abnormal/1 stratum

*Category:* `negation/stratified`

**Input**

```prolog
bird(pingu).
bird(robin).
bird(emu).
bird(polly).
bird(tweety).
bird(kiwi).
penguin(polly).
penguin(pingu).

injured(kiwi).
abnormal(X) :- penguin(X).
abnormal(X) :- injured(X).
flies(X) :- bird(X), \+ abnormal(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `flies(X)`, `flies(polly)`

**Output**

```text
network: 30 atoms, 27 hidden (clause) neurons, 51 weighted edges, 2 strata; run: 15 active atoms after 5 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(emu),flies(robin),flies(tweety)]
?- flies(polly)  =>  false
verify against source least model: equivalent
```

## 93. Mutual recursion even/odd over range 0..4

*Category:* `arithmetic/mutual-recursion`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 4).
```

Convert options: `(defaults: --mode step)`  
Queries: `even(X)`, `odd(3)`, `even(3)`

**Output**

```text
network: 10 atoms, 9 hidden (clause) neurons, 17 weighted edges, 1 strata; run: 5 active atoms after 6 rounds, fixpoint reached = true
?- even(X)  =>  [even(0),even(2),even(4)]
?- odd(3)  =>  true
?- even(3)  =>  false
verify against source least model: equivalent
```

## 94. Mutual recursion even/odd over range 0..6

*Category:* `arithmetic/mutual-recursion`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 6).
```

Convert options: `(defaults: --mode step)`  
Queries: `even(X)`, `odd(5)`, `even(5)`

**Output**

```text
network: 14 atoms, 13 hidden (clause) neurons, 25 weighted edges, 1 strata; run: 7 active atoms after 8 rounds, fixpoint reached = true
?- even(X)  =>  [even(0),even(2),even(4),even(6)]
?- odd(5)  =>  true
?- even(5)  =>  false
verify against source least model: equivalent
```

## 95. Mutual recursion even/odd over range 0..8

*Category:* `arithmetic/mutual-recursion`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 8).
```

Convert options: `(defaults: --mode step)`  
Queries: `even(X)`, `odd(7)`, `even(7)`

**Output**

```text
network: 18 atoms, 17 hidden (clause) neurons, 33 weighted edges, 1 strata; run: 9 active atoms after 10 rounds, fixpoint reached = true
?- even(X)  =>  [even(0),even(2),even(4),even(6),even(8)]
?- odd(7)  =>  true
?- even(7)  =>  false
verify against source least model: equivalent
```

## 96. Mutual recursion even/odd over range 0..10

*Category:* `arithmetic/mutual-recursion`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 10).
```

Convert options: `(defaults: --mode step)`  
Queries: `even(X)`, `odd(9)`, `even(9)`

**Output**

```text
network: 22 atoms, 21 hidden (clause) neurons, 41 weighted edges, 1 strata; run: 11 active atoms after 12 rounds, fixpoint reached = true
?- even(X)  =>  [even(0),even(2),even(4),even(6),even(8),even(10)]
?- odd(9)  =>  true
?- even(9)  =>  false
verify against source least model: equivalent
```

## 97. Mutual recursion even/odd over range 0..12

*Category:* `arithmetic/mutual-recursion`

**Input**

```prolog
even(0).
even(N) :- odd(M), N is M + 1.
odd(N) :- even(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 12).
```

Convert options: `(defaults: --mode step)`  
Queries: `even(X)`, `odd(11)`, `even(11)`

**Output**

```text
network: 26 atoms, 25 hidden (clause) neurons, 49 weighted edges, 1 strata; run: 13 active atoms after 14 rounds, fixpoint reached = true
?- even(X)  =>  [even(0),even(2),even(4),even(6),even(8),even(10),even(12)]
?- odd(11)  =>  true
?- even(11)  =>  false
verify against source least model: equivalent
```

## 98. Bounded is/2: squares within 0..5

*Category:* `arithmetic/bounded-is`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.
```

Domain file:

```prolog
range(n, 0, 5).
```

Convert options: `(defaults: --mode step)`  
Queries: `square(X, Y)`, `square(2, 4)`, `square(3, 8)`

**Output**

```text
network: 9 atoms, 9 hidden (clause) neurons, 12 weighted edges, 1 strata; run: 9 active atoms after 3 rounds, fixpoint reached = true
?- square(X, Y)  =>  [square(0,0),square(1,1),square(2,4)]
?- square(2, 4)  =>  true
?- square(3, 8)  =>  false
verify against source least model: equivalent
```

## 99. Bounded is/2: squares within 0..7

*Category:* `arithmetic/bounded-is`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.
```

Domain file:

```prolog
range(n, 0, 7).
```

Convert options: `(defaults: --mode step)`  
Queries: `square(X, Y)`, `square(2, 4)`, `square(3, 8)`

**Output**

```text
network: 11 atoms, 11 hidden (clause) neurons, 14 weighted edges, 1 strata; run: 11 active atoms after 3 rounds, fixpoint reached = true
?- square(X, Y)  =>  [square(0,0),square(1,1),square(2,4)]
?- square(2, 4)  =>  true
?- square(3, 8)  =>  false
verify against source least model: equivalent
```

## 100. Bounded is/2: squares within 0..9

*Category:* `arithmetic/bounded-is`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.
```

Domain file:

```prolog
range(n, 0, 9).
```

Convert options: `(defaults: --mode step)`  
Queries: `square(X, Y)`, `square(2, 4)`, `square(3, 8)`

**Output**

```text
network: 14 atoms, 14 hidden (clause) neurons, 18 weighted edges, 1 strata; run: 14 active atoms after 3 rounds, fixpoint reached = true
?- square(X, Y)  =>  [square(0,0),square(1,1),square(2,4),square(3,9)]
?- square(2, 4)  =>  true
?- square(3, 8)  =>  false
verify against source least model: equivalent
```

## 101. Bounded is/2: squares within 0..11

*Category:* `arithmetic/bounded-is`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.
```

Domain file:

```prolog
range(n, 0, 11).
```

Convert options: `(defaults: --mode step)`  
Queries: `square(X, Y)`, `square(2, 4)`, `square(3, 8)`

**Output**

```text
network: 16 atoms, 16 hidden (clause) neurons, 20 weighted edges, 1 strata; run: 16 active atoms after 3 rounds, fixpoint reached = true
?- square(X, Y)  =>  [square(0,0),square(1,1),square(2,4),square(3,9)]
?- square(2, 4)  =>  true
?- square(3, 8)  =>  false
verify against source least model: equivalent
```

## 102. Bounded is/2: squares within 0..15

*Category:* `arithmetic/bounded-is`

**Input**

```prolog
num(N) :- N >= 0.
square(N, S) :- num(N), S is N * N.
```

Domain file:

```prolog
range(n, 0, 15).
```

Convert options: `(defaults: --mode step)`  
Queries: `square(X, Y)`, `square(2, 4)`, `square(3, 8)`

**Output**

```text
network: 20 atoms, 20 hidden (clause) neurons, 24 weighted edges, 1 strata; run: 20 active atoms after 3 rounds, fixpoint reached = true
?- square(X, Y)  =>  [square(0,0),square(1,1),square(2,4),square(3,9)]
?- square(2, 4)  =>  true
?- square(3, 8)  =>  false
verify against source least model: equivalent
```

## 103. Integer comparisons: pairs X < Y summing to 6 over 0..6

*Category:* `arithmetic/comparison`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.
```

Domain file:

```prolog
range(n, 0, 6).
```

Convert options: `(defaults: --mode step)`  
Queries: `pair(X, Y)`, `pair(1, 5)`, `pair(3, 3)`

**Output**

```text
network: 10 atoms, 10 hidden (clause) neurons, 16 weighted edges, 1 strata; run: 10 active atoms after 3 rounds, fixpoint reached = true
?- pair(X, Y)  =>  [pair(0,6),pair(1,5),pair(2,4)]
?- pair(1, 5)  =>  true
?- pair(3, 3)  =>  false
verify against source least model: equivalent
```

## 104. Integer comparisons: pairs X < Y summing to 6 over 0..8

*Category:* `arithmetic/comparison`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.
```

Domain file:

```prolog
range(n, 0, 8).
```

Convert options: `(defaults: --mode step)`  
Queries: `pair(X, Y)`, `pair(1, 5)`, `pair(3, 3)`

**Output**

```text
network: 12 atoms, 12 hidden (clause) neurons, 18 weighted edges, 1 strata; run: 12 active atoms after 3 rounds, fixpoint reached = true
?- pair(X, Y)  =>  [pair(0,6),pair(1,5),pair(2,4)]
?- pair(1, 5)  =>  true
?- pair(3, 3)  =>  false
verify against source least model: equivalent
```

## 105. Integer comparisons: pairs X < Y summing to 6 over 0..10

*Category:* `arithmetic/comparison`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.
```

Domain file:

```prolog
range(n, 0, 10).
```

Convert options: `(defaults: --mode step)`  
Queries: `pair(X, Y)`, `pair(1, 5)`, `pair(3, 3)`

**Output**

```text
network: 14 atoms, 14 hidden (clause) neurons, 20 weighted edges, 1 strata; run: 14 active atoms after 3 rounds, fixpoint reached = true
?- pair(X, Y)  =>  [pair(0,6),pair(1,5),pair(2,4)]
?- pair(1, 5)  =>  true
?- pair(3, 3)  =>  false
verify against source least model: equivalent
```

## 106. Integer comparisons: pairs X < Y summing to 6 over 0..12

*Category:* `arithmetic/comparison`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.
```

Domain file:

```prolog
range(n, 0, 12).
```

Convert options: `(defaults: --mode step)`  
Queries: `pair(X, Y)`, `pair(1, 5)`, `pair(3, 3)`

**Output**

```text
network: 16 atoms, 16 hidden (clause) neurons, 22 weighted edges, 1 strata; run: 16 active atoms after 3 rounds, fixpoint reached = true
?- pair(X, Y)  =>  [pair(0,6),pair(1,5),pair(2,4)]
?- pair(1, 5)  =>  true
?- pair(3, 3)  =>  false
verify against source least model: equivalent
```

## 107. Integer comparisons: pairs X < Y summing to 6 over 0..20

*Category:* `arithmetic/comparison`

**Input**

```prolog
pair(X, Y) :- num(X), num(Y), X < Y, S is X + Y, S =:= 6.
num(X) :- X >= 0.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `pair(X, Y)`, `pair(1, 5)`, `pair(3, 3)`

**Output**

```text
network: 24 atoms, 24 hidden (clause) neurons, 30 weighted edges, 1 strata; run: 24 active atoms after 3 rounds, fixpoint reached = true
?- pair(X, Y)  =>  [pair(0,6),pair(1,5),pair(2,4)]
?- pair(1, 5)  =>  true
?- pair(3, 3)  =>  false
verify against source least model: equivalent
```

## 108. Divisibility by 2 over 1..20 using mod

*Category:* `arithmetic/modulo`

**Input**

```prolog
num(X) :- X >= 1.
div2(X) :- num(X), 0 =:= X mod 2.
```

Domain file:

```prolog
range(n, 1, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `div2(X)`, `div2(6)`, `div2(7)`

**Output**

```text
network: 32 atoms, 31 hidden (clause) neurons, 42 weighted edges, 1 strata; run: 30 active atoms after 3 rounds, fixpoint reached = true
?- div2(X)  =>  [div2(2),div2(4),div2(6),div2(8),div2(10),div2(12),div2(14),div2(16),div2(18),div2(20)]
?- div2(6)  =>  true
?- div2(7)  =>  false
verify against source least model: equivalent
```

## 109. Divisibility by 3 over 1..20 using mod

*Category:* `arithmetic/modulo`

**Input**

```prolog
num(X) :- X >= 1.
div3(X) :- num(X), 0 =:= X mod 3.
```

Domain file:

```prolog
range(n, 1, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `div3(X)`, `div3(9)`, `div3(10)`

**Output**

```text
network: 28 atoms, 27 hidden (clause) neurons, 34 weighted edges, 1 strata; run: 26 active atoms after 3 rounds, fixpoint reached = true
?- div3(X)  =>  [div3(3),div3(6),div3(9),div3(12),div3(15),div3(18)]
?- div3(9)  =>  true
?- div3(10)  =>  false
verify against source least model: equivalent
```

## 110. Divisibility by 4 over 1..20 using mod

*Category:* `arithmetic/modulo`

**Input**

```prolog
num(X) :- X >= 1.
div4(X) :- num(X), 0 =:= X mod 4.
```

Domain file:

```prolog
range(n, 1, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `div4(X)`, `div4(12)`, `div4(13)`

**Output**

```text
network: 27 atoms, 26 hidden (clause) neurons, 32 weighted edges, 1 strata; run: 25 active atoms after 3 rounds, fixpoint reached = true
?- div4(X)  =>  [div4(4),div4(8),div4(12),div4(16),div4(20)]
?- div4(12)  =>  true
?- div4(13)  =>  false
verify against source least model: equivalent
```

## 111. Divisibility by 5 over 1..20 using mod

*Category:* `arithmetic/modulo`

**Input**

```prolog
num(X) :- X >= 1.
div5(X) :- num(X), 0 =:= X mod 5.
```

Domain file:

```prolog
range(n, 1, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `div5(X)`, `div5(15)`, `div5(16)`

**Output**

```text
network: 26 atoms, 25 hidden (clause) neurons, 30 weighted edges, 1 strata; run: 24 active atoms after 3 rounds, fixpoint reached = true
?- div5(X)  =>  [div5(5),div5(10),div5(15),div5(20)]
?- div5(15)  =>  true
?- div5(16)  =>  false
verify against source least model: equivalent
```

## 112. Divisibility by 6 over 1..20 using mod

*Category:* `arithmetic/modulo`

**Input**

```prolog
num(X) :- X >= 1.
div6(X) :- num(X), 0 =:= X mod 6.
```

Domain file:

```prolog
range(n, 1, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `div6(X)`, `div6(18)`, `div6(19)`

**Output**

```text
network: 25 atoms, 24 hidden (clause) neurons, 28 weighted edges, 1 strata; run: 23 active atoms after 3 rounds, fixpoint reached = true
?- div6(X)  =>  [div6(6),div6(12),div6(18)]
?- div6(18)  =>  true
?- div6(19)  =>  false
verify against source least model: equivalent
```

## 113. Counting chain with step 1: reachable numbers from 0 within 0..20

*Category:* `arithmetic/chain`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 1.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `count(X)`, `count(4)`, `count(5)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 41 weighted edges, 1 strata; run: 21 active atoms after 22 rounds, fixpoint reached = true
?- count(X)  =>  [count(0),count(1),count(2),count(3),count(4),count(5),count(6),count(7),count(8),count(9),count(10),count(11),count(12),count(13),count(14),count(15),count(16),count(17),count(18),count(19),count(20)]
?- count(4)  =>  true
?- count(5)  =>  true
verify against source least model: equivalent
```

## 114. Counting chain with step 2: reachable numbers from 0 within 0..20

*Category:* `arithmetic/chain`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 2.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `count(X)`, `count(8)`, `count(9)`

**Output**

```text
network: 21 atoms, 20 hidden (clause) neurons, 39 weighted edges, 1 strata; run: 11 active atoms after 12 rounds, fixpoint reached = true
?- count(X)  =>  [count(0),count(2),count(4),count(6),count(8),count(10),count(12),count(14),count(16),count(18),count(20)]
?- count(8)  =>  true
?- count(9)  =>  false
verify against source least model: equivalent
```

## 115. Counting chain with step 3: reachable numbers from 0 within 0..20

*Category:* `arithmetic/chain`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 3.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `count(X)`, `count(12)`, `count(13)`

**Output**

```text
network: 21 atoms, 19 hidden (clause) neurons, 37 weighted edges, 1 strata; run: 7 active atoms after 8 rounds, fixpoint reached = true
?- count(X)  =>  [count(0),count(3),count(6),count(9),count(12),count(15),count(18)]
?- count(12)  =>  true
?- count(13)  =>  false
verify against source least model: equivalent
```

## 116. Counting chain with step 4: reachable numbers from 0 within 0..20

*Category:* `arithmetic/chain`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 4.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `count(X)`, `count(16)`, `count(17)`

**Output**

```text
network: 21 atoms, 18 hidden (clause) neurons, 35 weighted edges, 1 strata; run: 6 active atoms after 7 rounds, fixpoint reached = true
?- count(X)  =>  [count(0),count(4),count(8),count(12),count(16),count(20)]
?- count(16)  =>  true
?- count(17)  =>  false
verify against source least model: equivalent
```

## 117. Counting chain with step 5: reachable numbers from 0 within 0..20

*Category:* `arithmetic/chain`

**Input**

```prolog
count(0).
count(N) :- count(M), N is M + 5.
```

Domain file:

```prolog
range(n, 0, 20).
```

Convert options: `(defaults: --mode step)`  
Queries: `count(X)`, `count(20)`, `count(21)`

**Output**

```text
network: 21 atoms, 17 hidden (clause) neurons, 33 weighted edges, 1 strata; run: 5 active atoms after 6 rounds, fixpoint reached = true
?- count(X)  =>  [count(0),count(5),count(10),count(15),count(20)]
?- count(20)  =>  true
?- count(21)  =>  false
verify against source least model: equivalent
```

## 118. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(bob, gold).
likes(hal, gold).
likes(fay, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [bob, hal, fay, cy]).
domain(colour, [green, gold, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(cy, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(gold),liked(green)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(cy, C)  =>  []
verify against source least model: equivalent
```

## 119. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(fay, red).
likes(cy, blue).
likes(bob, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [fay, cy, bob, jo]).
domain(colour, [blue, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(jo, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(blue),liked(red)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(jo, C)  =>  []
verify against source least model: equivalent
```

## 120. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(jo, gold).
likes(fay, green).
likes(gus, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [jo, fay, gus, bob]).
domain(colour, [gold, green, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(bob, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(gold),liked(green)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(bob, C)  =>  []
verify against source least model: equivalent
```

## 121. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(eli, green).
likes(gus, green).
likes(cy, green).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [eli, gus, cy, fay]).
domain(colour, [green, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(fay, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(green)]
?- unliked(C)  =>  [unliked(purple),unliked(red)]
?- likes(fay, C)  =>  []
verify against source least model: equivalent
```

## 122. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(eli, red).
likes(fay, red).
likes(ivy, red).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [eli, fay, ivy, gus]).
domain(colour, [red, gold, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(gus, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(red)]
?- unliked(C)  =>  [unliked(gold),unliked(purple)]
?- likes(gus, C)  =>  []
verify against source least model: equivalent
```

## 123. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(ann, blue).
likes(hal, gold).
likes(eli, blue).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [ann, hal, eli, dee]).
domain(colour, [blue, gold, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(dee, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(blue),liked(gold)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(dee, C)  =>  []
verify against source least model: equivalent
```

## 124. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(gus, gold).
likes(eli, gold).
likes(cy, gold).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [gus, eli, cy, ivy]).
domain(colour, [gold, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(ivy, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(gold)]
?- unliked(C)  =>  [unliked(purple),unliked(red)]
?- likes(ivy, C)  =>  []
verify against source least model: equivalent
```

## 125. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(ivy, red).
likes(ann, green).
likes(gus, red).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [ivy, ann, gus, jo]).
domain(colour, [green, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(jo, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(green),liked(red)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(jo, C)  =>  []
verify against source least model: equivalent
```

## 126. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(ivy, gold).
likes(dee, gold).
likes(jo, red).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [ivy, dee, jo, bob]).
domain(colour, [gold, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(bob, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(gold),liked(red)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(bob, C)  =>  []
verify against source least model: equivalent
```

## 127. Typed finite domains restrict variable grounding

*Category:* `domains/typed`

**Input**

```prolog
likes(fay, gold).
likes(gus, gold).
likes(bob, red).

unliked(C) :- colour(C), \+ liked(C).
liked(C) :- likes(_, C).
colour(C) :- C = C.
```

Domain file:

```prolog
domain(person, [fay, gus, bob, ivy]).
domain(colour, [gold, red, purple]).
type(likes/2, 1, person).
type(likes/2, 2, colour).
type(liked/1, 1, colour).
type(unliked/1, 1, colour).
type(colour/1, 1, colour).
```

Convert options: `(defaults: --mode step)`  
Queries: `liked(C)`, `unliked(C)`, `likes(ivy, C)`

**Output**

```text
network: 21 atoms, 21 hidden (clause) neurons, 39 weighted edges, 2 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- liked(C)  =>  [liked(gold),liked(red)]
?- unliked(C)  =>  [unliked(purple)]
?- likes(ivy, C)  =>  []
verify against source least model: equivalent
```

## 128. Peano-style successor terms with --term-depth 1

*Category:* `terms/bounded-depth`

**Input**

```prolog
nat(z).
nat(s(X)) :- nat(X).
```

Convert options: `--term-depth 1`  
Queries: `nat(X)`, `nat(s(s(z)))`

**Output**

```text
network: 2 atoms, 2 hidden (clause) neurons, 3 weighted edges, 1 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- nat(X)  =>  [nat(z),nat(s(z))]
?- nat(s(s(z)))  =>  false
verify against source least model: equivalent
```

## 129. Peano-style successor terms with --term-depth 2

*Category:* `terms/bounded-depth`

**Input**

```prolog
nat(z).
nat(s(X)) :- nat(X).
```

Convert options: `--term-depth 2`  
Queries: `nat(X)`, `nat(s(s(z)))`

**Output**

```text
network: 3 atoms, 3 hidden (clause) neurons, 5 weighted edges, 1 strata; run: 3 active atoms after 4 rounds, fixpoint reached = true
?- nat(X)  =>  [nat(z),nat(s(z)),nat(s(s(z)))]
?- nat(s(s(z)))  =>  true
verify against source least model: equivalent
```

## 130. Peano-style successor terms with --term-depth 3

*Category:* `terms/bounded-depth`

**Input**

```prolog
nat(z).
nat(s(X)) :- nat(X).
```

Convert options: `--term-depth 3`  
Queries: `nat(X)`, `nat(s(s(z)))`

**Output**

```text
network: 4 atoms, 4 hidden (clause) neurons, 7 weighted edges, 1 strata; run: 4 active atoms after 5 rounds, fixpoint reached = true
?- nat(X)  =>  [nat(z),nat(s(z)),nat(s(s(z))),nat(s(s(s(z))))]
?- nat(s(s(z)))  =>  true
verify against source least model: equivalent
```

## 131. Wrapped values f(...) with depth 1

*Category:* `terms/bounded-depth`

**Input**

```prolog
p(a).
p(f(X)) :- p(X).
```

Convert options: `--term-depth 1`  
Queries: `p(X)`, `p(f(f(f(a))))`

**Output**

```text
network: 2 atoms, 2 hidden (clause) neurons, 3 weighted edges, 1 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- p(X)  =>  [p(a),p(f(a))]
?- p(f(f(f(a))))  =>  false
verify against source least model: equivalent
```

## 132. Wrapped values f(...) with depth 2

*Category:* `terms/bounded-depth`

**Input**

```prolog
p(a).
p(f(X)) :- p(X).
```

Convert options: `--term-depth 2`  
Queries: `p(X)`, `p(f(f(f(a))))`

**Output**

```text
network: 3 atoms, 3 hidden (clause) neurons, 5 weighted edges, 1 strata; run: 3 active atoms after 4 rounds, fixpoint reached = true
?- p(X)  =>  [p(a),p(f(a)),p(f(f(a)))]
?- p(f(f(f(a))))  =>  false
verify against source least model: equivalent
```

## 133. Wrapped values f(...) with depth 3

*Category:* `terms/bounded-depth`

**Input**

```prolog
p(a).
p(f(X)) :- p(X).
```

Convert options: `--term-depth 3`  
Queries: `p(X)`, `p(f(f(f(a))))`

**Output**

```text
network: 4 atoms, 4 hidden (clause) neurons, 7 weighted edges, 1 strata; run: 4 active atoms after 5 rounds, fixpoint reached = true
?- p(X)  =>  [p(a),p(f(a)),p(f(f(a))),p(f(f(f(a))))]
?- p(f(f(f(a))))  =>  true
verify against source least model: equivalent
```

## 134. Bounded list membership with --term-depth 2

*Category:* `terms/lists`

**Input**

```prolog
item(a).
item(b).
lst([]).
lst([H|T]) :- item(H), lst(T).
```

Convert options: `--term-depth 2`  
Queries: `lst([a])`, `lst([a, b])`, `lst([b, a, b])`

**Output**

```text
network: 159 atoms, 147 hidden (clause) neurons, 435 weighted edges, 1 strata; run: 9 active atoms after 4 rounds, fixpoint reached = true
?- lst([a])  =>  true
?- lst([a, b])  =>  true
?- lst([b, a, b])  =>  false
verify against source least model: equivalent
```

## 135. Depth-3 list generation exceeds --term-limit 500

*Category:* `terms/lists`

**Input**

```prolog
item(a).
item(b).
lst([]).
lst([H|T]) :- item(H), lst(T).
```

Convert options: `--term-depth 3 --term-limit 500`  
Queries: `lst([b, a, b])`

**Output**

```text
error: term_generation_limit(21612,500)
```

## 136. Explicit compound domain values; constants nested inside them do not enter the untyped universe, so leaf/1 is empty

*Category:* `terms/explicit-domain`

**Input**

```prolog
item(X) :- X = X.
leaf(Y) :- item(node(Y)).
```

Domain file:

```prolog
domain(term, [node(a), node(b), [a, b]]).
type(item/1, 1, term).
type(boxed/1, 1, term).
```

Convert options: `--term-depth 2`  
Queries: `item(X)`, `leaf(Y)`

**Output**

```text
network: 7 atoms, 5 hidden (clause) neurons, 7 weighted edges, 1 strata; run: 3 active atoms after 2 rounds, fixpoint reached = true
?- item(X)  =>  [item(node(a)),item(node(b)),item([a,b])]
?- leaf(Y)  =>  []
verify against source least model: equivalent
```

## 137. Fact deeper than the configured term depth is rejected

*Category:* `terms/depth-overflow`

**Input**

```prolog
p(f(f(a))).
```

Convert options: `--term-depth 1`  
Queries: `p(X)`

**Output**

```text
error: term_depth_exceeded(2,1) at line 1
```

## 138. ancestor example in sigmoid mode

*Category:* `modes/activation`

**Input**

```prolog
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `ancestor(ann, X)`, `ancestor(dee, ann)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(ann, X)  =>  [ancestor(ann,bob),ancestor(ann,cy),ancestor(ann,dee)]
?- ancestor(dee, ann)  =>  false
verify against source least model: equivalent
```

## 139. ancestor example in tanh mode

*Category:* `modes/activation`

**Input**

```prolog
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `--mode tanh`  
Queries: `ancestor(ann, X)`, `ancestor(dee, ann)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 9 active atoms after 5 rounds, fixpoint reached = true
?- ancestor(ann, X)  =>  [ancestor(ann,bob),ancestor(ann,cy),ancestor(ann,dee)]
?- ancestor(dee, ann)  =>  false
verify against source least model: equivalent
```

## 140. ancestor example in step with --step-limit 1 mode

*Category:* `modes/activation`

**Input**

```prolog
parent(ann, bob).
parent(bob, cy).
parent(cy, dee).
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
```

Convert options: `--step-limit 1`  
Queries: `ancestor(ann, X)`, `ancestor(dee, ann)`

**Output**

```text
network: 32 atoms, 83 hidden (clause) neurons, 227 weighted edges, 1 strata; run: 3 active atoms after 1 rounds, fixpoint reached = false
?- ancestor(ann, X)  =>  error: error(no_fixpoint(1),_58120)
?- ancestor(dee, ann)  =>  error: error(no_fixpoint(1),_72462)
verify against source least model: equivalent
```

## 141. reach-cycle example in sigmoid mode

*Category:* `modes/activation`

**Input**

```prolog
edge(a, b).
edge(b, c).
edge(c, a).
reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `reach(a, X)`, `reach(b, b)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 12 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c)]
?- reach(b, b)  =>  true
verify against source least model: equivalent
```

## 142. reach-cycle example in tanh mode

*Category:* `modes/activation`

**Input**

```prolog
edge(a, b).
edge(b, c).
edge(c, a).
reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `--mode tanh`  
Queries: `reach(a, X)`, `reach(b, b)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 12 active atoms after 5 rounds, fixpoint reached = true
?- reach(a, X)  =>  [reach(a,a),reach(a,b),reach(a,c)]
?- reach(b, b)  =>  true
verify against source least model: equivalent
```

## 143. reach-cycle example in step with --step-limit 1 mode

*Category:* `modes/activation`

**Input**

```prolog
edge(a, b).
edge(b, c).
edge(c, a).
reach(X, Y) :- edge(X, Y).
reach(X, Y) :- edge(X, Z), reach(Z, Y).
```

Convert options: `--step-limit 1`  
Queries: `reach(a, X)`, `reach(b, b)`

**Output**

```text
network: 18 atoms, 39 hidden (clause) neurons, 102 weighted edges, 1 strata; run: 3 active atoms after 1 rounds, fixpoint reached = false
?- reach(a, X)  =>  error: error(no_fixpoint(1),_28520)
?- reach(b, b)  =>  error: error(no_fixpoint(1),_35872)
verify against source least model: equivalent
```

## 144. flies example in sigmoid mode

*Category:* `modes/activation`

**Input**

```prolog
bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).
flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `flies(X)`, `flies(pingu)`

**Output**

```text
network: 9 atoms, 7 hidden (clause) neurons, 13 weighted edges, 2 strata; run: 6 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(polly),flies(tweety)]
?- flies(pingu)  =>  false
verify against source least model: equivalent
```

## 145. flies example in tanh mode

*Category:* `modes/activation`

**Input**

```prolog
bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).
flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `--mode tanh`  
Queries: `flies(X)`, `flies(pingu)`

**Output**

```text
network: 9 atoms, 7 hidden (clause) neurons, 13 weighted edges, 2 strata; run: 6 active atoms after 4 rounds, fixpoint reached = true
?- flies(X)  =>  [flies(polly),flies(tweety)]
?- flies(pingu)  =>  false
verify against source least model: equivalent
```

## 146. flies example in step with --step-limit 1 mode

*Category:* `modes/activation`

**Input**

```prolog
bird(tweety).
bird(polly).
bird(pingu).
penguin(pingu).
flies(X) :- bird(X), \+ penguin(X).
```

Convert options: `--step-limit 1`  
Queries: `flies(X)`, `flies(pingu)`

**Output**

```text
network: 9 atoms, 7 hidden (clause) neurons, 13 weighted edges, 2 strata; run: 4 active atoms after 1 rounds, fixpoint reached = false
?- flies(X)  =>  error: error(no_fixpoint(1),_7604)
?- flies(pingu)  =>  error: error(no_fixpoint(1),_9994)
verify against source least model: equivalent
```

## 147. disjunction example in sigmoid mode

*Category:* `modes/activation`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).
```

Convert options: `--mode sigmoid --weight auto`  
Queries: `ab(X)`, `ab(3)`

**Output**

```text
network: 10 atoms, 9 hidden (clause) neurons, 15 weighted edges, 1 strata; run: 5 active atoms after 3 rounds, fixpoint reached = true
?- ab(X)  =>  [ab(1),ab(2)]
?- ab(3)  =>  false
verify against source least model: equivalent
```

## 148. disjunction example in tanh mode

*Category:* `modes/activation`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).
```

Convert options: `--mode tanh`  
Queries: `ab(X)`, `ab(3)`

**Output**

```text
network: 10 atoms, 9 hidden (clause) neurons, 15 weighted edges, 1 strata; run: 5 active atoms after 3 rounds, fixpoint reached = true
?- ab(X)  =>  [ab(1),ab(2)]
?- ab(3)  =>  false
verify against source least model: equivalent
```

## 149. disjunction example in step with --step-limit 1 mode

*Category:* `modes/activation`

**Input**

```prolog
a(1).
b(2).
c(3).
ab(X) :- ( a(X) ; b(X) ).
```

Convert options: `--step-limit 1`  
Queries: `ab(X)`, `ab(3)`

**Output**

```text
network: 10 atoms, 9 hidden (clause) neurons, 15 weighted edges, 1 strata; run: 3 active atoms after 1 rounds, fixpoint reached = false
?- ab(X)  =>  error: error(no_fixpoint(1),_8308)
?- ab(3)  =>  error: error(no_fixpoint(1),_10872)
verify against source least model: equivalent
```

## 150. Rejects unsupported construct: cut

*Category:* `errors/rejection`

**Input**

```prolog
keep_first([X|_], X) :- !.
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(!) at line 1
```

## 151. Rejects unsupported construct: assert

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- assertz(q(X)).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(assert) at line 1
```

## 152. Rejects unsupported construct: retract

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- retract(q(X)).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(retract) at line 1
```

## 153. Rejects unsupported construct: findall

*Category:* `errors/rejection`

**Input**

```prolog
p(Xs) :- findall(Y, q(Y), Xs).
q(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(findall) at line 1
```

## 154. Rejects unsupported construct: I/O

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- write(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(io) at line 1
```

## 155. Rejects unsupported construct: if-then

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- ( q(X) -> r(X) ).
q(1).
r(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(conditional) at line 1
```

## 156. Rejects unsupported construct: soft-cut

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- ( q(X) *-> r(X) ).
q(1).
r(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(conditional) at line 1
```

## 157. Rejects unsupported construct: meta-call

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- call(q(X)).
q(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(meta_call) at line 1
```

## 158. Rejects unsupported construct: negated conjunction

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- q(X), \+ (r(X), s(X)).
q(1).
r(1).
s(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(negated_compound_goal) at line 1
```

## 159. Rejects non-stratified win (non-stratified negation)

*Category:* `errors/rejection`

**Input**

```prolog
move(a, b).
move(b, a).
win(X) :- move(X, Y), \+ win(Y).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: non_stratified_negation([win/1]) at line 3
```

## 160. Rejects negative self-loop (non-stratified negation)

*Category:* `errors/rejection`

**Input**

```prolog
p :- \+ p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: non_stratified_negation([p/0]) at line 1
```

## 161. Rejects negative mutual cycle (non-stratified negation)

*Category:* `errors/rejection`

**Input**

```prolog
a(1).
p(X) :- a(X), \+ q(X).
q(X) :- a(X), \+ p(X).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: non_stratified_negation([p/1,q/1]) at line 2
```

## 162. Rejects unsupported construct: unsupported arithmetic

*Category:* `errors/rejection`

**Input**

```prolog
p(X) :- num(X), Y is sqrt(X), Y > 1.
num(4).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(_620 is sqrt(_626)) at line 1
```

## 163. Rejects unsupported construct: assert on line 3 (error reports the line)

*Category:* `errors/rejection`

**Input**

```prolog
ok(a).
ok(b).
p(X) :- ok(X), assertz(seen(X)).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(assert) at line 3
```

## 164. Rejects unsupported construct: bagof

*Category:* `errors/rejection`

**Input**

```prolog
p(L) :- bagof(X, q(X), L).
q(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(bagof) at line 1
```

## 165. Rejects unsupported construct: format I/O

*Category:* `errors/rejection`

**Input**

```prolog
hello :- format("hi~n").
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(io) at line 1
```

## 166. Rejects unsupported construct: nb_setval

*Category:* `errors/rejection`

**Input**

```prolog
p :- nb_setval(k, 1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(nb_setval(k,1)) at line 1
```

## 167. Rejects unsupported construct: setof

*Category:* `errors/rejection`

**Input**

```prolog
p(L) :- setof(X, q(X), L).
q(2).
q(1).
```

Convert options: `(defaults: --mode step)`  
Queries: `p(X)`

**Output**

```text
error: unsupported_construct(setof) at line 1
```

## 168. Herbrand base exceeds --limit 5

*Category:* `errors/limits`

**Input**

```prolog
n(1).
n(2).
n(3).
pair(X, Y) :- n(X), n(Y).
```

Convert options: `--limit 5`  
Queries: `pair(X, Y)`

**Output**

```text
error: herbrand_base_limit(12,5)
```

## 169. Sigmoid weight below the derived bound is rejected

*Category:* `errors/limits`

**Input**

```prolog
a.
b :- a.
```

Convert options: `--mode sigmoid --weight 0.1`  
Queries: `b`

**Output**

```text
error: weight_below_bound(0.1,2.1972245773362196)
```

## 170. Tanh weight must be positive

*Category:* `errors/limits`

**Input**

```prolog
a.
b :- a.
```

Convert options: `--mode tanh --weight 0`  
Queries: `b`

**Output**

```text
error: domain_error(positive_weight,0)
```

## 171. Unknown mode is rejected

*Category:* `errors/limits`

**Input**

```prolog
a.
```

Convert options: `--mode relu`  
Queries: `a`

**Output**

```text
error: unsupported_mode(relu)
```

## 172. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
s.
v.
t :- v, \+ s.
w :- t, v.
u :- v, \+ s.
```

Convert options: `(defaults: --mode step)`  
Queries: `s`, `t`, `u`, `v`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 11 weighted edges, 2 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- s  =>  true
?- t  =>  false
?- u  =>  false
?- v  =>  true
?- w  =>  false
verify against source least model: equivalent
```

## 173. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
r.
s.
w :- u.
w :- t.
t :- s, w.
u :- r.
u :- t.
```

Convert options: `(defaults: --mode step)`  
Queries: `r`, `s`, `t`, `u`, `w`

**Output**

```text
network: 5 atoms, 7 hidden (clause) neurons, 13 weighted edges, 1 strata; run: 5 active atoms after 5 rounds, fixpoint reached = true
?- r  =>  true
?- s  =>  true
?- t  =>  true
?- u  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 174. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
v.
u.
s :- u, v.
q :- u, v.
r :- s, \+ v.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `u`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 11 weighted edges, 2 strata; run: 4 active atoms after 4 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  false
?- s  =>  true
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 175. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
t.
p.
s :- t.
s :- q.
q :- p.
q :- t.
u :- s, q.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 7 hidden (clause) neurons, 13 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- s  =>  true
?- t  =>  true
?- u  =>  true
verify against source least model: equivalent
```

## 176. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
p.
u.
w :- p.
q :- u, p.
s :- \+ p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `s`, `u`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 2 strata; run: 4 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- s  =>  false
?- u  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 177. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
w.
v.
p :- u, w.
s :- p.
u :- s.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `s`, `u`, `v`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 1 strata; run: 2 active atoms after 2 rounds, fixpoint reached = true
?- p  =>  false
?- s  =>  false
?- u  =>  false
?- v  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 178. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
p.
t.
r :- \+ t.
u :- \+ p.
s :- u, p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `r`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 2 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- p  =>  true
?- r  =>  false
?- s  =>  false
?- t  =>  true
?- u  =>  false
verify against source least model: equivalent
```

## 179. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
q.
s.
t :- s, q.
t :- s.
v :- q, s.
p :- v.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `s`, `t`, `v`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 12 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- s  =>  true
?- t  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 180. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
s.
q.
u :- s.
t :- \+ s.
r :- q, \+ t.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 3 strata; run: 4 active atoms after 6 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  true
?- s  =>  true
?- t  =>  false
?- u  =>  true
verify against source least model: equivalent
```

## 181. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
w.
p.
u :- s, v.
s :- w, u.
s :- v.
v :- w, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `s`, `u`, `v`, `w`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 13 weighted edges, 1 strata; run: 2 active atoms after 2 rounds, fixpoint reached = true
?- p  =>  true
?- s  =>  false
?- u  =>  false
?- v  =>  false
?- w  =>  true
verify against source least model: equivalent
```

## 182. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
t.
p.
r :- t, \+ p.
u :- t.
s :- t, \+ p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `r`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 10 weighted edges, 2 strata; run: 3 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- r  =>  false
?- s  =>  false
?- t  =>  true
?- u  =>  true
verify against source least model: equivalent
```

## 183. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
t.
q.
w :- t.
u :- r.
r :- t, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `t`, `u`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 1 strata; run: 3 active atoms after 3 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  false
?- t  =>  true
?- u  =>  false
?- w  =>  true
verify against source least model: equivalent
```

## 184. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
r.
s.
t :- \+ r.
w :- t, s.
q :- \+ w.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `t`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 3 strata; run: 3 active atoms after 5 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  true
?- s  =>  true
?- t  =>  false
?- w  =>  false
verify against source least model: equivalent
```

## 185. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
v.
q.
s :- t.
t :- s.
u :- t.
u :- q.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `s`, `t`, `u`, `v`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 10 weighted edges, 1 strata; run: 3 active atoms after 3 rounds, fixpoint reached = true
?- q  =>  true
?- s  =>  false
?- t  =>  false
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 186. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
u.
p.
q :- \+ p.
r :- \+ u.
v :- p, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `r`, `u`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 2 strata; run: 3 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  false
?- r  =>  false
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 187. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
v.
q.
u :- v.
p :- v.
p :- v.
r :- v, p.
r :- p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `r`, `u`, `v`

**Output**

```text
network: 5 atoms, 7 hidden (clause) neurons, 13 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- r  =>  true
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 188. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
u.
r.
v :- \+ r.
t :- v.
s :- u, \+ v.
```

Convert options: `(defaults: --mode step)`  
Queries: `r`, `s`, `t`, `u`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 3 strata; run: 3 active atoms after 5 rounds, fixpoint reached = true
?- r  =>  true
?- s  =>  true
?- t  =>  false
?- u  =>  true
?- v  =>  false
verify against source least model: equivalent
```

## 189. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
p.
q.
v :- u, w.
v :- u.
u :- v, q.
u :- v.
w :- q, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `u`, `v`, `w`

**Output**

```text
network: 5 atoms, 7 hidden (clause) neurons, 15 weighted edges, 1 strata; run: 2 active atoms after 2 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- u  =>  false
?- v  =>  false
?- w  =>  false
verify against source least model: equivalent
```

## 190. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
t.
v.
r :- t.
p :- v, \+ r.
s :- \+ v.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `r`, `s`, `t`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 2 strata; run: 3 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  false
?- r  =>  true
?- s  =>  false
?- t  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 191. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
s.
t.
q :- r, t.
r :- t, q.
u :- s.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 10 weighted edges, 1 strata; run: 3 active atoms after 3 rounds, fixpoint reached = true
?- q  =>  false
?- r  =>  false
?- s  =>  true
?- t  =>  true
?- u  =>  true
verify against source least model: equivalent
```

## 192. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
t.
r.
q :- t.
s :- q, r.
u :- t.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `t`, `u`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  true
?- s  =>  true
?- t  =>  true
?- u  =>  true
verify against source least model: equivalent
```

## 193. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
r.
p.
q :- u, r.
v :- p.
u :- p.
u :- v.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `r`, `u`, `v`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 11 weighted edges, 1 strata; run: 5 active atoms after 4 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- r  =>  true
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 194. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
v.
q.
r :- q, \+ v.
s :- r.
w :- q, s.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `r`, `s`, `v`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 10 weighted edges, 2 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- q  =>  true
?- r  =>  false
?- s  =>  false
?- v  =>  true
?- w  =>  false
verify against source least model: equivalent
```

## 195. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
u.
w.
t :- u, w.
p :- r, t.
r :- t, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `r`, `t`, `u`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 11 weighted edges, 1 strata; run: 5 active atoms after 5 rounds, fixpoint reached = true
?- p  =>  true
?- r  =>  true
?- t  =>  true
?- u  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 196. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
t.
q.
s :- \+ t.
u :- \+ q.
v :- u, \+ s.
```

Convert options: `(defaults: --mode step)`  
Queries: `q`, `s`, `t`, `u`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 3 strata; run: 2 active atoms after 4 rounds, fixpoint reached = true
?- q  =>  true
?- s  =>  false
?- t  =>  true
?- u  =>  false
?- v  =>  false
verify against source least model: equivalent
```

## 197. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
u.
s.
r :- v.
p :- u.
v :- s, p.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `r`, `s`, `u`, `v`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 9 weighted edges, 1 strata; run: 5 active atoms after 5 rounds, fixpoint reached = true
?- p  =>  true
?- r  =>  true
?- s  =>  true
?- u  =>  true
?- v  =>  true
verify against source least model: equivalent
```

## 198. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
s.
u.
q :- \+ u.
w :- u, \+ q.
p :- q, w.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `s`, `u`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 10 weighted edges, 3 strata; run: 3 active atoms after 5 rounds, fixpoint reached = true
?- p  =>  false
?- q  =>  false
?- s  =>  true
?- u  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 199. Propositional program with positive (possibly cyclic) rules

*Category:* `propositional/random`

**Input**

```prolog
u.
p.
w :- s, q.
s :- u, p.
s :- p.
q :- p, s.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `q`, `s`, `u`, `w`

**Output**

```text
network: 5 atoms, 6 hidden (clause) neurons, 13 weighted edges, 1 strata; run: 5 active atoms after 5 rounds, fixpoint reached = true
?- p  =>  true
?- q  =>  true
?- s  =>  true
?- u  =>  true
?- w  =>  true
verify against source least model: equivalent
```

## 200. Propositional program with stratified negation

*Category:* `propositional/random`

**Input**

```prolog
u.
t.
w :- u, \+ t.
p :- \+ t.
s :- w, u.
```

Convert options: `(defaults: --mode step)`  
Queries: `p`, `s`, `t`, `u`, `w`

**Output**

```text
network: 5 atoms, 5 hidden (clause) neurons, 10 weighted edges, 2 strata; run: 2 active atoms after 3 rounds, fixpoint reached = true
?- p  =>  false
?- s  =>  false
?- t  =>  true
?- u  =>  true
?- w  =>  false
verify against source least model: equivalent
```

