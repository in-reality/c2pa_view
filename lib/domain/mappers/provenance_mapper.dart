import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';

/// Converts a [ManifestStore] into a [ProvenanceNode] tree.
class ProvenanceMapper {
  /// Build a provenance tree from a ManifestStore.
  ///
  /// The root node is the active manifest's asset.
  /// Children are ingredients, resolved recursively through the manifest store.
  static ProvenanceNode mapToTree(ManifestStore store) {
    final activeLabel = store.activeManifest;
    final activeManifest =
        activeLabel != null ? store.manifests[activeLabel] : null;
    if (activeManifest == null) {
      throw StateError('No active manifest found in the manifest store');
    }

    // Build summaries for every manifest in the store up-front.
    // This is the single computation point for thumbnail + validation result
    // per manifest.  Both the tree node and the ingredient list item for the
    // same manifest will read from this map.
    final summaries = _buildSummaries(store);

    return _buildNode(
      manifest: activeManifest,
      label: activeLabel!,
      store: store,
      summaries: summaries,
      visited: {},
    );
  }

  /// Pre-compute a [ManifestSummary] for every manifest in [store].
  static Map<String, ManifestSummary> _buildSummaries(ManifestStore store) {
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
        validationResult:
            ManifestViewDataMapper.mapValidation(manifest.validationStatus),
        issuer: manifest.signatureInfo?.issuer,
      );
    }
    return result;
  }

  static ProvenanceNode _buildNode({
    required Manifest manifest,
    required String label,
    required ManifestStore store,
    required Map<String, ManifestSummary> summaries,
    required Set<String> visited,
  }) {
    visited.add(label);

    final children = <ProvenanceNode>[];
    for (final ingredient in manifest.ingredients) {
      if (ingredient.activeManifest != null &&
          !visited.contains(ingredient.activeManifest)) {
        final childManifest = store.manifests[ingredient.activeManifest];
        if (childManifest != null) {
          children.add(_buildNode(
            manifest: childManifest,
            label: ingredient.activeManifest!,
            store: store,
            summaries: summaries,
            visited: visited,
          ));
        }
      } else {
        // Use a parent-scoped ID to guarantee uniqueness across the whole tree.
        // ingredient.label is unique within its parent manifest (e.g.
        // "c2pa.ingredient", "c2pa.ingredient__1"), so prefixing with the
        // parent's label makes it globally unique.
        final leafId =
            '$label/${ingredient.label ?? ingredient.title ?? 'unknown'}';
        children.add(ProvenanceNode(
          id: leafId,
          summary: ManifestSummary(
            title: ingredient.title,
            validationResult: const ValidationResult.noCredential(),
          ),
        ));
      }
    }

    final rawJson = store.rawManifestJsons[label];
    final viewData = ManifestViewDataMapper.map(
      manifest,
      rawJson: rawJson,
      summaries: summaries,
    );

    return ProvenanceNode(
      id: label,
      summary: summaries[label] ??
          ManifestSummary(
            title: manifest.title,
            validationResult:
                ManifestViewDataMapper.mapValidation(manifest.validationStatus),
            issuer: manifest.signatureInfo?.issuer,
          ),
      signedDate: manifest.signatureInfo?.time,
      children: children,
      manifestViewData: viewData,
    );
  }
}
