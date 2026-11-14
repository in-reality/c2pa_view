import 'dart:async';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Backend implements C2paBackend {
  final ready = Completer<void>();
  final events = <String>[];

  @override
  Future<void> initialize() {
    events.add('initialize');
    return ready.future;
  }

  @override
  Future<String?> validateBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async {
    events.add('validate');
    expect(fileBytes, [1, 2, 3]);
    expect(format, 'image/png');
    return '{"manifests":{}}';
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw StateError('unexpected backend operation');
}

void main() {
  test(
    'URL first use locks backend before init, fetch and validation',
    () async {
      final backend = _Backend();
      installC2paBackend(backend);
      final requested = Completer<void>();
      final response = Completer<http.Response>();
      final read = http.runWithClient(
        () => getManifestJsonFromURL('https://fixture.invalid/image'),
        () => MockClient((final request) {
          backend.events.add('fetch');
          requested.complete();
          return response.future;
        }),
      );
      expect(() => installC2paBackend(_Backend()), throwsStateError);
      expect(backend.events, ['initialize']);
      backend.ready.complete();
      await requested.future;
      expect(backend.events, ['initialize', 'fetch']);
      expect(() => installC2paBackend(_Backend()), throwsStateError);
      response.complete(
        http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'content-type': 'image/png'},
        ),
      );
      expect(await read, '{"manifests":{}}');
      expect(backend.events, ['initialize', 'fetch', 'validate']);
      expect(RustLib.instance.initialized, isFalse);
    },
  );
}
