/*  to_markdown.pl -- write the recorded pairs (one JSON object per line) as markdown.
    to_markdown(+JsonLinesFile, +MarkdownFile, +Title, +Intro) */
:- module(to_markdown, [to_markdown/4]).
:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- use_module(library(pairs)).

to_markdown(In, Out, Title, Intro) :-
    read_pairs(In, Ps),
    length(Ps, N),
    findall(C, member(_{category:C, title:_, program:_, query:_, output:_}, Ps), Cs0),
    ordered_counts(Cs0, Counts),
    setup_call_cleanup(open(Out, write, S, [encoding(utf8)]),
        ( format(S, "# ~w: ~w input/output pairs~n~n~w~n~n| Category | Pairs |~n|---|---|~n", [Title, N, Intro]),
          forall(member(C-K, Counts), format(S, "| `~w` | ~w |~n", [C, K])),
          nl(S),
          forall(nth1(I, Ps, P), write_pair(S, I, P)) ),
        close(S)).

read_pairs(F, Ps) :-
    setup_call_cleanup(open(F, read, S, [encoding(utf8)]), read_lines(S, Ps), close(S)).
read_lines(S, Ps) :-
    read_line_to_string(S, L),
    (   L == end_of_file -> Ps = []
    ;   L == "" -> read_lines(S, Ps)
    ;   atom_json_dict(L, D, [value_string_as(string)]), Ps = [D|R], read_lines(S, R) ).

% categories in order of first appearance, with their counts
ordered_counts(Cs, Counts) :-
    foldl([C, A0, A]>>( memberchk(C, A0) -> A = A0 ; append(A0, [C], A) ), Cs, [], Us),
    maplist({Cs}/[U, U-K]>>aggregate_all(count, member(U, Cs), K), Us, Counts).

write_pair(S, I, P) :-
    format(S, "## ~w. ~w~n~n*Category:* `~w`~n~n**Input**~n~n```prolog~n", [I, P.title, P.category]),
    normalize_space(string(Prog0), P.program),
    ( Prog0 == "" -> true ; split_string(P.program, "", " \n", [Prog]), format(S, "~s~n~n", [Prog]) ),
    split_string(P.query, "", " \n", [Q]),
    format(S, "?- ~s.~n```~n~n**Output**~n~n```text~n", [Q]),
    split_string(P.output, "", " \n", [O]),
    format(S, "~s~n```~n~n", [O]).
