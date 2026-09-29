import 'dart:convert';

import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/src/rust/api/c2pa.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over raw FFI calls to the Rust C2PA bridge.
///
/// Provides convenient methods for loading [ManifestStore] instances from
/// files, URLs, or raw bytes. When [trustAnchorsPem] and/or [allowedListPem]
/// is provided, validation runs against those PEM bundles; otherwise the
/// default (no trust list) is used.
class C2paBridgeService {
  /// Get raw manifest JSON from a local file path.
  static Future<String?> getManifestJsonFromFile(
    final String path, {
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    if (_hasTrustMaterial(
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    )) {
      return getManifestWithTrustValidationFromPathAllowList(
        path: path,
        trustAnchorsPem: trustAnchorsPem ?? '',
        allowedListPem: allowedListPem,
      );
    }
    return getManifestWithValidationFromPath(path: path);
  }

  /// Get raw manifest JSON from a URL.
  static Future<String?> getManifestJsonFromUrl(
    final String url, {
    final String? format,
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final response = await http.get(Uri.parse(url));
    final mimeType =
        response.headers['content-type'] ?? format ?? 'image/jpeg';
    if (_hasTrustMaterial(
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    )) {
      return getManifestWithTrustValidationAllowList(
        fileBytes: response.bodyBytes,
        format: mimeType,
        trustAnchorsPem: trustAnchorsPem ?? '',
        allowedListPem: allowedListPem,
      );
    }
    return getManifestWithValidation(
      fileBytes: response.bodyBytes,
      format: mimeType,
    );
  }

  /// Get raw manifest JSON from bytes.
  static Future<String?> getManifestJsonFromBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    if (_hasTrustMaterial(
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    )) {
      return getManifestWithTrustValidationAllowList(
        fileBytes: fileBytes,
        format: format,
        trustAnchorsPem: trustAnchorsPem ?? '',
        allowedListPem: allowedListPem,
      );
    }
    return getManifestWithValidation(fileBytes: fileBytes, format: format);
  }

  /// Load a [ManifestStore] from a local file path.
  static Future<ManifestStore?> loadFromFile(
    final String path, {
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromFile(
      path,
      trustAnchorsPem: trustAnchorsPem,
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
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromUrl(
      url,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
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
    final String? allowedListPem,
  }) async {
    final json = await getManifestJsonFromBytes(
      fileBytes: fileBytes,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
      allowedListPem: allowedListPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }

  static bool _hasTrustMaterial({
    final String? trustAnchorsPem,
    final String? allowedListPem,
  }) =>
      (trustAnchorsPem != null && trustAnchorsPem.isNotEmpty) ||
      (allowedListPem != null && allowedListPem.isNotEmpty);
}
