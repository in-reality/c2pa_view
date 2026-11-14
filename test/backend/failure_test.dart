import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingBackend implements C2paBackend {
  int attempts = 0;
  late Future<void> nested;
  final failure = StateError('initialization failed');
  @override
  Future<void> initialize() {
    attempts++;
    nested = initRustLib();
    throw failure;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('reader must not dispatch after failed initialization');
}

void main() {
  test(
    'synchronous reentrant init failure reaches every caller without fallback',
    () async {
      RustLib.dispose();
      final backend = _FailingBackend();
      installC2paBackend(backend);
      final first = initRustLib();
      final second = initRustLib();
      expect(identical(first, second), isTrue);
      expect(identical(first, backend.nested), isTrue);
      await expectLater(first, throwsA(same(backend.failure)));
      await expectLater(backend.nested, throwsA(same(backend.failure)));
      await expectLater(
        getManifestJsonFromFile('unused.jpg'),
        throwsA(same(backend.failure)),
      );
      expect(backend.attempts, 1);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
