# Input/output pairs

[`io_pairs.md`](io_pairs.md) holds 200 input/output pairs for the RENN pipeline (`renn_pipeline`). Every output was produced by running this repository's code; nothing was written by hand.

| File | What it is |
|---|---|
| `generate.pl` | the queries, and the code that runs them (writes `pairs.jsonl` and `io_pairs.md`) |
| `harness.pl` | runs one query with a time limit and records what it printed and its variable bindings |
| `to_markdown.pl` | writes the recorded pairs as markdown |
| `pairs.jsonl` | the pairs, one JSON object per line |
| `io_pairs.md` | the pairs as markdown |

To regenerate them, build the networks first (see `config.pl` for EXP_DIR; clingo must be installed), from `renn_pipeline/`:

```
swipl convert_all.pl
swipl -q -g main -t halt io_pairs/generate.pl
```
