import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'layout follows theme dimensions and updates without replacing graph',
    (tester) async {
      const graph = ProvenanceGraph(
        rootId: 'root',
        nodes: {
          'root': ProvenanceNode(
            id: 'root',
            summary: ManifestSummary(title: 'Root'),
          ),
          'child': ProvenanceNode(
            id: 'child',
            summary: ManifestSummary(title: 'Child'),
          ),
        },
        edges: [ProvenanceEdge(parentId: 'root', childId: 'child')],
      );
      for (final theme in [
        C2paViewerThemeData.defaults,
        const C2paViewerThemeData(
          nodeWidth: 224,
          nodeHeight: 64,
          nodeSpacingY: 24,
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: C2paViewerTheme(
              data: theme,
              child: const Scaffold(
                body: SizedBox(
                  width: 358,
                  height: 260,
                  child: ProvenanceTreeViewer(graph: graph),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final root = find.byKey(const ValueKey('root'));
        final child = find.byKey(const ValueKey('child'));
        final rootPosition = tester.widget<Positioned>(
          find.ancestor(of: root, matching: find.byType(Positioned)).first,
        );
        final childPosition = tester.widget<Positioned>(
          find.ancestor(of: child, matching: find.byType(Positioned)).first,
        );
        expect(
          childPosition.top! - rootPosition.top!,
          theme.nodeHeight + theme.nodeSpacingY,
        );
        expect(tester.getSize(root).width, theme.nodeWidth);
        expect(tester.getSize(root).height, theme.nodeHeight);
        expect(find.byType(TreeNodeCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
