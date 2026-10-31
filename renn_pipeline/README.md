# RENN pipeline: network → input → code → optimisation algorithm, checked by a Prolog prover

This is the code behind the paper *Reading neural networks back into Prolog*. Every claim in the paper comes from these scripts and the JSON files in `results/`.

## What each part does

| Step | File | What it does |
| --- | --- | --- |
| 0 | `convert_all.py` | Compiles every dataset program with pl2ann (`--json` weight export). |
| 0 | `netlib.py`, `validate_sim.py` | Reads a network from its weights only and simulates it stratum by stratum. Reproduces all 1,669 dataset query answers. |
| 0 | `prover/prover.pl` `net_matches_program/3` | Proves a Prolog program equals a network, clause by clause, from neuron/edge facts only. |
| 1 | `renn_invert.py` | Finds the input from the output. Encodes the weights as an answer-set program (clingo) and returns all smallest inputs. |
| 1 | `stage1_run.py`, `stage1_cases.py` | Inversion over the dataset (regimes Q and F) and the trivial, edge and interesting cases. |
| 2 | `stage2_popper.py`, `stage2_pool.py` | Popper learns code from the recovered input and the network's output, per network and pooled. |
| 3 | `stage3_core.py` | Unoptimised originals → full pipeline → Spec to Algorithm learns each rewrite; windowed driver guarded by the prover. |
| 4 | `compose.py` | Joins two networks by their shared atom neurons and learns the end-to-end rule. |
| 5 | `mnn_rules.py`, `rules/` | Runs the method on the eight MNN rules (S2A, Starlog, PID, loop2, PLOp, AlgebraPLOp, Detlog, Piglog2). |
| 6 | `renn_bridge/renn_inverse.pl` | For RENN's real-valued relu/linear networks: finds every input region that gives an output, and rewrites the network as exact rules, using RENN's own weights.pl with CLP(Q). `run_tiny.pl` runs it on tiny-mlp (build it first with `python3 -m renn build examples/tiny-mlp.json --output build/tiny-mlp`, then run from that folder with renn_inverse.pl copied beside it). |
| — | `pipeline.py`, `datalog.py` | Shared helpers: compiling, calling the prover, Popper and S2A, token grains for S2A. |

## The prover (`prover/prover.pl`)

The prover checks that each stage's output is matched. Each call returns `proved(How)` or `refuted(Counterexample)`.

- `net_matches_program(+NetFile, +Program, -R)`: decodes every hidden unit from its weights into a ground clause and compares the set with the program grounded over the net's constants. Units whose threshold is not gain × (positives − 0.5) are rejected.
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

## Requirements and paths

- SWI-Prolog 9 or 10, clingo 5.5 with its Python module, Python 3.11+.
- pl2ann: https://github.com/luciangreen/pl2ann
- Spec to Algorithm: https://github.com/luciangreen/Philosophy (`s2a/`), with its sibling repositories listprologinterpreter, Languages, SSI, culturaltranslationtool, Prolog-to-List-Prolog and List-Prolog-to-Prolog-Converter checked out beside it.
- Popper 2.1.0 (`git clone --branch v2.1.0 https://github.com/logic-and-learning-lab/Popper`) with pyswip on `PYTHONPATH`.

The research scripts were written for one machine and still contain its absolute paths (`/home/claude/...`). The paths are constants at the top of `pipeline.py` (`PL2ANN`, `S2A_DIR`, `POPPER`, `WORK`), in `stage2_popper.py` (`POPPER`, `ENV`), in `convert_all.py`; the prover takes its pl2ann path from the `PL2ANN_PROLOG` environment variable. Edit them for your machine.

## Two traps we hit

- Popper's examples file uses `pos/1` and `neg/1`. A background predicate called `pos/1` silently breaks learning, so `pipeline.popper` renames it.
- A helper called `try/2` or `learn/2` loaded beside S2A overrides S2A's own predicates. Keep helper names prefixed (we use `xs_`).

## Order to reproduce

```
python3 parse_pairs.py pl2ann_io_pairs.md
python3 convert_all.py && python3 validate_sim.py
python3 stage1_run.py && python3 stage1_summary.py && python3 stage1_cases.py
python3 stage2_popper.py && python3 stage2_pool.py
python3 stage3_core.py
python3 compose.py
python3 mnn_rules.py
(cd prover && NETS_DIR=../work/nets OUT=../results/net_program_match.txt swipl -q -g "batch,halt" -t halt batch_match.pl)
```
