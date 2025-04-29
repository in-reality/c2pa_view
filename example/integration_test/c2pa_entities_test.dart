import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c2pa_view/c2pa_view.dart';

const testDataUrl = 'https://c2pa.org/public-testfiles/image/';
const url = 'https://c2pa.org/public-testfiles/image/jpeg/adobe-20220124-CACA.jpg';
const manifestUrl = 'https://c2pa.org/public-testfiles/image/jpeg/manifests/adobe-20220124-CACA/manifest_store.json';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  test('ManifestParsing', () async {
    // Get true manifest
    final manifestResponse = await http.get(Uri.parse(manifestUrl));

    // Check that the response is successful
    expect(
      manifestResponse.statusCode,
      200,
      reason: "Failed to get c2pa test manifest: ${manifestResponse.statusCode}"
        "\nLooked for: $manifestUrl"
        "\nCheck here for info: $testDataUrl",
    );
    // String trueManifestString = manifestResponse.body;
    Map<String, dynamic> trueManifest = json.decode(manifestResponse.body);

    // Parse as manifest store
    ManifestStore trueManifestStore = ManifestStore.fromJson(trueManifest);

    // Check active manifest
    expect(trueManifestStore.activeManifest, trueManifest['active_manifest']);

    // Get set of manifests for both
    final Set<String> activeManifests = trueManifestStore.manifests.keys.toSet();
    final Set<String> trueActiveManifests = trueManifest['manifests'].keys.toSet();

    // Check that the active manifests are the same
    expect(
      activeManifests,
      trueActiveManifests,
      reason: "Active manifests do not match expected active manifests",
    );
  });
}
