import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart';

// Release hosts bind immutable asset identity at compile time.
// ignore: do_not_use_environment
const _assetBase = String.fromEnvironment(
  'VERIFIER_ASSET_BASE',
  defaultValue: 'pkg/',
);

@JS('__inrealityC2paReadyBase')
external JSString? get _readyBase;
@JS('__inrealityC2paReadyBase')
external set _readyBase(final JSString? value);

/// Reuses only a successfully initialized bridge from this exact release.
Future<ExternalLibrary?> loadRustExternalLibrary() async {
  if (_readyBase?.toDart != _assetBase) {
    await initializeWasmModule(root: '${_assetBase}c2pa_view');
  }
  return const ExternalLibrary(debugInfo: 'c2pa_view at $_assetBase');
}

/// Written after FRB's content-hash sanity check and initializers succeed.
void markRustLibraryReady() => _readyBase = _assetBase.toJS;
