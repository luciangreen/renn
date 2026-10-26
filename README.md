# renn

`renn` is a prototype for translating neural networks into inspectable Prolog. The current implementation is a small, deterministic Tier 0 foundation: it accepts a user-authored JSON description of a dense feed-forward network and emits Prolog architecture, weights, forward/trace predicates, provenance, and verification artifacts.

It does **not** download models, inspect framework checkpoints, infer architectures, or claim research-grade equivalence. See [Feature status](#feature-status) for the implemented scope and remaining work.

## Requirements

- Python 3.10 or later (standard library only)
- SWI-Prolog 9.x to execute and independently check emitted Prolog

Python unit tests also run without SWI-Prolog; the Prolog integration test is skipped when `swipl` is unavailable.

## Build a model

Create a JSON file such as `examples/tiny-mlp.json`:

```json
{
  "model_id": "tiny-mlp",
  "source_revision": "local-example-v1",
  "license": "CC0-1.0",
  "layers": [
    {
      "name": "hidden",
      "weights": [[1.0, -1.0], [0.5, 0.5]],
      "bias": [0.0, 0.25],
      "activation": "relu"
    },
    {
      "name": "output",
      "weights": [[2.0, -1.0]],
      "bias": [0.5],
      "activation": "linear"
    }
  ],
  "validation_inputs": [[1.0, 2.0], [0.0, 0.0]]
}
```

Each weight matrix is output-neuron first: `weights[output_index][input_index]`. Supported activations are `linear`, `relu`, `tanh`, and `sigmoid`. At least one finite numeric validation input is required; its width must match the first layer. The license and revision are recorded as supplied metadata, not legally verified.

Run:

```sh
python3 -m renn build examples/tiny-mlp.json --output build/tiny-mlp
```

The build directory contains:

| File | Purpose |
| --- | --- |
| `architecture.pl` | Layer order, sizes, names, and activations |
| `weights.pl` | Every matrix and bias vector from the input |
| `ops.pl` | Pure-Prolog `forward/3`, `trace/3`, and `explain/3` |
| `provenance.pl` | Declared source metadata and input artifact SHA-256 |
| `training_config.pl` | Unknown training details, without invented defaults |
| `verification_cases.pl` | Input/output cases for the supplied validation inputs |
| `verification.json` | Reference layer activations, comparison tolerances, and verification status |
| `manifest.json` | SHA-256 hashes for every other generated artifact |

Generated files are deterministic for identical input bytes in the same runtime environment. If SWI-Prolog is installed, the CLI runs the emitted verifier and records `passed`; otherwise it records `generated_not_executed`. The verifier checks every layer activation and final output. The approximation ledger is empty: this input format performs no deliberate compression or rounding, although normal conversion of JSON numbers to runtime floating-point values still applies.

### Run emitted Prolog

From the output directory:

```sh
swipl -q -s ops.pl -g "forward('tiny-mlp',[1.0,2.0],Y),writeln(Y)" -t halt
```

Expected output for the example: `[-1.25]`.

Run the generated validation cases (SWI-Prolog 9.x):

```sh
swipl -q -s verification_cases.pl -g run_verification -t halt
```

The command exits with an error if any generated Prolog result differs from its Python reference by more than `1e-9` absolute or relative tolerance.

## Tests

From the repository root:

```sh
python3 -m unittest discover -s tests -v
```

The suite covers parsing and shape validation, non-finite and invalid values, deterministic hashes/artifacts, the Python reference calculation, and (when SWI-Prolog is installed) executing the generated Prolog and checking the validation cases.

## Feature status

**Implemented in this prototype**

- User-provided JSON input for dense feed-forward networks.
- Strict layer dimensions and finite-number validation; no checkpoint or repository code is loaded or executed.
- `linear`, `relu`, `tanh`, and `sigmoid` layers.
- Prolog architecture and complete weight/bias facts, plus pure-Prolog forward pass, intermediate trace, and a basic explanation result.
- Input artifact hash, declared revision/license, explicit unknown training metadata, deterministic output hashes, and supplied-input differential cases.

**Not implemented yet**

- GitHub/Hugging Face acquisition, revision pinning, checkpoint format detection, license-policy evaluation, and sandboxing.
- Safetensors, PyTorch, ONNX, GGUF, TensorFlow, Keras, convolutional/recurrent/transformer models, quantization, tokenizers, and large-model sidecars.
- An independent reference-model runner, layer-wise framework comparisons, adversarial/statistical verification, byte-identical reproducible environments, signed manifests, and continuous integration.
- Tier 1 circuit discovery/causal interventions, Tier 2 rule extraction, and evidence-backed explanations beyond the generated layer trace.
- Training-configuration reconstruction, benchmark suite, and publication-grade evaluation.
- Automatic branch creation and pull request creation by the CLI.

The requirements and research acceptance criteria are maintained in [`pr1.md`](pr1.md). In particular, this prototype does not meet the stated acceptance criteria for transformer facsimiles, circuits, rule extraction, or publication results. The next implementation milestones are safe checkpoint ingestion and independent reference comparison for the reference MLP, then broader model operators and transformer support; interpretation and research benchmarks follow those foundations.
