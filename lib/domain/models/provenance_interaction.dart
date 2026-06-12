import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:flutter/material.dart';

/// Host-supplied interaction callbacks for provenance graph widgets.
///
/// When null, taps select nodes for the detail panel (today's default).
/// [onEdgeTap] and [onFocusChangeRequested] are not invoked by
/// [ProvenanceTreeViewer] until edge hit-testing lands in a follow-on
/// change — downstream packages may call them from composed handlers.
abstract class ProvenanceInteractionHandler {
  void onNodeTap(
    final ProvenanceNode node, {
    final NodeDecoration? decoration,
  });

  void onEdgeTap(
    final ProvenanceEdge edge, {
    final EdgeDecoration? decoration,
  });

  void onBadgeTap(
    final String nodeId,
    final String badgeId, {
    final Object? payload,
  });

  void onIconTap(
    final String nodeId,
    final String iconId, {
    final Object? payload,
  });

  void onFocusChangeRequested(final String nodeId);
}

/// Runs [onSelect] before forwarding to [delegate] so composite viewers
/// keep detail-panel state in sync.
class ComposingProvenanceInteractionHandler
    implements ProvenanceInteractionHandler {
  ComposingProvenanceInteractionHandler({
    required this.delegate,
    required this.onSelect,
  });

  final ProvenanceInteractionHandler delegate;
  final ValueChanged<ProvenanceNode> onSelect;

  @override
  void onNodeTap(
    final ProvenanceNode node, {
    final NodeDecoration? decoration,
  }) {
    onSelect(node);
    delegate.onNodeTap(node, decoration: decoration);
  }

  @override
  void onEdgeTap(
    final ProvenanceEdge edge, {
    final EdgeDecoration? decoration,
  }) =>
      delegate.onEdgeTap(edge, decoration: decoration);

  @override
  void onBadgeTap(
    final String nodeId,
    final String badgeId, {
    final Object? payload,
  }) =>
      delegate.onBadgeTap(nodeId, badgeId, payload: payload);

  @override
  void onIconTap(
    final String nodeId,
    final String iconId, {
    final Object? payload,
  }) =>
      delegate.onIconTap(nodeId, iconId, payload: payload);

  @override
  void onFocusChangeRequested(final String nodeId) =>
      delegate.onFocusChangeRequested(nodeId);
}

/// Wraps the default node card with host-controlled chrome.
typedef ProvenanceNodeDecorator =
    Widget Function(
      BuildContext context, {
      required ProvenanceNode node,
      required NodeDecoration? decoration,
      required List<GraphHighlight> highlights,
      required bool isSelected,
      required Widget child,
    });

/// Optional edge paint hook after default stroke resolution.
typedef ProvenanceEdgeDecorator =
    void Function(
      Canvas canvas,
      ProvenanceEdge edge,
      EdgeDecoration? decoration,
      List<GraphHighlight> highlights,
      EdgeLineGeometry line,
    );

/// Edge geometry passed to [ProvenanceEdgeDecorator].
class EdgeLineGeometry {
  const EdgeLineGeometry({
    required this.parentId,
    required this.childId,
    required this.from,
    required this.to,
  });

  final String parentId;
  final String childId;
  final Offset from;
  final Offset to;
}
