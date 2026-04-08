import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/widgets.dart';

/// A node in the provenance DAG.
///
/// Each node represents an asset (the main asset or one of its ingredients)
/// and its credential status. Nodes appear exactly once in the graph even when
/// multiple parents reference the same manifest as an ingredient.
@immutable
class ProvenanceNode {

  const ProvenanceNode({
    required this.id,
    this.summary = const ManifestSummary(),
    this.signedDate,
    this.manifestViewData,
  });
  final String id;
  final ManifestSummary summary;
  final DateTime? signedDate;

  /// The full manifest view data for this node, used when the user
  /// selects this node to show its details in the sidebar.
  final ManifestViewData? manifestViewData;

  String? get title => summary.title;
  ImageProvider? get thumbnail => summary.thumbnail;
  ValidationResult get validationResult => summary.validationResult;
  String? get issuer => summary.issuer;
}

/// A directed edge in the provenance DAG (parent references child as
/// ingredient).
@immutable
class ProvenanceEdge {

  const ProvenanceEdge({required this.parentId, required this.childId});
  final String parentId;
  final String childId;
}

/// A directed acyclic graph of [ProvenanceNode]s.
///
/// Unlike a tree, a node may have multiple parents (when the same manifest is
/// an ingredient of more than one parent).  Each node appears exactly once in
/// [nodes]; relationships are expressed through [edges].
@immutable
class ProvenanceGraph {

  const ProvenanceGraph({
    required this.rootId,
    required this.nodes,
    required this.edges,
  });
  final String rootId;
  final Map<String, ProvenanceNode> nodes;
  final List<ProvenanceEdge> edges;

  ProvenanceNode? get rootNode => nodes[rootId];

  ProvenanceNode? findNode(final String id) => nodes[id];

  /// All child IDs for a given parent.
  List<String> childIdsOf(final String parentId) =>
      edges.where((final e) => e.parentId == parentId).map((final e) => e.childId).toList();

  /// All parent IDs for a given child.
  List<String> parentIdsOf(final String childId) =>
      edges.where((final e) => e.childId == childId).map((final e) => e.parentId).toList();

  bool hasChildren(final String nodeId) => edges.any((final e) => e.parentId == nodeId);
}
