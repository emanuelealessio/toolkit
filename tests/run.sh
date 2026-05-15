#!/usr/bin/env bash
# tests/run.sh — bootstrap bats-core (if missing) and run the test suite.
# Tests use an isolated CLAUDE_HOME, never touch your real ~/.claude.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
BATS_DIR="$TESTS_DIR/bats"
BATS_BIN="$BATS_DIR/bin/bats"

# Bootstrap bats-core on first run (shallow clone, vendored under tests/bats/)
if [ ! -x "$BATS_BIN" ]; then
  printf "Bootstrap bats-core in %s...\n" "$BATS_DIR"
  rm -rf "$BATS_DIR"
  git clone --depth 1 --quiet https://github.com/bats-core/bats-core.git "$BATS_DIR"
fi

cd "$TESTS_DIR"
exec "$BATS_BIN" --print-output-on-failure "$TESTS_DIR"/*.bats
