import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';

/// Converts a [ManifestStore] into a [ProvenanceGraph].
class ProvenanceMapper {
  /// Build a provenance DAG from a ManifestStore.
  ///
  /// Each manifest appears as exactly one [ProvenanceNode].  When the same
  /// manifest is an ingredient of multiple parents, it simply has multiple
  /// incoming [ProvenanceEdge]s rather than being duplicated.
  static ProvenanceGraph mapToGraph(final ManifestStore store) {
    final activeLabel = store.activeManifest;
    final activeManifest =
        activeLabel != null ? store.manifests[activeLabel] : null;
    if (activeManifest == null) {
      throw StateError('No active manifest found in the manifest store');
    }

    final summaries = _buildSummaries(store);

    final nodes = <String, ProvenanceNode>{};
    final edges = <ProvenanceEdge>[];

    _walk(
      label: activeLabel!,
      store: store,
      summaries: summaries,
      nodes: nodes,
      edges: edges,
    );

    return ProvenanceGraph(rootId: activeLabel, nodes: nodes, edges: edges);
  }

  /// Pre-compute a [ManifestSummary] for every manifest in [store].
  static Map<String, ManifestSummary> _buildSummaries(final ManifestStore store) {
    final result = <String, ManifestSummary>{};
    for (final entry in store.manifests.entries) {
      final manifest = entry.value;
      final viewData = ManifestViewDataMapper.map(
        manifest,
        rawJson: store.rawManifestJsons[entry.key],
      );
      result[entry.key] = ManifestSummary(
        title: manifest.title,
        thumbnail: viewData.thumbnail,
        validationResult: ManifestViewDataMapper.mapValidation(
          manifest.validationStatus,
        ),
        issuer: manifest.signatureInfo?.issuer,
      );
    }
    return result;
  }

  /// Recursively walk the manifest graph, creating nodes and edges.
  ///
  /// If a manifest has already been visited (its node exists in [nodes]),
  /// we still add an edge from the current parent but do **not** recurse
  /// into it again.
  static void _walk({
    required final String label,
    required final ManifestStore store,
    required final Map<String, ManifestSummary> summaries,
    required final Map<String, ProvenanceNode> nodes,
    required final List<ProvenanceEdge> edges,
    final String? parentLabel,
  }) {
    final manifest = store.manifests[label];
    if (manifest == null) {
      return;
    }

    // Add edge from parent (if any).
    if (parentLabel != null) {
      edges.add(ProvenanceEdge(parentId: parentLabel, childId: label));
    }

    // If we already created this node, stop recursion to avoid infinite loops.
    if (nodes.containsKey(label)) {
      return;
    }

    // Build the full view data for the detail panel.
    final rawJson = store.rawManifestJsons[label];
    final viewData = ManifestViewDataMapper.map(
      manifest,
      rawJson: rawJson,
      summaries: summaries,
    );

    nodes[label] = ProvenanceNode(
      id: label,
      summary:
          summaries[label] ??
          ManifestSummary(
            title: manifest.title,
            validationResult: ManifestViewDataMapper.mapValidation(
              manifest.validationStatus,
            ),
            issuer: manifest.signatureInfo?.issuer,
          ),
      signedDate: manifest.signatureInfo?.time,
      manifestViewData: viewData,
    );

    // Recurse into ingredients.
    for (final ingredient in manifest.ingredients) {
      final childLabel = ingredient.activeManifest;
      if (childLabel != null && store.manifests.containsKey(childLabel)) {
        _walk(
          label: childLabel,
          store: store,
          summaries: summaries,
          nodes: nodes,
          edges: edges,
          parentLabel: label,
        );
      } else {
        // Unresolvable ingredient — create a unique leaf node.
        final leafId =
            '$label/${ingredient.label ?? ingredient.title ?? 'unknown'}';
        if (!nodes.containsKey(leafId)) {
          nodes[leafId] = ProvenanceNode(
            id: leafId,
            summary: ManifestSummary(
              title: ingredient.title,
            ),
          );
        }
        edges.add(ProvenanceEdge(parentId: label, childId: leafId));
      }
    }
  }
}
