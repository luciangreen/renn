import hashlib
import json
import math
import re
import shutil
import subprocess
from pathlib import Path


ACTIVATIONS = {"linear", "relu", "tanh", "sigmoid"}
IDENTIFIER = re.compile(r"^[A-Za-z0-9_.-]+$")
ABS_TOLERANCE = 1e-9
REL_TOLERANCE = 1e-9


class BuildError(ValueError):
    """Raised when an input model description is invalid."""


def _is_number(value):
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _identifier(value, label):
    if not isinstance(value, str) or not value or not IDENTIFIER.fullmatch(value):
        raise BuildError(f"{label} must contain only letters, digits, '.', '_' or '-'")
    return value


def _number_list(values, label):
    if not isinstance(values, list) or not values or not all(_is_number(value) for value in values):
        raise BuildError(f"{label} must be a non-empty list of finite numbers")
    return [float(value) for value in values]


def load_model(path):
    try:
        with path.open(encoding="utf-8") as file:
            model = json.load(file)
    except json.JSONDecodeError as exc:
        raise BuildError(f"invalid JSON: {exc}") from exc
    if not isinstance(model, dict):
        raise BuildError("model description must be a JSON object")
    model_id = _identifier(model.get("model_id"), "model_id")
    revision = model.get("source_revision")
    license_name = model.get("license")
    if not isinstance(revision, str) or not revision.strip() or any(ord(char) < 32 for char in revision):
        raise BuildError("source_revision must be a non-empty string")
    if not isinstance(license_name, str) or not license_name.strip() or any(ord(char) < 32 for char in license_name):
        raise BuildError("license must be a non-empty string")
    layers = model.get("layers")
    if not isinstance(layers, list) or not layers:
        raise BuildError("layers must be a non-empty list")

    checked_layers = []
    expected_inputs = None
    for index, layer in enumerate(layers, start=1):
        if not isinstance(layer, dict):
            raise BuildError(f"layer {index} must be an object")
        name = _identifier(layer.get("name"), f"layer {index} name")
        activation = layer.get("activation")
        if not isinstance(activation, str) or activation not in ACTIVATIONS:
            raise BuildError(f"layer {index} activation must be one of {', '.join(sorted(ACTIVATIONS))}")
        weights = layer.get("weights")
        if not isinstance(weights, list) or not weights:
            raise BuildError(f"layer {index} weights must be a non-empty matrix")
        rows = [_number_list(row, f"layer {index} weight row") for row in weights]
        input_size = len(rows[0])
        if any(len(row) != input_size for row in rows):
            raise BuildError(f"layer {index} weight rows must have equal lengths")
        if expected_inputs is not None and input_size != expected_inputs:
            raise BuildError(f"layer {index} expects {input_size} inputs; previous layer produces {expected_inputs}")
        bias = _number_list(layer.get("bias"), f"layer {index} bias")
        if len(bias) != len(rows):
            raise BuildError(f"layer {index} has {len(rows)} output rows but {len(bias)} bias values")
        checked_layers.append({
            "name": name,
            "weights": rows,
            "bias": bias,
            "activation": activation,
            "input_size": input_size,
            "output_size": len(rows),
        })
        expected_inputs = len(rows)

    validation_inputs = model.get("validation_inputs")
    if not isinstance(validation_inputs, list) or not validation_inputs:
        raise BuildError("validation_inputs must contain at least one input vector")
    inputs = [_number_list(vector, "validation input") for vector in validation_inputs]
    if any(len(vector) != checked_layers[0]["input_size"] for vector in inputs):
        raise BuildError(f"each validation input must have width {checked_layers[0]['input_size']}")

    return {
        "model_id": model_id,
        "source_revision": revision.strip(),
        "license": license_name.strip(),
        "layers": checked_layers,
        "validation_inputs": inputs,
    }


def _atom(value):
    return "'" + value.replace("'", "''") + "'"


def _prolog_number(value):
    return repr(float(value))


def _prolog_list(values):
    return "[" + ",".join(_prolog_number(value) for value in values) + "]"


def _activate(value, activation):
    if activation == "linear":
        return value
    if activation == "relu":
        return max(0.0, value)
    if activation == "tanh":
        return math.tanh(value)
    if value >= 0:
        return 1.0 / (1.0 + math.exp(-value))
    exp_value = math.exp(value)
    return exp_value / (1.0 + exp_value)


def reference_forward(model, input_vector):
    return reference_trace(model, input_vector)[-1][1]


def reference_trace(model, input_vector):
    values = list(input_vector)
    trace = []
    for layer in model["layers"]:
        outputs = []
        for row, bias in zip(layer["weights"], layer["bias"]):
            total = bias
            for weight, value in zip(row, values):
                total += weight * value
            if not math.isfinite(total):
                raise BuildError("reference calculation produced a non-finite value")
            activated = _activate(total, layer["activation"])
            if not math.isfinite(activated):
                raise BuildError("reference calculation produced a non-finite value")
            outputs.append(activated)
        values = outputs
        trace.append((layer["name"], values))
    return trace


def _architecture_pl(model):
    lines = [":- module(renn_architecture, [layer/6]).", ""]
    for index, layer in enumerate(model["layers"], start=1):
        lines.append(
            f"layer({_atom(model['model_id'])},{index},{_atom(layer['name'])},"
            f"{layer['input_size']},{layer['output_size']},{layer['activation']})."
        )
    return "\n".join(lines) + "\n"


def _weights_pl(model):
    lines = [":- module(renn_weights, [weights/3, biases/3]).", ""]
    for index, layer in enumerate(model["layers"], start=1):
        rows = "[" + ",".join(_prolog_list(row) for row in layer["weights"]) + "]"
        lines.append(f"weights({_atom(model['model_id'])},{index},{rows}).")
    lines.append("")
    for index, layer in enumerate(model["layers"], start=1):
        lines.append(f"biases({_atom(model['model_id'])},{index},{_prolog_list(layer['bias'])}).")
    return "\n".join(lines) + "\n"


def _ops_pl():
    return """:- module(renn_ops, [forward/3, trace/3, explain/3]).
:- use_module('architecture.pl').
:- use_module('weights.pl').

forward(Model, Input, Output) :-
    trace(Model, Input, Trace),
    last(Trace, layer(_, Output)).

trace(Model, Input, Trace) :-
    layer(Model, 1, _, InputSize, _, _),
    length(Input, InputSize),
    trace_layers(Model, 1, Input, Trace).

trace_layers(Model, Index, Input, [layer(Name, Output)|Rest]) :-
    layer(Model, Index, Name, InputSize, OutputSize, Activation),
    length(Input, InputSize),
    weights(Model, Index, Matrix),
    biases(Model, Index, Bias),
    length(Matrix, OutputSize),
    length(Bias, OutputSize),
    maplist(neuron(Input, Activation), Matrix, Bias, Output),
    Next is Index + 1,
    ( layer(Model, Next, _, _, _, _) ->
        trace_layers(Model, Next, Output, Rest)
    ; Rest = []
    ).

neuron(Input, Activation, Weights, Bias, Output) :-
    dot(Weights, Input, Bias, Sum),
    activate(Activation, Sum, Output).

dot([], [], Sum, Sum).
dot([Weight|Weights], [Value|Values], Accumulator, Result) :-
    Next is Accumulator + Weight * Value,
    dot(Weights, Values, Next, Result).

activate(linear, Value, Value).
activate(relu, Value, Output) :- Output is max(0.0, Value).
activate(tanh, Value, Output) :- Output is tanh(Value).
activate(sigmoid, Value, Output) :-
    ( Value >= 0 ->
        Output is 1.0 / (1.0 + exp(-Value))
    ; ExpValue is exp(Value),
      Output is ExpValue / (1.0 + ExpValue)
    ).

explain(Model, Input, explanation(Trace, Output)) :-
    trace(Model, Input, Trace),
    last(Trace, layer(_, Output)).
"""


def _verification_cases_pl(model, cases):
    lines = [
        ":- module(renn_verification_cases, [run_verification/0]).",
        ":- use_module('ops.pl').",
        "",
    ]
    for index, (input_vector, expected, expected_trace) in enumerate(cases, start=1):
        trace = "[" + ",".join(
            f"layer({_atom(name)},{_prolog_list(values)})"
            for name, values in expected_trace
        ) + "]"
        lines.append(f"case({index},{_prolog_list(input_vector)},{_prolog_list(expected)},{trace}).")
    lines.extend([
        "",
        "run_verification :-",
        "    forall(case(Index, Input, Expected, ExpectedTrace), verify_case(Index, Input, Expected, ExpectedTrace)),",
        "    writeln('All Prolog verification cases passed.').",
        "",
        "verify_case(_Index, Input, Expected, ExpectedTrace) :-",
        f"    trace({_atom(model['model_id'])}, Input, ActualTrace),",
        "    close_traces(ActualTrace, ExpectedTrace),",
        f"    forward({_atom(model['model_id'])}, Input, ActualOutput),",
        "    close_lists(ActualOutput, Expected), !.",
        "verify_case(Index, _, _, _) :-",
        "    format(user_error, 'Verification case ~d failed.~n', [Index]),",
        "    halt(1).",
        "",
        "close_traces([], []).",
        "close_traces([layer(Name,Actual)|Actuals], [layer(Name,Expected)|Expecteds]) :-",
        "    close_lists(Actual, Expected),",
        "    close_traces(Actuals, Expecteds).",
        "",
        "close_lists([], []).",
        "close_lists([Actual|Actuals], [Expected|Expecteds]) :-",
        f"    Difference is abs(Actual - Expected),",
        f"    Scale is max(abs(Actual), abs(Expected)),",
        f"    Difference =< {ABS_TOLERANCE!r} + {REL_TOLERANCE!r} * Scale,",
        "    close_lists(Actuals, Expecteds).",
        "",
    ])
    return "\n".join(lines)


def _json_bytes(value):
    return (json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n").encode()


def build(input_path, output_path):
    input_path = Path(input_path)
    output_path = Path(output_path)
    model = load_model(input_path)
    source_hash = hashlib.sha256(input_path.read_bytes()).hexdigest()
    cases = []
    for vector in model["validation_inputs"]:
        expected_trace = reference_trace(model, vector)
        cases.append((vector, expected_trace[-1][1], expected_trace))

    provenance = (
        ":- module(renn_provenance, [source/3, source_sha256/1]).\n\n"
        f"source({_atom(model['model_id'])},{_atom(model['source_revision'])},{_atom(model['license'])}).\n"
        f"source_sha256('{source_hash}').\n"
    )
    artifacts = {
        "architecture.pl": _architecture_pl(model).encode(),
        "weights.pl": _weights_pl(model).encode(),
        "ops.pl": _ops_pl().encode(),
        "provenance.pl": provenance.encode(),
        "training_config.pl": (
            ":- module(renn_training_config, [training_fact/2]).\n\n"
            "training_fact(training_procedure, unknown).\n"
            "training_fact(optimizer, unknown).\n"
            "training_fact(training_data, unknown).\n"
        ).encode(),
        "verification_cases.pl": _verification_cases_pl(model, cases).encode(),
    }
    output_path.mkdir(parents=True, exist_ok=True)
    for name, content in artifacts.items():
        (output_path / name).write_bytes(content)
    verification = {
        "model_id": model["model_id"],
        "status": "generated_not_executed",
        "reference": "renn Python reference implementation",
        "cases": [
            {
                "input": vector,
                "expected_output": output,
                "expected_trace": [
                    {"layer": name, "output": values}
                    for name, values in expected_trace
                ],
            }
            for vector, output, expected_trace in cases
        ],
        "absolute_tolerance": ABS_TOLERANCE,
        "relative_tolerance": REL_TOLERANCE,
        "approximation_ledger": [],
    }
    swipl = shutil.which("swipl")
    verification_error = None
    if swipl:
        result = subprocess.run(
            [swipl, "-q", "-s", "verification_cases.pl", "-g", "run_verification", "-t", "halt"],
            cwd=output_path,
            capture_output=True,
            text=True,
            check=False,
        )
        verification["status"] = "passed" if result.returncode == 0 else "failed"
        verification["prolog_stdout"] = result.stdout.strip()
        verification["prolog_stderr"] = result.stderr.strip()
        if result.returncode != 0:
            verification_error = result.stderr.strip() or result.stdout.strip() or f"exit code {result.returncode}"
    else:
        verification["note"] = "Run verification_cases.pl with SWI-Prolog to check the emitted implementation."
    artifacts["verification.json"] = _json_bytes(verification)
    (output_path / "verification.json").write_bytes(artifacts["verification.json"])
    manifest = {
        "model_id": model["model_id"],
        "source_revision": model["source_revision"],
        "source_sha256": source_hash,
        "files": {
            name: hashlib.sha256(content).hexdigest()
            for name, content in sorted(artifacts.items())
        },
    }
    (output_path / "manifest.json").write_bytes(_json_bytes(manifest))
    if verification_error:
        raise BuildError(f"SWI-Prolog verification failed: {verification_error}")
    return {
        "files": sorted([*artifacts, "manifest.json"]),
        "verification_status": verification["status"],
        "cases": len(cases),
    }
