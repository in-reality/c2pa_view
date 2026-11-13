import 'dart:io';

import 'package:c2pa_view/core/trust/trust_list_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

const _caPemBody = '''
-----BEGIN CERTIFICATE-----
MIIBkTCCATigAwIBAgIUFakeCAforTest
-----END CERTIFICATE-----''';

const _tsaPemBody = '''
-----BEGIN CERTIFICATE-----
MIIBkTCCATigAwIBAgIUFakeTSAforTest
-----END CERTIFICATE-----''';

void main() {
  group('TrustListService', () {
    test('memory-only cache preserves each published trust purpose', () async {
      final calls = <String>[];
      final client = http_testing.MockClient((final request) async {
        calls.add(request.url.toString());
        if (request.url.toString() == TrustListService.c2paTrustListUrl) {
          return http.Response(_caPemBody, 200);
        }
        if (request.url.toString() == TrustListService.tsaTrustListUrl) {
          return http.Response(_tsaPemBody, 200);
        }
        return http.Response('not found', 404);
      });

      final service = TrustListService(httpClient: client);

      final ok = await service.initialize();

      expect(ok, isTrue);
      expect(service.isAvailable, isTrue);
      expect(
        service.trustAnchorsPem,
        contains('FakeCAforTest'),
        reason: 'CA bundle should be present',
      );
      expect(
        service.timestampTrustAnchorsPem,
        contains('FakeTSAforTest'),
        reason: 'TSA bundle should be present',
      );
      expect(service.trustAnchorsPem, isNot(contains('FakeTSAforTest')));
      expect(
        service.timestampTrustAnchorsPem,
        isNot(contains('FakeCAforTest')),
      );
      expect(calls.length, 2);
    });

    test('returns false and stays unavailable when both URLs fail', () async {
      final client = http_testing.MockClient(
        (final request) async => http.Response('boom', 500),
      );

      final service = TrustListService(httpClient: client);

      final ok = await service.initialize();

      expect(ok, isFalse);
      expect(service.isAvailable, isFalse);
      expect(service.trustAnchorsPem, isNull);
    });

    test(
      'reads from cache directory without hitting the network when fresh',
      () async {
        final dir = await Directory.systemTemp.createTemp('trust_list_test_');
        addTearDown(() async {
          if (dir.existsSync()) {
            await dir.delete(recursive: true);
          }
        });

        File(
          '${dir.path}/c2pa_manifest_trust_anchors.pem',
        ).writeAsStringSync(_caPemBody);
        File(
          '${dir.path}/c2pa_tsa_trust_anchors.pem',
        ).writeAsStringSync(_tsaPemBody);
        File(
          '${dir.path}/c2pa_trust_anchors_ts.txt',
        ).writeAsStringSync(DateTime.now().toUtc().toIso8601String());

        var calls = 0;
        final client = http_testing.MockClient((_) async {
          calls += 1;
          return http.Response('should not be called', 500);
        });

        final service = TrustListService(
          cacheDirectory: dir.path,
          httpClient: client,
        );

        final ok = await service.initialize();

        expect(ok, isTrue);
        expect(service.trustAnchorsPem, _caPemBody);
        expect(service.timestampTrustAnchorsPem, _tsaPemBody);
        // The cached PEM is fresh (timestamp = now), so the background
        // refresh path does not trigger a network call.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(calls, 0);
      },
    );
    test(
      'legacy combined and incomplete caches refetch separate origins',
      () async {
        for (final incomplete in [false, true]) {
          final dir = await Directory.systemTemp.createTemp('trust_legacy_');
          addTearDown(() => dir.delete(recursive: true));
          File(
            '${dir.path}/c2pa_trust_anchors.pem',
          ).writeAsStringSync('$_caPemBody\n$_tsaPemBody');
          if (incomplete) {
            File(
              '${dir.path}/c2pa_manifest_trust_anchors.pem',
            ).writeAsStringSync(_caPemBody);
          }
          File(
            '${dir.path}/c2pa_trust_anchors_ts.txt',
          ).writeAsStringSync(DateTime.now().toUtc().toIso8601String());
          final calls = <String>[];
          final service = TrustListService(
            cacheDirectory: dir.path,
            httpClient: http_testing.MockClient((final request) async {
              calls.add(request.url.toString());
              return http.Response(
                request.url.toString() == TrustListService.c2paTrustListUrl
                    ? _caPemBody
                    : _tsaPemBody,
                200,
              );
            }),
          );
          expect(await service.initialize(), isTrue);
          expect(calls, [
            TrustListService.c2paTrustListUrl,
            TrustListService.tsaTrustListUrl,
          ]);
          expect(service.trustAnchorsPem, _caPemBody);
          expect(service.timestampTrustAnchorsPem, _tsaPemBody);
          expect(
            File(
              '${dir.path}/c2pa_manifest_trust_anchors.pem',
            ).readAsStringSync(),
            _caPemBody,
          );
          expect(
            File('${dir.path}/c2pa_tsa_trust_anchors.pem').readAsStringSync(),
            _tsaPemBody,
          );
        }
      },
    );

    test('failed TSA refresh retains the last complete pair', () async {
      var failing = false;
      final service = TrustListService(
        httpClient: http_testing.MockClient((final request) async {
          if (request.url.toString() == TrustListService.c2paTrustListUrl) {
            return http.Response(failing ? 'replacement CA' : _caPemBody, 200);
          }
          return http.Response(
            failing ? 'unavailable' : _tsaPemBody,
            failing ? 503 : 200,
          );
        }),
      );
      expect(await service.initialize(), isTrue);
      failing = true;
      expect(await service.refresh(), isFalse);
      expect(service.isAvailable, isTrue);
      expect(service.trustAnchorsPem, _caPemBody);
      expect(service.timestampTrustAnchorsPem, _tsaPemBody);
    });
  });
}
