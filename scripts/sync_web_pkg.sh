#!/usr/bin/env bash
# Build the Rust crate to WASM, then copy web/pkg into each demo app's web/
# folder so "flutter run -d chrome" can load the Rust library.
#
# Pass --no-demo-copies to write web/pkg only. Release jobs use that so the
# tracked example and testfiles_app packages stay at their committed bytes.
#
# Requires wasm-pack: https://rustwasm.github.io/wasm-pack/installer/
# The supported named no-modules output isolates this reader from other FRB libraries.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUST_DIR="$REPO_ROOT/rust"
SRC="$REPO_ROOT/web/pkg"
DESTS=(
  "$REPO_ROOT/testfiles_app/web/pkg"
  "$REPO_ROOT/example/web/pkg"
)

copy_demos=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-demo-copies) copy_demos=0 ;;
    *)
      echo "Error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v wasm-pack >/dev/null 2>&1; then
  echo "Error: wasm-pack not found. Install from https://rustwasm.github.io/wasm-pack/installer/"
  exit 1
fi

echo "Building WASM (wasm-pack)..."
(
  cd "$RUST_DIR"
  wasm-pack build --no-opt --target no-modules --out-dir ../web/pkg --out-name c2pa_view
)

# wasm-pack installs the exact matching bindgen CLI. Re-run that generator with
# its supported namespace flag (wasm-pack does not expose this option).
BINDGEN_VERSION="$(python3 - "$RUST_DIR/Cargo.lock" <<'PYVERSION'
import sys, tomllib
with open(sys.argv[1], 'rb') as f:
    print(next(p['version'] for p in tomllib.load(f)['package'] if p['name'] == 'wasm-bindgen'))
PYVERSION
)"
BINDGEN="${WASM_BINDGEN:-}"
if [[ -z "$BINDGEN" ]]; then
  for candidate in \
    "$HOME/Library/Caches/.wasm-pack/wasm-bindgen-cargo-install-$BINDGEN_VERSION/wasm-bindgen" \
    "$HOME/.cache/.wasm-pack/wasm-bindgen-cargo-install-$BINDGEN_VERSION/wasm-bindgen"; do
    if [[ -x "$candidate" ]]; then BINDGEN="$candidate"; break; fi
  done
fi
if [[ -z "$BINDGEN" ]]; then BINDGEN="$(command -v wasm-bindgen || true)"; fi
if [[ -z "$BINDGEN" || "$("$BINDGEN" --version)" != "wasm-bindgen $BINDGEN_VERSION" ]]; then
  echo "Set WASM_BINDGEN to wasm-bindgen $BINDGEN_VERSION" >&2
  exit 1
fi
TARGET_DIR="$(cd "$RUST_DIR" && cargo metadata --no-deps --format-version 1 | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])')"
"$BINDGEN" "$TARGET_DIR/wasm32-unknown-unknown/release/c2pa_view.wasm" \
  --target no-modules --no-modules-global c2pa_view_bindgen \
  --out-dir "$SRC" --out-name c2pa_view
# Static JS interop reads a global property, not a top-level lexical binding.
# Publish only our generated namespace; no eval or shared wasm_bindgen alias.
printf '\nglobalThis.c2pa_view_bindgen = c2pa_view_bindgen;\n' >> "$SRC/c2pa_view.js"

if [[ ! -d "$SRC" ]]; then
  echo "Error: $SRC not found after wasm-pack build."
  exit 1
fi

if [[ "$copy_demos" -eq 0 ]]; then
  echo "Skipping demo copies (--no-demo-copies)"
else
  for DST in "${DESTS[@]}"; do
    mkdir -p "$DST"
    cp -r "$SRC"/* "$DST"/
    echo "Synced $SRC -> $DST"
  done
fi
