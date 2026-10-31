/*  pipeline.pl -- one pipeline used for every experiment and every MNN rule chapter:

      original Prolog --pl2ann--> network (weights)
      network + observed output --inverse (clingo over the weights)--> input facts
      input facts + output --Popper or Aleph--> learned code
      (original, optimised) pairs --Spec to Algorithm--> pattern-matching optimisation algorithm
      prover.pl checks every claim (net = program, input reproduces output, code equivalence).

    Programs are handled as lists of clause STRINGS without the final full stop (as written by
    the learners), e.g. "reach(X,Y):-edge(X,Y)". */
:- module(pipeline, [run_pl2ann/4, compile_net/5, net_matches_program/2, net_reproduces/4,
                     prove/2, equivalent/6, program_reproduces/4,
                     clauses_of/2, rules_of/2, facts_of/2, pl_list/2, split_top/2,
                     popper/7, popper/8, run_popper/3, popper_solution/3, closed_world/5, canon_clause/2, align/3, full_obs/4,
                     s2a_learn_and_apply/5, s2a_window_optimise/8, swipl_goal/5,
                     strip_spaces/2, write_text/2, take/3, sorted_strings/2]).
:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(library(pcre)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).
:- use_module(library(assoc)).
:- use_module(config).
:- use_module(netlib).

:- dynamic prover_loaded/0.

% ------------------------------------------------------------------ small helpers
write_text(F, S) :- setup_call_cleanup(open(F, write, O, [encoding(utf8)]), write(O, S), close(O)).
take(N, L, T) :- length(L, Len), ( Len =< N -> T = L ; length(T, N), append(T, _, L) ).
strip_spaces(S, T) :- split_string(S, " ", "", Ps), atomic_list_concat(Ps, A), atom_string(A, T).
sorted_strings(L, S) :- maplist(strip_spaces, L, L1), msort(L1, S).

% run swipl on a goal in a fresh process (used where a tool keeps global state: S2A, Aleph)
swipl_goal(Goal, Opts, Cwd, Timeout, Out) :-
    atomic_list_concat([Goal, ',halt'], G),
    append([['-q'], Opts, ['-g', G, '-t', 'halt(1)']], Args),
    format(atom(T), '~w', [Timeout]),
    exe(swipl, Swipl), process_create(path(timeout), [T, Swipl|Args],
                   [cwd(Cwd), stdout(pipe(O)), stderr(null), process(Pid)]),
    read_string(O, _, Out), close(O), process_wait(Pid, _).

exe(Name, Path) :- absolute_file_name(path(Name), Path, [access(execute)]).

% ------------------------------------------------------------------ program text
% split program text into clause strings (comments removed, no trailing full stop)
clauses_of(Text, Cs) :-
    re_replace("%.*"/g, "", Text, T1),
    re_split("\\.(?=\\s|$)", T1, Parts),
    findall(C, ( nth1(I, Parts, P), I mod 2 =:= 1, normalize_space(string(C), P), C \== "" ), Cs).
rules_of(Text, Rs) :- clauses_of(Text, Cs), include([C]>>sub_string(C, _, _, _, ":-"), Cs, Rs).
facts_of(Text, Fs) :- clauses_of(Text, Cs), exclude([C]>>sub_string(C, _, _, _, ":-"), Cs, Fs).

pl_list(Cs, S) :- maplist([C, P]>>format(string(P), "(~w)", [C]), Cs, Ps),
                  atomic_list_concat(Ps, ',', J), format(string(S), "[~w]", [J]).

% split at top-level commas (outside brackets)
split_top(S, Parts) :-
    string_chars(S, Cs), split_top_(Cs, 0, [], [], Rev), reverse(Rev, Parts0),
    exclude(==(""), Parts0, Parts).
split_top_([], _, Cur, Acc, [P|Acc]) :- reverse(Cur, R), string_chars(P0, R), normalize_space(string(P), P0).
split_top_([C|Cs], D, Cur, Acc, Out) :-
    (   C == ',', D =:= 0
    ->  reverse(Cur, R), string_chars(P0, R), normalize_space(string(P), P0),
        split_top_(Cs, D, [], [P|Acc], Out)
    ;   ( memberchk(C, ['(', '[']) -> D1 is D + 1 ; memberchk(C, [')', ']']) -> D1 is D - 1 ; D1 = D ),
        split_top_(Cs, D1, [C|Cur], Acc, Out)
    ).

% ------------------------------------------------------------------ stage 0: pl2ann
run_pl2ann(Src, Opts, Status, Err) :-
    path(pl2ann, Dir),
    process_create(path(swipl), ['bin/prolog2ann.pl', convert, Src|Opts],
                   [cwd(Dir), stdout(null), stderr(pipe(E)), process(Pid)]),
    read_string(E, _, Err), close(E), process_wait(Pid, exit(Status)).

compile_net(Name, Program, Domain, Opts, D-Net) :-
    path(work, W), format(atom(D), '~w/~w', [W, Name]), ensure_dir(D),
    format(atom(Src), '~w/src.pl', [D]), write_text(Src, Program),
    (   Domain \== none
    ->  format(atom(Dom), '~w/domain.pl', [D]), write_text(Dom, Domain), DO = ['--domain', Dom]
    ;   DO = []
    ),
    re_replace("\\W"/g, "_", Name, M0), atom_concat(n_, M0, Mod),
    format(atom(NP), '~w/net.pl', [D]), format(atom(NJ), '~w/net.json', [D]),
    append([DO, Opts, ['--out', NP, '--module', Mod, '--json', NJ]], All),
    run_pl2ann(Src, All, St, Err),
    ( St == 0 -> true ; throw(error(pl2ann_failed(Name, Err), _)) ),
    net_load(NJ, Net).

% ------------------------------------------------------------------ the prover
load_prover :-
    (   prover_loaded -> true
    ;   path(prover, P), path(pl2ann, D),
        ( getenv('PL2ANN_PROLOG', _) -> true ; atom_concat(D, '/prolog', PP), setenv('PL2ANN_PROLOG', PP) ),
        use_module(P, []), assertz(prover_loaded)
    ).

% prove(+GoalText, -ResultText): GoalText binds R; the result is printed as print/1 would
prove(GoalText, Result) :-
    load_prover,
    term_string(G, GoalText, [variable_names(Vs)]),
    (   memberchk('R'=R, Vs),
        catch(( call(prover:G) -> true ; R = goal_failed ), E, R = error(E))
    ->  copy_term(R, R1), numbervars(R1, 0, _), with_output_to(string(Result), print(R1))
    ;   Result = "goal_failed"
    ).

net_matches_program(D, R) :-
    format(string(G), "read_program('~w/src.pl',P),net_matches_program('~w/net.pl',P,R)", [D, D]), prove(G, R).

net_reproduces(D, Inp, Obs, R) :-
    maplist(show, Inp, Is), atomic_list_concat(Is, ',', IS),
    findall(L, ( member(A-V, Obs), show(A, S), format(string(L), "~w(~w)", [V, S]) ), Ls),
    atomic_list_concat(Ls, ',', OS),
    format(string(G), "net_reproduces('~w/net.pl',[~w],[~w],R)", [D, IS, OS]), prove(G, R).

program_reproduces(Code, BK, Obs, R) :-
    pl_list(Code, C), atomic_list_concat(BK, ',', B),
    findall(L, ( member(A-V, Obs), format(string(L), "~w(~w)", [V, A]) ), Ls),
    atomic_list_concat(Ls, ',', OS),
    format(string(G), "program_reproduces(~w,[~w],[~w],R)", [C, B, OS]), prove(G, R).

equivalent(A, B, Targets, Edb, Consts, R) :-
    pl_list(A, LA), pl_list(B, LB),
    atomic_list_concat(Targets, ',', T), atomic_list_concat(Edb, ',', E), atomic_list_concat(Consts, ',', C),
    format(string(G), "equivalent(~w,~w,[~w],edb([~w],[~w]),R)", [LA, LB, T, E, C]), prove(G, R).

% ------------------------------------------------------------------ stage 1 helpers
% observation of the target predicates on the network's own input, and that model
full_obs(Net, Targets, Obs, Model) :-
    net_true_input(Net, In), forward(Net, In, Model), net_atoms(Net, Atoms),
    findall(A-V, ( member(A, Atoms), pred_key(A, P), memberchk(P, Targets),
                   ( memberchk(A, Model) -> V = true ; V = false ) ), Obs).

% closed world: every tuple of the network's constants is an example of Target/Ar
closed_world(Net, Target, Ar, Model, Exs) :-
    consts_of(Net, Cs), length(Tup, Ar),
    findall(S-V, ( maplist({Cs}/[X]>>member(X, Cs), Tup),
                   ( Ar =:= 0 -> S = Target ; atomic_list_concat(Tup, ',', J), format(string(S), "~w(~w)", [Target, J]) ),
                   term_string(T, S), ( memberchk(T, Model) -> V = true ; V = false ) ), Exs).

% ------------------------------------------------------------------ Popper
% Popper's example file uses pos/1 and neg/1 itself, so those names are renamed in and out
reserved(pos, zpos). reserved(neg, zneg).
res(S, back, T) :- !, foldl([A-B, S0, S1]>>res1(B, A, S0, S1), [pos-zpos, neg-zneg], S, T).
res(S, fwd, T) :- foldl([A-B, S0, S1]>>res1(A, B, S0, S1), [pos-zpos, neg-zneg], S, T).
res1(X, Y, S0, S1) :- format(string(P), "\\b~w(?=[(/]|$)", [X]), re_replace(P/g, Y, S0, S1).

popper(Name, BK, Exs, Head, Body, Extra, Code) :- popper(Name, BK, Exs, Head, Body, Extra, 120, Code).
popper(Name, BK0, Exs0, H0-Ar, Body0, Extra, Timeout, Code) :-
    maplist([S, T]>>res(S, fwd, T), BK0, BK), maplist([S, T]>>res(S, fwd, T), Body0, Body),
    maplist([A-V, B-V]>>res(A, fwd, B), Exs0, Exs), res(H0, fwd, H1), atom_string(H, H1),
    path(work, W), format(atom(D), '~w/~w/popper', [W, Name]), ensure_dir(D),
    findall(L, ( member(A, BK), format(string(L), "~w.", [A]) ), BL),
    findall(L, ( member(B, Body), format(string(L), ":- dynamic ~w.", [B]) ), DL),
    append(BL, DL, BKL), atomic_list_concat(BKL, '\n', BKT),
    format(atom(BF), '~w/bk.pl', [D]), format(string(BKS), "~w~n", [BKT]), write_text(BF, BKS),
    % positives first, each group sorted by text
    findall(K-A, ( member(A-V, Exs), ( V == true -> K = 0 ; K = 1 ) ), KA), msort(KA, KAs),
    findall(L, ( member(K-A, KAs), ( K =:= 0 -> P = pos ; P = neg ), format(string(L), "~w(~w).", [P, A]) ), EL),
    atomic_list_concat(EL, '\n', ET), format(atom(EF), '~w/exs.pl', [D]), format(string(ES), "~w~n", [ET]), write_text(EF, ES),
    findall(L, ( member(B, Body), split_string(B, "/", "", [BN, BA]), format(string(L), "body_pred(~w,~w).~n", [BN, BA]) ), BPs),
    atomic_list_concat(BPs, BPT),
    format(atom(BiF), '~w/bias.pl', [D]), format(string(BiS), "head_pred(~w,~w).~n~w~w", [H, Ar, BPT, Extra]), write_text(BiF, BiS),
    run_popper(D, Timeout, Out),
    (   popper_solution(Out, Prog, _)
    ->  split_string(Prog, "\n", " \t", Ls0), exclude(==(""), Ls0, Ls1),
        maplist([L, C]>>( ( string_concat(C0, ".", L) -> C1 = C0 ; C1 = L ), normalize_space(string(C), C1) ), Ls1, Cs),
        maplist([S, T]>>res(S, back, T), Cs, Code)
    ;   Code = none
    ).
% Popper prints ******** SOLUTION ********, a statistics line, the program, then a row of stars
popper_solution(Out, Prog, Stats) :-
    re_matchsub("\\*+ SOLUTION \\*+\\n(.*?)\\n(.*?)\\*{10,}"/s, Out, M, []),
    get_dict(1, M, Stats), get_dict(2, M, P0),
    split_string(P0, "\n", " \t", Ls0), exclude(==(""), Ls0, Ls), atomic_list_concat(Ls, '\n', PA), atom_string(PA, Prog).
% stderr goes to a file: Popper can write more warnings than a pipe holds, and reading stdout
% to the end while stderr is full would block both programs
run_popper(D, Timeout, Out) :-
    path(popper, P), path(pyswip, Py),
    T1 is Timeout + 30, format(atom(TA), '~w', [T1]), format(atom(TO), '~w', [Timeout]),
    tmp_file_stream(text, EF, ES),
    exe(python3, Py3),
    setup_call_cleanup(
        process_create(path(timeout), [TA, Py3, P, D, '--timeout', TO],
                       [environment(['PYTHONPATH'=Py]), stdout(pipe(O)), stderr(stream(ES)), process(Pid)]),
        ( read_string(O, _, S1), process_wait(Pid, _) ),
        ( close(O), close(ES) )),
    read_file_to_string(EF, S2, []), delete_file(EF),
    string_concat(S1, S2, Out).

% ------------------------------------------------------------------ program normalisation
% rename variables in order of first appearance to V0, V1, ... (spaces removed); _ stays _
canon_clause(C, K) :-
    strip_spaces(C, C1),
    re_split("\\b[A-Z_][A-Za-z0-9_]*\\b", C1, Parts), empty_assoc(E),
    canon_parts(Parts, 0, E, Qs), atomic_list_concat(Qs, A), atom_string(A, K).
canon_parts([], _, _, []).
canon_parts([P], _, _, [P]) :- !.
canon_parts([P, V|Rest], N, M, [P, Q|Qs]) :-
    (   V == "_" -> Q = V, N1 = N, M1 = M
    ;   get_assoc(V, M, Q) -> N1 = N, M1 = M
    ;   format(string(Q), "V~w", [N]), N1 is N + 1, put_assoc(V, M, Q, M1)
    ),
    canon_parts(Rest, N1, M1, Qs).

% rename and reorder each learned clause to the variant of a target clause where one exists
align(Learned, Target0, Out) :-
    maplist([T, T2]>>( strip_spaces(T, T1), re_replace("([A-Z]\\w*)\\\\=([A-Z]\\w*)"/g, "neq($1,$2)", T1, T2) ), Target0, Target),
    maplist(align1(Target), Learned, Out).
align1(Target, C, Out) :-
    strip_spaces(C, C1), head_body(C1, H, B), ( B == "" -> Lits = [] ; split_top(B, Lits) ), length(Lits, N),
    (   member(T, Target), head_body(T, _, TB), ( TB == "" -> TL = [] ; split_top(TB, TL) ), length(TL, N),
        canon_clause(T, KT), permutation(Lits, Perm),
        ( Perm == [] -> Cand = H ; atomic_list_concat(Perm, ',', PJ), format(string(Cand), "~w:-~w", [H, PJ]) ),
        canon_clause(Cand, KT)
    ->  Out = T
    ;   Out = C1
    ).
head_body(C, H, B) :- ( sub_string(C, Bf, _, Af, ":-") -> sub_string(C, 0, Bf, _, H), sub_string(C, _, Af, 0, B) ; H = C, B = "" ).

% ------------------------------------------------------------------ Spec to Algorithm
% S2A sees each program as nested lists of opaque tokens, at one of three grains:
%   literal: a literal is one token               [[h, b1, b2], ...]
%   flat:    predicate tokens and argument tokens [[p1, vx, vy, p2, vx, vz], ...] (decoded by arity)
%   clause:  a whole clause is one token          [c1, c2, ...]
% A tokenizer is tk(Prefix, Grain, TextToId, IdToText, IdToArity).
tk_new(Prefix, Grain, tk(Prefix, Grain, T, T, T)) :- empty_assoc(T).
tk_id(Text, Ar, tk(P, G, T2I, I2T, I2A), Id, tk(P, G, T2I1, I2T1, I2A1)) :-
    (   get_assoc(Text, T2I, Id) -> T2I1 = T2I, I2T1 = I2T, I2A1 = I2A
    ;   assoc_to_keys(T2I, Ks), length(Ks, N), N1 is N + 1, format(atom(Id), '~w~w', [P, N1]),
        put_assoc(Text, T2I, Id, T2I1), put_assoc(Id, I2T, Text, I2T1), put_assoc(Id, I2A, Ar, I2A1)
    ).

tk_encode(Rules, Enc, Tk0, Tk) :- foldl(tk_rule, Rules, Enc, Tk0, Tk).
tk_rule(C0, E, Tk0, Tk) :-
    strip_spaces(C0, C), Tk0 = tk(_, G, _, _, _),
    (   G == clause -> tk_id(C, 0, Tk0, E, Tk)
    ;   head_body(C, H, B), ( B == "" -> Ls = [] ; split_top(B, Ls) ),
        (   G == literal -> foldl([L, I, T0, T1]>>tk_id(L, 0, T0, I, T1), [H|Ls], E, Tk0, Tk)
        ;   foldl(flat_lit, [H|Ls], Es, Tk0, Tk), append(Es, E)
        )
    ).
% a literal the simple term reader accepts (name or name(args), no operators) is split into its
% predicate and arguments; anything else (arithmetic, \=) stays whole
flat_lit(L, Toks, Tk0, Tk) :-
    (   re_match("^[a-z][A-Za-z0-9_]*(\\(.*\\))?$", L),
        catch(term_string(T, L, [variable_names(Vs)]), _, fail)
    ->  maplist([N=V]>>(V = '$VAR'(N)), Vs),
        (   compound(T)
        ->  T =.. [F|As], length(As, Ar), atom_string(F, FS), tk_id(FS, Ar, Tk0, Id, Tk),
            maplist(flat_arg, As, ATs), Toks = [Id|ATs]
        ;   atom_string(T, TS), tk_id(TS, 0, Tk0, Id, Tk), Toks = [Id]
        )
    ;   tk_id(L, 0, Tk0, Id, Tk), Toks = [Id]
    ).
flat_arg(A, Tok) :- var(A), !, Tok = v_.          % an anonymous variable _
flat_arg('$VAR'(N), Tok) :- !, downcase_atom(N, D), atom_concat(v, D, Tok).
flat_arg(A, Tok) :- with_output_to(atom(Tok), write_term(A, [quoted(true), ignore_ops(true), numbervars(true)])).

tk_decode(Enc, tk(_, G, _, I2T, I2A), Rules) :-
    (   G == clause
    ->  flatten(Enc, Flat), maplist({I2T}/[I, T]>>get_assoc(I, I2T, T), Flat, Rules)
    ;   G == literal
    ->  maplist({I2T}/[C, R]>>( maplist({I2T}/[X, S]>>( atom(X), get_assoc(X, I2T, S) -> true ; term_string(X, S) ), C, [H|Bs]),
                                atomic_list_concat(Bs, ',', BJ), format(string(R), "~w:-~w", [H, BJ]) ), Enc, Rules)
    ;   maplist(flat_decode(I2T, I2A), Enc, Rules)
    ).
flat_decode(I2T, I2A, Toks, R) :-
    flat_lits(Toks, I2T, I2A, [H|Bs]),
    ( Bs == [] -> R = H ; atomic_list_concat(Bs, ',', BJ), format(string(R), "~w:-~w", [H, BJ]) ).
flat_lits([], _, _, []).
flat_lits([P|Ts], I2T, I2A, [L|Ls]) :-
    get_assoc(P, I2A, Ar), get_assoc(P, I2T, Name), length(Args, Ar), append(Args, Rest, Ts),
    maplist([A, S]>>( sub_atom(A, 0, 1, _, v) -> sub_atom(A, 1, _, 0, A1), upcase_atom(A1, S) ; S = A ), Args, Ss),
    ( Ar =:= 0 -> L = Name ; atomic_list_concat(Ss, ',', J), format(string(L), "~w(~w)", [Name, J]) ),
    flat_lits(Rest, I2T, I2A, Ls).

to_pl(X, S) :- is_list(X), !, maplist(to_pl, X, Ss), atomic_list_concat(Ss, ',', J), format(string(S), "[~w]", [J]).
to_pl(X, X).

% S2A prints nested output as a flat token list with "[" and "]" strings
from_brackets(Out, Nested) :-
    re_foldl([M, A0, [T|A0]]>>get_dict(0, M, T), "\"\\[\"|\"\\]\"|[a-z]\\w*", Out, [], R, []), reverse(R, Toks),
    nest(Toks, [[]], Nested).
nest([], [Top], L) :- reverse(Top, L).
nest(["\"[\""|Ts], St, L) :- !, nest(Ts, [[]|St], L).
nest(["\"]\""|Ts], [Top, Next|St], L) :- !, reverse(Top, T1), nest(Ts, [[T1|Next]|St], L).
nest([T|Ts], [Top|St], L) :- atom_string(A, T), nest(Ts, [[A|Top]|St], L).

s2a_lib("
xs_reset :-
  retractall(num_s2a(_)),assertz(num_s2a(1)),retractall(vars_s2a(_)),assertz(vars_s2a([])),
  retractall(vars_base_s2a(_)),assertz(vars_base_s2a('A')),
  retractall(character_breakdown_mode(_)),assertz(character_breakdown_mode(off)),
  (catch(algs(As),_,fail)->forall(member(A0,As),retractall(A0));true),
  retractall(algs(_)),assertz(algs([])),
  retractall(vars_table_s2a(_)),assertz(vars_table_s2a([])).
xs_learn(Name,Specs) :- xs_reset,
  ( catch(spec_to_algorithm(Name,Specs,off,Alg),_,fail) -> format(\"ALG ~q~n\",[Alg]) ; (format(\"GENFAIL~n\"), fail) ).
xs_apply(Name,In) :-
  retractall(vars_table_s2a(_)),assertz(vars_table_s2a([])),
  retractall(character_breakdown_mode(_)),assertz(character_breakdown_mode(off)),
  G=..[Name,[In],Out], ( catch(G,_,fail) -> format(\"OUT ~q~n\",[Out]) ; format(\"NOOUT~n\") ).
").

% s2a_learn_and_apply(+Name, +Train, +Tests, +Grain, -Alg-Outputs)
%   Train: [Orig-Opt] rule lists; Tests: [Orig]. Outputs: decoded rule lists, or none.
s2a_learn_and_apply(Name, Train, Tests, Grain, Alg-Outs) :-
    findall(Spec, ( nth0(K, Train, O-P), format(atom(Px), 't~wx', [K]), tk_new(Px, Grain, T0),
                    tk_encode(O, EI, T0, T1), tk_encode(P, EO, T1, _), to_pl(EI, SI), to_pl(EO, SO),
                    format(string(Spec), "[[input,[['A',~w]]],[output,[['B',~w]]]]", [SI, SO]) ), Specs),
    findall(Tk-E, ( nth0(K, Tests, O), format(atom(Px), 'h~wx', [K]), tk_new(Px, Grain, T0), tk_encode(O, E, T0, Tk) ), Tst),
    re_replace("\\W"/g, "_", Name, N1), format(atom(PName), 'opt_~w_~w', [N1, Grain]),
    atomic_list_concat(Specs, ',', SJ),
    findall(G, ( member(_-E, Tst), to_pl(E, ES), format(string(G), "xs_apply(~w,~w)", [PName, ES]) ), Gs),
    atomic_list_concat(Gs, ',', GJ),
    s2a_lib(Lib), format(string(Script), "~w~nrun_it :- (xs_learn(~w,[~w]) -> (~w) ; true).~n", [Lib, PName, SJ, GJ]),
    path(work, W), ensure_dir(W), format(atom(F), '~w/s2a_~w.pl', [W, PName]), write_text(F, Script),
    path(s2a, Dir), format(atom(Goal), "consult('spec_to_algorithm'),consult('~w'),run_it", [F]),
    swipl_goal(Goal, [], Dir, 900, Out),
    ( re_matchsub("^ALG (.*)$"/m, Out, AM, []) -> get_dict(1, AM, Alg) ; Alg = none ),
    re_foldl([M, A0, [X|A0]]>>get_dict(1, M, X), "^(OUT .*|NOOUT)$"/m, Out, [], OR, []), reverse(OR, Os),
    findall(D, ( nth0(I, Os, O), nth0(I, Tst, Tk-_), s2a_decode(O, Tk, Grain, D) ), Outs).

s2a_decode(O, Tk, Grain, D) :-
    (   ( O == "NOOUT" ; sub_string(O, _, _, _, "'C") ) -> D = none     % unbound pattern variable
    ;   sub_string(O, 4, _, 0, Body), from_brackets(Body, N0),
        (   Grain == clause -> N = N0
        ;   unwrap(N0, N1), ( N1 = [X|_], \+ is_list(X) -> N = [N1] ; N = N1 )
        ),
        ( catch(tk_decode(N, Tk, D0), _, fail) -> D = D0 ; D = none )
    ).
% S2A wraps the result once: unwrap to a list of clauses
unwrap([X], N) :- is_list(X), X = [Y|_], is_list(Y), !, unwrap(X, N).
unwrap(N, N).

% windowed driver: slide a window over the program; where the learned rewrite fires, splice its
% output in. With a check (the prover) a proposed rewrite is kept only if it is proved.
windows(Prog, 1, Ws) :- !, findall([C], member(C, Prog), Ws).
windows(Prog, 2, Ws) :- findall([A, B], ( nth0(I, Prog, A), nth0(J, Prog, B), I \== J ), Ws).
splice(Prog, [W], [O|_], 1, New) :- !, maplist({W, O}/[C, D]>>( C == W -> D = O ; D = C ), Prog, New).
splice(Prog, [A, B], O, 2, New) :-
    nth0(IA, Prog, A), nth0(IB, Prog, B), First is min(IA, IB),
    selectchk(A, Prog, P1), selectchk(B, P1, P2),
    length(Pre, First), append(Pre, Post, P2), append([Pre, O, Post], New).

s2a_window_optimise(Name, TrainWindows, Prog0, Size, Grain, Rounds, Check, Prog-Trace) :-
    win_rounds(Rounds, Name, TrainWindows, Prog0, Size, Grain, Check, Prog, [], Trace0), reverse(Trace0, Trace).
win_rounds(0, _, _, P, _, _, _, P, T, T) :- !.
win_rounds(K, Name, TW, P0, Size, Grain, Check, P, T0, T) :-
    windows(P0, Size, Ws),
    (   Ws == [] -> P = P0, T = T0
    ;   s2a_learn_and_apply(Name, TW, Ws, Grain, _-Outs),
        try_windows(Ws, Outs, P0, Size, Check, P1, Applied, T0, T1),
        (   Applied == true
        ->  K1 is K - 1, win_rounds(K1, Name, TW, P1, Size, Grain, Check, P, T1, T)
        ;   P = P0, T = T1
        )
    ).
% the first window whose output differs and passes the check is applied; rejected ones are traced
try_windows([], _, P, _, _, P, false, T, T) :- !.
try_windows(_, [], P, _, _, P, false, T, T) :- !.
try_windows([W|Ws], [O|Os], P0, Size, Check, P, Applied, T0, T) :-
    (   ( O == none ; O == W ) -> try_windows(Ws, Os, P0, Size, Check, P, Applied, T0, T)
    ;   splice(P0, W, O, Size, Cand),
        ( Check == none -> Ok = true ; ( call(Check, P0, Cand) -> Ok = true ; Ok = false ) ),
        T1 = [_{window:W, output:O, accepted:Ok}|T0],
        (   Ok == true -> P = Cand, Applied = true, T = T1
        ;   try_windows(Ws, Os, P0, Size, Check, P, Applied, T1, T)
        )
    ).
