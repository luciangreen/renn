/*  parse_pairs.pl -- parse pl2ann_io_pairs.md into pairs.json: program, domain, options,
    queries and outputs for each numbered pair.

    swipl parse_pairs.pl [pl2ann_io_pairs.md]      (writes <EXP_DIR>/pairs.json) */
:- use_module(library(pcre)).
:- use_module(library(readutil)).
:- use_module(library(apply)).
:- use_module(library(yall)).
:- use_module(config).
:- use_module(netlib, [write_json/2, ensure_dir/1]).

:- initialization(main, main).

main :-
    current_prolog_flag(argv, Argv),
    ( Argv = [Src|_] -> true ; Src = 'pl2ann_io_pairs.md' ),
    read_file_to_string(Src, Text, [encoding(utf8)]),
    parse_pairs(Text, Pairs),
    path(exp, Exp), ensure_dir(Exp), atom_concat(Exp, '/pairs.json', Out),
    write_json(Out, Pairs),
    length(Pairs, N), include([P]>>get_dict(error, P, null), Pairs, Ok), length(Ok, K),
    format("~w pairs; ~w with networks~n", [N, K]).

% split at "\n## <n>. " headings; a "## " not followed by a number stays in the body before it
parse_pairs(Text, Pairs) :-
    re_split("\n## "/s, Text, [_|Parts]),
    chunks(Parts, Blocks),
    findall(P, ( member(N-Body, Blocks), pair(N, Body, P) ), Pairs).

chunks([], []).
chunks([_Sep, C|Rest], Blocks) :-
    (   re_matchsub("^(\\d+)\\. (.*)$"/s, C, M, [])
    ->  number_string(N, M.1), glue(Rest, M.2, Body, Rest1), Blocks = [N-Body|Bs], chunks(Rest1, Bs)
    ;   chunks(Rest, Blocks)
    ).
% following chunks that are not numbered headings belong to this body
glue([Sep, C|Rest], B0, B, Rest1) :-
    \+ re_match("^\\d+\\. "/s, C), !,
    atomic_list_concat([B0, Sep, C], B1), atom_string(B1, B2), glue(Rest, B2, B, Rest1).
glue(Rest, B, B, Rest).

pair(N, Body, P) :-
    split_string(Body, "\n", "", [Title0|_]), normalize_space(string(Title), Title0),
    re_matchsub("\\*Category:\\* `([^`]+)`", Body, C, []), Cat = C.1,
    findall(Lang-Code, ( re_foldl([M, A0, [L1-L2|A0]]>>(get_dict(1, M, L1), get_dict(2, M, L2)), "```(\\w+)\\n(.*?)```"/s, Body, [], L0, []),
                         reverse(L0, L), member(Lang-Code, L) ), Codes),
    findall(Cd, member("prolog"-Cd, Codes), Prolog),
    Prolog = [Program|_],
    (   sub_string(Body, _, _, _, "Domain file"), Prolog = [_, Dom|_] -> Domain = Dom ; Domain = null ),
    re_matchsub("Convert options: `([^`]*)`", Body, O, []),
    ( sub_string(O.1, 0, _, _, "(defaults") -> Opts = "" ; Opts = O.1 ),
    findall(T, member("text"-T, Codes), [Out|_]),
    re_foldl([M, A0, [_{query:Q, answer:A}|A0]]>>( get_dict(1, M, Q0), get_dict(2, M, A1),
                                                     normalize_space(string(Q), Q0), normalize_space(string(A), A1) ),
             "\\?- (.*?)  =>  (.*)", Out, [], Qs0, []), reverse(Qs0, Qs),
    (   re_matchsub("network: (\\d+) atoms, (\\d+) hidden.*?, (\\d+) weighted edges, (\\d+) strata; run: (\\d+) active atoms after (\\d+) rounds, fixpoint reached = (\\w+)",
                    Out, Nm, [])
    ->  Net = _{atoms:Nm.1, hidden:Nm.2, edges:Nm.3, strata:Nm.4, active:Nm.5, rounds:Nm.6, fixpoint:Nm.7}
    ;   Net = null
    ),
    ( re_matchsub("^error: (.*)$"/m, Out, Er, []) -> Err = Er.1 ; Err = null ),
    P = _{id:N, title:Title, category:Cat, program:Program, domain:Domain, options:Opts,
          queries:Qs, network:Net, error:Err}.
