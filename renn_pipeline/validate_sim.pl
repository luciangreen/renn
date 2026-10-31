/*  validate_sim.pl -- check the weights-only simulator against the dataset: the rebuilt network
    sizes, and every query answer.

    swipl validate_sim.pl */
:- use_module(config).
:- use_module(netlib).

:- initialization(main, main).

main :-
    path(exp, Exp), atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    include([P]>>get_dict(error, P, null), Pairs, Ok), length(Ok, NOk),
    foldl(check(Exp), Ok, s(0, 0, 0, []), s(SizeOk, AnsOk, AnsN, Bad)),
    format("network sizes reproduced: ~w/~w~n", [SizeOk, NOk]),
    format("query literals reproduced by weights-only simulator: ~w/~w~n", [AnsOk, AnsN]),
    reverse(Bad, B1), length(B1, NB), ( NB > 15 -> length(B15, 15), append(B15, _, B1) ; B15 = B1 ),
    print(B15), nl.

check(Exp, P, s(S0, A0, N0, B0), s(S, A, N, B)) :-
    get_dict(id, P, Id), format(atom(F), '~w/nets/~w/net.json', [Exp, Id]),
    net_load(F, Net),
    net_atoms(Net, Atoms), length(Atoms, NA), net_hidden(Net, Hs), length(Hs, NH), net_edge_count(Net, NE),
    Nw = P.network,
    (   number_string(NA, Nw.atoms), number_string(NH, Nw.hidden), number_string(NE, Nw.edges)
    ->  S is S0 + 1, B1 = B0
    ;   S = S0, B1 = [Id-size(NA, NH, NE)|B0]
    ),
    (   Nw.fixpoint \== "true" -> A = A0, N = N0, B = B1
    ;   net_true_input(Net, In), forward(Net, In, Model),
        observation_from_queries(Net, P.queries, Obs),
        foldl({Model, Id}/[At-V, a(X0, Y0, Z0), a(X, Y, Z)]>>(
                  Y is Y0 + 1,
                  ( ( memberchk(At, Model) -> V == true ; V == false ) -> X is X0 + 1, Z = Z0
                  ; X = X0, Z = [Id-At-V|Z0] ) ),
              Obs, a(A0, N0, B1), a(A, N, B))
    ),
    net_unload(Net).
