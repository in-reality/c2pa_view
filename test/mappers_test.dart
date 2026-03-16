import 'package:flutter_test/flutter_test.dart';
import 'package:c2pa_view/domain/entities/entities.dart';
import 'package:c2pa_view/domain/mappers/provenance_mapper.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';

void main() {
  group('ManifestViewDataMapper', () {
    test('maps basic manifest to view data', () {
      const manifest = Manifest(
        claimGenerator: 'TestApp/1.0',
        title: 'test.jpg',
        format: 'image/jpeg',
        signatureInfo: SignatureInfo(
          issuer: 'Test Issuer',
          time: null,
        ),
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.title, 'test.jpg');
      expect(viewData.issuer, 'Test Issuer');
    });

    test('maps claim generator info', () {
      const manifest = Manifest(
        claimGeneratorInfo: [
          ClaimGeneratorInfo(name: 'Photoshop', version: '25.0'),
        ],
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.claimGenerator, isNotNull);
      expect(viewData.claimGenerator!.name, 'Photoshop');
      expect(viewData.claimGenerator!.version, '25.0');
      expect(viewData.claimGenerator!.displayLabel, 'Photoshop 25.0');
    });

    test('maps claim generator from string', () {
      const manifest = Manifest(
        claimGenerator: 'Adobe_Photoshop/25.0',
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.claimGenerator, isNotNull);
      expect(viewData.claimGenerator!.name, 'Adobe Photoshop');
      expect(viewData.claimGenerator!.version, '25.0');
    });

    test('maps actions', () {
      const manifest = Manifest(
        actions: [
          Action(action: 'c2pa.created'),
          Action(action: 'c2pa.edited'),
        ],
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.actions.length, 2);
      expect(viewData.actions[0].actionType, 'c2pa.created');
      expect(viewData.actions[0].label, 'Created');
      expect(viewData.actions[1].label, 'Edited');
    });

    test('maps ingredients', () {
      const manifest = Manifest(
        ingredients: [
          Ingredient(
            title: 'bg.jpg',
            format: 'image/jpeg',
            activeManifest: 'urn:c2pa:bg',
            relationship: 'parentOf',
          ),
        ],
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.ingredients.length, 1);
      expect(viewData.ingredients.first.title, 'bg.jpg');
      expect(viewData.ingredients.first.hasManifest, true);
      expect(
        viewData.ingredients.first.relationship,
        IngredientRelationship.parentOf,
      );
    });

    test('maps exif data', () {
      const manifest = Manifest(
        exifData: ExifData(
          cameraMake: 'Canon',
          cameraModel: 'EOS R5',
          iso: '400',
          width: 8192,
          height: 5464,
        ),
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.exifData, isNotNull);
      expect(viewData.exifData!.cameraMake, 'Canon');
      expect(viewData.exifData!.dimensionsLabel, '8192 x 5464');
    });

    test('maps social accounts', () {
      const manifest = Manifest(
        creativeWork: CreativeWork(
          producer: 'Test Producer',
          website: 'https://example.com',
          socialAccounts: [
            SocialAccount(
              platform: 'Twitter',
              url: 'https://twitter.com/user',
            ),
          ],
        ),
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.producer, 'Test Producer');
      expect(viewData.website, 'https://example.com');
      expect(viewData.socialAccounts.length, 1);
      expect(viewData.socialAccounts.first.platform, 'Twitter');
    });

    test('maps training mining', () {
      const manifest = Manifest(
        trainingMining: TrainingMining(doNotTrain: true),
      );

      final viewData = ManifestViewDataMapper.map(manifest);
      expect(viewData.doNotTrain, true);
    });

    test('maps custom fields', () {
      const manifest = Manifest(
        customFields: [
          CustomField(key: 'vendor.data', value: 'test', source: 'assertion'),
        ],
      );

      final viewData = ManifestViewDataMapper.map(manifest);
      expect(viewData.customFields.length, 1);
    });

    test('mapValidation returns noCredential for empty statuses', () {
      final result = ManifestViewDataMapper.mapValidation([]);
      expect(result.status, ValidationStatus.noCredential);
    });

    test('mapValidation returns valid for all trusted/validated', () {
      final result = ManifestViewDataMapper.mapValidation([
        const ValidationStatusEntry(code: 'claimSignature.validated'),
        const ValidationStatusEntry(code: 'signingCredential.trusted'),
      ]);
      expect(result.status, ValidationStatus.valid);
    });

    test('mapValidation returns invalid for error codes', () {
      final result = ManifestViewDataMapper.mapValidation([
        const ValidationStatusEntry(
          code: 'assertion.hashedURI.mismatch',
          explanation: 'Hash mismatch',
        ),
      ]);
      expect(result.status, ValidationStatus.invalid);
      expect(result.message, contains('Hash mismatch'));
    });

    test('detects AI generated content from actions', () {
      const manifest = Manifest(
        actions: [
          Action(
            action: 'c2pa.created',
            sourceType:
                'http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia',
            parameters: {'softwareAgent': 'DALL-E'},
          ),
        ],
      );

      final viewData = ManifestViewDataMapper.map(manifest);

      expect(viewData.generativeInfo, isNotNull);
      expect(viewData.generativeInfo!.type, GenerativeType.aiGenerated);
      expect(viewData.aiToolsUsed.contains('DALL-E'), true);
    });
  });

  group('ProvenanceMapper', () {
    test('mapToGraph builds root node from active manifest', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'main.jpg',
            'claim_generator': 'TestApp/1.0',
            'assertions': [],
            'ingredients': [],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      expect(graph.rootId, 'urn:c2pa:main');
      expect(graph.rootNode?.title, 'main.jpg');
      expect(graph.edges, isEmpty);
    });

    test('mapToGraph builds children from ingredients with manifests', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'composite.jpg',
            'assertions': [],
            'ingredients': [
              {
                'title': 'background.jpg',
                'active_manifest': 'urn:c2pa:bg',
              },
              {
                'title': 'overlay.png',
                'active_manifest': 'urn:c2pa:overlay',
              },
            ],
          },
          'urn:c2pa:bg': {
            'title': 'background.jpg',
            'assertions': [],
            'ingredients': [],
          },
          'urn:c2pa:overlay': {
            'title': 'overlay.png',
            'assertions': [],
            'ingredients': [],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      final childIds = graph.childIdsOf('urn:c2pa:main');
      expect(childIds.length, 2);
      expect(childIds, contains('urn:c2pa:bg'));
      expect(childIds, contains('urn:c2pa:overlay'));
      expect(graph.findNode('urn:c2pa:bg')?.title, 'background.jpg');
      expect(graph.findNode('urn:c2pa:overlay')?.title, 'overlay.png');
    });

    test('mapToGraph handles leaf ingredients without manifests', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'test.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'external.jpg', 'label': 'ext-label'},
            ],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      final childIds = graph.childIdsOf('urn:c2pa:main');
      expect(childIds.length, 1);
      final leaf = graph.findNode(childIds.first);
      expect(leaf?.title, 'external.jpg');
      expect(leaf?.validationResult.status, ValidationStatus.noCredential);
    });

    test('mapToGraph deduplicates shared manifests', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:a',
        'manifests': {
          'urn:c2pa:a': {
            'title': 'a.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'b.jpg', 'active_manifest': 'urn:c2pa:b'},
              {'title': 'c.jpg', 'active_manifest': 'urn:c2pa:c'},
            ],
          },
          'urn:c2pa:b': {
            'title': 'b.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'shared.jpg', 'active_manifest': 'urn:c2pa:shared'},
            ],
          },
          'urn:c2pa:c': {
            'title': 'c.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'shared.jpg', 'active_manifest': 'urn:c2pa:shared'},
            ],
          },
          'urn:c2pa:shared': {
            'title': 'shared.jpg',
            'assertions': [],
            'ingredients': [],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      // shared.jpg appears only once as a node
      expect(graph.nodes.length, 4);
      // but has two parent edges
      final parents = graph.parentIdsOf('urn:c2pa:shared');
      expect(parents.length, 2);
      expect(parents, containsAll(['urn:c2pa:b', 'urn:c2pa:c']));
    });

    test('mapToGraph prevents infinite loops from circular references', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:a',
        'manifests': {
          'urn:c2pa:a': {
            'title': 'a.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'b.jpg', 'active_manifest': 'urn:c2pa:b'},
            ],
          },
          'urn:c2pa:b': {
            'title': 'b.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'a.jpg', 'active_manifest': 'urn:c2pa:a'},
            ],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      expect(graph.rootId, 'urn:c2pa:a');
      // Both nodes exist.
      expect(graph.nodes.length, 2);
      // b -> a edge is added (but a is already visited, so no re-recursion).
      final bChildren = graph.childIdsOf('urn:c2pa:b');
      expect(bChildren, contains('urn:c2pa:a'));
    });

    test('mapToGraph throws for missing active manifest', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'nonexistent',
        'manifests': <String, dynamic>{},
      });

      expect(
        () => ProvenanceMapper.mapToGraph(store),
        throwsStateError,
      );
    });

    test('mapToGraph attaches manifestViewData to nodes', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'main.jpg',
            'claim_generator': 'TestApp/1.0',
            'assertions': [],
            'ingredients': [],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);
      final root = graph.rootNode;

      expect(root?.manifestViewData, isNotNull);
      expect(root?.manifestViewData!.title, 'main.jpg');
    });

    test('nodes map contains all nodes', () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'main.jpg',
            'assertions': [],
            'ingredients': [
              {'title': 'child.jpg', 'active_manifest': 'urn:c2pa:child'},
            ],
          },
          'urn:c2pa:child': {
            'title': 'child.jpg',
            'assertions': [],
            'ingredients': [],
          },
        },
      });

      final graph = ProvenanceMapper.mapToGraph(store);

      expect(graph.nodes.length, 2);
      expect(graph.nodes.keys, containsAll(['urn:c2pa:main', 'urn:c2pa:child']));
    });
  });
}
