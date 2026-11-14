import 'package:test/test.dart';

import '../../hook/build.dart';

void main() {
  test('omitted null and true retain native build; false opts out', () {
    expect(buildNativeEnabled(null), isTrue);
    expect(buildNativeEnabled(true), isTrue);
    expect(buildNativeEnabled(false), isFalse);
  });
  test('malformed build_native fails with the specific boolean error', () {
    for (final value in <Object>['false', 0, <Object>[], <String, Object>{}]) {
      expect(
        () => buildNativeEnabled(value),
        throwsA(
          isA<FormatException>().having(
            (final error) => error.message,
            'message',
            'build_native must be a boolean',
          ),
        ),
      );
    }
  });
}
