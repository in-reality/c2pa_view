import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
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

    return _buildNode(
      manifest: activeManifest,
      label: activeLabel!,
      store: store,
      visited: {},
    );
  }

  static ProvenanceNode _buildNode({
    required Manifest manifest,
    required String label,
    required ManifestStore store,
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
            visited: visited,
          ));
        }
      } else {
        children.add(ProvenanceNode(
          id: ingredient.label ?? ingredient.title ?? 'unknown',
          title: ingredient.title,
          validationResult: const ValidationResult.noCredential(),
        ));
      }
    }

    final rawJson = store.rawManifestJsons[label];
    final viewData = ManifestViewDataMapper.map(manifest, rawJson: rawJson);

    return ProvenanceNode(
      id: label,
      title: manifest.title,
      thumbnail: viewData.thumbnail,
      validationResult:
          ManifestViewDataMapper.mapValidation(manifest.validationStatus),
      issuer: manifest.signatureInfo?.issuer,
      signedDate: manifest.signatureInfo?.time,
      children: children,
      manifestViewData: viewData,
    );
  }
}
