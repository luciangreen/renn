import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from renn.generator import BuildError, build, load_model, reference_forward, verify_artifacts


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

    def test_build_emits_hashed_artifacts(self):
        result = build(EXAMPLE, self.output)
        self.assertIn(result["verification_status"], {"generated_not_executed", "passed"})
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
        with self.assertRaisesRegex(BuildError, "finite numbers"):
            load_model(path)

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
