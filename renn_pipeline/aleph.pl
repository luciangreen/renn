/*  aleph.pl -- run Aleph (friguzzi/aleph) on a learning task and return its theory.

    Aleph is used where Popper 2.1 cannot go: negation (through closed-world not_P/N background
    predicates) and arithmetic (through add/mul/compare predicates whose constants Aleph picks
    from the examples). Each task runs in a fresh swipl process, because Aleph keeps global state.

    run_aleph(+Name, +BK, +Pos, +Neg, +Modes, +Dets, +Settings, -Theory)
        BK, Pos, Neg, Modes: lists of clause strings; Dets: [Head-Body] strings;
        Settings: [Key-Value]; Theory: list of clause strings (as Aleph prints them), or none */
:- module(aleph, [run_aleph/8]).
:- use_module(library(pcre)).
:- use_module(config).
:- use_module(netlib, [ensure_dir/1]).
:- use_module(pipeline, [write_text/2, swipl_goal/5]).

defaults([verbosity-0, i-3, clauselength-6, minpos-2, noise-0, nodes-50000]).

run_aleph(Name, BK, Pos, Neg, Modes, Dets, Settings, Theory) :-
    path(work, W), format(atom(D), '~w/aleph/~w', [W, Name]), ensure_dir(D),
    defaults(Def), foldl([K-V, S0, S]>>( selectchk(K-_, S0, S1) -> append(S1, [K-V], S) ; append(S0, [K-V], S) ),
                         Settings, Def, Set),
    findall(L, ( member(K-V, Set), format(string(L), ":- aleph_set(~w,~w).", [K, V]) ), SL),
    findall(L, ( member(M, Modes), format(string(L), ":- ~w.", [M]) ), ML),
    findall(L, ( member(A-B, Dets), format(string(L), ":- determination(~w,~w).", [A, B]) ), DL),
    findall(L, ( member(B, BK), ( string_concat(_, ".", B) -> L = B ; string_concat(B, ".", L) ) ), BL),
    findall(L, ( member(P, Pos), string_concat(P, ".", L) ), PL),
    findall(L, ( member(N, Neg), string_concat(N, ".", L) ), NL),
    append([[":- use_module(library(aleph)).", ":- aleph."], SL, ML, DL,
            [":- begin_bg."], BL, [":- end_bg."], [":- begin_in_pos."], PL, [":- end_in_pos."],
            [":- begin_in_neg."], NL, [":- end_in_neg."]], Lines),
    atomic_list_concat(Lines, '\n', T), format(string(Text), "~w~n", [T]),
    format(atom(F), '~w/task.pl', [D]), write_text(F, Text),
    path(aleph, Lib), format(atom(LibOpt), 'library=~w', [Lib]),
    Goal = "consult('task.pl'),induce(P),forall(member(C,P),(numbervars(C,0,_),print(learned(C)),nl))",
    (   catch(swipl_goal(Goal, ['-p', LibOpt], D, 300, Out), _, fail)
    ->  re_foldl([M, A0, [X|A0]]>>get_dict(1, M, X), "^learned\\((.*)\\)$"/m, Out, [], R, []), reverse(R, Theory)
    ;   Theory = none
    ).
