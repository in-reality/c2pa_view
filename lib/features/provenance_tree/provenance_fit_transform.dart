import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Axis-aligned bounds of laid-out provenance node cards.
Rect provenanceGraphBounds({
  required final Iterable<Offset> nodePositions,
  required final double nodeWidth,
  required final double nodeHeight,
}) {
  final iterator = nodePositions.iterator;
  if (!iterator.moveNext()) {
    return Rect.zero;
  }

  var minX = iterator.current.dx;
  var minY = iterator.current.dy;
  var maxX = minX + nodeWidth;
  var maxY = minY + nodeHeight;

  while (iterator.moveNext()) {
    final position = iterator.current;
    minX = math.min(minX, position.dx);
    minY = math.min(minY, position.dy);
    maxX = math.max(maxX, position.dx + nodeWidth);
    maxY = math.max(maxY, position.dy + nodeHeight);
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Builds an [InteractiveViewer] transform that uniformly scales [contentBounds]
/// to fit inside [viewportSize] with [padding], centred in the viewport.
Matrix4 provenanceFitToViewTransform({
  required final Rect contentBounds,
  required final Size viewportSize,
  final double padding = 24,
  final double minScale = 0.1,
  final double maxScale = 5,
}) {
  if (viewportSize.isEmpty ||
      contentBounds.isEmpty ||
      contentBounds.width <= 0 ||
      contentBounds.height <= 0) {
    return Matrix4.identity();
  }

  final availableWidth = viewportSize.width - padding * 2;
  final availableHeight = viewportSize.height - padding * 2;
  if (availableWidth <= 0 || availableHeight <= 0) {
    return Matrix4.identity();
  }

  final scaleX = availableWidth / contentBounds.width;
  final scaleY = availableHeight / contentBounds.height;
  final scale = math.min(scaleX, scaleY).clamp(minScale, maxScale);

  final dx =
      (viewportSize.width - contentBounds.width * scale) / 2 -
      contentBounds.left * scale;
  final dy =
      (viewportSize.height - contentBounds.height * scale) / 2 -
      contentBounds.top * scale;

  return Matrix4.identity()
    ..translateByDouble(dx, dy, 0, 1)
    ..scaleByDouble(scale, scale, scale, 1);
}
