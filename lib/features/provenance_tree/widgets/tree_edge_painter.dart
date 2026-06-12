import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_interaction.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:flutter/rendering.dart';

/// Custom painter that draws curved edges between tree nodes.
class TreeEdgePainter extends CustomPainter {
  TreeEdgePainter({
    required this.edges,
    required this.theme,
    this.edgeHighlights = const {},
    this.edgeDecorations = const {},
    this.edgeDecorator,
  });

  final List<EdgeLine> edges;
  final C2paViewerThemeData theme;
  final Map<String, List<GraphHighlight>> edgeHighlights;
  final Map<String, EdgeDecoration> edgeDecorations;
  final ProvenanceEdgeDecorator? edgeDecorator;

  @override
  void paint(final Canvas canvas, final Size size) {
    for (final edge in edges) {
      final edgeId = provenanceEdgeId(edge.parentId, edge.childId);
      final highlights = edgeHighlights[edgeId] ?? const [];
      final decoration = edgeDecorations[edgeId];

      final color = HighlightResolver.resolveEdgeColor(
        highlights: highlights,
        theme: theme,
        decoration: decoration,
      );
      final strokeWidth = HighlightResolver.resolveEdgeStrokeWidth(
        highlights: highlights,
        decoration: decoration,
      );

      final paint =
          Paint()
            ..color = color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      final path = Path()..moveTo(edge.from.dx, edge.from.dy);

      final midY = (edge.from.dy + edge.to.dy) / 2;
      path.cubicTo(
        edge.from.dx,
        midY,
        edge.to.dx,
        midY,
        edge.to.dx,
        edge.to.dy,
      );

      canvas.drawPath(path, paint);

      edgeDecorator?.call(
        canvas,
        ProvenanceEdge(parentId: edge.parentId, childId: edge.childId),
        decoration,
        highlights,
        EdgeLineGeometry(
          parentId: edge.parentId,
          childId: edge.childId,
          from: edge.from,
          to: edge.to,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(final TreeEdgePainter oldDelegate) =>
      edges != oldDelegate.edges ||
      theme != oldDelegate.theme ||
      edgeHighlights != oldDelegate.edgeHighlights ||
      edgeDecorations != oldDelegate.edgeDecorations ||
      edgeDecorator != oldDelegate.edgeDecorator;
}

/// A line segment between two points in the tree layout.
class EdgeLine {
  const EdgeLine({
    required this.parentId,
    required this.childId,
    required this.from,
    required this.to,
  });

  final String parentId;
  final String childId;
  final Offset from;
  final Offset to;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EdgeLine &&
          parentId == other.parentId &&
          childId == other.childId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(parentId, childId, from, to);
}
