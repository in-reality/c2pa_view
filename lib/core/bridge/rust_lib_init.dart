import 'package:c2pa_view/core/bridge/rust_lib_init_platform.dart'
    if (dart.library.js_interop) 'package:c2pa_view/core/bridge/rust_lib_init_web.dart';
import 'package:c2pa_view/src/rust/frb_generated.dart';

/// Initializes the c2pa_view Rust/WASM bridge once per app session.
///
/// On web, Flutter hot restart re-runs `main` while the browser keeps the
/// previously loaded `wasm_bindgen` global. Re-injecting `pkg/*.js` throws
/// `Identifier 'wasm_bindgen' has already been declared` and breaks decode.
/// When WASM is already on `window`, pass a reused [ExternalLibrary] so FRB
/// skips script injection.
Future<void> initRustLib({
  Duration timeout = const Duration(seconds: 15),
}) async {
  if (RustLib.instance.initialized) {
    return;
  }

  await RustLib.init(
    externalLibrary: createReusedExternalLibraryIfAny(),
  ).timeout(timeout);
}
