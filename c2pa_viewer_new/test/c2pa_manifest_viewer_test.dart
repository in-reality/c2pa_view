import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c2pa_manifest_viewer/c2pa_manifest_viewer.dart';

void main() {
  group('ValidationResult', () {
    test('valid status reports correctly', () {
      const result = ValidationResult.valid();
      expect(result.isValid, isTrue);
      expect(result.isInvalid, isFalse);
      expect(result.hasCredential, isTrue);
    });

    test('invalid status reports correctly', () {
      const result = ValidationResult.invalid('tampered');
      expect(result.isValid, isFalse);
      expect(result.isInvalid, isTrue);
      expect(result.hasCredential, isTrue);
      expect(result.message, 'tampered');
    });

    test('noCredential status reports correctly', () {
      const result = ValidationResult.noCredential();
      expect(result.hasCredential, isFalse);
    });
  });

  group('ProvenanceNode', () {
    test('flatten returns all nodes depth-first', () {
      const tree = ProvenanceNode(
        id: 'root',
        children: [
          ProvenanceNode(id: 'a', children: [
            ProvenanceNode(id: 'a.1'),
          ]),
          ProvenanceNode(id: 'b'),
        ],
      );

      final flat = tree.flatten();
      expect(flat.map((n) => n.id), ['root', 'a', 'a.1', 'b']);
    });

    test('totalDescendants counts all children', () {
      const tree = ProvenanceNode(
        id: 'root',
        children: [
          ProvenanceNode(id: 'a', children: [
            ProvenanceNode(id: 'a.1'),
          ]),
          ProvenanceNode(id: 'b'),
        ],
      );

      expect(tree.totalDescendants, 3);
    });
  });

  group('ManifestViewData', () {
    test('defaults are sensible', () {
      const data = ManifestViewData();
      expect(data.actions, isEmpty);
      expect(data.ingredients, isEmpty);
      expect(data.validationResult.hasCredential, isFalse);
    });
  });

  group('ActionDisplayInfo', () {
    test('humanLabel returns readable labels for known actions', () {
      expect(ActionDisplayInfo.humanLabel('c2pa.created'), 'Created');
      expect(ActionDisplayInfo.humanLabel('c2pa.edited'), 'Edited');
      expect(ActionDisplayInfo.humanLabel('c2pa.cropped'), 'Cropped');
    });

    test('humanLabel strips prefix for unknown actions', () {
      expect(ActionDisplayInfo.humanLabel('c2pa.custom_action'), 'custom_action');
    });
  });

  group('ExifDisplayData', () {
    test('cameraLabel combines make and model', () {
      const exif = ExifDisplayData(
        cameraMake: 'Canon',
        cameraModel: 'Canon EOS R5',
      );
      expect(exif.cameraLabel, 'Canon EOS R5');
    });

    test('cameraLabel concatenates when model does not include make', () {
      const exif = ExifDisplayData(
        cameraMake: 'Canon',
        cameraModel: 'EOS R5',
      );
      expect(exif.cameraLabel, 'Canon EOS R5');
    });

    test('dimensionsLabel formats correctly', () {
      const exif = ExifDisplayData(width: 8192, height: 5464);
      expect(exif.dimensionsLabel, '8192 x 5464');
    });

    test('hasLocation checks both lat and lng', () {
      const noLoc = ExifDisplayData();
      expect(noLoc.hasLocation, isFalse);

      const withLoc = ExifDisplayData(latitude: 37.7, longitude: -122.4);
      expect(withLoc.hasLocation, isTrue);
    });
  });

  group('GenerativeInfo', () {
    test('description varies by type', () {
      const ai = GenerativeInfo(type: GenerativeType.aiGenerated);
      expect(ai.description, contains('generated with an AI tool'));

      const composite = GenerativeInfo(type: GenerativeType.compositeWithAi);
      expect(composite.description, contains('combines multiple'));
    });
  });

  group('Widget tests', () {
    testWidgets('ManifestDetailPanel renders header', (tester) async {
      const data = ManifestViewData(
        title: 'test.jpg',
        validationResult: ValidationResult.valid(),
        issuer: 'Test Issuer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: C2paViewerTheme(
              data: const C2paViewerThemeData(),
              child: const SizedBox(
                width: 360,
                height: 800,
                child: ManifestDetailPanel(data: data),
              ),
            ),
          ),
        ),
      );

      expect(find.text('test.jpg'), findsOneWidget);
    });

    testWidgets('CredentialIndicator shows correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: C2paViewerTheme(
            data: const C2paViewerThemeData(),
            child: const CredentialIndicator(
              result: ValidationResult.valid(),
            ),
          ),
        ),
      );

      expect(find.text('Content Credential'), findsOneWidget);
    });

    testWidgets('ProvenanceTreeViewer renders root node', (tester) async {
      const root = ProvenanceNode(
        id: 'root',
        title: 'photo.jpg',
        validationResult: ValidationResult.valid(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: C2paViewerTheme(
              data: const C2paViewerThemeData(),
              child: const SizedBox(
                width: 800,
                height: 600,
                child: ProvenanceTreeViewer(rootNode: root),
              ),
            ),
          ),
        ),
      );

      expect(find.text('photo.jpg'), findsOneWidget);
    });

    testWidgets('ErrorBanner shows for invalid credentials', (tester) async {
      const data = ManifestViewData(
        title: 'tampered.jpg',
        validationResult: ValidationResult.invalid(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: C2paViewerTheme(
              data: const C2paViewerThemeData(),
              child: const SizedBox(
                width: 360,
                height: 800,
                child: ManifestDetailPanel(data: data),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('tampered'), findsWidgets);
    });
  });
}
