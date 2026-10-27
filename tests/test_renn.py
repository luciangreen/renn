import hashlib
import json
import struct
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from renn.generator import (
    BuildError,
    build,
    compare_runner,
    compare_reference,
    load_model,
    reference_forward,
    run_prolog_verification,
    verify_artifacts,
)
from renn.safetensors import _read_safetensors, import_safetensors


ROOT = Path(__file__).resolve().parents[1]
EXAMPLE = ROOT / "examples" / "tiny-mlp.json"


class RENNBuildTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.output = Path(self.tempdir.name) / "build"

    def test_reference_forward(self):
        model = load_model(EXAMPLE)
        self.assertEqual(reference_forward(model, [1.0, 2.0]), [-1.25])
        self.assertEqual(reference_forward(model, [0.0, 0.0]), [0.25])

    def test_softmax_is_layer_wise_and_numerically_stable(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"] = [{
            "name": "probabilities",
            "weights": [[1.0, 0.0], [0.0, 1.0]],
            "bias": [0.0, 0.0],
            "activation": "softmax",
        }]
        source["validation_inputs"] = [[1000.0, -1000.0]]
        path = Path(self.tempdir.name) / "softmax.json"
        path.write_text(json.dumps(source))

        model = load_model(path)
        outputs = reference_forward(model, [1000.0, -1000.0])
        self.assertEqual(outputs, [1.0, 0.0])
        self.assertAlmostEqual(sum(outputs), 1.0)
        self.assertEqual(reference_forward(model, [0.0, 0.0]), [0.5, 0.5])

        build(path, self.output)
        self.assertIn("activate_layer(softmax, Values, Outputs)", (self.output / "ops.pl").read_text())

    def test_build_emits_hashed_artifacts(self):
        result = build(EXAMPLE, self.output)
        self.assertIn(result["verification_status"], {"generated_not_executed", "passed"})
        architecture = (self.output / "architecture.pl").read_text()
        self.assertIn("layer_evidence/5", architecture)
        self.assertIn(
            "layer_evidence('tiny-mlp',1,name,stated,"
            "'validated input description: layers[0].name').",
            architecture,
        )
        self.assertIn(
            "layer_evidence('tiny-mlp',1,input_size,derived,"
            "'validated input description: layers[0].weights shape').",
            architecture,
        )
        manifest = json.loads((self.output / "manifest.json").read_text())
        for name, expected_hash in manifest["files"].items():
            self.assertEqual(
                hashlib.sha256((self.output / name).read_bytes()).hexdigest(),
                expected_hash,
            )
        verification = json.loads((self.output / "verification.json").read_text())
        self.assertEqual(verification["approximation_ledger"], [])
        self.assertEqual(verification["cases"][0]["expected_output"], [-1.25])
        self.assertEqual(verification["cases"][0]["expected_trace"][0]["output"], [0.0, 1.75])
        self.assertEqual(verification["status"], result["verification_status"])
        training_config = (self.output / "training_config.pl").read_text()
        self.assertIn("training_fact(training_procedure, unknown, unknown).", training_config)
        self.assertIn("training_fact(optimizer, unknown, unknown).", training_config)
        self.assertIn("training_fact(training_data, unknown, unknown).", training_config)
        training_report = (self.output / "training_report.md").read_text()
        self.assertIn("underdetermined", training_report)
        self.assertIn("no reconstructed launch command is emitted", training_report)

    def test_verify_artifacts_checks_manifest_hashes(self):
        build(EXAMPLE, self.output)
        result = verify_artifacts(self.output)
        self.assertEqual(result["model_id"], "tiny-mlp")
        self.assertEqual(result["files_verified"], 8)

        (self.output / "ops.pl").write_text("modified")
        with self.assertRaisesRegex(BuildError, "SHA-256 mismatch"):
            verify_artifacts(self.output)

    def test_verify_artifacts_rejects_unsafe_manifest_filename(self):
        build(EXAMPLE, self.output)
        manifest_path = self.output / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        manifest["files"]["../outside"] = "0" * 64
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(BuildError, "invalid artifact filename"):
            verify_artifacts(self.output)

    def test_verify_artifacts_rejects_duplicate_manifest_keys(self):
        build(EXAMPLE, self.output)
        (self.output / "manifest.json").write_text('{"files":{},"files":{}}')
        with self.assertRaisesRegex(BuildError, "duplicate JSON key 'files'"):
            verify_artifacts(self.output)

    def test_output_is_deterministic(self):
        first = self.output / "first"
        second = self.output / "second"
        build(EXAMPLE, first)
        build(EXAMPLE, second)
        first_files = {path.name: path.read_bytes() for path in first.iterdir()}
        second_files = {path.name: path.read_bytes() for path in second.iterdir()}
        self.assertEqual(first_files, second_files)

    def test_rejects_non_finite_and_boolean_weights(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"][0]["weights"][0][0] = float("nan")
        path = Path(self.tempdir.name) / "invalid.json"
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(BuildError, "invalid JSON constant NaN"):
            load_model(path)

    def test_rejects_duplicate_keys_and_nonstandard_json_constants(self):
        path = Path(self.tempdir.name) / "invalid.json"
        path.write_text('{"model_id":"first","model_id":"second"}')
        with self.assertRaisesRegex(BuildError, "duplicate JSON key 'model_id'"):
            load_model(path)

        path.write_text(EXAMPLE.read_text().replace('"weights": [[1.0, -1.0]', '"weights": [[NaN, -1.0]'))
        with self.assertRaisesRegex(BuildError, "invalid JSON constant NaN"):
            load_model(path)

        source = json.loads(EXAMPLE.read_text())
        source["layers"][0]["weights"][0][0] = True
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(BuildError, "finite numbers"):
            load_model(path)

    def test_rejects_arithmetic_overflow(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"][0]["weights"][0][0] = 1e308
        source["validation_inputs"] = [[10.0, 0.0]]
        path = Path(self.tempdir.name) / "overflow.json"
        path.write_text(json.dumps(source))
        model = load_model(path)
        with self.assertRaisesRegex(BuildError, "non-finite"):
            reference_forward(model, model["validation_inputs"][0])

    def test_rejects_inconsistent_layer_dimensions(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"][1]["weights"] = [[1.0]]
        path = Path(self.tempdir.name) / "invalid.json"
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(BuildError, "previous layer produces"):
            load_model(path)

    def test_rejects_duplicate_layer_names(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"][1]["name"] = source["layers"][0]["name"]
        path = Path(self.tempdir.name) / "duplicate-names.json"
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(BuildError, "layer names must be unique"):
            load_model(path)

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_tanh_and_sigmoid_prolog_verification(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"][0]["activation"] = "tanh"
        source["layers"][1]["activation"] = "sigmoid"
        path = Path(self.tempdir.name) / "nonlinear.json"
        path.write_text(json.dumps(source))
        result = build(path, self.output)
        self.assertEqual(result["verification_status"], "passed")

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_softmax_prolog_verification(self):
        source = json.loads(EXAMPLE.read_text())
        source["layers"] = [{
            "name": "probabilities",
            "weights": [[1.0, 0.0], [0.0, 1.0]],
            "bias": [0.0, 0.0],
            "activation": "softmax",
        }]
        source["validation_inputs"] = [[1000.0, -1000.0], [0.0, 0.0]]
        path = Path(self.tempdir.name) / "softmax.json"
        path.write_text(json.dumps(source))

        result = build(path, self.output)
        self.assertEqual(result["verification_status"], "passed")

    def test_cli_build(self):
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "renn",
                "build",
                str(EXAMPLE),
                "--output",
                str(self.output),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.output / "ops.pl").exists())

    def test_cli_verify(self):
        build(EXAMPLE, self.output)
        result = subprocess.run(
            [sys.executable, "-m", "renn", "verify", str(self.output)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Verified 8 artifact hashes", result.stdout)

    def test_cli_verify_runs_generated_prolog_cases(self):
        build(EXAMPLE, self.output)
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "renn",
                "verify",
                str(self.output),
                "--run-prolog",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if shutil.which("swipl"):
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("All Prolog verification cases passed.", result.stdout)
        else:
            self.assertEqual(result.returncode, 1)
            self.assertIn("SWI-Prolog is required", result.stderr)

    def test_run_prolog_verification_requires_manifested_cases(self):
        build(EXAMPLE, self.output)
        manifest_path = self.output / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        del manifest["files"]["verification_cases.pl"]
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(BuildError, "manifest does not include"):
            run_prolog_verification(self.output)

    def _write_reference(self, data):
        path = Path(self.tempdir.name) / "reference.json"
        path.write_text(json.dumps(data))
        return path

    def _write_safetensors(self, path, tensors):
        header = {}
        chunks = []
        offset = 0
        for name, (shape, values) in tensors.items():
            payload = struct.pack("<" + "f" * len(values), *values)
            header[name] = {
                "dtype": "F32",
                "shape": shape,
                "data_offsets": [offset, offset + len(payload)],
            }
            chunks.append(payload)
            offset += len(payload)
        encoded_header = json.dumps(header, separators=(",", ":")).encode()
        path.write_bytes(struct.pack("<Q", len(encoded_header)) + encoded_header + b"".join(chunks))
        return path

    def _write_safetensors_descriptor(self, path):
        descriptor = {
            "model_id": "tiny-mlp",
            "source_revision": "checkpoint-v1",
            "license": "CC0-1.0",
            "layers": [
                {
                    "name": "hidden",
                    "weights_tensor": "hidden.weight",
                    "bias_tensor": "hidden.bias",
                    "activation": "relu",
                },
                {
                    "name": "output",
                    "weights_tensor": "output.weight",
                    "bias_tensor": "output.bias",
                    "activation": "linear",
                },
            ],
            "validation_inputs": [[1.0, 2.0], [0.0, 0.0]],
        }
        path.write_text(json.dumps(descriptor), encoding="utf-8")
        return path

    def _write_safetensors_index(self, path, shards):
        weight_map = {}
        for filename, tensors in shards.items():
            for name in tensors:
                weight_map[name] = filename
        path.write_text(json.dumps({"weight_map": weight_map}), encoding="utf-8")
        return path

    def test_import_safetensors_builds_verified_dense_mlp(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "model.safetensors",
            {
                "hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5]),
                "hidden.bias": ([2], [0.0, 0.25]),
                "output.weight": ([1, 2], [2.0, -1.0]),
                "output.bias": ([1], [0.5]),
            },
        )
        descriptor = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        result = import_safetensors(checkpoint, descriptor, self.output)
        self.assertIn(result["verification_status"], {"generated_not_executed", "passed"})
        self.assertEqual(verify_artifacts(self.output)["model_id"], "tiny-mlp")
        self.assertIn("source_sha256", (self.output / "provenance.pl").read_text())
        provenance = (self.output / "provenance.pl").read_text()
        self.assertIn(hashlib.sha256(checkpoint.read_bytes()).hexdigest(), provenance)
        self.assertIn(hashlib.sha256(descriptor.read_bytes()).hexdigest(), provenance)
        self.assertIn("weights('tiny-mlp',1,[[1.0,-1.0],[0.5,0.5]]).", (self.output / "weights.pl").read_text())

    def test_import_sharded_safetensors_builds_and_hashes_all_sources(self):
        shard_dir = Path(self.tempdir.name)
        first_shard = self._write_safetensors(
            shard_dir / "model-00001-of-00002.safetensors",
            {
                "hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5]),
                "hidden.bias": ([2], [0.0, 0.25]),
            },
        )
        second_shard = self._write_safetensors(
            shard_dir / "model-00002-of-00002.safetensors",
            {
                "output.weight": ([1, 2], [2.0, -1.0]),
                "output.bias": ([1], [0.5]),
            },
        )
        index = self._write_safetensors_index(
            shard_dir / "model.safetensors.index.json",
            {
                first_shard.name: {
                    "hidden.weight": None,
                    "hidden.bias": None,
                },
                second_shard.name: {
                    "output.weight": None,
                    "output.bias": None,
                },
            },
        )
        descriptor = self._write_safetensors_descriptor(shard_dir / "architecture.json")

        result = import_safetensors(index, descriptor, self.output)

        self.assertIn(result["verification_status"], {"generated_not_executed", "passed"})
        self.assertEqual(verify_artifacts(self.output)["model_id"], "tiny-mlp")
        provenance = (self.output / "provenance.pl").read_text()
        source_files = {
            "index": {
                "filename": index.name,
                "sha256": hashlib.sha256(index.read_bytes()).hexdigest(),
            },
            "shards": [
                {
                    "filename": shard.name,
                    "sha256": hashlib.sha256(shard.read_bytes()).hexdigest(),
                }
                for shard in sorted((first_shard, second_shard), key=lambda path: path.name)
            ],
        }
        source_hash = hashlib.sha256(
            json.dumps(source_files, sort_keys=True, separators=(",", ":")).encode("utf-8")
        ).hexdigest()
        self.assertIn(source_hash, provenance)
        self.assertIn("weights('tiny-mlp',2,[[2.0,-1.0]]).", (self.output / "weights.pl").read_text())

    def test_import_sharded_safetensors_rejects_unsafe_shard_path(self):
        index = Path(self.tempdir.name) / "model.safetensors.index.json"
        index.write_text(
            json.dumps({"weight_map": {"hidden.weight": "../outside.safetensors"}}),
            encoding="utf-8",
        )
        descriptor = self._write_safetensors_descriptor(Path(self.tempdir.name) / "architecture.json")
        with self.assertRaisesRegex(BuildError, "invalid Safetensors shard filename"):
            import_safetensors(index, descriptor, self.output)

    def test_import_sharded_safetensors_rejects_index_shard_mismatch(self):
        shard = self._write_safetensors(
            Path(self.tempdir.name) / "model-00001-of-00001.safetensors",
            {"actual.weight": ([1], [1.0])},
        )
        index = self._write_safetensors_index(
            Path(self.tempdir.name) / "model.safetensors.index.json",
            {shard.name: {"expected.weight": None}},
        )
        descriptor = self._write_safetensors_descriptor(Path(self.tempdir.name) / "architecture.json")
        with self.assertRaisesRegex(BuildError, "does not match index weight_map"):
            import_safetensors(index, descriptor, self.output)

    def test_import_sharded_safetensors_rejects_symlinked_shard(self):
        target = self._write_safetensors(
            Path(self.tempdir.name) / "target.safetensors",
            {"tensor": ([1], [1.0])},
        )
        shard_link = Path(self.tempdir.name) / "linked.safetensors"
        shard_link.symlink_to(target)
        index = self._write_safetensors_index(
            Path(self.tempdir.name) / "model.safetensors.index.json",
            {shard_link.name: {"tensor": None}},
        )
        descriptor = self._write_safetensors_descriptor(Path(self.tempdir.name) / "architecture.json")
        with self.assertRaisesRegex(BuildError, "not a regular file"):
            import_safetensors(index, descriptor, self.output)

    def test_import_safetensors_rejects_missing_tensor(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "model.safetensors",
            {"hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5])},
        )
        descriptor = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        with self.assertRaisesRegex(BuildError, "references a missing tensor"):
            import_safetensors(checkpoint, descriptor, self.output)

    def test_import_safetensors_rejects_unreferenced_checkpoint_tensors(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "model.safetensors",
            {
                "hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5]),
                "hidden.bias": ([2], [0.0, 0.25]),
                "output.weight": ([1, 2], [2.0, -1.0]),
                "output.bias": ([1], [0.5]),
                "unused.weight": ([1], [99.0]),
            },
        )
        descriptor = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        with self.assertRaisesRegex(BuildError, "tensors not mapped.*unused.weight"):
            import_safetensors(checkpoint, descriptor, self.output)

    def test_import_safetensors_rejects_duplicate_tensor_references(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "model.safetensors",
            {
                "hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5]),
                "hidden.bias": ([2], [0.0, 0.25]),
                "output.weight": ([1, 2], [2.0, -1.0]),
                "output.bias": ([1], [0.5]),
            },
        )
        descriptor_path = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        descriptor = json.loads(descriptor_path.read_text())
        descriptor["layers"][1]["weights_tensor"] = "hidden.weight"
        descriptor_path.write_text(json.dumps(descriptor))
        with self.assertRaisesRegex(BuildError, "references tensor 'hidden.weight' more than once"):
            import_safetensors(checkpoint, descriptor_path, self.output)

    def test_import_safetensors_rejects_duplicate_descriptor_keys(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "model.safetensors",
            {"hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5])},
        )
        descriptor = Path(self.tempdir.name) / "architecture.json"
        descriptor.write_text('{"model_id":"first","model_id":"second"}')
        with self.assertRaisesRegex(BuildError, "duplicate JSON key 'model_id'"):
            import_safetensors(checkpoint, descriptor, self.output)

    def test_import_safetensors_rejects_non_finite_tensor(self):
        checkpoint = self._write_safetensors(
            Path(self.tempdir.name) / "non-finite.safetensors",
            {"tensor": ([1], [float("inf")])},
        )
        descriptor = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        with self.assertRaisesRegex(BuildError, "non-finite"):
            import_safetensors(checkpoint, descriptor, self.output)

    def test_safetensors_reads_f16_and_bf16(self):
        path = Path(self.tempdir.name) / "low-precision.safetensors"
        header = {
            "half": {"dtype": "F16", "shape": [1], "data_offsets": [0, 2]},
            "bfloat": {"dtype": "BF16", "shape": [1], "data_offsets": [2, 4]},
        }
        encoded_header = json.dumps(header, separators=(",", ":")).encode()
        path.write_bytes(
            struct.pack("<Q", len(encoded_header))
            + encoded_header
            + struct.pack("<eH", 1.5, 0xC010)
        )
        self.assertEqual(_read_safetensors(path), {"half": ([1], [1.5]), "bfloat": ([1], [-2.25])})

    def test_safetensors_rejects_duplicate_header_keys_and_nonstandard_constants(self):
        path = Path(self.tempdir.name) / "invalid-header.safetensors"
        for header, expected_error in (
            ('{"tensor":{},"tensor":{}}', "duplicate JSON key 'tensor'"),
            ('{"__metadata__":{"value":NaN}}', "invalid JSON constant NaN"),
        ):
            encoded_header = header.encode()
            path.write_bytes(struct.pack("<Q", len(encoded_header)) + encoded_header)
            with self.assertRaisesRegex(BuildError, expected_error):
                _read_safetensors(path)

    def test_cli_import_safetensors(self):
        first_shard = self._write_safetensors(
            Path(self.tempdir.name) / "model-00001-of-00002.safetensors",
            {
                "hidden.weight": ([2, 2], [1.0, -1.0, 0.5, 0.5]),
                "hidden.bias": ([2], [0.0, 0.25]),
            },
        )
        second_shard = self._write_safetensors(
            Path(self.tempdir.name) / "model-00002-of-00002.safetensors",
            {
                "output.weight": ([1, 2], [2.0, -1.0]),
                "output.bias": ([1], [0.5]),
            },
        )
        checkpoint = self._write_safetensors_index(
            Path(self.tempdir.name) / "model.safetensors.index.json",
            {
                first_shard.name: {
                    "hidden.weight": None,
                    "hidden.bias": None,
                },
                second_shard.name: {
                    "output.weight": None,
                    "output.bias": None,
                },
            },
        )
        descriptor = self._write_safetensors_descriptor(
            Path(self.tempdir.name) / "architecture.json"
        )
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "renn",
                "import-safetensors",
                str(checkpoint),
                str(descriptor),
                "--output",
                str(self.output),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.output / "manifest.json").exists())

    def test_compare_reference_rejects_mismatched_model_id(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "other",
            "cases": [{"input": [1], "expected_output": [1]}],
        })
        with self.assertRaisesRegex(BuildError, "model_id must match"):
            compare_reference(self.output, reference)

    def test_compare_reference_rejects_non_finite_outputs(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{"input": [1.0, 2.0], "expected_output": [float("nan")]}],
        })
        with self.assertRaisesRegex(BuildError, "invalid JSON constant NaN"):
            compare_reference(self.output, reference)

    def test_compare_reference_rejects_invalid_vector_and_trace_shapes(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{"input": [1.0], "expected_output": [-1.25]}],
        })
        with self.assertRaisesRegex(BuildError, "input must have width 2"):
            compare_reference(self.output, reference)

        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{
                "input": [1.0, 2.0],
                "expected_output": [-1.25, 0.0],
            }],
        })
        with self.assertRaisesRegex(BuildError, "expected_output must have width 1"):
            compare_reference(self.output, reference)

        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{
                "input": [1.0, 2.0],
                "expected_output": [-1.25],
                "expected_trace": [
                    {"layer": "output", "output": [-1.25]},
                    {"layer": "hidden", "output": [0.0, 1.75]},
                ],
            }],
        })
        with self.assertRaisesRegex(BuildError, "layer 1 must be 'hidden'"):
            compare_reference(self.output, reference)

        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{
                "input": [1.0, 2.0],
                "expected_output": [-1.25],
                "expected_trace": [
                    {"layer": "hidden", "output": [0.0]},
                    {"layer": "output", "output": [-1.25]},
                ],
            }],
        })
        with self.assertRaisesRegex(BuildError, "trace layer 1 output must have width 2"):
            compare_reference(self.output, reference)

        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{
                "input": [1.0, 2.0],
                "expected_output": [-1.25],
                "expected_trace": [{"layer": "hidden", "output": [0.0, 1.75]}],
            }],
        })
        with self.assertRaisesRegex(BuildError, "expected_trace must contain 2 layers"):
            compare_reference(self.output, reference)

    def test_compare_reference_rejects_duplicate_keys(self):
        build(EXAMPLE, self.output)
        reference = Path(self.tempdir.name) / "reference.json"
        reference.write_text('{"model_id":"tiny-mlp","model_id":"tiny-mlp","cases":[]}')
        with self.assertRaisesRegex(BuildError, "duplicate JSON key 'model_id'"):
            compare_reference(self.output, reference)

    def test_compare_runner_rejects_mismatched_model_id(self):
        build(EXAMPLE, self.output)
        inputs = self._write_reference({
            "model_id": "other",
            "cases": [{"input": [1.0, 2.0]}],
        })
        with self.assertRaisesRegex(BuildError, "input model_id must match"):
            compare_runner(self.output, inputs, sys.executable)

    def test_compare_runner_rejects_invalid_input_width_before_execution(self):
        build(EXAMPLE, self.output)
        inputs = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{"input": [1.0]}],
        })
        with self.assertRaisesRegex(BuildError, "input must have width 2"):
            compare_runner(self.output, inputs, "runner-that-must-not-be-invoked")

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_compare_runner_cli_executes_reference_and_checks_traces(self):
        build(EXAMPLE, self.output)
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "renn",
                "compare-runner",
                str(self.output),
                str(ROOT / "examples" / "tiny-mlp-inputs.json"),
                "--runner",
                sys.executable,
                "--runner-arg",
                str(ROOT / "examples" / "tiny-mlp-runner.py"),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("compared 2 cases for tiny-mlp", result.stdout)
        self.assertIn("All independent reference cases passed.", result.stdout)

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_compare_independent_reference_outputs_and_traces(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [
                {
                    "input": [1.0, 2.0],
                    "expected_output": [-1.25],
                    "expected_trace": [
                        {"layer": "hidden", "output": [0.0, 1.75]},
                        {"layer": "output", "output": [-1.25]},
                    ],
                },
                {"input": [0.0, 0.0], "expected_output": [0.25]},
            ],
        })
        result = compare_reference(self.output, reference)
        self.assertEqual(result["cases"], 2)
        self.assertIn("All independent reference cases passed.", result["stdout"])
        self.assertEqual(list(self.output.glob(".renn-reference-*.pl")), [])

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_compare_reference_reports_mismatch(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{"input": [1.0, 2.0], "expected_output": [123.0]}],
        })
        with self.assertRaisesRegex(BuildError, "reference comparison failed"):
            compare_reference(self.output, reference)

    def test_cli_compare_requires_reference_file(self):
        build(EXAMPLE, self.output)
        reference = self._write_reference({
            "model_id": "tiny-mlp",
            "cases": [{"input": [1.0, 2.0], "expected_output": [-1.25]}],
        })
        result = subprocess.run(
            [sys.executable, "-m", "renn", "compare", str(self.output), str(reference)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if shutil.which("swipl"):
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("Compared 1 independent reference cases", result.stdout)
        else:
            self.assertEqual(result.returncode, 1)
            self.assertIn("SWI-Prolog is required", result.stderr)

    @unittest.skipUnless(shutil.which("swipl"), "SWI-Prolog is not installed")
    def test_emitted_prolog_verification(self):
        build(EXAMPLE, self.output)
        result = subprocess.run(
            ["swipl", "-q", "-s", "verification_cases.pl", "-g", "run_verification", "-t", "halt"],
            cwd=self.output,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("All Prolog verification cases passed.", result.stdout)


if __name__ == "__main__":
    unittest.main()
