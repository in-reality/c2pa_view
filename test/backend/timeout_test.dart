import 'dart:async';
import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _SlowBackend implements C2paBackend {
  final ready = Completer<void>();
  int attempts = 0;
  @override
  Future<void> initialize() {
    attempts++;
    return ready.future;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('reader must not dispatch after initialization timeout');
}

void main() {
  test(
    'first timeout stays failed even if initialization later completes',
    () async {
      RustLib.dispose();
      final backend = _SlowBackend();
      installC2paBackend(backend);
      final first = initRustLib(timeout: const Duration(milliseconds: 1));
      expect(identical(first, initRustLib()), isTrue);
      await expectLater(first, throwsA(isA<TimeoutException>()));
      backend.ready.complete();
      await expectLater(
        getManifestJsonFromFile('unused.jpg'),
        throwsA(isA<TimeoutException>()),
      );
      expect(backend.attempts, 1);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
