/*  stage1_summary.pl -- totals per category and regime from stage1.json; writes stage1_summary.json.
    swipl stage1_summary.pl */
:- use_module(config).
:- use_module(netlib).

:- initialization(main, main).

main :-
    path(results, R), atom_concat(R, '/stage1.json', F), json_file(F, Rows),
    partition([X]>>get_dict(closed, X, true), Rows, Closed, Open),
    length(Closed, NC),
    findall(C, ( member(X, Closed), get_dict(category, X, C) ), Cs0), msort(Cs0, Cs),
    clumped(Cs, CC0), maplist([K-V, A-V]>>atom_string(A, K), CC0, CC), dict_pairs(CCD, _, CC),
    ( forall(member(X, Open), get_dict(all_verified_forward, X, true)) -> AV = true ; AV = false ),
    ( forall(member(X, Open), get_dict(orig_consistent, X, true)) -> OC = true ; OC = false ),
    Summary = _{closed:NC, closed_cats:CCD, verified_forward_all:AV, orig_consistent_all:OC},
    print(Summary), nl,
    findall(Cat-Reg, ( member(X, Open), get_dict(category, X, Cat), get_dict(regime, X, Reg) ), K0), sort(K0, Keys),
    findall([Cat, Reg, N, Sat, Min, Uniq, Smaller, ME, Cap, MS],
            ( member(Cat-Reg, Keys),
              include({Cat, Reg}/[X]>>( get_dict(category, X, Cat), get_dict(regime, X, Reg) ), Open, G),
              length(G, N), cnt(G, [X]>>get_dict(status, X, "sat"), Sat),
              cnt(G, [X]>>get_dict(orig_is_minimal_explanation, X, true), Min),
              cnt(G, [X]>>get_dict(orig_unique, X, true), Uniq),
              cnt(G, [X]>>( get_dict(min_size, X, M), get_dict(orig_size, X, O), ( M == null -> 99 < O ; M < O ) ), Smaller),
              sum_of(G, n_explanations, SE), round_even(SE / N, 1, ME),
              cnt(G, [X]>>get_dict(capped, X, true), Cap),
              sum_of(G, seconds, SS), round_even(SS / N, 2, MS),
              format("~w~t~31|~w n=~w sat=~w origMin=~w unique=~w smaller=~w meanExpl=~w capped=~w s=~w~n",
                     [Cat, Reg, N, Sat, Min, Uniq, Smaller, ME, Cap, MS]) ), Table),
    findall(Reg-T, ( member(Reg, ["Q", "F"]), include({Reg}/[X]>>get_dict(regime, X, Reg), Open, S), length(S, N),
                     cnt(S, [X]>>get_dict(status, X, "sat"), Sat), cnt(S, [X]>>get_dict(orig_unique, X, true), U),
                     cnt(S, [X]>>get_dict(orig_is_minimal_explanation, X, true), Mi),
                     findall(Sec, ( member(X, S), get_dict(seconds, X, Sec) ), Secs), max_list(Secs, MaxS),
                     T = _{n:N, sat:Sat, unique:U, minimal:Mi, max_s:MaxS}, format("~w ~p~n", [Reg, T]) ), Tot),
    maplist([K-V, A-V]>>atom_string(A, K), Tot, Tot1), dict_pairs(TotD, _, Tot1),
    atom_concat(R, '/stage1_summary.json', Out),
    write_json(Out, _{summary:Summary, table:Table, totals:TotD}).

cnt(L, G, N) :- include(G, L, L1), length(L1, N).
sum_of(L, K, S) :- findall(V, ( member(X, L), get_dict(K, X, V) ), Vs), sum_list(Vs, S).

% round to D decimals as Python's round does: correctly rounded from the exact binary value
round_even(X0, D, Y) :- X is float(X0), format(atom(A), "~*f", [D, X]), atom_number(A, Y).
