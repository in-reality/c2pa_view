import 'dart:async';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReentrantBackend implements C2paBackend {
  final ready = Completer<void>();
  int attempts = 0;
  late Future<void> nested;

  @override
  Future<void> initialize() {
    attempts++;
    nested = initRustLib();
    return ready.future;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('unexpected reader operation');
}

void main() {
  test(
    'synchronous host reentry observes the published initialization',
    () async {
      final backend = _ReentrantBackend();
      installC2paBackend(backend);
      final first = initRustLib();
      expect(backend.attempts, 1);
      expect(identical(first, backend.nested), isTrue);
      expect(identical(first, initRustLib()), isTrue);
      backend.ready.complete();
      await Future.wait([first, backend.nested]);
      expect(backend.attempts, 1);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
