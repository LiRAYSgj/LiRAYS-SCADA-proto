#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/proto"
JS_PACKAGE_DIR="$ROOT_DIR/packages/js/lirays-scada-proto"
JS_LOCAL_PROTOC_GEN_ES="$JS_PACKAGE_DIR/node_modules/.bin/protoc-gen-es"

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

resolve_js_protoc_gen_es() {
  if [ -x "$JS_LOCAL_PROTOC_GEN_ES" ]; then
    JS_PROTOC_GEN_ES="$JS_LOCAL_PROTOC_GEN_ES"
    return 0
  fi

  if command -v protoc-gen-es > /dev/null 2>&1; then
    JS_PROTOC_GEN_ES="$(command -v protoc-gen-es)"
    return 0
  fi

  require_cmd npm
  echo "protoc-gen-es not found; installing JS dependencies in $JS_PACKAGE_DIR..."
  npm install --prefix "$JS_PACKAGE_DIR"

  if [ -x "$JS_LOCAL_PROTOC_GEN_ES" ]; then
    JS_PROTOC_GEN_ES="$JS_LOCAL_PROTOC_GEN_ES"
    return 0
  fi

  if command -v protoc-gen-es > /dev/null 2>&1; then
    JS_PROTOC_GEN_ES="$(command -v protoc-gen-es)"
    return 0
  fi

  echo "Unable to find protoc-gen-es after dependency installation." >&2
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
  resolve_js_protoc_gen_es

  mkdir -p "$ROOT_DIR/packages/js/lirays-scada-proto/src/generated"

  protoc \
    -I "$PROTO_DIR" \
    --plugin="protoc-gen-es=$JS_PROTOC_GEN_ES" \
    --es_out="$ROOT_DIR/packages/js/lirays-scada-proto/src/generated" \
    --es_opt=target=ts,import_extension=.js \
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
  generate_python
fi

if [ "$WANT_JS" = true ]; then
  generate_js
fi
