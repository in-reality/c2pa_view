import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Default satellite card width in graph space (scales with zoom).
const double kNodeAttachmentWidth = 90;

/// Default satellite card height in graph space (scales with zoom).
const double kNodeAttachmentHeight = 40;

/// Gap between an anchor node edge and the fan arc centre.
const double kNodeAttachmentAnchorGap = 10;

/// Fan spacing is tuned for up to this many attachments per anchor; more still
/// render with denser semicircle placement rather than being dropped.
///
/// A node carrying its full companion set may exceed this count — all satellites
/// remain visible, but crowding may warrant a grouping / "+N" overflow
/// affordance in the host layer.
const int kNodeAttachmentFanTunedMax = 8;

/// Graph-space top-left offsets for [count] attachments fanned around an
/// anchor node whose card size is [anchorNodeSize].
///
/// Offsets are relative to the anchor node's top-left corner so they scale with
/// the same [InteractiveViewer] transform as node cards.
List<Offset> nodeAttachmentFanOffsets({
  required final int count,
  required final Size anchorNodeSize,
  final double attachmentWidth = kNodeAttachmentWidth,
  final double attachmentHeight = kNodeAttachmentHeight,
}) {
  if (count <= 0) {
    return const [];
  }

  final anchorCenter = Offset(
    anchorNodeSize.width / 2,
    anchorNodeSize.height / 2,
  );
  final radius =
      math.max(anchorNodeSize.width, anchorNodeSize.height) / 2 +
      kNodeAttachmentAnchorGap +
      math.max(attachmentWidth, attachmentHeight) / 2;

  return List.generate(count, (final index) {
    final angle = _fanAngle(index: index, count: count);
    final centre = Offset(
      anchorCenter.dx + radius * math.cos(angle),
      anchorCenter.dy + radius * math.sin(angle),
    );
    return Offset(
      centre.dx - attachmentWidth / 2,
      centre.dy - attachmentHeight / 2,
    );
  });
}

/// Absolute graph-space bounding rects for attachments on an anchor at
/// [anchorPosition].
List<Rect> nodeAttachmentRects({
  required final Offset anchorPosition,
  required final Size anchorNodeSize,
  required final int attachmentCount,
  final double attachmentWidth = kNodeAttachmentWidth,
  final double attachmentHeight = kNodeAttachmentHeight,
}) {
  final offsets = nodeAttachmentFanOffsets(
    count: attachmentCount,
    anchorNodeSize: anchorNodeSize,
    attachmentWidth: attachmentWidth,
    attachmentHeight: attachmentHeight,
  );

  return offsets
      .map(
        (final offset) => Rect.fromLTWH(
          anchorPosition.dx + offset.dx,
          anchorPosition.dy + offset.dy,
          attachmentWidth,
          attachmentHeight,
        ),
      )
      .toList();
}

/// Right-side semicircle fan: tuned spread for ≤ [kNodeAttachmentFanTunedMax],
/// denser full semicircle beyond that so visibility is never sacrificed.
double _fanAngle({required final int index, required final int count}) {
  if (count == 1) {
    return 0;
  }

  if (count <= kNodeAttachmentFanTunedMax) {
    const startAngle = -math.pi / 3;
    const endAngle = math.pi / 3;
    final t = index / (count - 1);
    return startAngle + t * (endAngle - startAngle);
  }

  const startAngle = -math.pi / 2;
  const endAngle = math.pi / 2;
  final t = index / (count - 1);
  return startAngle + t * (endAngle - startAngle);
}
