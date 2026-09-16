import 'dart:convert';
import 'dart:io';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relative to the c2pa_view package root → monorepo signing corpus.
const _samplesDir =
    '../../../c2pa/evidence/backend-signing/samples';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('detached manifest validation', () {
    late List<int> manifestBytes;
    late List<int> assetBytes;
    var fixturesAvailable = false;

    setUpAll(() async {
      await initRustLib();

      final manifestFile = File('$_samplesDir/a-sample.c2pa');
      final assetFile = File('$_samplesDir/subject_unsigned.jpg');
      fixturesAvailable =
          manifestFile.existsSync() && assetFile.existsSync();
      if (!fixturesAvailable) {
        return;
      }
      manifestBytes = await manifestFile.readAsBytes();
      assetBytes = await assetFile.readAsBytes();
    });

    test('fromDetached validates matching asset bytes', () async {
      if (!fixturesAvailable) {
        return;
      }

      final manifestJson = await getDetachedManifestJsonFromBytes(
        manifestBytes: manifestBytes,
        assetBytes: assetBytes,
        assetFormat: 'image/jpeg',
      );
      expect(manifestJson, isNotNull);

      final parsed = json.decode(manifestJson!) as Map<String, dynamic>;
      final successes = (parsed['validation_results']?['activeManifest']?['success']
              as List<dynamic>?)
          ?.map((final e) => (e as Map)['code'] as String)
          .toList();
      expect(successes, contains('assertion.dataHash.match'));
      expect(parsed['validation_state'], 'Valid');

      final store = ManifestStore.fromJson(parsed);
      expect(store.activeManifest, isNotNull);
    });

    test('fromDetached reports hash mismatch for altered asset', () async {
      if (!fixturesAvailable) {
        return;
      }

      final tampered = List<int>.from(assetBytes);
      tampered[0] ^= 0xff;

      final store = await ManifestStore.fromDetached(
        manifestBytes: manifestBytes,
        assetBytes: tampered,
        assetFormat: 'image/jpeg',
      );

      expect(store, isNotNull);
      expect(
        store!.validationStatus.any(
          (final e) => e.code == 'assertion.dataHash.mismatch',
        ),
        isTrue,
      );
    });

    test('fromDetached reports untrusted without trust anchors', () async {
      if (!fixturesAvailable) {
        return;
      }

      final store = await ManifestStore.fromDetached(
        manifestBytes: manifestBytes,
        assetBytes: assetBytes,
        assetFormat: 'image/jpeg',
      );

      expect(store, isNotNull);
      expect(
        store!.validationStatus.any(
          (final e) => e.code == 'signingCredential.untrusted',
        ),
        isTrue,
      );
    });

    test('fromDetached fails clearly on manifest store format mismatch', () async {
      if (!fixturesAvailable) {
        return;
      }

      expect(
        () => ManifestStore.fromDetached(
          manifestBytes: manifestBytes,
          assetBytes: assetBytes,
          assetFormat: 'image/jpeg',
          manifestFormat: 'image/jpeg',
        ),
        throwsA(
          isA<Object>().having(
            (final e) => e.toString(),
            'message',
            contains('unsupported manifest store format'),
          ),
        ),
      );
    });

    test('fromDetached fails clearly on invalid manifest store bytes', () async {
      if (!fixturesAvailable) {
        return;
      }

      expect(
        () => ManifestStore.fromDetached(
          manifestBytes: const [0, 1, 2, 3],
          assetBytes: assetBytes,
          assetFormat: 'image/jpeg',
        ),
        throwsA(
          isA<Object>().having(
            (final e) => e.toString(),
            'message',
            contains('detached manifest validation failed'),
          ),
        ),
      );
    });
  });
}
