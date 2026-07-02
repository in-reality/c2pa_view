import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_interaction.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/features/provenance_tree/node_attachment_layout.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_fit_transform.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_tree_viewer.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _attachmentColor = Color(0xFFAA5500);

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

List<NodeAttachment> _attachmentsForAnchor(
  final String anchorId,
  final int count,
) => List.generate(
  count,
  (final index) => NodeAttachment(
    id: 'att-$index',
    anchorNodeId: anchorId,
    color: _attachmentColor,
    payload: 'payload-$index',
  ),
);

Widget _wrap(final Widget child) => MaterialApp(
  home: C2paViewerTheme(
    data: C2paViewerThemeData.defaults,
    child: Scaffold(
      body: SizedBox(width: 800, height: 600, child: child),
    ),
  ),
);

Offset _nodeGraphPosition(final WidgetTester tester, final String nodeId) {
  final positioned = tester.widget<Positioned>(
    find.ancestor(
      of: find.byWidgetPredicate(
        (final widget) => widget is TreeNodeCard && widget.node.id == nodeId,
      ),
      matching: find.byType(Positioned),
    ),
  );
  return Offset(positioned.left ?? 0, positioned.top ?? 0);
}

class _RecordingHandler implements ProvenanceInteractionHandler {
  String? tappedAnchorId;
  String? tappedAttachmentId;
  Object? tappedPayload;

  @override
  void onAttachmentTap(
    final String anchorNodeId,
    final String attachmentId, {
    final Object? payload,
  }) {
    tappedAnchorId = anchorNodeId;
    tappedAttachmentId = attachmentId;
    tappedPayload = payload;
  }

  @override
  void onBadgeTap(
    final String nodeId,
    final String badgeId, {
    final Object? payload,
  }) {}

  @override
  void onEdgeTap(
    final ProvenanceEdge edge, {
    final EdgeDecoration? decoration,
  }) {}

  @override
  void onFocusChangeRequested(final String nodeId) {}

  @override
  void onIconTap(
    final String nodeId,
    final String iconId, {
    final Object? payload,
  }) {}

  @override
  void onNodeTap(
    final ProvenanceNode node, {
    final NodeDecoration? decoration,
  }) {}
}

void main() {
  group('nodeAttachmentFanOffsets', () {
    test('returns empty list for zero count', () {
      expect(
        nodeAttachmentFanOffsets(
          count: 0,
          anchorNodeSize: const Size(200, 100),
        ),
        isEmpty,
      );
    });

    test('single attachment sits to the right of anchor centre', () {
      const anchorSize = Size(200, 100);
      final offsets = nodeAttachmentFanOffsets(
        count: 1,
        anchorNodeSize: anchorSize,
      );

      expect(offsets, hasLength(1));
      expect(offsets.single.dx, greaterThan(anchorSize.width / 2));
    });

    test('nine attachments still produce nine distinct offsets', () {
      final offsets = nodeAttachmentFanOffsets(
        count: 9,
        anchorNodeSize: const Size(200, 100),
      );

      expect(offsets, hasLength(9));
      expect(offsets.toSet(), hasLength(9));
    });
  });

  group('provenanceGraphBounds attachments', () {
    test('includes satellite rects beyond node cards', () {
      const theme = C2paViewerThemeData.defaults;
      const anchor = Offset(80, 80);
      final nodeBounds = provenanceGraphBounds(
        nodePositions: const [anchor],
        nodeWidth: theme.nodeWidth,
        nodeHeight: theme.nodeHeight,
      );
      final attachmentRects = nodeAttachmentRects(
        anchorPosition: anchor,
        anchorNodeSize: Size(theme.nodeWidth, theme.nodeHeight),
        attachmentCount: 3,
      );
      final combined = provenanceGraphBounds(
        nodePositions: const [anchor],
        nodeWidth: theme.nodeWidth,
        nodeHeight: theme.nodeHeight,
        attachmentRects: attachmentRects,
      );

      expect(combined.left, lessThanOrEqualTo(nodeBounds.left));
      expect(combined.top, lessThanOrEqualTo(nodeBounds.top));
      expect(combined.right, greaterThan(nodeBounds.right));
      expect(combined.bottom, greaterThanOrEqualTo(nodeBounds.bottom));

      for (final rect in attachmentRects) {
        expect(combined.overlaps(rect), isTrue);
        expect(combined.left, lessThanOrEqualTo(rect.left));
        expect(combined.top, lessThanOrEqualTo(rect.top));
        expect(combined.right, greaterThanOrEqualTo(rect.right));
        expect(combined.bottom, greaterThanOrEqualTo(rect.bottom));
      }
    });
  });

  group('ProvenanceTreeViewer node attachments', () {
    testWidgets('empty attachments preserve default node layout', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ProvenanceTreeViewer(graph: _twoNodeGraph())),
      );
      await tester.pump();

      final baselineRoot = _nodeGraphPosition(tester, 'root');
      final baselineChild = _nodeGraphPosition(tester, 'child');
      final baselineNodeCount = tester.widgetList(find.byType(TreeNodeCard)).length;

      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: const ProvenanceAnnotations(attachments: {}),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeGraphPosition(tester, 'root'), baselineRoot);
      expect(_nodeGraphPosition(tester, 'child'), baselineChild);
      expect(tester.widgetList(find.byType(TreeNodeCard)).length, baselineNodeCount);
      expect(find.byKey(const ValueKey('attachment:att-0')), findsNothing);
    });

    testWidgets('attachments do not move media node positions', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(ProvenanceTreeViewer(graph: _twoNodeGraph())),
      );
      await tester.pump();

      final baselineRoot = _nodeGraphPosition(tester, 'root');
      final baselineChild = _nodeGraphPosition(tester, 'child');
      final baselineOffset = baselineChild - baselineRoot;

      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': _attachmentsForAnchor('root', 4),
              },
            ),
            attachmentContentBuilder:
                (final context, {required final attachment}) =>
                    ColoredBox(color: attachment.color),
          ),
        ),
      );
      await tester.pump();

      final withAttachmentsRoot = _nodeGraphPosition(tester, 'root');
      final withAttachmentsChild = _nodeGraphPosition(tester, 'child');
      final attachedOffset = withAttachmentsChild - withAttachmentsRoot;
      expect(attachedOffset.dx, closeTo(baselineOffset.dx, 0.001));
      expect(attachedOffset.dy, closeTo(baselineOffset.dy, 0.001));
    });

    test('offsets are relative to anchor top-left in graph space', () {
      const anchorSize = Size(200, 100);
      const anchorPosition = Offset(80, 80);
      final offsets = nodeAttachmentFanOffsets(
        count: 2,
        anchorNodeSize: anchorSize,
      );
      final rects = nodeAttachmentRects(
        anchorPosition: anchorPosition,
        anchorNodeSize: anchorSize,
        attachmentCount: 2,
      );

      expect(
        rects[0].topLeft - anchorPosition,
        offsets[0],
      );
      expect(
        rects[1].topLeft - anchorPosition,
        offsets[1],
      );
    });

    testWidgets('more than eight attachments still render', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': _attachmentsForAnchor('root', 9),
              },
            ),
            attachmentContentBuilder:
                (final context, {required final attachment}) => Text(
                  attachment.id,
                  key: ValueKey('label:${attachment.id}'),
                ),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 9; i++) {
        expect(find.byKey(ValueKey('attachment:att-$i')), findsOneWidget);
        expect(find.byKey(ValueKey('label:att-$i')), findsOneWidget);
      }
    });

    testWidgets('attachment tap invokes interaction handler', (
      final tester,
    ) async {
      final handler = _RecordingHandler();

      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': const [
                  NodeAttachment(
                    id: 'att-0',
                    anchorNodeId: 'root',
                    color: _attachmentColor,
                    payload: 'tap-payload',
                  ),
                ],
              },
            ),
            interactionHandler: handler,
            attachmentContentBuilder:
                (final context, {required final attachment}) =>
                    const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('attachment:att-0')),
      );
      detector.onTap!.call();
      await tester.pump();

      expect(handler.tappedAnchorId, 'root');
      expect(handler.tappedAttachmentId, 'att-0');
      expect(handler.tappedPayload, 'tap-payload');
    });

    testWidgets('null interaction handler ignores attachment taps', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': _attachmentsForAnchor('root', 1),
              },
            ),
            attachmentContentBuilder:
                (final context, {required final attachment}) =>
                    const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('attachment:att-0')));
      await tester.pump();
    });

    testWidgets('top-row attachments are not clipped above stack origin', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': _attachmentsForAnchor('root', 4),
              },
            ),
            attachmentContentBuilder:
                (final context, {required final attachment}) =>
                    ColoredBox(color: attachment.color),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 4; i++) {
        final positioned = tester.widget<Positioned>(
          find.ancestor(
            of: find.byKey(ValueKey('attachment:att-$i')),
            matching: find.byType(Positioned),
          ),
        );
        expect(positioned.top, greaterThanOrEqualTo(0));
        expect(positioned.left, greaterThanOrEqualTo(0));
      }
    });

    testWidgets('null handler does not block node taps under attachments', (
      final tester,
    ) async {
      var selectedId = 'child';

      await tester.pumpWidget(
        _wrap(
          ProvenanceTreeViewer(
            graph: _twoNodeGraph(),
            selectedNodeId: selectedId,
            onNodeSelected: (final node) => selectedId = node.id,
            annotations: ProvenanceAnnotations(
              attachments: {
                'root': _attachmentsForAnchor('root', 1),
              },
            ),
            attachmentContentBuilder:
                (final context, {required final attachment}) =>
                    const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(TreeNodeCard).first);
      await tester.pump();

      expect(selectedId, 'root');
    });
  });
}
