:- encoding(utf8).
/*  types_report.pl -- run proof/types (types.pl) on every MNN rule program in rules/: the
    inclusions proved for every input, the slots that are the same type, the related slots
    (shared variables), the refinement and conversion templates, and the type guards that a
    related variable proves redundant. Writes <RESULTS_DIR>/types.json.   swipl types_report.pl */
:- use_module(library(readutil)).
:- use_module(config).
:- use_module(netlib, [write_json/2, ensure_dir/1, show/2]).
:- use_module(datalog, [parse_program/2]).
:- use_module(types).

:- initialization(main, main).

main :-
    path(rules, RD), path(results, R), ensure_dir(R),
    path(prover, PV), path(pl2ann, PD), atom_concat(PD, '/prolog', PP),
    ( getenv('PL2ANN_PROLOG', _) -> true ; setenv('PL2ANN_PROLOG', PP) ), use_module(PV, []),
    directory_files(RD, Fs0), msort(Fs0, Fs),
    findall(K-Rep, ( member(F, Fs), atom_concat(Base, '_orig.pl', F), atom_string(K0, Base), K = K0,
                     format(atom(Path), '~w/~w', [RD, F]), once(report(Path, Rep)) ), L),
    dict_pairs(D, _, L),
    atom_concat(R, '/types.json', Out), write_json(Out, D),
    forall(member(K-Rep, L), summary(K, Rep)).

report(Path, Rep) :-
    read_file_to_string(Path, T, []), parse_program(T, Cs),
    partition([_-B]>>(B == []), Cs, FC, Rules), findall(H, member(H-[], FC), Facts),
    P = prog(Facts, Rules),
    memo_reset, infer_types(P, types(Incl, Same, Classes, Ts)),
    findall(S, ( member(A-B, Incl), format(string(S), "~w ⊆ ~w", [A, B]) ), IS),
    findall(S, ( member(A=B, Same), format(string(S), "~w = ~w", [A, B]) ), SS),
    findall(S, ( member(C, Classes), C = [_, _|_], format(string(S), "~w", [C]) ), CS),
    findall(S, ( member(X, Ts), format(string(S), "~w", [X]) ), TS),
    findall(S, ( nth1(I, Rules, _-Bd), nth1(J, Bd, G), functor(G, _, 1), implied_guard(P, I, J, implied(_, by(Sl), _)),
                 nth1(I, Rules, Rule), copy_term(Rule, H1-B1), numbervars(H1-B1, 0, _),
                 format(string(S), "rule ~w ~w :- ~w: literal ~w is implied by slot ~w", [I, H1, B1, J, Sl]) ), GS),
    Rep = _{inclusions:IS, same_type:SS, related:CS, templates:TS, implied_guards:GS}.

summary(K, Rep) :-
    maplist([F, N]>>( get_dict(F, Rep, L), length(L, N) ), [inclusions, same_type, related, templates, implied_guards], Ns),
    format("~w: inclusions ~w, same type ~w, related classes ~w, templates ~w, implied guards ~w~n", [K|Ns]),
    forall(member(G, Rep.implied_guards), format("   ~w~n", [G])),
    forall(member(G, Rep.templates), format("   template ~w~n", [G])).
