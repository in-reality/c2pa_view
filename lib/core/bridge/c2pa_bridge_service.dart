import 'dart:convert';
import 'dart:io';

import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/src/rust/api/c2pa.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over raw FFI calls to the Rust C2PA bridge.
///
/// Provides convenient methods for loading [ManifestStore] instances from
/// files, URLs, or raw bytes. When [trustAnchorsPem] is provided, validation
/// runs against that trust list; otherwise the default (no trust list) is used.
class C2paBridgeService {
  /// Get raw manifest JSON from a local file path.
  static String? getManifestJsonFromFile(
    final String path, {
    final String? trustAnchorsPem,
  }) {
    final file = File(path);
    if (trustAnchorsPem != null) {
      return getManifestWithTrustValidationFromPath(
        fileBytes: file.readAsBytesSync(),
        path: file.path,
        trustAnchorsPem: trustAnchorsPem,
      );
    }
    return getManifestWithValidationFromPath(
      fileBytes: file.readAsBytesSync(),
      path: file.path,
    );
  }

  /// Get raw manifest JSON from a URL.
  static Future<String?> getManifestJsonFromUrl(
    final String url, {
    final String? format,
    final String? trustAnchorsPem,
  }) async {
    final response = await http.get(Uri.parse(url));
    final mimeType =
        response.headers['content-type'] ?? format ?? 'image/jpeg';
    if (trustAnchorsPem != null) {
      return getManifestWithTrustValidation(
        fileBytes: response.bodyBytes,
        format: mimeType,
        trustAnchorsPem: trustAnchorsPem,
      );
    }
    return getManifestWithValidation(
      fileBytes: response.bodyBytes,
      format: mimeType,
    );
  }

  /// Get raw manifest JSON from bytes.
  static String? getManifestJsonFromBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
  }) {
    if (trustAnchorsPem != null) {
      return getManifestWithTrustValidation(
        fileBytes: fileBytes,
        format: format,
        trustAnchorsPem: trustAnchorsPem,
      );
    }
    return getManifestWithValidation(fileBytes: fileBytes, format: format);
  }

  /// Load a [ManifestStore] from a local file path.
  static ManifestStore? loadFromFile(
    final String path, {
    final String? trustAnchorsPem,
  }) {
    final json =
        getManifestJsonFromFile(path, trustAnchorsPem: trustAnchorsPem);
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
  }) async {
    final json = await getManifestJsonFromUrl(
      url,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }

  /// Load a [ManifestStore] from raw bytes.
  static ManifestStore? loadFromBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
  }) {
    final json = getManifestJsonFromBytes(
      fileBytes: fileBytes,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
    );
    if (json == null) {
      return null;
    }
    return ManifestStore.fromJson(jsonDecode(json));
  }
}
