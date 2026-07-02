import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Axis-aligned bounds of laid-out provenance node cards and optional
/// satellite attachment rects.
Rect provenanceGraphBounds({
  required final Iterable<Offset> nodePositions,
  required final double nodeWidth,
  required final double nodeHeight,
  final Iterable<Rect> attachmentRects = const [],
}) {
  final iterator = nodePositions.iterator;
  final attachmentIterator = attachmentRects.iterator;

  final hasNodes = iterator.moveNext();
  final hasAttachments = attachmentIterator.moveNext();

  if (!hasNodes && !hasAttachments) {
    return Rect.zero;
  }

  var minX = hasNodes ? iterator.current.dx : attachmentIterator.current.left;
  var minY = hasNodes ? iterator.current.dy : attachmentIterator.current.top;
  var maxX =
      hasNodes
          ? iterator.current.dx + nodeWidth
          : attachmentIterator.current.right;
  var maxY =
      hasNodes
          ? iterator.current.dy + nodeHeight
          : attachmentIterator.current.bottom;

  while (iterator.moveNext()) {
    final position = iterator.current;
    minX = math.min(minX, position.dx);
    minY = math.min(minY, position.dy);
    maxX = math.max(maxX, position.dx + nodeWidth);
    maxY = math.max(maxY, position.dy + nodeHeight);
  }

  if (hasAttachments) {
    minX = math.min(minX, attachmentIterator.current.left);
    minY = math.min(minY, attachmentIterator.current.top);
    maxX = math.max(maxX, attachmentIterator.current.right);
    maxY = math.max(maxY, attachmentIterator.current.bottom);
  }

  while (attachmentIterator.moveNext()) {
    final rect = attachmentIterator.current;
    minX = math.min(minX, rect.left);
    minY = math.min(minY, rect.top);
    maxX = math.max(maxX, rect.right);
    maxY = math.max(maxY, rect.bottom);
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
