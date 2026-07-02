import 'package:c2pa_view/domain/models/manifest_detail_section.dart';
import 'package:flutter/material.dart';

/// Stable edge id for annotation and highlight maps.
///
/// Format: `"$parentId→$childId"` where both ids are manifest labels.
String provenanceEdgeId(final String parentId, final String childId) =>
    '$parentId→$childId';

/// Opaque decoration slot for a provenance graph node.
///
/// Host packages attach badges, border hints, and payloads without the OSS
/// package interpreting product-specific semantics.
class NodeDecoration {
  const NodeDecoration({
    this.borderColor,
    this.borderWidth,
    this.badges = const [],
    this.payload,
  });

  final Color? borderColor;
  final double? borderWidth;
  final List<DecorationBadge> badges;

  /// Host-owned payload — opaque to `c2pa_view`.
  final Object? payload;
}

/// Opaque decoration slot for a provenance graph edge.
class EdgeDecoration {
  const EdgeDecoration({
    this.strokeColor,
    this.strokeWidth,
    this.payload,
  });

  final Color? strokeColor;
  final double? strokeWidth;
  final Object? payload;
}

/// Opaque satellite box anchored to a graph node outside the layout algorithm.
///
/// Host packages supply color and payload; OSS paints via
/// [ProvenanceAttachmentContentBuilder] without interpreting semantics.
class NodeAttachment {
  const NodeAttachment({
    required this.id,
    required this.anchorNodeId,
    required this.color,
    this.payload,
  });

  final String id;

  /// [ProvenanceNode.id] (manifest label) of the anchor media node.
  final String anchorNodeId;
  final Color color;

  /// Host-owned payload — opaque to `c2pa_view`.
  final Object? payload;
}

/// A compact badge rendered on a node by the default or custom decorator.
class DecorationBadge {
  const DecorationBadge({
    required this.id,
    required this.label,
    this.icon,
    this.payload,
  });

  final String id;
  final String label;
  final IconData? icon;
  final Object? payload;
}

/// Parallel annotation sidecar keyed by graph node and edge ids.
///
/// An empty instance preserves today's default appearance.
class ProvenanceAnnotations {
  const ProvenanceAnnotations({
    this.nodeDecorations = const {},
    this.edgeDecorations = const {},
    this.detailSections = const {},
    this.attachments = const {},
  });

  static const ProvenanceAnnotations empty = ProvenanceAnnotations();

  /// Key: [ProvenanceNode.id] (manifest label).
  final Map<String, NodeDecoration> nodeDecorations;

  /// Key: [provenanceEdgeId] (`"$parentId→$childId"`).
  final Map<String, EdgeDecoration> edgeDecorations;

  /// Key: [ProvenanceNode.id] — ordered extra detail-panel sections.
  final Map<String, List<ManifestDetailSection>> detailSections;

  /// Key: anchor [ProvenanceNode.id] — satellites excluded from layout depth.
  final Map<String, List<NodeAttachment>> attachments;
}
