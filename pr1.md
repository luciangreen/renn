**Prolog Neural Network Reverse-Engineering Agent — Requirements**  
Version for Doctoral Research  
27 October 2026

### 1. Purpose and Scope

This agent takes an open-weight neural network (from GitHub or Hugging Face) and produces a Prolog program that computes exactly the same thing as the original model. It also produces clear, evidence-tagged explanations of how the Prolog version was built and what parts of the model’s behaviour can be understood.

**In scope**  
- Open-weight models the user can lawfully download.  
- Classic networks (MLPs, CNNs, RNNs) and transformer language models.

**Out of scope**  
- Closed or hosted models.  
- Recovery of training data.  
- Anything that breaks the model’s licence.

**What “complete, undoctored facsimile” means**  
The Prolog version is accepted only if three conditions hold:

1. **Complete** — Every weight tensor from the original checkpoint is present, with matching shapes and counts.  
2. **Exact** — The Prolog program produces the same outputs as the original (within declared numeric tolerance).  
3. **Undoctored** — No silent simplification, pruning, or rounding. Every change is recorded in an approximation ledger with its measured effect on accuracy.

### 2. Fidelity Tiers

Only Tier 0 is a true exact copy. Higher tiers make the model more readable and must report how faithful they remain.

| Tier | What it produces | How faithful it must be | Readable by a person? | When it applies |
|------|------------------|--------------------------|-----------------------|-----------------|
| 0 – Exact translation | All weights as Prolog facts + operators that run the full forward pass | Bit-exact for integer/quantised models; within declared float tolerance otherwise | No — it is the model restated | Every model (mandatory) |
| 1 – Circuit extraction | Small subgraphs that drive a named behaviour | Measured recovery score + causal tests (see Benchmarks) | Partly | Transformers and deep nets |
| 2 – Rule extraction | Simple if-then rules | Measured agreement with the model on held-out data | Yes | Small networks or single components |

Tier 0 is the source of truth. Tiers 1 and 2 are derived from it and must cite the Tier 0 facts they use.

### 3. System Architecture and Workflow

The agent runs in eight stages. A verification gate sits between generation and any output the user sees. If verification fails, a discrepancy log is returned to the generator. Interpretation (Tiers 1 and 2) runs only on a verified Tier 0 facsimile.

### 4. Functional Requirements

**Acquisition**  
- FR-1 Accept a GitHub repository URL or Hugging Face model ID, pinned to a specific commit or revision.  
- FR-2 Detect common checkpoint formats (safetensors, PyTorch, ONNX, GGUF, TensorFlow, Keras).  
- FR-3 Read the model licence and stop with a clear report if analysis or derivative works are forbidden.  
- FR-4 Load weights only with safe, non-executing loaders. Never unpickle untrusted objects.  
- FR-5 Run any repository code needed to understand the architecture only inside a network-isolated sandbox.

**Architecture recovery**  
- FR-6 Build the computation graph from the most reliable source available (ONNX graph preferred, then model code, then config files, then tensor names and shapes).  
- FR-7 Tag every architectural fact with its evidence source. Shape-only guesses must be labelled “inferred”.  
- FR-8 Detect and represent quantisation schemes exactly; never de-quantise silently.

**Prolog generation**  
- FR-9 Emit every tensor as Prolog facts or as a hash-checked binary sidecar.  
- FR-10 Provide a standard operator library (matrix multiply, convolution, attention, normalisation, activation functions, residual connections, etc.).  
- FR-11 Provide `forward/3` (model, input, output) and a step-by-step `trace/3` that records intermediate activations.  
- FR-12 Reproduce the tokenizer as facts with `encode/3` and `decode/3`.

**Interpretation**  
- FR-13 Tier 1: Locate circuits for a user-supplied behaviour using activation patching and attribution. Emit them as subgraph predicates together with recovery and causal scores.  
- FR-14 Tier 2: Extract simple rules from small networks or components and report agreement with the model.  
- FR-15 Provide `explain/3` queries that return the facts and activations behind a given output.

**Delivery**  
- FR-16 Write results to a new branch and open a pull request containing the Prolog files, sidecars, manifest, and verification report.  
- FR-17 Add a continuous-integration workflow that re-runs verification on every change.

### 5. Prolog Knowledge Representation

The program is split into five modules so facts, mathematics, and explanations can be checked independently. Target platform: SWI-Prolog 9.x. Heavy tensor mathematics may use C for speed; a pure-Prolog version of every operator must also exist for verification on small models.

| Module | Contents |
|--------|----------|
| provenance.pl | Source repository, revision, licence, file hashes |
| architecture.pl | Layers, connections, hyperparameters — each with an evidence tag |
| weights.pl | Tensor facts (inline for small tensors, sidecar references for large ones) |
| ops.pl | Operator predicates, `forward/3`, `trace/3` |
| interpret.pl | Tier 1 circuits, Tier 2 rules, `explain/3` |

### 6. Training-Configuration Inference

Weights tell us what the model computes, not how it was trained. The agent reconstructs training details only as far as the evidence allows and labels every claim clearly.

| Evidence tag | Meaning |
|--------------|---------|
| stated | Read directly from a file in the repository |
| derived | Follows deterministically from the weights |
| inferred | Statistical estimate, always with a confidence score and the evidence used |
| unknown | Not recoverable from the available artefacts |

- IR-1 Emit a `training_config.pl` file and a human-readable reconstructed launch script. Every line is annotated with its evidence tag.  
- IR-2 Anything tagged unknown is written as unknown. The agent must not invent plausible defaults.  
- IR-3 Every inferred claim carries a confidence score and the supporting evidence.  
- IR-4 Produce an under-determination report listing families of training procedures that remain indistinguishable given the artefacts.

### 7. Verification, Provenance and Anti-Doctoring

A facsimile is accepted only when an independent harness (not the generator) confirms it matches the reference model.

- VR-1 Hash chain — hash every source tensor on load and every exported tensor after export. Any mismatch fails the build.  
- VR-2 Layer-wise differential testing — compare every intermediate activation, not just the final output.  
- VR-3 End-to-end numeric tolerance — exact equality for integer and quantised paths; declared maximum relative error for floating-point (set per data type).  
- VR-4 Behavioural match — for language models, greedy decoding produces the same tokens as the reference on a fixed prompt suite.  
- VR-5 Approximation ledger — every transformation is logged with its location and measured fidelity cost. An empty ledger is the expected result for a pure Tier 0.  
- VR-6 Reproducible build — pinned tool versions; regenerating from the same revision yields byte-identical Prolog files.  
- VR-7 Signed manifest — lists every output file, its hash, the source revision, and the verification results.  
- VR-8 Adversarial verification — include inputs deliberately chosen to maximise intermediate differences.  
- VR-9 Statistical testing — layer-wise discrepancies are tested across a large random input set with appropriate multiple-comparison correction.

### 8. Complete Benchmark Suite

All results intended for doctoral publication must be evaluated on the following public, versioned benchmark suite. Success criteria are defined in advance.

**Tier 0 Exactness Benchmarks**  
- Small MLP (reference implementation provided).  
- Small open-weight transformer (≤ 100 M parameters).  
- Mid-size open-weight transformer (approximately 1 B parameters).  
- One quantised model (GGUF or equivalent).  

Required: pass VR-1 to VR-9 with empty or fully justified approximation ledger. Report wall-clock time and peak memory.

**Tier 1 Circuit Benchmarks**  
Standard behaviours with pre-registered success criteria:  
- Induction heads / in-context learning.  
- Indirect Object Identification (IOI).  
- Greater-than / numerical comparison.  
- One user-supplied behaviour per model.  

Required metrics for every circuit:  
- Recovery score (behaviour recovered when only the circuit runs).  
- Ablation score (behaviour collapses when the circuit is removed).  
- Interchange intervention / activation-patching score.  
- Negative-control score (circuit must not recover unrelated behaviours above chance).  
- Statistical significance across multiple random seeds and prompt distributions.  
- Held-out prompt suite never used during discovery.

**Tier 2 Rule Benchmarks**  
- Reference MLP.  
- Single attention head or MLP block from a small transformer.  

Required: agreement with the original model on a held-out set, comparison against strong baselines (decision trees trained on the same activations, linear probes), and effect-size reporting.

**Cross-cutting Benchmarks**  
- Superposition audit (sparse autoencoder or equivalent) on key layers of every model larger than a few million parameters. Report fraction of behaviour explained by monosemantic versus residual features.  
- Family-level consistency: for at least one model family, report which circuits and features are conserved across variants.  
- Computational cost: report time and memory for every stage.

### 9. Publication Standards for Doctoral Results

Results may be submitted for publication only when they meet all of the following standards. These standards exist so that complex technical work remains trustworthy and understandable.

**Clarity and honesty**  
- State the exact claim being made in plain language at the start of every result section.  
- Report residual uncertainty explicitly. Never imply that a circuit or rule explains the whole model when it explains only part of it.  
- Distinguish correlation from causation. Causal tests are required for any claim that a circuit “implements” a behaviour.

**Evidence and reproducibility**  
- Every number in a paper must be traceable to a signed verification report and a public commit hash.  
- Release the exact Prolog facsimile, the approximation ledger, the benchmark prompts, and the evaluation scripts.  
- Pin every software version used for both generation and reference runs.

**Evaluation completeness**  
- Report all pre-registered metrics, including negative results and failed circuit searches.  
- Provide both in-distribution and distribution-shift performance.  
- Compare against strong baselines; absolute numbers alone are not sufficient.

**Handling of complexity**  
- When discussing superposition, polysemanticity, or under-determination, define the terms once in simple language and then use them consistently.  
- Use diagrams or short pseudocode to show the structure of any recovered circuit.  
- Separate “what the model computes” (Tier 0) from “what we currently understand about how it computes it” (Tiers 1 and 2).

**Ethical and licensing compliance**  
- Record the model licence in the provenance module.  
- Do not redistribute weight sidecars when the licence forbids it; publish generator, hashes, and verification reports instead.

### 10. Non-Functional Requirements

- NFR-1 Scale — Large models stream weights from memory-mapped sidecars. The Prolog database does not need to hold every fact at once.  
- NFR-2 Performance — Correctness is the goal; speed is secondary. Pure-Prolog operators are required for verification on small models.  
- NFR-3 Security — No untrusted code runs outside the sandbox. The sandbox has no network access.  
- NFR-4 Licensing — Honour the original model licence in all published artefacts.  
- NFR-5 Scope guard — Accept only checkpoints the user supplies or downloads from public open-weight sources.  
- NFR-6 Portability — Runs on SWI-Prolog 9.x on Linux and macOS. The agent itself runs as a GitHub Action or locally.  
- NFR-7 Auditability — Every output is traceable to a source tensor, file, or evidence item.

### 11. Known Limits and Acceptance Criteria

**Known limits (stated plainly)**  
- An exact copy of a large language model is still a very large collection of numbers. Exactness does not automatically create understanding.  
- Neurons in large models often encode many features at once. Tier 1 and Tier 2 results therefore explain parts of behaviour, never the whole network.  
- Most details of how a model was trained cannot be recovered from the weights alone.  
- Floating-point arithmetic is not associative; exact numeric matching may require reproducing the original library’s summation order.

**Acceptance criteria for the agent itself**  
- Tier 0 facsimile of the reference MLP passes all verification requirements with an empty approximation ledger.  
- Tier 0 facsimile of a small open-weight transformer passes all verification requirements, including greedy-decode match.  
- Tier 2 rules for the reference MLP meet the pre-registered agreement target.  
- At least one Tier 1 circuit report is produced for a named behaviour, with full causal metrics.  
- `training_config.pl` contains no untagged claims.  
- The agent opens a pull request that includes outputs and a passing continuous-integration run.

### 12. Core Research Questions the System Is Designed to Answer

1. What is the largest model for which we can produce a verified Tier 0 facsimile plus at least one high-recovery, causally validated circuit under realistic compute budgets?  
2. How does the quality of recovered circuits change as models grow larger and as superposition increases?  
3. What fraction of commonly studied behaviours in modern language models admit compact, high-recovery circuits?  
4. How much of a model’s training configuration can be reliably recovered from weights and repository artefacts alone?  
5. Can the Prolog representation enable new analyses (formal verification of properties, symbolic reasoning about circuits, compositional tests) that are difficult in the original framework?

These requirements turn the agent into a research platform capable of producing reliable, publishable results while keeping every complex idea stated as clearly as possible.
