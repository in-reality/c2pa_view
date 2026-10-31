import 'dart:convert';
import 'dart:ui' as ui;

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/embedded_preview_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native and WASM resolve identical signed embedded preview content',
    () async {
      await initRustLib();
      final store = await ManifestStore.fromBytes(
        base64Decode(embeddedPreviewAsset),
        'image/png',
      );
      expect(store, isNotNull);
      expect(store!.manifests.length, 3);
      final edited = store.manifests[store.activeManifest]!;
      expect(edited.thumbnail!.resolution, 'resolved');
      final middle = store.manifests.values.singleWhere(
        (m) => m.title == 'middle',
      );
      expect(middle.ingredients.single.thumbnail!.resolution, 'resolved');
      expect(middle.ingredients.single.thumbnail!.format, 'image/jpeg');
      expect(
        middle.ingredients.single.thumbnail!.containingManifest,
        middle.label,
      );
      expect(edited.ingredients.length, 3);
      for (final ingredient in edited.ingredients.skip(1)) {
        expect(ingredient.thumbnail!.resolution, 'resolved');
        expect(
          ingredient.thumbnail!.data,
          middle.ingredients.single.thumbnail!.data,
        );
      }
      final graph = ProvenanceMapper.mapToGraph(store);
      expect(graph.nodes.length, 5);
      expect(graph.edges.length, 4);
      final original = graph.nodes.values.singleWhere(
        (n) => n.summary.title == 'original',
      );
      expect(original.manifestViewData, isNotNull);
      expect(original.summary.validationResult.hasCredential, isTrue);
      expect(original.summary.previewSource!.isIngredient, isTrue);
      expect(original.summary.previewSource!.containingManifest, middle.label);
      expect(
        original.summary.previewSource!.validationResult!.isUntrusted,
        isTrue,
      );
      // Decode bytes from SDK lookup, not a separately injected test image.
      for (final sample in [
        (edited.thumbnail!.data!, [255, 0, 0, 255]),
        ((original.summary.thumbnail as MemoryImage).bytes, [0, 0, 254, 255]),
      ]) {
        final codec = await ui.instantiateImageCodec(sample.$1);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 2);
        expect(frame.image.height, 2);
        final pixels = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final rgba = pixels!.buffer.asUint8List();
        for (var c = 0; c < 4; c++) {
          expect(rgba[c], closeTo(sample.$2[c], 2));
        }
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
  test(
    'trusted current signature does not clear recorded input binding failure',
    () async {
      await initRustLib();
      final store = await ManifestStore.fromBytes(
        base64Decode(recordedInputFailureAsset),
        'image/png',
        allowedListPem: testAllowedLeafPem,
      );
      final graph = ProvenanceMapper.mapToGraph(store!);
      final original = graph.nodes.values.singleWhere(
        (final n) => n.summary.title == 'original',
      );
      expect(original.summary.validationResult.isInvalid, isTrue);
      expect(original.summary.inputValidationEvidence, isNotEmpty);
      expect(
        original.summary.inputValidationEvidence.single.failures.any(
          (final s) => s.code == 'assertion.dataHash.mismatch',
        ),
        isTrue,
      );
      expect(
        original
            .summary
            .inputValidationEvidence
            .single
            .containingValidation!
            .isValid,
        isTrue,
      );
      expect(original.summary.previewSource!.validationResult!.isValid, isTrue);
      expect(original.manifestViewData!.validationResult.isInvalid, isTrue);
      expect(original.summary.thumbnail, isA<MemoryImage>());
    },
  );
}
