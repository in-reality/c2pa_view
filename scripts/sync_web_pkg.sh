#!/usr/bin/env bash
# Build the Rust crate to WASM, then copy web/pkg into each demo app's web/
# folder so "flutter run -d chrome" can load the Rust library.
#
# Requires wasm-pack: https://rustwasm.github.io/wasm-pack/installer/
# no-modules is required so the JS exposes global wasm_bindgen for flutter_rust_bridge.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUST_DIR="$REPO_ROOT/rust"
SRC="$REPO_ROOT/web/pkg"
DESTS=(
  "$REPO_ROOT/testfiles_app/web/pkg"
  "$REPO_ROOT/example/web/pkg"
)

if ! command -v wasm-pack >/dev/null 2>&1; then
  echo "Error: wasm-pack not found. Install from https://rustwasm.github.io/wasm-pack/installer/"
  exit 1
fi

echo "Building WASM (wasm-pack)..."
(
  cd "$RUST_DIR"
  wasm-pack build --target no-modules --out-dir ../web/pkg --out-name c2pa_view
)

# Hot restart re-injects pkg/*.js; `let wasm_bindgen` is not re-declarable in JS.
if [[ -f "$SRC/c2pa_view.js" ]]; then
  sed -i 's/^let wasm_bindgen/var wasm_bindgen/' "$SRC/c2pa_view.js"
fi

if [[ ! -d "$SRC" ]]; then
  echo "Error: $SRC not found after wasm-pack build."
  exit 1
fi

for DST in "${DESTS[@]}"; do
  mkdir -p "$DST"
  cp -r "$SRC"/* "$DST"/
  echo "Synced $SRC -> $DST"
done
