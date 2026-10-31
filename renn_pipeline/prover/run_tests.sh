#!/usr/bin/env bash
# Build the three fixture networks with pl2ann, then run the prover's 14 tests.
# Usage: PL2ANN_DIR=/path/to/pl2ann ./run_tests.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
: "${PL2ANN_DIR:?set PL2ANN_DIR to a pl2ann checkout}"
export PL2ANN_PROLOG="$PL2ANN_DIR/prolog"
export NETS_DIR="${NETS_DIR:-$here/build}"
for name in reach flies_a flies_b; do
  mkdir -p "$NETS_DIR/$name"
  ( cd "$PL2ANN_DIR" && swipl bin/prolog2ann.pl convert "$here/fixtures/$name/src.pl" \
      --mode step --out "$NETS_DIR/$name/net.pl" --module "net_$name" )
done
cd "$here"
swipl -q -g main -t 'halt(1)' test_prover.pl
