#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
elif [ -n "${1:-}" ]; then
  echo "Unknown option: $1" >&2
  echo "Usage: ./scripts/clean-generated.sh [--dry-run]" >&2
  exit 1
fi

cd "$ROOT_DIR"

if [ "$DRY_RUN" = true ]; then
  echo "Previewing ignored generated files to remove..."
  CLEAN_FLAGS=(-ndX)
else
  echo "Removing ignored generated files..."
  CLEAN_FLAGS=(-fdX)
fi

# Scoped cleanup: only package/build areas that contain generated artifacts.
git clean "${CLEAN_FLAGS[@]}" -- \
  debug \
  target \
  packages/rust/lirays-scada-proto \
  packages/python/lirays-scada-proto \
  packages/js/lirays-scada-proto
