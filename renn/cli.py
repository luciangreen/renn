import argparse
import json
import sys
from pathlib import Path

from renn.generator import BuildError, build, verify_artifacts


def main(argv=None):
    parser = argparse.ArgumentParser(prog="renn")
    subparsers = parser.add_subparsers(dest="command", required=True)
    build_parser = subparsers.add_parser("build", help="build Prolog files from an MLP JSON description")
    build_parser.add_argument("model", type=Path, help="input model JSON")
    build_parser.add_argument("--output", required=True, type=Path, help="output directory")
    verify_parser = subparsers.add_parser("verify", help="check generated files against their manifest")
    verify_parser.add_argument("directory", type=Path, help="generated build directory")
    args = parser.parse_args(argv)

    try:
        if args.command == "verify":
            result = verify_artifacts(args.directory)
        else:
            result = build(args.model, args.output)
    except (BuildError, OSError, json.JSONDecodeError) as exc:
        print(f"renn: {exc}", file=sys.stderr)
        return 1
    if args.command == "verify":
        print(f"Verified {result['files_verified']} artifact hashes for {result['model_id']}.")
        print("Manifest hashes detect accidental changes; they do not authenticate the source.")
        return 0
    print(f"Generated {len(result['files'])} files in {args.output}")
    print(f"Prolog verification: {result['verification_status']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
