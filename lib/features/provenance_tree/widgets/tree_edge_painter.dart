import 'package:flutter/rendering.dart';

/// Custom painter that draws curved edges between tree nodes.
class TreeEdgePainter extends CustomPainter {
  final List<EdgeLine> edges;
  final Color color;
  final double strokeWidth;

  TreeEdgePainter({
    required this.edges,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final path = Path();
      path.moveTo(edge.from.dx, edge.from.dy);

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
    }
  }

  @override
  bool shouldRepaint(TreeEdgePainter oldDelegate) =>
      edges != oldDelegate.edges ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}

/// A line segment between two points in the tree layout.
class EdgeLine {
  final Offset from;
  final Offset to;
  const EdgeLine({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgeLine && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}
