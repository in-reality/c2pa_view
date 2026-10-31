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
    this.previewResourcesTruncated = false,
  });

  /// Creates a ManifestStore from a JSON map.
  factory ManifestStore.fromJson(final Map<String, dynamic> json) {
    // Use the same normalized collection for attribution and final loading.
    // Non-map values are skipped once; strict key/Manifest parsing failures
    // still reject the whole store, as before, rather than silently disappearing.
    final rawManifestJsons = <String, Map<String, dynamic>>{};
    final manifestsJson = json['manifests'];
    if (manifestsJson is Map) {
      for (final entry in manifestsJson.entries) {
        final raw = entry.value;
        if (raw is Map) {
          rawManifestJsons[entry.key] = Map<String, dynamic>.from(raw);
        }
      }
    }

    final rawValidation = json['validation_status'];
    // A non-list container must remain an invalid row, even if its map happens
    // to look like a status. Do not coerce malformed containers into valid rows.
    final rawEntries = rawValidation is List
        ? rawValidation
        : rawValidation == null
        ? const <dynamic>[]
        : <dynamic>[
            [rawValidation],
          ];
    final topLevelValidation = <ValidationStatusEntry>[];
    final activeLabel = json['active_manifest'] as String?;

    // Preserve every raw row through attribution, including malformed rows.
    // Otherwise filtering here could turn partial diagnostics into a clean
    // computed claim list. Unattributable rows retain the active-claim fallback.
    final perManifestValidation = <String, List<dynamic>>{};
    for (final item in rawEntries) {
      ValidationStatusEntry? parsed;
      // Public top-level evidence contains only rows the strict entry parser
      // can read. Keep unmatched successes here without attesting another claim.
      if (item is Map<String, dynamic> &&
          item['code'] is String &&
          (item['code'] as String).trim().isNotEmpty &&
          (item['url'] == null || item['url'] is String) &&
          (item['explanation'] == null || item['explanation'] is String)) {
        parsed = ValidationStatusEntry.fromJson(item);
        topLevelValidation.add(parsed);
      }
      final rawUrl = item is Map ? item['url'] : null;
      final manifestLabel = _extractManifestLabel(
        rawUrl is String ? rawUrl : null,
      );
      final target =
          manifestLabel != null && rawManifestJsons.containsKey(manifestLabel)
          ? manifestLabel
          : null;
      if (manifestLabel != null &&
          target == null &&
          parsed != null &&
          !parsed.isError &&
          !parsed.isUntrusted) {
        // A claim-specific success for an unloaded target cannot verify the
        // active claim. Do not create an empty computed-clean active bucket.
        continue;
      }
      final key = target ?? activeLabel ?? '';
      perManifestValidation.putIfAbsent(key, () => []).add(item);
    }

    final manifests = <String, Manifest>{};
    for (final entry in rawManifestJsons.entries) {
      final manifestJson = entry.value;
      // Merge attributed evidence without losing malformed-row completeness.
      final entries = perManifestValidation[entry.key];
      if (entries != null && entries.isNotEmpty) {
        manifestJson['validation_status'] = [
          if (manifestJson['validation_status'] is List)
            ...manifestJson['validation_status'] as List
          else if (manifestJson['validation_status'] != null)
            [manifestJson['validation_status']],
          ...entries,
        ];
      }
      manifests[entry.key] = Manifest.fromJson(
        manifestJson,
        previewsTruncated: json['preview_resources_truncated'] == true,
      );
    }

    return ManifestStore(
      activeManifest: activeLabel,
      manifests: manifests,
      rawManifestJsons: rawManifestJsons,
      validationStatus: topLevelValidation,
      previewResourcesTruncated: json['preview_resources_truncated'] == true,
    );
  }

  /// Extracts the manifest label from a C2PA JUMBF URL.
  ///
  /// Input: `self#jumbf=/c2pa/contentauth:urn:uuid:XXXX/c2pa.signature`
  /// Output: `contentauth:urn:uuid:XXXX`
  static String? _extractManifestLabel(final String? url) {
    if (url == null) {
      return null;
    }
    // Find the /c2pa/ prefix in the fragment or path.
    const prefix = '/c2pa/';
    final idx = url.indexOf(prefix);
    if (idx == -1) {
      return null;
    }
    final afterPrefix = url.substring(idx + prefix.length);
    // The manifest label ends at the next '/' (if present).
    final slashIdx = afterPrefix.indexOf('/');
    return slashIdx == -1 ? afterPrefix : afterPrefix.substring(0, slashIdx);
  }

  /// Creates a ManifestStore from a local file path.
  ///
  /// When [trustAnchorsPem] and/or [allowedListPem] is provided, validation
  /// runs against those PEM bundles (CA anchors and end-entity allow-list);
  /// otherwise the underlying `c2pa-rs` defaults are used and certificates
  /// report as `untrusted`.
  static Future<ManifestStore?> fromLocalPath(
    final String localPath, {
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final manifestJson = await getManifestJsonFromFile(
      localPath,
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (manifestJson == null) {
      return null;
    }
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from a URL.
  ///
  /// See [fromLocalPath] for the meaning of [trustAnchorsPem] /
  /// [allowedListPem].
  static Future<ManifestStore?> fromUrl(
    final String url, {
    final String? format,
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final manifestJson = await getManifestJsonFromURL(
      url,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (manifestJson == null) {
      return null;
    }
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from raw bytes.
  ///
  /// See [fromLocalPath] for the meaning of [trustAnchorsPem] /
  /// [allowedListPem].
  static Future<ManifestStore?> fromBytes(
    final List<int> fileBytes,
    final String format, {
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final manifestJson = await getManifestJsonFromBytes(
      fileBytes: fileBytes,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (manifestJson == null) {
      return null;
    }
    return ManifestStore.fromJson(json.decode(manifestJson));
  }

  /// Creates a ManifestStore from a detached sidecar plus bound asset bytes.
  ///
  /// Validates hash binding and signatures the same way as [fromBytes] does
  /// for embedded manifests. [manifestFormat] must be a manifest-store MIME;
  /// defaults to `application/c2pa`.
  /// See [fromLocalPath] for the meaning of [trustAnchorsPem] /
  /// [allowedListPem].
  static Future<ManifestStore?> fromDetached({
    required final List<int> manifestBytes,
    required final List<int> assetBytes,
    required final String assetFormat,
    final String manifestFormat = 'application/c2pa',
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final manifestJson = await getDetachedManifestJsonFromBytes(
      manifestBytes: manifestBytes,
      assetBytes: assetBytes,
      assetFormat: assetFormat,
      manifestFormat: manifestFormat,
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (manifestJson == null) {
      return null;
    }
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

  /// Preview traversal/augmentation limit reached; unvisited references use limit.
  final bool previewResourcesTruncated;

  @override
  List<Object?> get props => [
    activeManifest,
    manifests,
    validationStatus,
    previewResourcesTruncated,
  ];
}
