import 'package:test/test.dart';

import '../../hook/native_capabilities.dart';

void main() {
  test('omitted capabilities retain standalone HTTP and OpenSSL', () {
    expect(c2paCargoFeatures(null), ['c2pa-http', 'c2pa-openssl']);
    expect(c2paCargoFeatures(true, openssl: true), [
      'c2pa-http',
      'c2pa-openssl',
    ]);
  });
  test('HTTP and OpenSSL requests are independent', () {
    expect(c2paCargoFeatures(false), ['c2pa-openssl']);
    expect(c2paCargoFeatures(null, openssl: false), ['c2pa-http']);
    expect(c2paCargoFeatures(false, openssl: false), isEmpty);
  });
  test('invalid HTTP settings fail before Cargo', () {
    for (final value in ['false', 0, [], {}]) {
      expect(() => c2paCargoFeatures(value), throwsFormatException);
    }
  });
  test('invalid OpenSSL settings fail before Cargo', () {
    for (final value in ['false', 0, [], {}]) {
      expect(
        () => c2paCargoFeatures(null, openssl: value),
        throwsFormatException,
      );
    }
  });
}
