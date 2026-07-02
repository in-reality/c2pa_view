import 'dart:typed_data';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/manifest_detail_section.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_content.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_tree_viewer.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _customBorderColor = Color(0xFFFF00FF);

Widget _wrap(final Widget child) => MaterialApp(
      home: C2paViewerTheme(
        data: C2paViewerThemeData.defaults,
        child: Scaffold(body: child),
      ),
    );

const _decoratorBorderColor = Color(0xFF00FF00);

ProvenanceGraph _twoNodeGraph() => ProvenanceGraph(
      rootId: 'root',
      nodes: {
        'root': const ProvenanceNode(
          id: 'root',
          summary: ManifestSummary(
            title: 'root.jpg',
            validationResult: ValidationResult.valid(),
          ),
        ),
        'child': const ProvenanceNode(
          id: 'child',
          summary: ManifestSummary(
            title: 'child.jpg',
            validationResult: ValidationResult.valid(),
          ),
        ),
      },
      edges: const [ProvenanceEdge(parentId: 'root', childId: 'child')],
    );

TreeNodeCard _cardForNodeId(final WidgetTester tester, final String nodeId) {
  final cards = tester.widgetList<TreeNodeCard>(find.byType(TreeNodeCard));
  return cards.firstWhere((final c) => c.node.id == nodeId);
}

ProvenanceNode _sampleNode() => const ProvenanceNode(
      id: 'manifest-1',
      summary: ManifestSummary(
        title: 'sample.jpg',
        validationResult: ValidationResult.valid(),
      ),
    );

void main() {
  group('TreeNodeCard extension API', () {
    testWidgets('custom highlight changes node border color', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TreeNodeCard(
            node: _sampleNode(),
            highlights: const [
              GraphHighlight(
                layerId: 'test-layer',
                style: HighlightStyle(borderColor: _customBorderColor),
              ),
            ],
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TreeNodeCard),
          matching: find.byType(Container).first,
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;

      expect(border.top.color, _customBorderColor);
    });

    testWidgets('nodeDecorator can override node border color', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TreeNodeCard(
            node: _sampleNode(),
            nodeDecorator:
                (final context, {
                  required final node,
                  required final decoration,
                  required final highlights,
                  required final isSelected,
                  required final child,
                }) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _decoratorBorderColor, width: 4),
                  ),
                  child: child,
                ),
          ),
        ),
      );

      final outer = tester.widget<Container>(
        find.descendant(
          of: find.byType(TreeNodeCard),
          matching: find.byType(Container).first,
        ),
      );
      final outerDecoration = outer.decoration! as BoxDecoration;
      final outerBorder = outerDecoration.border! as Border;
      expect(outerBorder.top.color, _decoratorBorderColor);
    });

    testWidgets('nodeDecorator wraps the default card', (final tester) async {
      await tester.pumpWidget(
        _wrap(
          TreeNodeCard(
            node: _sampleNode(),
            nodeDecorator:
                (final context, {
                  required final node,
                  required final decoration,
                  required final highlights,
                  required final isSelected,
                  required final child,
                }) => Column(
                  children: [
                    const Text('decorator-chrome'),
                    child,
                  ],
                ),
          ),
        ),
      );

      expect(find.text('decorator-chrome'), findsOneWidget);
      expect(find.text('sample.jpg'), findsOneWidget);
    });
  });

  group('resolveProvenanceNodeThumbnail', () {
    final rootImage = MemoryImage(Uint8List.fromList([1]));
    final parentImage = MemoryImage(Uint8List.fromList([2]));
    final embeddedImage = MemoryImage(Uint8List.fromList([3]));

    test('host provider wins over embedded thumbnail', () {
      final node = ProvenanceNode(
        id: 'child',
        summary: ManifestSummary(thumbnail: embeddedImage),
      );

      final resolved = resolveProvenanceNodeThumbnail(
        node: node,
        rootId: 'root',
        thumbnailProvider: (_) => parentImage,
      );

      expect(resolved, parentImage);
    });

    test('embedded thumbnail used when provider returns null', () {
      final node = ProvenanceNode(
        id: 'child',
        summary: ManifestSummary(thumbnail: embeddedImage),
      );

      final resolved = resolveProvenanceNodeThumbnail(
        node: node,
        rootId: 'root',
      );

      expect(resolved, embeddedImage);
    });

    test('root mediaImage used when no provider or embedded thumbnail', () {
      const node = ProvenanceNode(id: 'root');

      final resolved = resolveProvenanceNodeThumbnail(
        node: node,
        rootId: 'root',
        mediaImage: rootImage,
      );

      expect(resolved, rootImage);
    });

    test('non-root nodes do not inherit root mediaImage', () {
      const node = ProvenanceNode(id: 'child');

      final resolved = resolveProvenanceNodeThumbnail(
        node: node,
        rootId: 'root',
        mediaImage: rootImage,
      );

      expect(resolved, isNull);
    });
  });

  group('ProvenanceTreeViewer default params', () {
    testWidgets('selection path uses inherited theme border colors', (
      final tester,
    ) async {
      final darkTheme = C2paViewerThemeData.dark();

      await tester.pumpWidget(
        MaterialApp(
          home: C2paViewerTheme(
            data: darkTheme,
            child: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: ProvenanceTreeViewer(
                  graph: _twoNodeGraph(),
                  selectedNodeId: 'child',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TreeNodeCard), findsNWidgets(2));

      final rootCard = _cardForNodeId(tester, 'root');
      final childCard = _cardForNodeId(tester, 'child');

      expect(rootCard.isOnPath, isTrue);
      expect(childCard.isSelected, isTrue);
      expect(
        rootCard.highlights.single.style.borderColor,
        darkTheme.pathNodeBorderColor,
      );
      expect(
        childCard.highlights.single.style.borderColor,
        darkTheme.selectedNodeBorderColor,
      );
      expect(
        HighlightResolver.resolveNodeBorder(
          highlights: rootCard.highlights,
          isSelected: rootCard.isSelected,
          isOnPath: rootCard.isOnPath,
          theme: darkTheme,
        ),
        darkTheme.pathNodeBorderColor,
      );
      expect(
        HighlightResolver.resolveNodeBorder(
          highlights: childCard.highlights,
          isSelected: childCard.isSelected,
          isOnPath: childCard.isOnPath,
          theme: darkTheme,
        ),
        darkTheme.selectedNodeBorderColor,
      );
    });

    testWidgets('nodeThumbnailProvider supplies distinct images per node', (
      final tester,
    ) async {
      final rootImage = MemoryImage(Uint8List.fromList([1]));
      final parentImage = MemoryImage(Uint8List.fromList([2]));

      await tester.pumpWidget(
        MaterialApp(
          home: C2paViewerTheme(
            data: C2paViewerThemeData.defaults,
            child: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: ProvenanceTreeViewer(
                  graph: _twoNodeGraph(),
                  nodeThumbnailProvider: (final node) {
                    switch (node.id) {
                      case 'root':
                        return rootImage;
                      case 'child':
                        return parentImage;
                      default:
                        return null;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_cardForNodeId(tester, 'root').thumbnailOverride, rootImage);
      expect(_cardForNodeId(tester, 'child').thumbnailOverride, parentImage);
    });
  });

  group('ManifestDetailContent extension API', () {
    testWidgets('extraSections render host content', (final tester) async {
      const data = ManifestViewData(
        title: 'sample.jpg',
        validationResult: ValidationResult.valid(),
      );

      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            height: 600,
            child: ManifestDetailContent(
              data: data,
              extraSections: [
                ManifestDetailSection(
                  id: 'host-section',
                  builder: _hostSectionBuilder,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('host-extra-section'), findsOneWidget);
    });
  });

  group('ProvenanceAnnotations', () {
    test('empty preserves default maps', () {
      expect(ProvenanceAnnotations.empty.nodeDecorations, isEmpty);
      expect(ProvenanceAnnotations.empty.edgeDecorations, isEmpty);
      expect(ProvenanceAnnotations.empty.detailSections, isEmpty);
      expect(ProvenanceAnnotations.empty.attachments, isEmpty);
    });

    test('provenanceEdgeId uses arrow joiner', () {
      expect(provenanceEdgeId('parent', 'child'), 'parent→child');
    });
  });
}

Widget _hostSectionBuilder(
  final BuildContext context,
  final ManifestViewData data,
) => const Padding(
  padding: EdgeInsets.all(16),
  child: Text('host-extra-section'),
);
