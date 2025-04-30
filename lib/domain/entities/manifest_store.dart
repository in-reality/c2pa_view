import 'dart:convert';
import 'package:c2pa_view/api.dart';
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

  /// Creates a ManifestStore from a local file path
  static ManifestStore? fromLocalPath(final String localPath) {
    // Get manifest from file bytes
    final manifestJson = getManifestJsonFromFile(
      localPath,
    );

    // Check that the manifest was found
    if (manifestJson == null) {
      return null;
    }

    // Parse and return ManifestStore
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from a URL
  static Future<ManifestStore?> fromUrl(
    final String url,
    {final String? format,}
  ) async {
    // Get manifest from file bytes
    final manifestJson = await getManifestJsonFromURL(
      url,
      format: format,
    );

    // Check that the manifest was found
    if (manifestJson == null) {
      return null;
    }

    // Parse and return ManifestStore
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from raw bytes
  static ManifestStore? fromBytes(
      final List<int> fileBytes,
      final String format,
    ) {
    // Get manifest from file bytes
    final manifestJson = getManifestJsonFromBytes(
      fileBytes: fileBytes,
      format: format,
    );

    // Check that the manifest was found
    if (manifestJson == null) {
      return null;
    }

    // Parse and return ManifestStore
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

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
