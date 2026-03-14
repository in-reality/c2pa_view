import 'package:flutter_test/flutter_test.dart';
import 'package:c2pa_view/domain/entities/entities.dart';

void main() {
  group('SignatureInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'issuer': 'Test Issuer',
        'cert_serial_number': '12345',
        'time': '2024-01-15T10:30:00Z',
        'alg': 'SHA-256',
      };

      final info = SignatureInfo.fromJson(json);

      expect(info.issuer, 'Test Issuer');
      expect(info.certSerialNumber, '12345');
      expect(info.time, DateTime.utc(2024, 1, 15, 10, 30));
      expect(info.algorithm, 'SHA-256');
    });

    test('fromJson handles null fields', () {
      final info = SignatureInfo.fromJson({});

      expect(info.issuer, isNull);
      expect(info.certSerialNumber, isNull);
      expect(info.time, isNull);
      expect(info.algorithm, isNull);
      expect(info.certificateChain, isNull);
    });

    test('fromJson parses certificate chain', () {
      final json = {
        'issuer': 'Test',
        'cert_chain': [
          {
            'subject': 'CN=Test',
            'issuer': 'CN=Root',
            'serial_number': 'ABC',
          },
        ],
      };

      final info = SignatureInfo.fromJson(json);

      expect(info.certificateChain, isNotNull);
      expect(info.certificateChain!.length, 1);
      expect(info.certificateChain!.first.subject, 'CN=Test');
    });
  });

  group('ValidationStatusEntry', () {
    test('fromJson parses fields', () {
      final json = {
        'code': 'claimSignature.validated',
        'url': 'https://example.com',
        'explanation': 'Signature is valid',
      };

      final entry = ValidationStatusEntry.fromJson(json);

      expect(entry.code, 'claimSignature.validated');
      expect(entry.url, 'https://example.com');
      expect(entry.explanation, 'Signature is valid');
    });

    test('isError returns false for validated codes', () {
      final entry = ValidationStatusEntry(code: 'claimSignature.validated');
      expect(entry.isError, false);
    });

    test('isError returns false for trusted codes', () {
      final entry = ValidationStatusEntry(code: 'signingCredential.trusted');
      expect(entry.isError, false);
    });

    test('isError returns true for error codes', () {
      final entry =
          ValidationStatusEntry(code: 'assertion.hashedURI.mismatch');
      expect(entry.isError, true);
    });
  });

  group('ClaimGeneratorInfo', () {
    test('fromJson parses fields', () {
      final json = {
        'name': 'Adobe Photoshop',
        'version': '25.0',
        'icon': {'format': 'image/png', 'data': 'base64data'},
      };

      final info = ClaimGeneratorInfo.fromJson(json);

      expect(info.name, 'Adobe Photoshop');
      expect(info.version, '25.0');
      expect(info.icon, isNotNull);
    });

    test('fromJson defaults name to Unknown', () {
      final info = ClaimGeneratorInfo.fromJson({});
      expect(info.name, 'Unknown');
    });
  });

  group('ThumbnailData', () {
    test('fromJson parses fields', () {
      final json = {
        'format': 'image/jpeg',
        'identifier': 'c2pa.thumbnail.claim.jpeg',
      };

      final thumb = ThumbnailData.fromJson(json);

      expect(thumb.format, 'image/jpeg');
      expect(thumb.identifier, 'c2pa.thumbnail.claim.jpeg');
      expect(thumb.data, isNull);
    });
  });

  group('ExifData', () {
    test('fromAssertionData parses known fields', () {
      final data = {
        'tiff:Make': 'Canon',
        'tiff:Model': 'EOS R5',
        'exif:FNumber': '2.8',
        'exif:ISOSpeedRatings': 400,
        'exif:PixelXDimension': 8192,
        'exif:PixelYDimension': 5464,
      };

      final exif = ExifData.fromAssertionData(data);

      expect(exif.cameraMake, 'Canon');
      expect(exif.cameraModel, 'EOS R5');
      expect(exif.fNumber, '2.8');
      expect(exif.iso, '400');
      expect(exif.width, 8192);
      expect(exif.height, 5464);
    });

    test('fromAssertionData captures unknown fields as custom', () {
      final data = {
        'tiff:Make': 'Canon',
        'custom:VendorField': 'vendor_value',
      };

      final exif = ExifData.fromAssertionData(data);

      expect(exif.customFields.length, 1);
      expect(exif.customFields.first.key, 'custom:VendorField');
      expect(exif.customFields.first.value, 'vendor_value');
      expect(exif.customFields.first.source, 'exif_extension');
    });
  });

  group('CreativeWork', () {
    test('fromAssertionData parses basic fields', () {
      final data = {
        '@context': 'https://schema.org',
        '@type': 'CreativeWork',
        'author': {'name': 'John Doe'},
        'copyrightNotice': '2024 John Doe',
        'producer': 'Adobe Photoshop',
        'url': 'https://example.com',
      };

      final cw = CreativeWork.fromAssertionData(data);

      expect(cw.author, 'John Doe');
      expect(cw.copyrightNotice, '2024 John Doe');
      expect(cw.producer, 'Adobe Photoshop');
      expect(cw.website, 'https://example.com');
    });

    test('fromAssertionData parses social accounts', () {
      final data = {
        'sameAs': [
          {'@type': 'Twitter', 'url': 'https://twitter.com/user'},
          'https://instagram.com/user',
        ],
      };

      final cw = CreativeWork.fromAssertionData(data);

      expect(cw.socialAccounts.length, 2);
      expect(cw.socialAccounts[0].platform, 'Twitter');
      expect(cw.socialAccounts[1].platform, 'Instagram');
    });

    test('fromAssertionData captures custom fields', () {
      final data = {
        '@context': 'https://schema.org',
        'customVendor': 'custom_value',
      };

      final cw = CreativeWork.fromAssertionData(data);

      expect(cw.customFields.length, 1);
      expect(cw.customFields.first.key, 'customVendor');
    });
  });

  group('TrainingMining', () {
    test('fromAssertionData detects do-not-train', () {
      final data = {
        'entries': [
          {
            'use': 'notAllowed',
          },
        ],
      };

      final tm = TrainingMining.fromAssertionData(data);

      expect(tm.doNotTrain, true);
      expect(tm.doNotMine, true);
    });

    test('fromAssertionData with no entries', () {
      final tm = TrainingMining.fromAssertionData({});

      expect(tm.doNotTrain, false);
      expect(tm.doNotMine, false);
    });
  });

  group('CustomField', () {
    test('isSimple returns true for primitives', () {
      expect(
        const CustomField(key: 'k', value: 'string', source: 's').isSimple,
        true,
      );
      expect(
        const CustomField(key: 'k', value: 42, source: 's').isSimple,
        true,
      );
      expect(
        const CustomField(key: 'k', value: true, source: 's').isSimple,
        true,
      );
    });

    test('isMap returns true for maps', () {
      expect(
        const CustomField(key: 'k', value: {'a': 1}, source: 's').isMap,
        true,
      );
    });

    test('isList returns true for lists', () {
      expect(
        const CustomField(key: 'k', value: [1, 2, 3], source: 's').isList,
        true,
      );
    });

    test('toFlatEntries flattens simple values', () {
      final field = CustomField(key: 'myKey', value: 'hello', source: 's');
      final entries = field.toFlatEntries();

      expect(entries.length, 1);
      expect(entries.first.key, 'myKey');
      expect(entries.first.value, 'hello');
    });

    test('toFlatEntries flattens nested maps', () {
      final field = CustomField(
        key: 'parent',
        value: {'child': 'value', 'nested': {'deep': 42}},
        source: 's',
      );
      final entries = field.toFlatEntries();

      expect(entries.length, 2);
      expect(entries.any((e) => e.key == 'parent.child'), true);
      expect(entries.any((e) => e.key == 'parent.nested.deep'), true);
    });
  });

  group('Manifest', () {
    test('fromJson parses basic fields', () {
      final json = {
        'claim_generator': 'TestApp/1.0',
        'title': 'test.jpg',
        'format': 'image/jpeg',
        'label': 'urn:c2pa:test',
        'assertions': [],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.claimGenerator, 'TestApp/1.0');
      expect(manifest.title, 'test.jpg');
      expect(manifest.format, 'image/jpeg');
      expect(manifest.label, 'urn:c2pa:test');
    });

    test('fromJson routes c2pa.actions assertion', () {
      final json = {
        'assertions': [
          {
            'label': 'c2pa.actions',
            'data': {
              'actions': [
                {'action': 'c2pa.created'},
                {'action': 'c2pa.edited'},
              ]
            },
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.actions, isNotNull);
      expect(manifest.actions!.length, 2);
      expect(manifest.actions![0].action, 'c2pa.created');
      expect(
        manifest.assertions.where((a) => a.label == 'c2pa.actions'),
        isEmpty,
      );
    });

    test('fromJson routes stds.exif assertion to ExifData', () {
      final json = {
        'assertions': [
          {
            'label': 'stds.exif',
            'data': {
              'tiff:Make': 'Nikon',
              'tiff:Model': 'D850',
            },
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.exifData, isNotNull);
      expect(manifest.exifData!.cameraMake, 'Nikon');
      expect(
        manifest.assertions.where((a) => a.label == 'stds.exif'),
        isEmpty,
      );
    });

    test('fromJson routes creative work assertion', () {
      final json = {
        'assertions': [
          {
            'label': 'stds.schema-org.CreativeWork',
            'data': {
              'author': 'Jane',
            },
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.creativeWork, isNotNull);
      expect(manifest.creativeWork!.author, 'Jane');
    });

    test('fromJson routes training-mining assertion', () {
      final json = {
        'assertions': [
          {
            'label': 'c2pa.training-mining',
            'data': {
              'entries': [
                {'use': 'notAllowed'},
              ],
            },
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.trainingMining, isNotNull);
      expect(manifest.trainingMining!.doNotTrain, true);
    });

    test('fromJson keeps unknown assertions as custom fields', () {
      final json = {
        'assertions': [
          {
            'label': 'com.vendor.custom',
            'data': {'key': 'value'},
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.assertions.length, 1);
      expect(manifest.assertions.first.label, 'com.vendor.custom');
      expect(manifest.customFields.length, 1);
      expect(manifest.customFields.first.key, 'com.vendor.custom');
      expect(manifest.customFields.first.source, 'assertion');
    });

    test('fromJson parses signature info as structured type', () {
      final json = {
        'signature_info': {
          'issuer': 'Adobe Inc.',
          'cert_serial_number': '123',
          'time': '2024-06-01T12:00:00Z',
          'alg': 'SHA-256',
        },
        'assertions': [],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.signatureInfo, isNotNull);
      expect(manifest.signatureInfo!.issuer, 'Adobe Inc.');
      expect(manifest.signatureInfo!.algorithm, 'SHA-256');
    });

    test('fromJson parses claim_generator_info', () {
      final json = {
        'claim_generator_info': [
          {'name': 'Photoshop', 'version': '25.0'},
        ],
        'assertions': [],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.claimGeneratorInfo.length, 1);
      expect(manifest.claimGeneratorInfo.first.name, 'Photoshop');
    });

    test('fromJson parses validation_status', () {
      final json = {
        'validation_status': [
          {
            'code': 'claimSignature.validated',
            'explanation': 'Valid signature',
          },
        ],
        'assertions': [],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      expect(manifest.validationStatus.length, 1);
      expect(manifest.validationStatus.first.code,
          'claimSignature.validated');
    });

    test('fromJson extracts custom action parameters', () {
      final json = {
        'assertions': [
          {
            'label': 'c2pa.actions',
            'data': {
              'actions': [
                {
                  'action': 'c2pa.created',
                  'parameters': {
                    'softwareAgent': 'TestApp',
                    'vendorCustomParam': 'custom_value',
                  },
                },
              ]
            },
          },
        ],
        'ingredients': [],
      };

      final manifest = Manifest.fromJson(json);

      final customActionFields = manifest.customFields
          .where((f) => f.source == 'action_parameter')
          .toList();
      expect(customActionFields.length, 1);
      expect(customActionFields.first.key, 'vendorCustomParam');
      expect(customActionFields.first.parentLabel, 'c2pa.created');
    });
  });

  group('Ingredient', () {
    test('fromJson parses all fields', () {
      final json = {
        'title': 'background.jpg',
        'format': 'image/jpeg',
        'document_id': 'doc-123',
        'instance_id': 'inst-456',
        'active_manifest': 'urn:c2pa:background',
        'relationship': 'parentOf',
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.title, 'background.jpg');
      expect(ingredient.format, 'image/jpeg');
      expect(ingredient.relationship, 'parentOf');
      expect(ingredient.activeManifest, 'urn:c2pa:background');
    });

    test('fromJson parses thumbnail', () {
      final json = {
        'title': 'test.jpg',
        'thumbnail': {
          'format': 'image/jpeg',
          'identifier': 'thumb-1',
        },
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.thumbnail, isNotNull);
      expect(ingredient.thumbnail!.format, 'image/jpeg');
    });
  });

  group('ManifestStore', () {
    test('fromJson parses manifests and active manifest', () {
      final json = {
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'main.jpg',
            'assertions': [],
            'ingredients': [],
          },
        },
      };

      final store = ManifestStore.fromJson(json);

      expect(store.activeManifest, 'urn:c2pa:main');
      expect(store.manifests.length, 1);
      expect(store.manifests['urn:c2pa:main']!.title, 'main.jpg');
    });

    test('fromJson propagates validation status to active manifest', () {
      final json = {
        'active_manifest': 'urn:c2pa:main',
        'manifests': {
          'urn:c2pa:main': {
            'title': 'main.jpg',
            'assertions': [],
            'ingredients': [],
          },
        },
        'validation_status': [
          {'code': 'claimSignature.validated'},
        ],
      };

      final store = ManifestStore.fromJson(json);

      expect(store.validationStatus.length, 1);
      expect(
        store.manifests['urn:c2pa:main']!.validationStatus.length,
        1,
      );
    });
  });
}
