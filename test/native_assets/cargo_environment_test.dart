import 'dart:io';

import 'package:test/test.dart';

import '../../hook/build.dart';

void main() {
  test(
    'absent settings preserve the existing map and never resolve a path',
    () {
      final additions = configuredCargoEnvironment(
        cargoHome: null,
        cargoOffline: null,
        resolveCargoHome: () => throw StateError('must not resolve'),
      );
      expect(additions, isEmpty);
      const existing = {'CARGO_BUILD_JOBS': '1', 'CARGO_INCREMENTAL': '0'};
      expect({...existing, ...additions}, existing);
    },
  );

  test('file path is forwarded without changing target/profile/jobs', () {
    final uri = Directory.systemTemp.uri.resolve('cargo%20cache/');
    expect(
      configuredCargoEnvironment(
        cargoHome: 'cargo cache',
        cargoOffline: true,
        resolveCargoHome: () => uri,
      ),
      {'CARGO_HOME': Directory.fromUri(uri).path, 'CARGO_NET_OFFLINE': 'true'},
    );
  });

  test('explicit false is forwarded while unspecified home stays absent', () {
    expect(
      configuredCargoEnvironment(
        cargoHome: null,
        cargoOffline: false,
        resolveCargoHome: () => throw StateError('must not resolve'),
      ),
      {'CARGO_NET_OFFLINE': 'false'},
    );
  });

  test(
    'raw malformed/empty home cannot silently become default configuration',
    () {
      for (final value in <Object>[
        true,
        42,
        <Object>[],
        <String, Object>{},
        '',
        '  ',
      ]) {
        var resolved = false;
        expect(
          () => configuredCargoEnvironment(
            cargoHome: value,
            cargoOffline: null,
            resolveCargoHome: () {
              resolved = true;
              return Directory.systemTemp.uri;
            },
          ),
          throwsFormatException,
        );
        expect(resolved, isFalse);
      }
    },
  );

  test('offline accepts only null or bool before path resolution', () {
    for (final value in <Object>['true', 1, <Object>[]]) {
      var resolved = false;
      expect(
        () => configuredCargoEnvironment(
          cargoHome: 'cache',
          cargoOffline: value,
          resolveCargoHome: () {
            resolved = true;
            return Directory.systemTemp.uri;
          },
        ),
        throwsFormatException,
      );
      expect(resolved, isFalse);
    }
  });

  test('missing/nonfile/relative/query/fragment URI is refused', () {
    for (final uri in <Uri?>[
      null,
      Uri.parse('https://example.invalid/cache'),
      Uri(path: 'relative/cache'),
      Uri.parse('file:///cache?query'),
      Uri.parse('file:///cache#fragment'),
    ]) {
      expect(
        () => configuredCargoEnvironment(
          cargoHome: 'cache',
          cargoOffline: true,
          resolveCargoHome: () => uri,
        ),
        throwsFormatException,
      );
    }
  });

  test('path conversion exceptions fail before invoking a builder', () {
    expect(
      () => configuredCargoEnvironment(
        cargoHome: 'cache',
        cargoOffline: true,
        resolveCargoHome: () => throw ArgumentError('malformed URI'),
      ),
      throwsFormatException,
    );
    expect(
      () => configuredCargoEnvironment(
        cargoHome: 'cache',
        cargoOffline: true,
        resolveCargoHome: () => Uri.parse('file:///cache%2Finside'),
      ),
      throwsFormatException,
    );
  });
}
