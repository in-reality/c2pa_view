import 'dart:typed_data';

import 'package:c2pa_view/api.dart' as api;
import 'package:c2pa_view/core/bridge/c2pa_bridge_service.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Argument transport only. Real SDK timestamp controls live in timestamp_trust_test.
class _CaptureApi implements RustLibApi {
  int calls = 0;

  @override
  dynamic noSuchMethod(final Invocation invocation) {
    expect(invocation.memberName.toString(), contains('TrustValidation'));
    expect(invocation.namedArguments[#trustAnchorsPem], '');
    expect(invocation.namedArguments[#timestampTrustAnchorsPem], 'tsa-test');
    expect(invocation.namedArguments[#allowedListPem], isNull);
    calls++;
    return Future<String?>.value('{"manifests":{}}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = _CaptureApi();
  setUpAll(() {
    // The native testExecutable initializes the real library before this file.
    RustLib.dispose();
    RustLib.initMock(api: capture);
  });
  tearDownAll(RustLib.dispose);
  final bytes = Uint8List.fromList([1, 2, 3]);
  final cases = <String, Future<Object?> Function()>{
    'public file': () => api.getManifestJsonFromFile(
      'fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'public URL': () => api.getManifestJsonFromURL(
      'https://example.invalid/fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'public bytes': () => api.getManifestJsonFromBytes(
      fileBytes: bytes,
      format: 'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'public detached': () => api.getDetachedManifestJsonFromBytes(
      manifestBytes: bytes,
      assetBytes: bytes,
      assetFormat: 'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge file JSON': () => C2paBridgeService.getManifestJsonFromFile(
      'fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge URL JSON': () => C2paBridgeService.getManifestJsonFromUrl(
      'https://example.invalid/fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge bytes JSON': () => C2paBridgeService.getManifestJsonFromBytes(
      fileBytes: bytes,
      format: 'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge file store': () => C2paBridgeService.loadFromFile(
      'fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge URL store': () => C2paBridgeService.loadFromUrl(
      'https://example.invalid/fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'bridge byte store': () => C2paBridgeService.loadFromBytes(
      fileBytes: bytes,
      format: 'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'store file': () => ManifestStore.fromLocalPath(
      'fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'store URL': () => ManifestStore.fromUrl(
      'https://example.invalid/fixture.jpg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'store bytes': () => ManifestStore.fromBytes(
      bytes,
      'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
    'store detached': () => ManifestStore.fromDetached(
      manifestBytes: bytes,
      assetBytes: bytes,
      assetFormat: 'image/jpeg',
      timestampTrustAnchorsPem: 'tsa-test',
    ),
  };
  for (final entry in cases.entries) {
    test(
      '${entry.key} forwards TSA-only input without widening Manifest trust',
      () async {
        final before = capture.calls;
        await http.runWithClient(
          entry.value,
          () => MockClient((_) async => http.Response.bytes(bytes, 200)),
        );
        expect(capture.calls, before + 1);
      },
    );
  }
}
