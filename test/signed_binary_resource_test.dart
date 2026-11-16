// @dart=3.11
import 'dart:convert';
import 'dart:typed_data';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/signed_recovery_fixture.dart';

Uint8List _hex(final String value) => Uint8List.fromList([
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixtures = (jsonDecode(signedRecoveryFixtures) as List)
      .cast<Map<String, dynamic>>();

  for (final fixture in fixtures) {
    test(
      'native/WASM binary read: ${fixture['case'] ?? fixture['mime']}',
      () async {
        final asset = base64Decode(fixture['asset_b64'] as String);
        final descriptor = fixture['descriptor'] as Map<String, dynamic>;
        final patch =
            (descriptor['patches'] as List).first as Map<String, dynamic>;
        final resource = patch['resource'] as Map<String, dynamic>;
        final reference = resource['resource'] as Map<String, dynamic>;
        final claim = descriptor['manifest_label'] as String;
        final identifier = reference['identifier'] as String;
        final payloadHash = Uint8List.fromList(
          (resource['payload_sha256'] as List).cast<int>(),
        );
        final inputHash = _hex(fixture['input_sha256'] as String);
        Future<C2paResourceRead> read({
          final Uint8List? bytes,
          final Uint8List? input,
          final Uint8List? payload,
          final String? label,
          final String? id,
          final int maxBytes = 32 * 1024 * 1024,
        }) => readEmbeddedC2paResource(
          fileBytes: bytes ?? asset,
          format: fixture['mime'] as String,
          expectedInputSha256: input ?? inputHash,
          manifestLabel: label ?? claim,
          identifier: id ?? identifier,
          expectedPayloadSha256: payload ?? payloadHash,
          maxBytes: maxBytes,
          allowedListPem: fixture['allowed_leaf'] as String,
        );

        final result = await read();
        expect(result.resolution, 'resolved');
        expect(result.bytes, base64Decode(fixture['payload_b64'] as String));
        expect(result.inputSha256, inputHash);
        final current =
            (jsonDecode(utf8.decode(result.currentValidationJson)) as List)
                .cast<Map<String, dynamic>>();
        expect(current.any((final s) => s['kind'] == 'failure'), isFalse);
        expect(
          current.any((final s) => s['code'] == 'signingCredential.trusted'),
          isTrue,
        );
        final metadata =
            jsonDecode(
                  (await C2paBridgeService.getManifestJsonFromBytes(
                    fileBytes: asset,
                    format: fixture['mime'] as String,
                    allowedListPem: fixture['allowed_leaf'] as String,
                  ))!,
                )
                as Map<String, dynamic>;
        final containing = (metadata['manifests'] as Map)[claim] as Map;
        final actual =
            (containing['assertions'] as List).cast<Map>().singleWhere(
                  (final a) => a['label'] == 'io.inreality.overlay_recovery',
                )['data']
                as Map;
        expect(actual['manifest_label'], claim);
        // SDK public JSON uses base64 for digest bytes; the typed Rust fixture
        // serializes the same digest bytes as JSON arrays.
        final expectedPatches =
            jsonDecode(jsonEncode(descriptor['patches'])) as List;
        for (final patch in expectedPatches.cast<Map>()) {
          final encoded = patch['resource'] as Map;
          final uri = encoded['hashed_uri'] as Map;
          uri['hash'] = base64Encode(
            Uint8List.fromList((uri['hash'] as List).cast<int>()),
          );
          encoded['payload_sha256'] = base64Encode(payloadHash);
        }
        expect(actual['patches'], expectedPatches);
        final relative =
            'self#jumbf=c2pa.databoxes/${identifier.split('/').last}';
        expect((await read(id: relative)).bytes, result.bytes);
        if (fixture.containsKey('active_manifest')) {
          final active = fixture['active_manifest'] as String;
          expect(
            (await read(id: relative, label: active)).resolution,
            'payload_mismatch',
          );
          expect((await read(label: active)).resolution, 'invalid_reference');
          final activeRead = await read(
            id: relative,
            label: active,
            payload: Uint8List.fromList(
              (fixture['active_payload_sha256'] as List).cast<int>(),
            ),
          );
          expect(activeRead.resolution, 'resolved');
          expect(activeRead.bytes, isNot(orderedEquals(result.bytes)));
          return;
        }

        expect((await read(input: Uint8List(32))).resolution, 'input_mismatch');
        expect(
          (await read(payload: Uint8List(32))).resolution,
          'payload_mismatch',
        );
        expect(
          (await read(label: 'urn:uuid:other')).resolution,
          'invalid_reference',
        );
        expect(
          (await read(id: 'https://example.com/resource')).resolution,
          'invalid_reference',
        );
        expect(
          (await read(id: 'self#jumbf=c2pa.databoxes/missing')).resolution,
          'missing',
        );
        expect((await read(maxBytes: 1)).resolution, 'limit');
        await expectLater(
          read(maxBytes: 32 * 1024 * 1024 + 1),
          throwsA(anything),
        );

        // Databox payload substitution must fail even when the caller knowingly
        // updates the whole-file fingerprint. It cannot borrow an old validation.
        final payload = result.bytes;
        var offset = -1;
        for (var i = 0; i <= asset.length - payload.length; i++) {
          var equal = true;
          for (var j = 0; j < payload.length && equal; j++) {
            equal = asset[i + j] == payload[j];
          }
          if (equal) {
            offset = i;
          }
        }
        expect(offset, greaterThanOrEqualTo(0));
        final changed = Uint8List.fromList(asset);
        changed[offset + payload.length - 1] ^= 1;
        final changedIdentity = await read(bytes: changed);
        expect(changedIdentity.resolution, 'input_mismatch');
        final substituted = await read(
          bytes: changed,
          input: changedIdentity.inputSha256,
        );
        expect(substituted.resolution, isNot('resolved'));
        expect(substituted.bytes, isEmpty);

        // A changed signed descriptor must use fresh checks even if binary
        // resolution still succeeds and the same signing leaf remains trusted.
        final descriptorChanged = Uint8List.fromList(asset);
        final clean = ascii.encode('clean');
        var descriptorOffset = -1;
        for (var i = 0; i <= asset.length - clean.length; i++) {
          var equal = true;
          for (var j = 0; j < clean.length && equal; j++) {
            equal = asset[i + j] == clean[j];
          }
          if (equal) {
            descriptorOffset = i;
            break;
          }
        }
        expect(descriptorOffset, greaterThanOrEqualTo(0));
        descriptorChanged[descriptorOffset + clean.length - 1] ^= 1;
        final newIdentity = await read(bytes: descriptorChanged);
        final changedDescriptor = await read(
          bytes: descriptorChanged,
          input: newIdentity.inputSha256,
        );
        if (changedDescriptor.resolution == 'resolved') {
          final checks =
              (jsonDecode(utf8.decode(changedDescriptor.currentValidationJson))
                      as List)
                  .cast<Map>();
          expect(checks.any((final s) => s['kind'] == 'failure'), isTrue);
        } else {
          expect(changedDescriptor.bytes, isEmpty);
        }

        final truncated = Uint8List.sublistView(asset, 0, asset.length ~/ 2);
        final truncatedIdentity = await read(bytes: truncated);
        final truncatedRead = await read(
          bytes: truncated,
          input: truncatedIdentity.inputSha256,
        );
        expect(truncatedRead.resolution, isNot('resolved'));
        expect(truncatedRead.bytes, isEmpty);
      },
    );
  }
}
