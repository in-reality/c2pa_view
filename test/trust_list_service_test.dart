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
    test('memory-only cache fetches both lists and concatenates the PEMs',
        () async {
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
        service.trustAnchorsPem,
        contains('FakeTSAforTest'),
        reason: 'TSA bundle should be present',
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

        const cachedPem = '$_caPemBody\n$_tsaPemBody';
        File('${dir.path}/c2pa_trust_anchors.pem').writeAsStringSync(cachedPem);
        File('${dir.path}/c2pa_trust_anchors_ts.txt').writeAsStringSync(
          DateTime.now().toUtc().toIso8601String(),
        );

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
        expect(service.trustAnchorsPem, cachedPem);
        // The cached PEM is fresh (timestamp = now), so the background
        // refresh path does not trigger a network call.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(calls, 0);
      },
    );
  });
}
