import 'package:c2pa_view/core/bridge/rust_lib_init.dart';
import 'package:c2pa_view/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedApi implements RustLibApi {
  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('concurrent and repeated callers share initialization', () async {
    if (!RustLib.instance.initialized) {
      RustLib.initMock(api: _UnusedApi());
    }
    final first = initRustLib();
    final second = initRustLib();
    expect(identical(first, second), isTrue);
    await Future.wait([first, second]);
    expect(RustLib.instance.initialized, isTrue);
    await initRustLib();
  });
}
