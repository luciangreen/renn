# renn_pipeline: program requirements

## Purpose

Read neural networks back into Prolog, and prove each step. The steps are:

- compile Prolog with pl2ann;
- prove that the network equals the program;
- recover the input from the output;
- learn code from that input and output;
- find the optimisation that turns the original program into the learned one.

This directory holds the phase-one pipeline and the prover shared with ann2pl and s2a2.

## Functional requirements

| Id | Requirement | Status |
| --- | --- | --- |
| R1 | Rebuild the 176 non-error pl2ann networks from `pl2ann_io_pairs.md` | done (`parse_pairs.pl`, `convert_all.pl`) |
| R2 | A weights-only simulator that reproduces the dataset's answers | done: 1,669 of 1,669 (`netlib.pl`, `validate_sim.pl`) |
| R3 | Prove that a network equals its program, clause by clause, from weights only | done: 176 of 176 (`prover/prover.pl`, `net_matches_program/4`), including compound terms, typed domains and arithmetic |
| R4 | Recover the input from the output, smallest and largest, with every answer verified | done (`invert.pl`, clingo) |
| R5 | Learn code from recovered input and output | done (`stage2_popper.pl`, `stage2_pool.pl`; Aleph in `stage2_aleph.pl`, `stage2_aleph_mnn.pl`) |
| R6 | Prove two programs equal for every input (syntactic, or exhaustive up to 2^16 inputs) | done (`equivalent/5`) |
| R7 | Join two networks at a shared predicate and prove the result | done (`compose.pl`) |
| R8 | Run the prover's 14 tests on every change | done (`prover/run_tests.sh`, `.github/workflows/prover.yml`) |
| R9 | Time limits from callers are never swallowed inside the prover | done (arithmetic errors fail the goal; time limits are rethrown) |
| R10 | The whole pipeline in SWI-Prolog | done: every stage is a `.pl` script; clingo, pl2ann and Popper are called as programs |
| R11 | Agreement on random inputs reproducible across the Python and Prolog versions | done (`datalog.pl`: Mersenne Twister seeded as Python's `random.Random`) |

## Related repositories

- [renn-inverse](https://github.com/luciangreen/renn-inverse): inputs of RENN's real-valued networks.
- [ann2pl](https://github.com/luciangreen/ann2pl): networks back to Prolog with variables.
- [s2a2](https://github.com/luciangreen/s2a2): learning the optimisation algorithm.

## Work remaining

1. **Deterministic Popper.** Popper can return different, equally short programs from identical input files. Fix its seed, or enumerate all optimal programs, so learned code is reproducible.
2. **Aleph by default.** Make Aleph the default learner for negation and arithmetic, and keep Popper for predicate invention.
3. **Largest input by default.** Run smallest and largest inversion together and pass both to the learner. That raised unique recovery from 50 to 98 of 156 networks.
4. **Compose more than two networks.** Composition is tested on one pair. Generalise it to any number of networks joined at observed predicates.
5. **Pre-registered benchmark.** Fix the success criteria before running, and publish them with the data.
