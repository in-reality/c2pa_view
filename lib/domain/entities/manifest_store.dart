
import 'package:equatable/equatable.dart';

import 'manifest.dart';

/// Root domain entity representing a C2PA Content Credential Manifest store
class ManifestStore extends Equatable {
  /// A label for the active (most recent) manifest in the store
  final String? activeManifest;

  /// A HashMap of Manifests
  final Map<String, Manifest> manifests;

  const ManifestStore({
    this.activeManifest,
    this.manifests = const {},
  });

  /// Creates a ManifestStore from a JSON map.
  factory ManifestStore.fromJson(Map<String, dynamic> json) {
    return ManifestStore(
      activeManifest: json['active_manifest'] as String?,
      manifests: (json['manifests'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          Manifest.fromJson(e as Map<String, dynamic>),
        ),
      ) ?? {},
    );
  }

  @override
  List<Object?> get props => [
    activeManifest,
    manifests,
  ];
}
