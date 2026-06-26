import 'package:c2pa_view/domain/entities/manifest_assertion.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ManifestAssertion.fromJson accepts string assertion data', () {
    const inline = 'AAAAAAAAAAAAAAAA';
    final assertion = ManifestAssertion.fromJson({
      'label': 'cawg.identity',
      'data': inline,
    });
    expect(assertion.data, {'_c2pa_inline': inline});
  });

  test('ManifestStore.fromJson accepts cawg.identity string assertion bodies', () {
    final store = ManifestStore.fromJson({
      'active_manifest': 'urn:c2pa:test',
      'manifests': {
        'urn:c2pa:test': {
          'label': 'urn:c2pa:test',
          'assertions': [
            {
              'label': 'cawg.identity',
              'data': 'AAAA${'A' * 100}',
            },
          ],
        },
      },
    });
    expect(store.manifests, isNotEmpty);
  });
}
