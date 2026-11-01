/*  harness.pl -- run one query and record it as an input/output pair (a JSON line).
    pair(+Category, +Title, +ProgramText, +QueryText)
    The output is whatever the query prints, then the bindings of its named variables
    (true / false / the error when there are none). */
:- module(harness, [open_pairs/1, close_pairs/0, pair/4, pair/3, set_limit/1]).
:- dynamic limit/1.
limit(120).
set_limit(S) :- retractall(limit(_)), assertz(limit(S)).
:- use_module(library(http/json)).
:- dynamic out_stream/1.

open_pairs(File) :- open(File, write, S, [encoding(utf8)]), assertz(out_stream(S)).
close_pairs :- retract(out_stream(S)), close(S).

pair(Cat, Title, Q) :- pair(Cat, Title, "", Q).
pair(Cat, Title, Prog, Q) :-
    term_string(G, Q, [variable_names(Bs)]),
    with_output_to(string(Printed),
        catch(( limit(Lim), call_with_time_limit(Lim, ( once(G) -> R = true ; R = false )) ), E, R = error(E))),
    bindings(R, Bs, BT),
    ( Printed == "" -> Out = BT ; BT == "true" -> Out = Printed ; string_concat(Printed, BT, Out) ),
    out_stream(S),
    json_write_dict(S, _{category:Cat, title:Title, program:Prog, query:Q, output:Out}, [width(0)]), nl(S),
    format(user_error, ".", []).

bindings(error(time_limit_exceeded), _, T) :- !, limit(L), format(string(T), "no answer within the ~w-second limit", [L]).
bindings(error(E), _, T) :- !, message_to_codes(E, T0), format(string(T), "error: ~s", [T0]).
bindings(false, _, "false") :- !.
bindings(true, Bs, T) :-
    include([N=V]>>( \+ sub_atom(N, 0, _, _, '_'), nonvar(V) ), Bs, Vis),
    (   Vis == [] -> T = "true"
    ;   copy_term(Vis, VisC), numbervars(VisC, 0, _, [singletons(true)]),
        findall(L, ( member(N=V, VisC),
                     format(string(L), "~w = ~W", [N, V, [quoted(true), portray(true), numbervars(true), max_depth(0), spacing(next_argument)]]) ), Ls),
        atomic_list_concat(Ls, '\n', A), atom_string(A, T0), string_concat(T0, "\n", T) ).
message_to_codes(E, S) :- catch(( message_to_codes(E, [], C), atom_codes(S, C) ), _, format(string(S), "~q", [E])).
message_to_codes(E, _, C) :- format(codes(C), "~q", [E]).
