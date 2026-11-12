import 'dart:convert';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/embedded_preview_fixture.dart' show testAllowedLeafPem;
import 'fixtures/trusted_timestamp_fixture.dart';

List<String> _currentCodes(final String? raw) {
  expect(raw, isNotNull);
  final value = jsonDecode(raw!) as Map<String, dynamic>;
  expect((value['manifests'] as Map).length, 1);
  return (value['current_validation_status'] as List)
      .cast<Map<String, dynamic>>()
      .where((final s) => s['ingredient_uri'] == null)
      .map((final s) => s['code'] as String)
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native and WASM trust a real v2 timestamp with explicit TSA input',
    () async {
      await initRustLib();
      final bytes = base64Decode(timestampAsset);
      final codes = _currentCodes(
        await getManifestJsonFromBytes(
          fileBytes: bytes,
          format: 'image/jpeg',
          timestampTrustAnchorsPem: timestampCaPem,
        ),
      );
      expect(codes, contains('timeStamp.validated'));
      expect(codes, contains('timeStamp.trusted'));
      expect(codes, isNot(contains('timeStamp.untrusted')));
      expect(codes, contains('signingCredential.untrusted'));
      expect(codes, contains('cawg.x509.credential.untrusted'));
      final bridge = _currentCodes(
        await C2paBridgeService.getManifestJsonFromBytes(
          fileBytes: bytes,
          format: 'image/jpeg',
          timestampTrustAnchorsPem: timestampCaPem,
        ),
      );
      expect(bridge, contains('timeStamp.trusted'));
      final store = await ManifestStore.fromBytes(
        bytes,
        'image/jpeg',
        timestampTrustAnchorsPem: timestampCaPem,
      );
      expect(store, isNotNull);
      expect(
        store!.validationStatus.any(
          (final s) => s.code == 'signingCredential.untrusted',
        ),
        isTrue,
      );
    },
  );
  test(
    'native and WASM refuse missing, wrong-purpose and unrelated TSA trust',
    () async {
      await initRustLib();
      final bytes = base64Decode(timestampAsset);
      for (final input in [
        (null, null),
        (timestampCaPem, null),
        (null, testAllowedLeafPem),
      ]) {
        final codes = _currentCodes(
          await getManifestJsonFromBytes(
            fileBytes: bytes,
            format: 'image/jpeg',
            trustAnchorsPem: input.$1,
            timestampTrustAnchorsPem: input.$2,
          ),
        );
        expect(codes, contains('timeStamp.validated'));
        expect(codes, contains('timeStamp.untrusted'));
        expect(codes, isNot(contains('timeStamp.trusted')));
      }
    },
  );
}
