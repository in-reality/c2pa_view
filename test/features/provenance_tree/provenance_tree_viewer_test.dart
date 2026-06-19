import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_tree_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProvenanceGraph _twoNodeGraph() {
  const root = ProvenanceNode(
    id: 'root',
    summary: ManifestSummary(
      title: 'Root asset',
      validationResult: ValidationResult.valid(),
    ),
  );
  const child = ProvenanceNode(
    id: 'child',
    summary: ManifestSummary(
      title: 'Ingredient',
      validationResult: ValidationResult.valid(),
    ),
  );

  return const ProvenanceGraph(
    rootId: 'root',
    nodes: {
      'root': root,
      'child': child,
    },
    edges: [
      ProvenanceEdge(parentId: 'root', childId: 'child'),
    ],
  );
}

Widget _wrap(final Widget child) => MaterialApp(
  home: C2paViewerTheme(
    data: C2paViewerThemeData.defaults,
    child: Scaffold(body: child),
  ),
);

void main() {
  group('ProvenanceTreeViewer fit to view', () {
    testWidgets('Fit to view applies a non-identity centred transform', (
      final tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            height: 480,
            child: ProvenanceTreeViewer(graph: _twoNodeGraph()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = viewer.transformationController!;
      controller.value = Matrix4.translationValues(-500, -500, 0);
      await tester.pump();

      await tester.tap(find.byTooltip('Fit to view'));
      await tester.pumpAndSettle();

      final matrix = controller.value;
      final scale = matrix.getMaxScaleOnAxis();

      expect(scale, greaterThan(0.1));
      expect(scale, lessThanOrEqualTo(5.0));
      expect(matrix, isNot(Matrix4.translationValues(-500, -500, 0)));

      const theme = C2paViewerThemeData.defaults;
      const graphTopLeft = Offset(80, 80);
      final graphBottomRight = Offset(
        80 + theme.nodeWidth,
        80 + theme.nodeHeight + theme.nodeSpacingY + theme.nodeHeight,
      );

      final fittedTopLeft = MatrixUtils.transformPoint(matrix, graphTopLeft);
      final fittedBottomRight = MatrixUtils.transformPoint(
        matrix,
        graphBottomRight,
      );

      expect(fittedTopLeft.dx, greaterThan(0));
      expect(fittedTopLeft.dy, greaterThan(0));
      expect(fittedBottomRight.dx, lessThan(320));
      expect(fittedBottomRight.dy, lessThan(480));
    });
  });
}
