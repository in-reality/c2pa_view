import 'dart:convert';

import 'package:c2pa_view/api.dart' as api;
import 'package:c2pa_view/domain/entities/manifest_store.dart';

/// Thin wrapper over raw FFI calls to the Rust C2PA bridge.
///
/// Provides convenient methods for loading [ManifestStore] instances from
/// files, URLs, or raw bytes. When `trustAnchorsPem`, `timestampTrustAnchorsPem` and/or `allowedListPem`
/// is provided, validation runs against those PEM bundles; otherwise the
/// default (no trust list) is used.
class C2paBridgeService {
  /// Get raw manifest JSON from a local file path.
  static Future<String?> getManifestJsonFromFile(
    final String path, {
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async => api.getManifestJsonFromFile(
    path,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );

  /// Get raw manifest JSON from a URL.
  static Future<String?> getManifestJsonFromUrl(
    final String url, {
    final String? format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async => api.getManifestJsonFromURL(
    url,
    format: format,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );

  /// Get raw manifest JSON from bytes.
  static Future<String?> getManifestJsonFromBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async => api.getManifestJsonFromBytes(
    fileBytes: fileBytes,
    format: format,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );

  /// Load a [ManifestStore] from a local file path.
  static Future<ManifestStore?> loadFromFile(
    final String path, {
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromFile(
      path,
      trustAnchorsPem: trustAnchorsPem,
      timestampTrustAnchorsPem: timestampTrustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }

  /// Load a [ManifestStore] from a URL.
  static Future<ManifestStore?> loadFromUrl(
    final String url, {
    final String? format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromUrl(
      url,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
      timestampTrustAnchorsPem: timestampTrustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }

  /// Load a [ManifestStore] from raw bytes.
  static Future<ManifestStore?> loadFromBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromBytes(
      fileBytes: fileBytes,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
      timestampTrustAnchorsPem: timestampTrustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }
}
