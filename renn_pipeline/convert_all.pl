/*  convert_all.pl -- Stage 0: compile every pair's source program to a network with pl2ann,
    exporting the weights as JSON. Reads <EXP_DIR>/pairs.json, writes <EXP_DIR>/nets/<id>/.

    swipl convert_all.pl */
:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(config).
:- use_module(netlib, [json_file/2, ensure_dir/1]).
:- use_module(pipeline, [run_pl2ann/4]).

:- initialization(main, main).

main :-
    path(exp, Exp), atom_concat(Exp, '/pairs.json', PF), json_file(PF, Pairs),
    include([P]>>get_dict(error, P, null), Pairs, Ok),
    foldl(convert(Exp), Ok, 0-0, Good-Bad),
    format("converted ~w failed ~w~n", [Good, Bad]).

convert(Exp, P, G0-B0, G-B) :-
    get_dict(id, P, Id), format(atom(D), '~w/nets/~w', [Exp, Id]), ensure_dir(D),
    format(atom(Src), '~w/src.pl', [D]), write_text(Src, P.program),
    (   P.domain \== null
    ->  format(atom(Dom), '~w/domain.pl', [D]), write_text(Dom, P.domain), DomOpt = ['--domain', Dom]
    ;   DomOpt = []
    ),
    split_string(P.options, " ", " ", Os0), exclude(==(""), Os0, Os),
    format(atom(Mod), 'net~w', [Id]),
    format(atom(NetPl), '~w/net.pl', [D]), format(atom(NetJson), '~w/net.json', [D]),
    append([DomOpt, Os, ['--out', NetPl, '--module', Mod, '--json', NetJson]], Opts),
    run_pl2ann(Src, Opts, Status, Err),
    (   Status == 0, exists_file(NetJson)
    ->  G is G0 + 1, B = B0
    ;   B is B0 + 1, G = G0, sub_atom_tail(Err, 300, E), format("FAIL ~w ~w~n", [Id, E])
    ).

write_text(F, S) :- setup_call_cleanup(open(F, write, O, [encoding(utf8)]), write(O, S), close(O)).
sub_atom_tail(S, N, T) :- string_length(S, L), ( L =< N -> T = S ; K is L - N, sub_string(S, K, N, 0, T) ).
