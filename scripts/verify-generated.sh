#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/generate.sh" all

TRACKED_PATHS=(
  packages/rust/lirays-scada-proto/src/generated
  packages/python/lirays-scada-proto/src/namespace
  packages/js/lirays-scada-proto/src/generated
)

(
  cd "$ROOT_DIR"

  if ! git diff --quiet -- "${TRACKED_PATHS[@]}"; then
    echo "Generated code is out of date. Run ./scripts/generate.sh and commit changes." >&2
    git --no-pager diff -- "${TRACKED_PATHS[@]}"
    exit 1
  fi

  UNTRACKED="$(git ls-files --others --exclude-standard -- "${TRACKED_PATHS[@]}")"
  if [ -n "$UNTRACKED" ]; then
    echo "Found untracked generated files:" >&2
    echo "$UNTRACKED" >&2
    echo "Run ./scripts/generate.sh and commit generated files." >&2
    exit 1
  fi
)
