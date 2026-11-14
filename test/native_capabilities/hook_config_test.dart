import 'package:test/test.dart';

import '../../hook/native_capabilities.dart';

void main() {
  test('omitted HTTP retains standalone transport', () {
    expect(c2paCargoFeatures(null), ['c2pa-http']);
    expect(c2paCargoFeatures(true), ['c2pa-http']);
  });
  test('explicit offline host omits HTTP', () {
    expect(c2paCargoFeatures(false), isEmpty);
  });
  test('invalid HTTP settings fail before Cargo', () {
    for (final value in ['false', 0, [], {}]) {
      expect(() => c2paCargoFeatures(value), throwsFormatException);
    }
  });
}
