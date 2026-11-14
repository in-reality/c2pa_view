import 'package:c2pa_view/core/bridge/c2pa_backend.dart';

/// Initializes the selected backend once, coalescing concurrent callers.
///
/// Failed or timed-out initialization stays failed until reload. Injected
/// backends never load the standalone native/WASM library through this facade.
Future<void> initRustLib({
  final Duration timeout = const Duration(seconds: 15),
}) => initializeC2paBackend(timeout: timeout);
