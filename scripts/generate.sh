#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/proto"
JS_PACKAGE_DIR="$ROOT_DIR/packages/js/lirays-scada-proto"
JS_LOCAL_PROTOC_GEN_TS_PROTO="$JS_PACKAGE_DIR/node_modules/.bin/protoc-gen-ts_proto"

TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=(all)
fi

WANT_RUST=false
WANT_PYTHON=false
WANT_JS=false

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
}

collect_proto_files() {
  PROTO_FILES=()
  while IFS= read -r file; do
    PROTO_FILES+=("$file")
  done < <(find "$PROTO_DIR" -type f -name '*.proto' | sort)

  if [ ${#PROTO_FILES[@]} -eq 0 ]; then
    echo "No .proto files found under $PROTO_DIR" >&2
    exit 1
  fi
}

resolve_js_protoc_gen_ts_proto() {
  if [ -x "$JS_LOCAL_PROTOC_GEN_TS_PROTO" ]; then
    JS_PROTOC_GEN_TS_PROTO="$JS_LOCAL_PROTOC_GEN_TS_PROTO"
    return 0
  fi

  if command -v protoc-gen-ts_proto > /dev/null 2>&1; then
    JS_PROTOC_GEN_TS_PROTO="$(command -v protoc-gen-ts_proto)"
    return 0
  fi

  require_cmd npm
  echo "protoc-gen-ts_proto not found; installing JS dependencies in $JS_PACKAGE_DIR..."
  npm install --prefix "$JS_PACKAGE_DIR"

  if [ -x "$JS_LOCAL_PROTOC_GEN_TS_PROTO" ]; then
    JS_PROTOC_GEN_TS_PROTO="$JS_LOCAL_PROTOC_GEN_TS_PROTO"
    return 0
  fi

  if command -v protoc-gen-ts_proto > /dev/null 2>&1; then
    JS_PROTOC_GEN_TS_PROTO="$(command -v protoc-gen-ts_proto)"
    return 0
  fi

  echo "Unable to find protoc-gen-ts_proto after dependency installation." >&2
  exit 1
}

generate_python() {
  require_cmd protoc
  collect_proto_files

  protoc \
    -I "$PROTO_DIR" \
    --python_out="$ROOT_DIR/packages/python/lirays-scada-proto/src" \
    "${PROTO_FILES[@]}"

  if [ -d "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace" ]; then
    touch "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace/__init__.py"
  fi
  if [ -d "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace/v1" ]; then
    touch "$ROOT_DIR/packages/python/lirays-scada-proto/src/namespace/v1/__init__.py"
  fi
}

generate_js() {
  require_cmd protoc
  collect_proto_files
  resolve_js_protoc_gen_ts_proto

  rm -rf "$ROOT_DIR/packages/js/lirays-scada-proto/src/generated"
  mkdir -p "$ROOT_DIR/packages/js/lirays-scada-proto/src/generated"

  protoc \
    -I "$PROTO_DIR" \
    --plugin="protoc-gen-ts_proto=$JS_PROTOC_GEN_TS_PROTO" \
    --ts_proto_out="$ROOT_DIR/packages/js/lirays-scada-proto/src/generated" \
    --ts_proto_opt=esModuleInterop=true,importSuffix=.js,exportCommonSymbols=false \
    "${PROTO_FILES[@]}"
}

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
  "$ROOT_DIR/scripts/vendor-rust-proto.sh"
fi

if [ "$WANT_PYTHON" = true ]; then
  "$ROOT_DIR/scripts/sync-license.sh" python
  generate_python
fi

if [ "$WANT_JS" = true ]; then
  "$ROOT_DIR/scripts/sync-license.sh" js
  generate_js
fi
