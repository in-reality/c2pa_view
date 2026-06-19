import 'package:c2pa_view/features/provenance_tree/provenance_fit_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('provenanceGraphBounds', () {
    test('returns zero rect for empty positions', () {
      expect(
        provenanceGraphBounds(
          nodePositions: const [],
          nodeWidth: 200,
          nodeHeight: 100,
        ),
        Rect.zero,
      );
    });

    test('wraps a single node card', () {
      final bounds = provenanceGraphBounds(
        nodePositions: const [Offset(80, 80)],
        nodeWidth: 200,
        nodeHeight: 100,
      );

      expect(bounds, const Rect.fromLTRB(80, 80, 280, 180));
    });

    test('wraps multiple node cards', () {
      final bounds = provenanceGraphBounds(
        nodePositions: const [
          Offset(80, 80),
          Offset(340, 260),
        ],
        nodeWidth: 200,
        nodeHeight: 100,
      );

      expect(bounds, const Rect.fromLTRB(80, 80, 540, 360));
    });
  });

  group('provenanceFitToViewTransform', () {
    test('returns identity for empty viewport or content', () {
      const content = Rect.fromLTRB(0, 0, 400, 300);

      expect(
        provenanceFitToViewTransform(
          contentBounds: content,
          viewportSize: Size.zero,
        ),
        Matrix4.identity(),
      );
      expect(
        provenanceFitToViewTransform(
          contentBounds: Rect.zero,
          viewportSize: const Size(320, 480),
        ),
        Matrix4.identity(),
      );
    });

    test('scales wide content down to fit a narrow viewport', () {
      const content = Rect.fromLTRB(80, 80, 540, 360);
      const viewport = Size(320, 480);
      const padding = 24.0;

      final matrix = provenanceFitToViewTransform(
        contentBounds: content,
        viewportSize: viewport,
        padding: padding,
      );

      final scale = matrix.getMaxScaleOnAxis();
      final availableWidth = viewport.width - padding * 2;
      final expectedScale =
          (availableWidth / content.width).clamp(0.1, 5.0).toDouble();

      expect(scale, closeTo(expectedScale, 0.001));
      expect(scale, lessThan(1.0));

      final topLeft = MatrixUtils.transformPoint(
        matrix,
        Offset(content.left, content.top),
      );
      final bottomRight = MatrixUtils.transformPoint(
        matrix,
        Offset(content.right, content.bottom),
      );

      expect(topLeft.dx, closeTo(padding, 0.5));
      expect(topLeft.dy, greaterThanOrEqualTo(padding - 0.5));
      expect(bottomRight.dx, closeTo(viewport.width - padding, 0.5));
      expect(bottomRight.dy, lessThanOrEqualTo(viewport.height - padding + 0.5));
    });

    test('centres content in the viewport', () {
      const content = Rect.fromLTRB(10, 10, 110, 60);
      const viewport = Size(320, 480);

      final matrix = provenanceFitToViewTransform(
        contentBounds: content,
        viewportSize: viewport,
        maxScale: 5,
      );

      final centre = MatrixUtils.transformPoint(matrix, content.center);
      expect(centre.dx, closeTo(viewport.width / 2, 0.5));
      expect(centre.dy, closeTo(viewport.height / 2, 0.5));
    });
  });
}
