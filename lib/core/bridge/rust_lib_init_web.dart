import 'dart:js_interop';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

@JS('wasm_bindgen')
external JSAny? get _windowWasmBindgen;

/// Reuses an already-loaded `wasm_bindgen` global after Flutter hot restart.
ExternalLibrary? createReusedExternalLibraryIfAny() {
  try {
    if (_windowWasmBindgen == null) {
      return null;
    }
    return ExternalLibrary(
      debugInfo: 'reused wasm_bindgen after hot restart',
      wasmBindgenName: 'wasm_bindgen',
    );
  } on Object {
    return null;
  }
}
