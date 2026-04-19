#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_LICENSE="$ROOT_DIR/LICENSE"

if [ ! -f "$SOURCE_LICENSE" ]; then
  echo "Root LICENSE file not found: $SOURCE_LICENSE" >&2
  exit 1
fi

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
      echo "Unknown sync target: $target" >&2
      echo "Valid targets: all, rust, python, js" >&2
      exit 1
      ;;
  esac
done

sync_to() {
  local package_dir="$1"
  local target_license="$package_dir/LICENSE"
  cp "$SOURCE_LICENSE" "$target_license"
}

if [ "$WANT_RUST" = true ]; then
  sync_to "$ROOT_DIR/packages/rust/lirays-scada-proto"
fi

if [ "$WANT_PYTHON" = true ]; then
  sync_to "$ROOT_DIR/packages/python/lirays-scada-proto"
fi

if [ "$WANT_JS" = true ]; then
  sync_to "$ROOT_DIR/packages/js/lirays-scada-proto"
fi
