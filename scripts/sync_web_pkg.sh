#!/usr/bin/env bash
# Copy the plugin's built WASM pkg into the testfiles_app's web folder so
# "flutter run -d chrome" can load the Rust library. Run this after building
# WASM from rust/ with: wasm-pack build --target no-modules --out-dir ../web/pkg --out-name c2pa_view
# (no-modules is required so the JS exposes global wasm_bindgen for flutter_rust_bridge.)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/web/pkg"
DST="$REPO_ROOT/testfiles_app/web/pkg"
if [[ ! -d "$SRC" ]]; then
  echo "Error: $SRC not found. Build WASM first from rust/: wasm-pack build --target no-modules --out-dir ../web/pkg --out-name c2pa_view"
  exit 1
fi
mkdir -p "$DST"
cp -r "$SRC"/* "$DST"/
echo "Synced $SRC -> $DST"
