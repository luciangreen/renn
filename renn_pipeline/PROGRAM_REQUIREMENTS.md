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
| R1 | Rebuild the 176 non-error pl2ann networks from `pl2ann_io_pairs.md` | done (`convert_all.py`) |
| R2 | A weights-only simulator that reproduces the dataset's answers | done: 1,669 of 1,669 (`validate_sim.py`) |
| R3 | Prove that a network equals its program, clause by clause, from weights only | done: 176 of 176 (`prover/prover.pl`, `net_matches_program/4`), including compound terms, typed domains and arithmetic |
| R4 | Recover the input from the output, smallest and largest, with every answer verified | done (`renn_invert.py`, clingo) |
| R5 | Learn code from recovered input and output | done (`stage2_popper.py`; Aleph runs are in the report) |
| R6 | Prove two programs equal for every input (syntactic, or exhaustive up to 2^16 inputs) | done (`equivalent/5`) |
| R7 | Join two networks at a shared predicate and prove the result | done (`compose.py`) |
| R8 | Run the prover's 14 tests on every change | done (`prover/run_tests.sh`, `.github/workflows/prover.yml`) |
| R9 | Time limits from callers are never swallowed inside the prover | done (arithmetic errors fail the goal; time limits are rethrown) |

## Related repositories

- [renn-inverse](https://github.com/luciangreen/renn-inverse): inputs of RENN's real-valued networks.
- [ann2pl](https://github.com/luciangreen/ann2pl): networks back to Prolog with variables.
- [s2a2](https://github.com/luciangreen/s2a2): learning the optimisation algorithm.

## Work remaining

1. **One language.** The pipeline stages (inversion, Popper and Aleph drivers, composition) are Python. Port them to SWI-Prolog, so the whole chain runs in Prolog, calling clingo through its Prolog interface or a subprocess.
2. **Aleph by default.** Make Aleph the default learner for negation and arithmetic, and keep Popper for predicate invention.
3. **Largest input by default.** Run smallest and largest inversion together and pass both to the learner. That raised unique recovery from 50 to 98 of 156 networks.
4. **Compose more than two networks.** Composition is tested on one pair. Generalise it to any number of networks joined at observed predicates.
5. **Pre-registered benchmark.** Fix the success criteria before running, and publish them with the data.
