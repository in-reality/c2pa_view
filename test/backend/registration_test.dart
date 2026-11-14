import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _Backend implements C2paBackend {
  int initializations = 0;

  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('unexpected reader operation');
}

void main() {
  test(
    'registration is single-use before initialization or any read',
    () async {
      final first = _Backend();
      final replacement = _Backend();
      expect(RustLib.instance.initialized, isFalse);
      installC2paBackend(first);
      expect(first.initializations, 0);
      expect(() => installC2paBackend(first), throwsStateError);
      expect(() => installC2paBackend(replacement), throwsStateError);
      await initRustLib();
      expect(first.initializations, 1);
      expect(replacement.initializations, 0);
      expect(() => installC2paBackend(replacement), throwsStateError);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
