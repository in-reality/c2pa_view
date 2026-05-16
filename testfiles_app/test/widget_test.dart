// Placeholder smoke test for the testfiles_app harness. The full
// behaviour is exercised by the integration tests under
// `integration_test/` and by the c2pa_view package tests, which load
// the Rust library and walk the validator evidence corpus.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('testfiles_app test harness boots', () {
    // Smoke test: the test runner can compile and execute this file.
    // Real behavioural coverage lives in `integration_test/` and in
    // the c2pa_view package tests.
    expect(2 + 2, 4);
  });
}
