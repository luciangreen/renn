:- use_module(prover).
batch :-
  ( getenv('NETS_DIR', NetsDir) -> true ; NetsDir = '../work/nets' ),
  ( getenv('OUT', OutFile) -> true ; OutFile = '../results/net_program_match.txt' ),
  open(OutFile, write, Out),
  forall(between(1, 200, I),
    ( format(atom(D), '~w/~w', [NetsDir, I]),
      atom_concat(D, '/net.pl', NF), atom_concat(D, '/src.pl', SF),
      ( exists_file(NF) ->
          read_program(SF, P),
          ( catch(net_matches_program(NF, P, R), E, R = error(E)) -> true ; R = failed ),
          ( R = proved(_) -> Tag = proved ; R = refuted(_,_) -> Tag = refuted ; R = refuted(E2) -> Tag = refuted_unit(E2) ; Tag = R ),
          format(Out, "~w ~q~n", [I, Tag])
      ; true ) )),
  close(Out).
