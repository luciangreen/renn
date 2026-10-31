# RENN pipeline: network → input → code → optimisation algorithm, checked by a Prolog prover

This is the code behind the report *Manual Neuronets: Exposing Black-Box Workings by Reading Neural Networks Back into Prolog*. Every stage is written in SWI-Prolog. It calls three outside programs: pl2ann (Prolog), clingo (the answer-set solver, as a command) and Popper (a Python program, used as a black box).

## What each part does

| Step | File | What it does |
| --- | --- | --- |
| — | `config.pl` | Paths, each overridable by an environment variable (`EXP_DIR`, `RESULTS_DIR`, `WORK_DIR`, `PL2ANN_DIR`, `S2A_DIR`, `POPPER`, `PYSWIP_PATH`, `ALEPH_LIB`, `CLINGO`, `PROVER`, `RULES_DIR`). |
| 0 | `parse_pairs.pl` | Parses `pl2ann_io_pairs.md` into `pairs.json`. |
| 0 | `convert_all.pl` | Compiles every dataset program with pl2ann (`--json` weight export). |
| 0 | `netlib.pl`, `validate_sim.pl` | Reads a network from its weights only and simulates it stratum by stratum. Reproduces all 1,669 dataset query answers. |
| 0 | `prover/prover.pl` `net_matches_program/3,4` | Proves a Prolog program equals a network, clause by clause, from neuron/edge facts only. |
| 1 | `invert.pl` | Finds the input from the output. Encodes the weights as an answer-set program and runs clingo; returns all smallest (or largest) inputs. |
| 1 | `stage1_run.pl`, `stage1_max.pl`, `stage1_cases.pl`, `stage1_summary.pl` | Inversion over the dataset (regimes Q and F, smallest and largest), and the trivial, edge and interesting cases. |
| 2 | `stage2_popper.pl`, `stage2_pool.pl`, `popper_tasks.pl` | Popper learns code from the recovered input and the network's output, per network and pooled. |
| 2 | `aleph.pl`, `stage2_aleph.pl`, `stage2_aleph_mnn.pl` | Aleph learns with negation (closed-world `not_P`) and arithmetic (AlgebraPLOp's formula, Detlog's comparison). |
| 2 | `datalog.pl` | A small stratified Datalog evaluator, and random-input agreement with a Mersenne Twister seeded exactly as Python's `random.Random`, so agreement figures match the earlier Python runs. |
| 3 | `stage3_core.pl` | Unoptimised originals → full pipeline → Spec to Algorithm learns each rewrite; windowed driver guarded by the prover. |
| 4 | `compose.pl` | Joins two networks by their shared atom neurons and learns the end-to-end rule. |
| 5 | `mnn_rules.pl`, `rules/` | Runs the method on the eight MNN rules (S2A, Starlog, PID, loop2, PLOp, AlgebraPLOp, Detlog, Piglog2). |
| 6 | `renn_bridge/renn_inverse.pl` | For RENN's real-valued networks; superseded by the [renn-inverse](https://github.com/luciangreen/renn-inverse) repository. |
| — | `pipeline.pl` | Shared helpers: compiling, calling the prover, Popper and S2A, program text, token grains for S2A, the windowed driver. |

## The prover (`prover/prover.pl`)

The prover checks that each stage's output is matched. Each call returns `proved(How)` or `refuted(Counterexample)`.

- `net_matches_program(+NetFile, +Program, -R)`: decodes every hidden unit from its weights into a ground clause and compares the set with the program grounded over the net's constants (compound terms, typed domains and arithmetic included). Units whose threshold is not gain × (positives − 0.5) are rejected.
- `net_equivalent_program(+NetFile, +Program, +Targets, +MaxInputs, -R)`: the same comparison by behaviour, over every subset of input atoms.
- `net_reproduces(+NetFile, +Input, +Observed, -R)`: the weights, clamped with Input, produce every observed `true(A)` / `false(A)`.
- `program_reproduces(+Program, +Input, +Observed, -R)`: the same for a Prolog program.
- `equivalent(+ProgA, +ProgB, +Targets, edb(Preds, Consts), -R)`: equal for every input. It tries a syntactic derivation first (duplicate literal, duplicate clause, θ-subsumed clause; sound for all domains), then an exhaustive check up to 2^16 inputs, then a fixed sample of 2,000 inputs (`passed_sample`, evidence rather than proof).

Run its 14 tests. `run_tests.sh` builds the three fixture networks in `prover/fixtures/` with pl2ann, then runs `test_prover.pl`, which exits 1 if any test fails:

```
git clone https://github.com/luciangreen/pl2ann /tmp/pl2ann
PL2ANN_DIR=/tmp/pl2ann prover/run_tests.sh
```

The `Prover tests` workflow in `.github/workflows/prover.yml` runs the same script on every push and pull request.

## Requirements

- SWI-Prolog 9 or 10, with `library(pcre)`.
- clingo 5.5 (the `clingo` command).
- pl2ann: https://github.com/luciangreen/pl2ann
- Spec to Algorithm: https://github.com/luciangreen/Philosophy (`s2a/`), with its sibling repositories listprologinterpreter, Languages, SSI, culturaltranslationtool, Prolog-to-List-Prolog and List-Prolog-to-Prolog-Converter checked out beside it.
- Popper 2.1.0 (`git clone --branch v2.1.0 https://github.com/logic-and-learning-lab/Popper`) with pyswip on `PYSWIP_PATH`.
- Aleph: https://github.com/friguzzi/aleph (its `prolog/` folder as `ALEPH_LIB`).

## Order to reproduce

```
export EXP_DIR=/path/to/data PL2ANN_DIR=/path/to/pl2ann      # and the others in config.pl as needed
swipl parse_pairs.pl pl2ann_io_pairs.md
swipl convert_all.pl && swipl validate_sim.pl
swipl stage1_run.pl && swipl stage1_summary.pl && swipl stage1_max.pl && swipl stage1_cases.pl
swipl stage2_popper.pl && swipl stage2_pool.pl && swipl stage2_aleph.pl
swipl stage3_core.pl
swipl compose.pl
swipl mnn_rules.pl && swipl stage2_aleph_mnn.pl
(cd prover && NETS_DIR=$EXP_DIR/work/nets OUT=$RESULTS_DIR/net_program_match.txt swipl -q -g "batch,halt" -t halt batch_match.pl)
```

## How the Prolog port was checked against the earlier Python scripts

Every stage was run in both versions and the outputs compared. `results/` holds the earlier (Python) runs that the report's numbers come from, and `results/prolog_port/` the same stages run with this Prolog code.

| Stage | Result |
| --- | --- |
| `parse_pairs` | `pairs.json` identical (200 pairs) |
| `convert_all` | 176/176 networks; weights, neurons and edges identical (only the source path in trace facts differs) |
| `validate_sim` | 176/176 sizes, 1,669/1,669 answers, as before |
| `stage1_run`, `stage1_max` | every status, count, size, uniqueness and verification field identical, except one network (47, regime Q) capped at 500 of a larger answer set, where whether the original falls inside the first 500 depends on enumeration order |
| `stage1_cases` | identical answer sets for all 13 cases |
| `stage2_aleph`, `stage2_aleph_mnn` | identical theories, inputs and equality checks (30 + 4 runs) |
| `datalog.pl` agreement | on the 156 programs the Python run learned, the Prolog evaluator gives the same agreement fraction and the same "reproduces the network" flag in 156/156 cases |
| `stage2_popper`, `stage2_pool` | identical example counts and input sizes; learned programs equal up to literal order except where several smallest inputs or several equally short programs exist and a different one was chosen (both clingo's Python interface and Popper vary between runs on identical input) |
| `stage3_core` | identical networks, matches, inversions, proofs, S2A outputs and windowed rewrites; Popper's programs equal up to literal order |
| `compose` | identical networks and proofs; the joint observation recovers the same input and learns the same composed rule (checked on 2,000 sampled inputs) |
| `mnn_rules` | identical networks, matches, inversions and S2A results. One proof changed, and the new one is right: AlgebraPLOp original against optimised was `proved(exhaustive(8))` with the older prover, which did not evaluate `is/2`; the current prover refutes it, because the rule-only original has no base case `val(0,1)` (see S2A2's finding that the closed form needs a gap-free index) |

Two sources of run-to-run variation are outside the port. clingo's order of equally good answers differs between runs of its Python interface, whereas the `clingo` command used here gives the same order every time. Popper can return different, equally short programs from the same files.

## Two traps we hit

- Popper's examples file uses `pos/1` and `neg/1`. A background predicate called `pos/1` silently breaks learning, so `pipeline:popper/7` renames it.
- A helper called `try/2` or `learn/2` loaded beside S2A overrides S2A's own predicates. Keep helper names prefixed (we use `xs_`).

## Related repositories (Manual Neuronets pipeline)

| Repository | Step |
| --- | --- |
| [pl2ann](https://github.com/luciangreen/pl2ann) | Prolog → threshold network |
| [renn-inverse](https://github.com/luciangreen/renn-inverse) | the inputs of a RENN (real-valued) network from its output: exact for ReLU, exact last layer for softmax/sigmoid/tanh, certified boxes otherwise |
| [ann2pl](https://github.com/luciangreen/ann2pl) | a pl2ann network → Prolog with variables, proved equal (176/176) |
| [s2a2](https://github.com/luciangreen/s2a2) | learns the optimisation algorithm from (original, optimised) program pairs, on terms, with an MNN-ordered search |

The prover in `prover/` is the same file in all of them. This copy now handles compound and list terms, typed domains and arithmetic (`net_matches_program/4`).
