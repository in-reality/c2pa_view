import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:c2pa_view/c2pa_view.dart';
import 'test_helpers.dart';

void runManifestParsingTest() {
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