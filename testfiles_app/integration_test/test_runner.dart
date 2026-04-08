import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'manifest_parsing_test.dart';
import 'manifest_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('C2PA Tests', () {
    setUpAll(setupTestEnvironment);

    runManifestParsingTest();
    runManifestTest();
  });
}
