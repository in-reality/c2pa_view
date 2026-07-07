import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:flutter/foundation.dart';

/// Whether [attachment] may be painted on [anchorNodeId] in the rendered graph.
///
/// Release builds use this predicate to omit invalid entries without asserting.
@visibleForTesting
bool isNodeAttachmentPaintable({
  required final NodeAttachment attachment,
  required final String anchorNodeId,
  required final Set<String> graphNodeIds,
}) =>
    graphNodeIds.contains(anchorNodeId) &&
    graphNodeIds.contains(attachment.anchorNodeId) &&
    attachment.anchorNodeId == anchorNodeId;

/// Debug-only check that every attachments-map key is a rendered graph node.
///
/// Orphan keys are never painted; release builds rely on layout iteration
/// over graph nodes only.
void assertNoOrphanAttachmentMapKeys({
  required final Map<String, List<NodeAttachment>> attachmentsByAnchor,
  required final Set<String> graphNodeIds,
}) {
  for (final mapKey in attachmentsByAnchor.keys) {
    assert(
      graphNodeIds.contains(mapKey),
      'attachments map key ($mapKey) is not a rendered graph node',
    );
  }
}

/// Returns attachments on [anchorNodeId] that may be painted.
///
/// Debug builds assert when the map key or [NodeAttachment.anchorNodeId]
/// is not a rendered graph node, or when anchor does not match map key.
/// Release builds omit invalid entries — never re-home to another node.
List<NodeAttachment> paintableNodeAttachmentsForAnchor({
  required final String anchorNodeId,
  required final Map<String, List<NodeAttachment>> attachmentsByAnchor,
  required final Set<String> graphNodeIds,
}) {
  assert(
    graphNodeIds.contains(anchorNodeId),
    'attachments map key ($anchorNodeId) is not a rendered graph node',
  );
  if (!graphNodeIds.contains(anchorNodeId)) {
    return const [];
  }

  final attachments = attachmentsByAnchor[anchorNodeId] ?? const [];
  final paintable = <NodeAttachment>[];
  for (final attachment in attachments) {
    if (!isNodeAttachmentPaintable(
      attachment: attachment,
      anchorNodeId: anchorNodeId,
      graphNodeIds: graphNodeIds,
    )) {
      assert(
        graphNodeIds.contains(attachment.anchorNodeId),
        'attachment ${attachment.id} anchorNodeId (${attachment.anchorNodeId}) '
        'is not a rendered graph node',
      );
      assert(
        attachment.anchorNodeId == anchorNodeId,
        'attachment ${attachment.id} anchorNodeId (${attachment.anchorNodeId}) '
        'must match annotations map key ($anchorNodeId)',
      );
      continue;
    }
    paintable.add(attachment);
  }
  return paintable;
}
