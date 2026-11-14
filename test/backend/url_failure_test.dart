import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Backend implements C2paBackend {
  final events = <String>[];

  @override
  Future<void> initialize() async {
    events.add('initialize');
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('failed fetch must not reach a reader');
}

void main() {
  test(
    'failed first URL fetch preserves selected backend and original error',
    () async {
      final backend = _Backend();
      installC2paBackend(backend);
      final failure = http.ClientException('fetch failed');
      final read = http.runWithClient(
        () => C2paBridgeService.getManifestJsonFromUrl(
          'https://fixture.invalid/image',
        ),
        () => MockClient((final request) async {
          backend.events.add('fetch');
          throw failure;
        }),
      );
      expect(() => installC2paBackend(_Backend()), throwsStateError);
      await expectLater(read, throwsA(same(failure)));
      expect(backend.events, ['initialize', 'fetch']);
      expect(() => installC2paBackend(_Backend()), throwsStateError);
      await initRustLib();
      expect(backend.events, ['initialize', 'fetch']);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
