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

The JSON object requires `model_id`, `source_revision`, `license`, `layers`, and `validation_inputs`. Each layer requires a unique `name`, a non-empty rectangular `weights` matrix, a `bias` vector with one value per output row, and a supported `activation`. Layer dimensions must connect in order: each matrix column count equals the preceding layer's output count. Booleans are not accepted as numbers, and all weights, biases, and validation inputs must be finite.

### Import a Safetensors checkpoint

For dense MLPs stored in a Safetensors file, provide an architecture descriptor that maps each layer to its weight and bias tensor names:

```json
{
  "model_id": "tiny-mlp",
  "source_revision": "checkpoint-commit-or-revision",
  "license": "CC0-1.0",
  "layers": [
    {
      "name": "hidden",
      "weights_tensor": "hidden.weight",
      "bias_tensor": "hidden.bias",
      "activation": "relu"
    }
  ],
  "validation_inputs": [[1.0, 2.0]]
}
```

The weight tensors must be two-dimensional with output neurons first; biases must be one-dimensional. Layer dimensions, names, activations, and validation inputs are checked by the same model validator as JSON builds. Import and build with:

```sh
python3 -m renn import-safetensors model.safetensors architecture.json --output build/model
```

The importer safely parses the tensor data without loading or executing checkpoint code. It currently accepts `F16`, `BF16`, `F32`, and `F64` tensors for dense MLP weights and biases; integer/quantized formats, other architectures, and automatic architecture discovery are not supported. It reads the checkpoint into memory, so it is intended for small models. `provenance.pl` and `manifest.json` record the checkpoint and architecture-descriptor SHA-256 values. The revision and license are recorded from the descriptor and are not independently validated.

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
| `training_config.pl` | Training facts with explicit value and evidence tags |
| `training_report.md` | Human-readable account of unknown training details and why they cannot be reconstructed |
| `verification_cases.pl` | Input/output cases for the supplied validation inputs |
| `verification.json` | Reference layer activations, comparison tolerances, and verification status |
| `manifest.json` | SHA-256 hashes for every other generated artifact |

Generated files are deterministic for identical input bytes in the same runtime environment. If SWI-Prolog is installed, the CLI runs the emitted verifier and records `passed`; otherwise it records `generated_not_executed`. The verifier checks every layer activation and final output. The approximation ledger is empty: this input format performs no deliberate compression or rounding, although normal conversion of JSON numbers to runtime floating-point values still applies.

Check that build artifacts still match their manifest:

```sh
python3 -m renn verify build/tiny-mlp
```

This checks the SHA-256 digest of each listed artifact and fails if a file is missing, altered, or listed with an unsafe path. The manifest is unsigned, so this detects accidental changes but does not authenticate who created the files or prove their source.

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

### Compare with independent reference outputs

To compare the generated Prolog with outputs from an independent implementation (for example, the original framework), provide JSON test cases and run:

```sh
python3 -m renn compare build/tiny-mlp examples/tiny-mlp-reference.json
```

The reference file identifies the model and lists finite numeric inputs and expected outputs. An optional `expected_trace` checks named layer outputs as well:

```json
{
  "model_id": "tiny-mlp",
  "cases": [
    {
      "input": [1.0, 2.0],
      "expected_output": [-1.25],
      "expected_trace": [
        {"layer": "hidden", "output": [0.0, 1.75]},
        {"layer": "output", "output": [-1.25]}
      ]
    }
  ]
}
```

Comparison first verifies the build manifest, then runs the emitted Prolog using SWI-Prolog and checks outputs with the same `1e-9` absolute and relative tolerances. It requires SWI-Prolog 9.x; a mismatch exits nonzero. Only compare build directories you trust: this command executes their Prolog artifacts, and the manifest is unsigned. The reference values must be obtained separately from the implementation being checked. `examples/tiny-mlp-reference.json` is a runnable format example, not an external framework result. This command compares supplied samples; it does not load checkpoints or run a framework itself.

## Tests

From the repository root:

```sh
python3 -m unittest discover -s tests -v
```

The suite covers JSON parsing and shape validation, safe Safetensors import and tensor validation, deterministic hashes/artifacts, manifest integrity and tampering, evidence-tagged training metadata, the Python reference calculation, independent reference-output comparison, and (when SWI-Prolog is installed) executing the generated Prolog and checking both generated and supplied cases.

To run the full suite locally, install SWI-Prolog 9.x first; without it, the Prolog integration tests are skipped. GitHub Actions installs SWI-Prolog and runs this same command on every push and pull request, so the Prolog integration tests run in CI.

## Feature status

**Implemented in this prototype**

- User-provided JSON input for dense feed-forward networks.
- Safetensors import for dense MLPs using an explicit tensor-to-layer descriptor; only floating-point F16, BF16, F32, and F64 tensors are accepted.
- Strict layer dimensions, unique layer names, and finite-number validation; checkpoint or repository code is not loaded or executed.
- `linear`, `relu`, `tanh`, and `sigmoid` layers.
- Prolog architecture and complete weight/bias facts, plus pure-Prolog forward pass, intermediate trace, and a basic explanation result.
- Input/checkpoint and architecture descriptor hashes, declared revision/license, evidence-tagged unknown training facts and an underdetermination report, deterministic output hashes, and supplied-input differential cases.
- CLI integrity verification of generated artifacts against the unsigned manifest.
- CLI comparison of emitted Prolog against independently supplied outputs and optional layer traces.
- GitHub Actions CI for the Python suite and SWI-Prolog integration tests.

**Not implemented yet**

- GitHub/Hugging Face acquisition, revision pinning, checkpoint format detection, license-policy evaluation, and sandboxing.
- PyTorch, ONNX, GGUF, TensorFlow, Keras, convolutional/recurrent/transformer models, quantization, tokenizers, and large-model sidecars. Safetensors import is currently limited to small floating-point dense MLPs and reads the whole checkpoint into memory.
- Automated execution of an independent framework reference model and checkpoint-to-framework layer-wise comparisons (sample-based external reference comparisons are supported as documented above), adversarial/statistical verification, byte-identical reproducible environments, and signed manifests.
- Tier 1 circuit discovery/causal interventions, Tier 2 rule extraction, and evidence-backed explanations beyond the generated layer trace.
- Reconstructing training configuration or launch scripts from evidence, a benchmark suite, and publication-grade evaluation. The report documents what remains unknown rather than guessing.
- Automatic branch creation and pull request creation by the CLI.

The requirements and research acceptance criteria are maintained in [`pr1.md`](pr1.md). In particular, this prototype does not meet the stated acceptance criteria for transformer facsimiles, circuits, rule extraction, or publication results. The next implementation milestones are independent framework-run reference comparison and broader safe checkpoint support (large-model sidecars, quantization, and additional formats), followed by broader model operators and transformer support; interpretation and research benchmarks follow those foundations.
