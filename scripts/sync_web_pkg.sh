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

if [[ ! -d "$SRC" ]]; then
  echo "Error: $SRC not found after wasm-pack build."
  exit 1
fi

for DST in "${DESTS[@]}"; do
  mkdir -p "$DST"
  cp -r "$SRC"/* "$DST"/
  echo "Synced $SRC -> $DST"
done
