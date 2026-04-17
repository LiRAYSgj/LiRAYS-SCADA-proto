#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PROTO_DIR="$ROOT_DIR/proto"
TARGET_PROTO_DIR="$ROOT_DIR/packages/rust/lirays-scada-proto/proto"

if [ ! -d "$SOURCE_PROTO_DIR" ]; then
  echo "Source proto directory not found: $SOURCE_PROTO_DIR" >&2
  exit 1
fi

rm -rf "$TARGET_PROTO_DIR"
mkdir -p "$TARGET_PROTO_DIR"
cp -R "$SOURCE_PROTO_DIR"/. "$TARGET_PROTO_DIR"/
