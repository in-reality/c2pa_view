import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

const testDataUrl = 'https://c2pa.org/public-testfiles/image/';
const url =
    'https://c2pa.org/public-testfiles/image/jpeg/adobe-20220124-CACA.jpg';
const manifestUrl =
    'https://c2pa.org/public-testfiles/image/jpeg/manifests/adobe-20220124-CACA/manifest_store.json';

Future<void> setupTestEnvironment() async {
  await RustLib.init();
}
