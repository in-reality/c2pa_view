
import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:equatable/equatable.dart';

/// Root domain entity representing a C2PA Content Credential Manifest store
class ManifestStore extends Equatable {

  /// Creates a new instance of [ManifestStore].
  const ManifestStore({
    this.activeManifest,
    this.manifests = const {},
  });

  /// Creates a ManifestStore from a JSON map.
  factory ManifestStore.fromJson(final Map<String, dynamic> json) =>
    ManifestStore(
      activeManifest: json['active_manifest'] as String?,
      manifests: (json['manifests'] as Map<String, dynamic>?)?.map(
        (final k, final e) => MapEntry(
          k,
          Manifest.fromJson(e as Map<String, dynamic>),
        ),
      ) ?? {},
    );
  /// A label for the active (most recent) manifest in the store
  final String? activeManifest;

  /// A HashMap of Manifests
  final Map<String, Manifest> manifests;

  @override
  List<Object?> get props => [
    activeManifest,
    manifests,
  ];
}
