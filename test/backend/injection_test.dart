import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/src/rust/api/c2pa.dart' as standalone;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Backend implements C2paBackend {
  final ready = Completer<void>();
  int initializations = 0;
  final calls = <String>[];
  final inputs = <List<Object?>>[];
  String? result = '{"manifests":{}}';
  StateError? error;

  @override
  Future<void> initialize() {
    initializations++;
    return ready.future;
  }

  Future<String?> record(final String call, final List<Object?> input) async {
    calls.add(call);
    inputs.add(input);
    if (error != null) {
      throw error!;
    }
    return result;
  }

  @override
  Future<String?> validatePath({
    required final String path,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) => record('path', [
    path,
    trustAnchorsPem,
    timestampTrustAnchorsPem,
    allowedListPem,
  ]);

  @override
  Future<String?> validateBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) => record('bytes', [
    fileBytes,
    format,
    trustAnchorsPem,
    timestampTrustAnchorsPem,
    allowedListPem,
  ]);

  @override
  Future<String?> readManifestStore({
    required final List<int> fileBytes,
    required final String format,
  }) => record('store', [fileBytes, format]);

  @override
  Future<String?> validateDetached({
    required final List<int> manifestBytes,
    required final List<int> assetBytes,
    required final String assetFormat,
    final String manifestFormat = 'application/c2pa',
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) => record('detached', [
    manifestBytes,
    assetBytes,
    assetFormat,
    manifestFormat,
    trustAnchorsPem,
    timestampTrustAnchorsPem,
    allowedListPem,
  ]);
}

void main() {
  final backend = _Backend();
  final bytes = Uint8List.fromList([1, 2, 3]);
  setUpAll(() async {
    // The nested test config deliberately omits native initialization.
    expect(RustLib.instance.initialized, isFalse);
    // Failing standalone-dispatch sentinel: the old entrypoint cannot run.
    expect(
      () => standalone.getManifestWithValidation(
        fileBytes: bytes,
        format: 'image/png',
      ),
      throwsStateError,
    );
    installC2paBackend(backend);
    final firstRead = getManifestJsonFromBytes(
      fileBytes: bytes,
      format: 'image/png',
    );
    final first = initRustLib();
    final second = initRustLib();
    expect(identical(first, second), isTrue);
    expect(backend.initializations, 1);
    expect(backend.calls, isEmpty);
    backend.ready.complete();
    await firstRead;
    await first;
    expect(RustLib.instance.initialized, isFalse);
  });

  setUp(() {
    backend
      ..result = '{"manifests":{}}'
      ..error = null;
  });

  test(
    'selected backend stays initialized and rejects late replacement',
    () async {
      await initRustLib();
      expect(backend.initializations, 1);
      expect(() => installC2paBackend(_Backend()), throwsStateError);
      expect(RustLib.instance.initialized, isFalse);
    },
  );

  test(
    'every facade forwards independent trust inputs and detached formats',
    () async {
      final start = backend.inputs.length;
      final cases = <Future<Object?> Function()>[
        () => getManifestJsonFromFile(
          'a.png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => getManifestJsonFromURL(
          'https://fixture.invalid/a',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => getManifestJsonFromBytes(
          fileBytes: bytes,
          format: 'image/png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => getDetachedManifestJsonFromBytes(
          manifestBytes: bytes,
          assetBytes: bytes,
          assetFormat: 'image/png',
          manifestFormat: 'c2pa',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => C2paBridgeService.loadFromFile(
          'a.png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => C2paBridgeService.loadFromUrl(
          'https://fixture.invalid/a',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => C2paBridgeService.loadFromBytes(
          fileBytes: bytes,
          format: 'image/png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => ManifestStore.fromLocalPath(
          'a.png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => ManifestStore.fromUrl(
          'https://fixture.invalid/a',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => ManifestStore.fromBytes(
          bytes,
          'image/png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
        () => ManifestStore.fromDetached(
          manifestBytes: bytes,
          assetBytes: bytes,
          assetFormat: 'image/png',
          trustAnchorsPem: 'manifest',
          timestampTrustAnchorsPem: 'tsa',
          allowedListPem: 'leaf',
        ),
      ];
      for (final call in cases) {
        final before = backend.calls.length;
        await http.runWithClient(
          call,
          () => MockClient(
            (_) async => http.Response.bytes(
              bytes,
              200,
              headers: {'content-type': 'image/png'},
            ),
          ),
        );
        expect(backend.calls.length, before + 1);
        expect(backend.inputs.last.sublist(backend.inputs.last.length - 3), [
          'manifest',
          'tsa',
          'leaf',
        ]);
        expect(RustLib.instance.initialized, isFalse);
      }
      expect(backend.inputs[start + 3][3], 'c2pa');
      await getManifestStoreJsonFromBytes(
        fileBytes: bytes,
        format: 'application/c2pa',
      );
      expect(backend.calls.last, 'store');
      expect(backend.inputs.last, [bytes, 'application/c2pa']);
    },
  );

  test(
    'preview and unperformed/failed evidence survive injected execution',
    () async {
      for (final status in <List<Map<String, String>>?>[
        null,
        [],
        [
          {'code': 'assertion.dataHash.mismatch'},
        ],
      ]) {
        backend.result = jsonEncode({
          'active_manifest': 'claim',
          'manifests': {
            'claim': {
              'label': 'claim',
              'thumbnail': {
                'format': 'image/png',
                'identifier': 'embedded',
                'resolution': 'resolved',
                'containing_manifest': 'claim',
                'data': [1, 2, 3],
              },
              if (status != null) 'validation_status': status,
            },
          },
        });
        expect(
          await getManifestJsonFromBytes(fileBytes: bytes, format: 'image/png'),
          backend.result,
        );
        final store = await ManifestStore.fromBytes(bytes, 'image/png');
        final claim = store!.manifests['claim']!;
        expect(claim.validationStatusComputed, status != null);
        expect(
          claim.validationStatus.map((final s) => s.code),
          status?.map((final s) => s['code']) ?? [],
        );
        expect(claim.thumbnail!.data, [1, 2, 3]);
        expect(claim.thumbnail!.containingManifest, 'claim');
        expect(claim.thumbnail!.resolution, 'resolved');
        expect(RustLib.instance.initialized, isFalse);
      }
    },
  );

  test('null, malformed JSON and backend errors keep their meanings', () async {
    backend.result = null;
    expect(await ManifestStore.fromBytes(bytes, 'image/png'), isNull);
    backend.result = 'malformed';
    await expectLater(
      ManifestStore.fromBytes(bytes, 'image/png'),
      throwsFormatException,
    );
    backend.result = '{"manifests":{}}';
    final failure = StateError('backend validation failed');
    backend.error = failure;
    await expectLater(
      getManifestJsonFromBytes(fileBytes: bytes, format: 'image/png'),
      throwsA(same(failure)),
    );
    expect(RustLib.instance.initialized, isFalse);
  });
}
