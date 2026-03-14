import 'package:flutter/widgets.dart';

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
  final String? title;
  final ImageProvider? thumbnail;
  final ValidationResult validationResult;
  final String? issuer;
  final DateTime? signedDate;
  final List<ProvenanceNode> children;

  /// The full manifest view data for this node, used when the user
  /// selects this node to show its details in the sidebar.
  final ManifestViewData? manifestViewData;

  const ProvenanceNode({
    required this.id,
    this.title,
    this.thumbnail,
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
    this.signedDate,
    this.children = const [],
    this.manifestViewData,
  });

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
