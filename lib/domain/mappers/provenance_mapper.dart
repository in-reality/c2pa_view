import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
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
    final activeManifest = activeLabel != null
        ? store.manifests[activeLabel]
        : null;
    if (activeManifest == null) {
      throw StateError('No active manifest found in the manifest store');
    }

    // When the active manifest is invalid we cannot trust its assertions
    // (including the ingredient list). Collapse the graph to a single root
    // node so the detail panel renders the tampered placeholder without
    // walking into potentially malformed ingredients.
    final activeResult = ManifestViewDataMapper.mapValidation(
      activeManifest.validationStatus,
      isComputed: activeManifest.validationStatusComputed,
    );
    if (activeResult.isInvalid) {
      final viewData = ManifestViewDataMapper.map(
        activeManifest,
        rawJson: store.rawManifestJsons[activeLabel],
        containingLabel: activeLabel,
      );
      final node = ProvenanceNode(
        id: activeLabel!,
        summary: ManifestSummary(
          title: activeManifest.title,
          thumbnail: viewData.thumbnail,
          previewSource: viewData.previewSource,
          ingredientDescriptions: viewData.ingredientDescriptions,
          validationResult: activeResult,
          issuer: activeManifest.signatureInfo?.issuer,
        ),
        signedDate: activeManifest.signatureInfo?.time,
        manifestViewData: viewData,
      );
      return ProvenanceGraph(
        rootId: activeLabel,
        nodes: {activeLabel: node},
        edges: const [],
      );
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
  static Map<String, ManifestSummary> _buildSummaries(
    final ManifestStore store,
  ) => ManifestViewDataMapper.buildSummaries(store);

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
      previewSummary: summaries[label],
      containingLabel: label,
    );

    nodes[label] = ProvenanceNode(
      id: label,
      summary:
          summaries[label] ??
          ManifestSummary(
            title: manifest.title,
            validationResult: ManifestViewDataMapper.mapValidation(
              manifest.validationStatus,
              isComputed: manifest.validationStatusComputed,
            ),
            issuer: manifest.signatureInfo?.issuer,
          ),
      signedDate: manifest.signatureInfo?.time,
      manifestViewData: viewData,
    );

    // Recurse into ingredients.
    for (var index = 0; index < manifest.ingredients.length; index++) {
      final ingredient = manifest.ingredients[index];
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
        final baseId =
            '$label/${ingredient.label ?? ingredient.title ?? 'unknown'}';
        var leafId = baseId;
        var collision = 0;
        while (nodes.containsKey(leafId)) {
          collision++;
          leafId = '$baseId/$index/$collision';
        }
        final summary = ManifestViewDataMapper.ingredientSummary(
          ingredient,
          manifest,
          containingLabel: label,
          ingredientIndex: index,
        );
        nodes[leafId] = ProvenanceNode(
          id: leafId,
          summary: summary,
          manifestViewData: ManifestViewData(
            title: summary.title,
            thumbnail: summary.thumbnail,
            previewSource: summary.previewSource,
            inputValidationEvidence: summary.inputValidationEvidence,
            ingredientDescriptions: summary.ingredientDescriptions,
            validationResult: summary.validationResult,
          ),
        );
        edges.add(ProvenanceEdge(parentId: label, childId: leafId));
      }
    }
  }
}
