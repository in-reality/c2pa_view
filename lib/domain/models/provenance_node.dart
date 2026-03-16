import 'package:flutter/widgets.dart';

import 'manifest_summary.dart';
import 'manifest_view_data.dart';
import 'validation_result.dart';

/// A node in the provenance tree.
///
/// Each node represents an asset (the main asset or one of its ingredients)
/// and its credential status. The tree is built from a C2PA manifest store
/// where the root is the active manifest and children are its ingredients,
/// recursively.
@immutable
class ProvenanceNode {
  final String id;
  final ManifestSummary summary;
  final DateTime? signedDate;
  final List<ProvenanceNode> children;

  /// The full manifest view data for this node, used when the user
  /// selects this node to show its details in the sidebar.
  final ManifestViewData? manifestViewData;

  const ProvenanceNode({
    required this.id,
    this.summary = const ManifestSummary(),
    this.signedDate,
    this.children = const [],
    this.manifestViewData,
  });

  // Convenience accessors so call-sites that read these fields individually
  // keep working without change.
  String? get title => summary.title;
  ImageProvider? get thumbnail => summary.thumbnail;
  ValidationResult get validationResult => summary.validationResult;
  String? get issuer => summary.issuer;

  bool get hasChildren => children.isNotEmpty;

  int get totalDescendants {
    var count = children.length;
    for (final child in children) {
      count += child.totalDescendants;
    }
    return count;
  }

  /// Flatten the tree to a list (depth-first).
  List<ProvenanceNode> flatten() {
    final result = <ProvenanceNode>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }
}
