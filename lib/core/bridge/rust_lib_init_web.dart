import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart'
    show ExternalLibrary;
import 'package:web/web.dart' as web;

// Release hosts bind immutable asset identity at compile time.
// ignore: do_not_use_environment
const _assetBase = String.fromEnvironment(
  'VERIFIER_ASSET_BASE',
  defaultValue: 'pkg/',
);

@JS('c2pa_view_bindgen')
external JSAny? get _initializer;
@JS('__inrealityC2paReadyBase')
external JSString? get _readyBase;
@JS('__inrealityC2paReadyBase')
external set _readyBase(final JSString? value);

/// Loads the generated reader namespace without eval or changing other bridges.
Future<ExternalLibrary?> loadRustExternalLibrary() async {
  if (_readyBase?.toDart != _assetBase) {
    final scriptUri = Uri.base.resolve('${_assetBase}c2pa_view.js');
    final wasmUri = Uri.base.resolve('${_assetBase}c2pa_view_bg.wasm');
    final response = await web.window.fetch(wasmUri.toString().toJS).toDart;
    if (!response.ok) {
      throw StateError('Missing reader WASM asset');
    }
    final script = web.HTMLScriptElement()
      ..src = scriptUri.toString()
      ..crossOrigin = 'anonymous';
    final loaded = Completer<void>();
    final onLoad = script.onLoad.listen((_) => loaded.complete());
    final onError = script.onError.listen((_) {
      loaded.completeError(StateError('Could not load reader script'));
    });
    try {
      web.document.head!.append(script);
      await loaded.future;
      if (!_initializer.typeofEquals('function')) {
        throw StateError('Reader script did not publish its initializer');
      }
      await ((_initializer! as JSFunction).callAsFunction(
                null,
                {'module_or_path': response}.jsify(),
              )!
              as JSPromise<JSAny?>)
          .toDart;
    } finally {
      await onLoad.cancel();
      await onError.cancel();
      script.remove();
    }
  }
  return const ExternalLibrary(
    debugInfo: 'c2pa_view at $_assetBase',
    wasmBindgenName: 'c2pa_view_bindgen',
  );
}

/// Written after FRB's content-hash sanity check and initializers succeed.
void markRustLibraryReady() => _readyBase = _assetBase.toJS;
