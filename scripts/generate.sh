#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=(all)
fi

WANT_RUST=false
WANT_PYTHON=false
WANT_JS=false

for target in "${TARGETS[@]}"; do
  case "$target" in
    all)
      WANT_RUST=true
      WANT_PYTHON=true
      WANT_JS=true
      ;;
    rust)
      WANT_RUST=true
      ;;
    python)
      WANT_PYTHON=true
      ;;
    js|javascript)
      WANT_JS=true
      ;;
    *)
      echo "Unknown generation target: $target" >&2
      echo "Valid targets: all, rust, python, js" >&2
      exit 1
      ;;
  esac
done

if [ "$WANT_RUST" = true ]; then
  cargo run --quiet \
    --manifest-path "$ROOT_DIR/tools/rust-codegen/Cargo.toml" \
    -- \
    "$ROOT_DIR/proto" \
    "$ROOT_DIR/packages/rust/lirays-scada-proto/src/generated"
fi

if [ "$WANT_PYTHON" = true ]; then
  (
    cd "$ROOT_DIR"
    buf generate --template buf.gen.python.yaml
  )

  if [ -d "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace" ]; then
    touch "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace/__init__.py"
  fi
fi

if [ "$WANT_JS" = true ]; then
  (
    cd "$ROOT_DIR"
    buf generate --template buf.gen.js.yaml
  )
fi
