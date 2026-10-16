import 'dart:async';
import 'dart:io';

import 'package:c2pa_view/src/rust/frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Exercises the hook-built library before any legacy Cargo test fallback.
Future<void> testExecutable(final FutureOr<void> Function() testMain) async {
  final libraryName = Platform.isMacOS
      ? 'libc2pa_view.dylib'
      : Platform.isWindows
      ? 'c2pa_view.dll'
      : 'libc2pa_view.so';
  final nativeAsset = File(
    'build/native_assets/${Platform.operatingSystem}/$libraryName',
  );
  if (nativeAsset.existsSync()) {
    await RustLib.init(externalLibrary: ExternalLibrary.open(nativeAsset.path));
  }
  await testMain();
}
