import argparse
import json
import sys
from pathlib import Path

from renn.generator import (
    BuildError,
    build,
    compare_runner,
    compare_reference,
    run_prolog_verification,
    verify_artifacts,
)
from renn.safetensors import import_safetensors


def main(argv=None):
    parser = argparse.ArgumentParser(prog="renn")
    subparsers = parser.add_subparsers(dest="command", required=True)
    build_parser = subparsers.add_parser("build", help="build Prolog files from an MLP JSON description")
    build_parser.add_argument("model", type=Path, help="input model JSON")
    build_parser.add_argument("--output", required=True, type=Path, help="output directory")
    verify_parser = subparsers.add_parser("verify", help="check generated files against their manifest")
    verify_parser.add_argument("directory", type=Path, help="generated build directory")
    verify_parser.add_argument(
        "--run-prolog",
        action="store_true",
        help="execute the generated differential verification cases (requires SWI-Prolog)",
    )
    compare_parser = subparsers.add_parser(
        "compare",
        help="compare generated Prolog with independent reference outputs",
    )
    compare_parser.add_argument("directory", type=Path, help="generated build directory")
    compare_parser.add_argument("reference", type=Path, help="JSON file containing reference cases")
    runner_parser = subparsers.add_parser(
        "compare-runner",
        help="run an independent reference implementation and compare its outputs",
    )
    runner_parser.add_argument("directory", type=Path, help="generated build directory")
    runner_parser.add_argument("inputs", type=Path, help="JSON file containing model inputs")
    runner_parser.add_argument(
        "--runner",
        required=True,
        help="trusted executable that implements the reference-runner JSON protocol",
    )
    runner_parser.add_argument(
        "--runner-arg",
        action="append",
        default=[],
        help="argument passed to the runner executable; may be repeated",
    )
    import_parser = subparsers.add_parser(
        "import-safetensors",
        help="build a dense MLP from a Safetensors checkpoint and architecture descriptor",
    )
    import_parser.add_argument("checkpoint", type=Path, help="Safetensors checkpoint file")
    import_parser.add_argument("descriptor", type=Path, help="JSON architecture descriptor")
    import_parser.add_argument("--output", required=True, type=Path, help="output directory")
    args = parser.parse_args(argv)

    try:
        if args.command == "verify":
            result = (
                run_prolog_verification(args.directory)
                if args.run_prolog
                else verify_artifacts(args.directory)
            )
        elif args.command == "compare":
            result = compare_reference(args.directory, args.reference)
        elif args.command == "compare-runner":
            result = compare_runner(args.directory, args.inputs, args.runner, args.runner_arg)
        elif args.command == "import-safetensors":
            result = import_safetensors(args.checkpoint, args.descriptor, args.output)
        else:
            result = build(args.model, args.output)
    except (BuildError, OSError, json.JSONDecodeError) as exc:
        print(f"renn: {exc}", file=sys.stderr)
        return 1
    if args.command == "verify":
        print(f"Verified {result['files_verified']} artifact hashes for {result['model_id']}.")
        print("Manifest hashes detect accidental changes; they do not authenticate the source.")
        if args.run_prolog:
            print(result["stdout"])
        return 0
    if args.command == "compare":
        print(f"Compared {result['cases']} independent reference cases for {result['model_id']}.")
        print(result["stdout"])
        return 0
    if args.command == "compare-runner":
        print(f"Ran {result['runner']!r} and compared {result['cases']} cases for {result['model_id']}.")
        print(result["stdout"])
        return 0
    if args.command == "import-safetensors":
        print(f"Generated {len(result['files'])} files in {args.output}")
        print(f"Prolog verification: {result['verification_status']}")
        return 0
    print(f"Generated {len(result['files'])} files in {args.output}")
    print(f"Prolog verification: {result['verification_status']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
