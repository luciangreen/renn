/*  renn_inverse.pl -- the method applied to RENN's real-valued networks.

    RENN (github.com/luciangreen/renn) turns a dense network described in JSON into
    Prolog: weights/3, biases/3, layer/6 and forward/3. This file reads ONLY those
    weight and architecture facts and, for networks whose activations are
    piecewise linear (relu, linear), does three things exactly with CLP(Q):

      invert(Model, Output, Lo-Hi, Regions)
          every region of inputs in the box [Lo,Hi]^n that produces Output
          (finding the input from the output; usually a set, not a point)

      rules(Model, Lo-Hi, Rules)
          the network rewritten as if-then rules, one per ReLU on/off pattern
          (Tier 2 rule extraction that is exact, not approximate)

      check_rules(Model, Lo-Hi, N, Result)
          the rules agree with RENN's own forward/3 on N grid inputs (the prover's
          behavioural check for real-valued nets)

    tanh, sigmoid and softmax are not piecewise linear; for them invert/4 and
    rules/3 refuse with unsupported(Activation).
*/
:- module(renn_inverse, [invert/4, rules/3, check_rules/4, print_rules/2]).
:- use_module(library(clpq)).
:- use_module(library(lists)).
:- use_module(library(apply)).

% ---------------------------------------------------------------- symbolic forward pass
% sym_forward(+Model, +Inputs, -Outputs, -Pattern): Inputs are CLP(Q) variables; every
% relu unit chooses on (sum >= 0, out = sum) or off (sum =< 0, out = 0) on backtracking.
sym_forward(Model, In, Out, Pattern) :-
    sym_layers(Model, 1, In, Out, Pattern).
sym_layers(Model, I, In, Out, [P|Ps]) :-
    renn_architecture:layer(Model, I, _Name, _, _, Act),
    renn_weights:weights(Model, I, W), renn_weights:biases(Model, I, B),
    maplist(sym_unit(Act, In), W, B, Mid, P),
    I1 is I + 1,
    (   renn_architecture:layer(Model, I1, _, _, _, _)
    ->  sym_layers(Model, I1, Mid, Out, Ps)
    ;   Out = Mid, Ps = []
    ).
sym_unit(Act, In, Row, Bias, Y, Choice) :-
    lin(Row, In, Bias, S),
    act(Act, S, Y, Choice).
lin([], [], B, S) :- Q is rationalize(B), { S = Q }.
lin([W|Ws], [X|Xs], B, S) :- lin(Ws, Xs, B, S0), Q is rationalize(W), { S = S0 + Q*X }.
act(linear, S, S, lin).
act(relu, S, Y, on)  :- { S >= 0, Y = S }.
act(relu, S, Y, off) :- { S =< 0, Y = 0 }.
act(A, _, _, _) :- \+ memberchk(A, [linear, relu]), throw(unsupported(A)).

box(Lo-Hi, Xs) :- L is rationalize(Lo), H is rationalize(Hi), maplist([X]>>{X >= L, X =< H}, Xs).

input_size(Model, N) :- renn_architecture:layer(Model, 1, _, N, _, _).

% ---------------------------------------------------------------- 1. input from output
invert(Model, Target, Box, Regions) :-
    input_size(Model, N),
    findall(region(Pattern, Bounds, Witness),
            ( length(Xs, N), box(Box, Xs),
              sym_forward(Model, Xs, Ys, Pattern),
              maplist([Y,T]>>(Q is rationalize(T), {Y = Q}), Ys, Target),
              bounds(Xs, Bounds), witness(Xs, Witness) ),
            Regions).

bounds(Xs, Bs) :- maplist([X, L-H]>>(inf(X, L0), sup(X, H0), L is float(L0), H is float(H0)), Xs, Bs).
% a concrete point inside the region: fix each input in turn to the middle of its range
witness([], []).
witness([X|Xs], [V|Vs]) :- inf(X, L), sup(X, H), M is (L + H) / 2, { X = M }, V is float(M), witness(Xs, Vs).

% ---------------------------------------------------------------- 2. exact rules
rules(Model, Box, Rules) :-
    input_size(Model, N),
    findall(rule(Pattern, NXs, NYs, Region),
            ( length(Xs, N), box(Box, Xs),
              sym_forward(Model, Xs, Ys0, Pattern),
              length(Ys0, NY), length(Ys, NY),
              maplist([A,B]>>{A = B}, Ys, Ys0),
              append(Xs, Ys, Vars),
              length(Xs, NXl), length(NXs, NXl), length(NYs, NY), append(NXs, NYs, Names),
              safe_dump(Vars, Names, Region) ),
            Rules).

print_rules(Model, Box) :-
    rules(Model, Box, Rules), length(Rules, K),
    format("% ~w: ~d exact rules over the box ~w~n", [Model, K, Box]),
    forall(member(rule(P, Xs, Ys, R), Rules),
           ( numbervars(Xs-Ys-R, 0, _), format("rule(~q, ~q) :- ~q.   % pattern ~q~n", [Xs, Ys, R, P]) )).

% ---------------------------------------------------------------- 3. rules agree with RENN's forward/3
check_rules(Model, Lo-Hi, Steps, Result) :-
    input_size(Model, N), rules(Model, Lo-Hi, Rules),
    Step is (Hi - Lo) / Steps,
    numlist(0, Steps, Is),
    findall(P, ( length(P, N), maplist([V]>>(member(I, Is), V is Lo + I*Step), P) ), Points),
    length(Points, NP),
    (   member(P, Points),
        renn_ops:forward(Model, P, Out),
        \+ rule_gives(Rules, P, Out)
    ->  Result = refuted(input(P), network_output(Out))
    ;   Result = agreed_on_grid(NP)
    ).
rule_gives(Rules, P, Out) :-
    member(rule(_, Xs0, Ys0, R0), Rules),
    copy_term(Xs0-Ys0-R0, Xs-Ys-R),
    maplist([X,V]>>(Q is rationalize(V), X = Q), Xs, P),
    catch(maplist(call_constraint, R), _, fail),
    maplist([Y,O]>>(Y0 is float(Y), abs(Y0 - O) =< 1.0e-9 * max(1, abs(O))), Ys, Out), !.
call_constraint(C) :- { C }.

% dump/3 needs unbound targets; a variable the constraints fixed to a number becomes Name = Value
safe_dump(Vars, Names, Region) :-
    foldl(split_bound, Vars, Names, []-[]-[], Fs-FNs-Eqs),
    dump(Fs, FNs, R0), append(R0, Eqs, Region).
split_bound(V, N, Fs-FNs-Eqs, Fs1-FNs1-Eqs1) :-
    (   var(V) -> Fs1 = [V|Fs], FNs1 = [N|FNs], Eqs1 = Eqs
    ;   Fs1 = Fs, FNs1 = FNs, Eqs1 = [N = V|Eqs]
    ).
