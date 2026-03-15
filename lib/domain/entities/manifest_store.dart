import 'dart:convert';

import 'package:c2pa_view/api.dart';
import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:equatable/equatable.dart';

/// Root domain entity representing a C2PA Content Credential Manifest store.
class ManifestStore extends Equatable {
  const ManifestStore({
    this.activeManifest,
    this.manifests = const {},
    this.rawManifestJsons = const {},
    this.validationStatus = const [],
  });

  /// Creates a ManifestStore from a JSON map.
  factory ManifestStore.fromJson(final Map<String, dynamic> json) {
    // Parse top-level validation status
    final topLevelValidation = <ValidationStatusEntry>[];
    if (json['validation_status'] is List) {
      for (final item in json['validation_status'] as List) {
        if (item is Map<String, dynamic>) {
          topLevelValidation.add(ValidationStatusEntry.fromJson(item));
        }
      }
    }

    // Parse manifests, propagating top-level validation to the active manifest
    final activeLabel = json['active_manifest'] as String?;
    final rawManifestJsons = <String, Map<String, dynamic>>{};
    final manifests =
        (json['manifests'] as Map<String, dynamic>?)?.map((final k, final e) {
              final manifestJson = e as Map<String, dynamic>;
              // If this is the active manifest and it has no validation_status
              // but there is a top-level one, inject it.
              if (k == activeLabel &&
                  manifestJson['validation_status'] == null &&
                  topLevelValidation.isNotEmpty) {
                manifestJson['validation_status'] =
                    (json['validation_status'] as List);
              }
              rawManifestJsons[k] = manifestJson;
              return MapEntry(k, Manifest.fromJson(manifestJson));
            }) ??
            {};

    return ManifestStore(
      activeManifest: activeLabel,
      manifests: manifests,
      rawManifestJsons: rawManifestJsons,
      validationStatus: topLevelValidation,
    );
  }

  /// Creates a ManifestStore from a local file path.
  static ManifestStore? fromLocalPath(final String localPath) {
    final manifestJson = getManifestJsonFromFile(localPath);
    if (manifestJson == null) return null;
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from a URL.
  static Future<ManifestStore?> fromUrl(
    final String url, {
    final String? format,
  }) async {
    final manifestJson = await getManifestJsonFromURL(url, format: format);
    if (manifestJson == null) return null;
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from raw bytes.
  static ManifestStore? fromBytes(
    final List<int> fileBytes,
    final String format,
  ) {
    final manifestJson =
        getManifestJsonFromBytes(fileBytes: fileBytes, format: format);
    if (manifestJson == null) return null;
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// A label for the active (most recent) manifest in the store.
  final String? activeManifest;

  /// A HashMap of Manifests.
  final Map<String, Manifest> manifests;

  /// Raw JSON maps for each manifest, keyed by label.
  /// Used to allow callers to copy or inspect the unprocessed manifest data.
  final Map<String, Map<String, dynamic>> rawManifestJsons;

  /// Top-level validation status entries.
  final List<ValidationStatusEntry> validationStatus;

  @override
  List<Object?> get props => [activeManifest, manifests, validationStatus];
}
