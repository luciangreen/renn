/*  config.pl -- paths for the pipeline, each one overridable by an environment variable.

    Variable       Default                         What it is
    EXP_DIR        /home/claude/exp                pairs.json and nets/<id>/ (built by convert_all.pl)
    RESULTS_DIR    <EXP_DIR>/results               where every stage writes its JSON
    WORK_DIR       <EXP_DIR>/work                  scratch networks, Popper and Aleph task folders
    PL2ANN_DIR     /home/claude/pl2ann             a pl2ann checkout
    PROVER         <this folder>/prover/prover.pl  the prover
    S2A_DIR        /home/claude/Philosophy/s2a     Spec to Algorithm (Philosophy repository)
    POPPER         /home/claude/pop_v2.1.0/popper.py   Popper 2.1.0 (a Python program)
    PYSWIP_PATH    /home/claude/build/pyswip/src   pyswip, which Popper needs
    ALEPH_LIB      /home/claude/research2/aleph/prolog   Aleph (friguzzi/aleph prolog folder)
    RULES_DIR      <this folder>/rules             the MNN rule programs (<rule>_orig.pl, <rule>_opt.pl)
    CLINGO         clingo                          the clingo executable */
:- module(config, [path/2]).

:- prolog_load_context(directory, D), assertz(here(D)).

path(Key, Value) :- default(Key, Env, Def), ( getenv(Env, V) -> Value = V ; call(Def, Value) ).

default(exp,     'EXP_DIR',     =('/home/claude/exp')).
default(results, 'RESULTS_DIR', sub(exp, results)).
default(work,    'WORK_DIR',    sub(exp, work)).
default(pl2ann,  'PL2ANN_DIR',  =('/home/claude/pl2ann')).
default(prover,  'PROVER',      local('prover/prover.pl')).
default(s2a,     'S2A_DIR',     =('/home/claude/Philosophy/s2a')).
default(popper,  'POPPER',      =('/home/claude/pop_v2.1.0/popper.py')).
default(pyswip,  'PYSWIP_PATH', =('/home/claude/build/pyswip/src')).
default(aleph,   'ALEPH_LIB',   =('/home/claude/research2/aleph/prolog')).
default(rules,   'RULES_DIR',   local(rules)).
default(clingo,  'CLINGO',      =(clingo)).

sub(Base, Name, P) :- path(Base, B), atomic_list_concat([B, /, Name], P).
local(Rel, P) :- here(D), atomic_list_concat([D, /, Rel], P).
