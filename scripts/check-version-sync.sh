#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_VERSION="${1:-}"

ROOT_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"

if [[ "$ROOT_VERSION" == v* ]]; then
  ROOT_VERSION="${ROOT_VERSION#v}"
fi

if [ -n "$EXPECTED_VERSION" ] && [ "$ROOT_VERSION" != "$EXPECTED_VERSION" ]; then
  echo "VERSION file mismatch: expected '$EXPECTED_VERSION', got '$ROOT_VERSION'" >&2
  exit 1
fi

RUST_VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT_DIR/packages/rust/lirays-scada-proto/Cargo.toml" | head -n1)"
PYTHON_VERSION="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$ROOT_DIR/packages/python/lirays-scada-proto/pyproject.toml" | head -n1)"
JS_VERSION="$(sed -n 's/^  "version": "\(.*\)",$/\1/p' "$ROOT_DIR/packages/js/lirays-scada-proto/package.json" | head -n1)"

if [ -z "$RUST_VERSION" ] || [ -z "$PYTHON_VERSION" ] || [ -z "$JS_VERSION" ]; then
  echo "Failed to read package versions." >&2
  exit 1
fi

if [ "$ROOT_VERSION" != "$RUST_VERSION" ] || [ "$ROOT_VERSION" != "$PYTHON_VERSION" ] || [ "$ROOT_VERSION" != "$JS_VERSION" ]; then
  echo "Version mismatch detected:" >&2
  echo "  VERSION: $ROOT_VERSION" >&2
  echo "  Rust:    $RUST_VERSION" >&2
  echo "  Python:  $PYTHON_VERSION" >&2
  echo "  JS:      $JS_VERSION" >&2
  exit 1
fi

echo "Version sync OK: $ROOT_VERSION"
