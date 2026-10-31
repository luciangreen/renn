/*  compose.pl -- combining nets: two separately compiled networks are joined by wiring the outputs of
    one into the matching inputs of the other (shared atom neurons). The method then runs on the
    combined net only: prove the combined net equals the union program, find the input from the end
    output, and let Popper learn the end-to-end algorithm, which neither net contains on its own.
    Writes <RESULTS_DIR>/compose.json.     swipl compose.pl */
:- if(exists_source(library(json))).
:- use_module(library(json)).
:- else.
:- use_module(library(http/json)).
:- endif.
:- use_module(config).
:- use_module(netlib).
:- use_module(invert).
:- use_module(pipeline).

:- initialization(main, main).

dom("domain(c, [a,b,c,d,x,y,z,ok]).\n").
prog_a("f(a,b). f(b,c). f(c,d).\ng(b,x). g(c,y). g(d,z).\nt2(X,Z) :- f(X,Y), g(Y,Z).\n").
prog_b("h(x,ok). h(z,ok).\nr(X,W) :- t2(X,Z), h(Z,W).\n").

% hidden(K) becomes hidden(<Tag>K), so the two networks' hidden units stay apart; atom neurons
% with the same name are shared
ren_id(Tag, Id, New) :-
    ( sub_string(Id, 0, 7, _, "hidden(") -> sub_string(Id, 7, _, 1, K), format(string(New), "hidden(~w~w)", [Tag, K]) ; New = Id ).

merge(JA, JB, OutJson, OutPl, Module) :-
    json_file(JA, A), json_file(JB, B),
    ren(A, "1000", NA, EA), ren(B, "2000", NB, EB),
    append(NA, NB, NAll), foldl(add_neuron, NAll, []-t, Ids-Map),
    reverse(Ids, IdOrder), findall(N, ( member(I, IdOrder), get_assoc(I, Map, N) ), Neurons),
    append(A.atoms, B.atoms, As0), sort(As0, Atoms),
    findall(F-T, ( member(R, A.recurrent) ; member(R, B.recurrent) ), _),
    findall(F-T, ( ( member(R, A.recurrent) ; member(R, B.recurrent) ), get_dict(from, R, F), get_dict(to, R, T) ), Rs0),
    sort(Rs0, Rs), findall(_{from:F, to:T}, member(F-T, Rs), Rec),
    append(EA, EB, Edges),
    Merged = _{mode:"step", atoms:Atoms, neurons:Neurons, edges:Edges, recurrent:Rec, traces:[]},
    write_json(OutJson, Merged),
    setup_call_cleanup(open(OutPl, write, S),
        ( format(S, ":- module(~w, [neuron/4, edge/3, recurrent/2]).~n", [Module]),
          forall(member(N, Neurons), format(S, "neuron(~w,~w,~w,~w).~n", [N.id, N.layer, N.activation, N.threshold])),
          forall(member(E, Edges), format(S, "edge(~w,~w,~w).~n", [E.from, E.to, E.weight])),
          forall(member(R, Rec), format(S, "recurrent(~w,~w).~n", [R.from, R.to])) ),
        close(S)).

ren(D, Tag, Ns, Es) :-
    findall(N1, ( member(N, D.neurons), ren_id(Tag, N.id, I), N1 = N.put(id, I) ), Ns),
    findall(E1, ( member(E, D.edges), ren_id(Tag, E.from, F), ren_id(Tag, E.to, T), E1 = E.put(_{from:F, to:T}) ), Es).

% first appearance fixes the position; a later neuron with the same id replaces the earlier one
add_neuron(N, Ids0-M0, Ids-M) :-
    get_dict(id, N, I), ( get_assoc(I, M0, _) -> Ids = Ids0 ; Ids = [I|Ids0] ), put_assoc(I, M0, N, M).

main :-
    path(results, R), ensure_dir(R), path(work, W),
    dom(Dom), prog_a(A), prog_b(B),
    compile_net(compose_A, A, Dom, [], DA-NetA), compile_net(compose_B, B, Dom, [], DB-NetB),
    format(atom(D), '~w/compose_AB', [W]), ensure_dir(D),
    format(atom(JA), '~w/net.json', [DA]), format(atom(JB), '~w/net.json', [DB]),
    format(atom(J), '~w/net.json', [D]), format(atom(Pl), '~w/net.pl', [D]),
    merge(JA, JB, J, Pl, n_compose_ab),
    format(atom(Src), '~w/src.pl', [D]), string_concat(A, B, AB), write_text(Src, AB),
    net_load(J, Net),
    info(NetA, IA), info(NetB, IB), info(Net, IC),
    net_matches_program(D, Match),
    full_obs(Net, [r/2], Obs, _), net_true_input(Net, True), report(Net, Obs, True, 50, Inv),
    invert(Net, Obs, [cap(1)], I1), get_dict(explanations, I1, [Inp|_]),
    net_reproduces(D, Inp, Obs, Proof),
    maplist(show, Inp, InpS), findall(S, ( member(X-true, Obs), show(X, S) ), OT0), msort(OT0, OT),
    Res0 = _{net_A:IA, net_B:IB, combined:IC, combined_matches_union_program:Match,
             inverse:_{observed_true:OT, recovered:InpS, n_minimal:Inv.n_explanations, proof:Proof}},
    rules_of(AB, RAB), rules_of(A, RA),
    foldl(learn(Net, RAB, RA), [recovered-Inp, original-True], Res0, Res1),
    observe_joint(Net, D, RAB, RA, Joint),
    Res = Res1.put(observe_intermediate, Joint),
    atom_concat(R, '/compose.json', Out), write_json(Out, Res),
    print(Res), nl.

% observe the joint between the networks (t2) as well as the end output (r): the recovered input
% then passes through the right intermediate values, and the composed rule can be learned
observe_joint(Net, D, RAB, RA, _{recovered:InpS, n_minimal:N, proof:Proof, popper:CodeJ, vs_union:V}) :-
    full_obs(Net, [r/2, t2/2], Obs, _), net_true_input(Net, True), report(Net, Obs, True, 50, Inv),
    get_dict(n_explanations, Inv, N),
    invert(Net, Obs, [cap(1)], I1), get_dict(explanations, I1, [Inp|_]),
    net_reproduces(D, Inp, Obs, Proof), maplist(show, Inp, InS0), msort(InS0, InpS),
    forward(Net, Inp, RM), closed_world(Net, r, 2, RM, Exs),
    popper(compose_AB_joint, InpS, Exs, r-2, ["f/2", "g/2", "h/2"], "max_vars(4).\nmax_body(3).\n", Code),
    (   Code == none -> CodeJ = null, V = null
    ;   CodeJ = Code, append(Code, RA, CRA), equivalent(RAB, CRA, ['r/2'], ['f/2', 'g/2', 'h/2'], [a, b, c], V)
    ).

info(Net, _{hidden:NH, inputs:Ps}) :-
    net_hidden(Net, Hs), length(Hs, NH), net_edb_preds(Net, P0),
    findall(S, ( member(N/A, P0), format(string(S), "('~w', ~w)", [N, A]) ), P1), msort(P1, Ps).

learn(Net, RAB, RA, Src-In, R0, R) :-
    forward(Net, In, RM), closed_world(Net, r, 2, RM, Exs),
    maplist(show, In, InS0), msort(InS0, InS),
    atom_concat('compose_AB_', Src, Name),
    popper(Name, InS, Exs, r-2, ["f/2", "g/2", "h/2"], "max_vars(4).\nmax_body(3).\n", Code),
    format(atom(K), 'popper_~w', [Src]),
    (   Code == none -> R = R0.put(K, null)
    ;   append(Code, RA, CRA), equivalent(RAB, CRA, ['r/2'], ['f/2', 'g/2', 'h/2'], [a, b, c], V),
        format(atom(KV), 'popper_~w_vs_union', [Src]),
        R = R0.put(K, Code).put(KV, V)
    ).
