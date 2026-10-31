/*  popper_tasks.pl -- the five Popper learning tasks of Stage 2, and running Popper on a folder. */
:- module(popper_tasks, [task/5, task_of/2, popper_dir/4]).
:- use_module(pipeline, [run_popper/3, popper_solution/3]).

% task(Key, Target, Arity, BodyPreds, BiasExtras)
task("recursion/reachability", reach, 2, ["edge/2"], "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n").
task("relations/family:ancestor", ancestor, 2, ["parent/2"], "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n").
task("relations/family:grandparent", grandparent, 2, ["parent/2"], "max_vars(3).\nmax_body(2).\n").
task("relations/family:sibling", sibling, 2, ["parent/2", "neq/2"], "max_vars(3).\nmax_body(3).\n").
task("negation/stratified", flies, 1, ["bird/1", "penguin/1", "injured/1", "abnormal/1"], "max_vars(2).\nmax_body(3).\n").

task_of(P, T) :-
    get_dict(category, P, C),
    (   C == "relations/family"
    ->  member(N, ["ancestor", "grandparent", "sibling"]), string_concat(N, "(", NP),
        sub_string(P.program, _, _, _, NP), !, string_concat("relations/family:", N, T)
    ;   task(C, _, _, _, _), T = C
    ).

% run Popper on a folder; Prog = the program text or null; Stats = its statistics line or null
popper_dir(D, Timeout, Prog, Stats-Secs) :-
    get_time(T0), run_popper(D, Timeout, Out), get_time(T1), Secs is round((T1 - T0) * 10) / 10,
    ( popper_solution(Out, Prog, Stats) -> true ; Prog = null, Stats = null ).
