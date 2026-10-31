import 'dart:async';

import 'helpers/init_native_rust_stub.dart'
    if (dart.library.io) 'helpers/init_native_rust.dart';

/// Exercises the hook-built library before any legacy Cargo test fallback.
Future<void> testExecutable(final FutureOr<void> Function() testMain) async {
  await initNativeRust();
  await testMain();
}
