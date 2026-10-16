import 'package:c2pa_view/core/bridge/rust_lib_init_platform.dart'
    if (dart.library.js_interop) 'package:c2pa_view/core/bridge/rust_lib_init_web.dart';
import 'package:c2pa_view/src/rust/frb_generated.dart';

Future<void>? _initialization;

/// Initializes the bridge once, coalescing concurrent callers.
///
/// A failed or timed-out browser initialization stays failed until reload:
/// partially installed JavaScript globals are never treated as ready.
Future<void> initRustLib({
  final Duration timeout = const Duration(seconds: 15),
}) => _initialization ??= _initialize().timeout(timeout);

Future<void> _initialize() async {
  if (RustLib.instance.initialized) {
    return;
  }
  await RustLib.init(externalLibrary: await loadRustExternalLibrary());
  markRustLibraryReady();
}
