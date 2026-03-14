import 'dart:convert';
import 'dart:io';

import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/src/rust/api/c2pa.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over raw FFI calls to the Rust C2PA bridge.
///
/// Provides convenient methods for loading [ManifestStore] instances from
/// files, URLs, or raw bytes.
class C2paBridgeService {
  /// Get raw manifest JSON from a local file path.
  static String? getManifestJsonFromFile(String path) {
    final file = File(path);
    return getManifestWithValidationFromPath(
      fileBytes: file.readAsBytesSync(),
      path: file.path,
    );
  }

  /// Get raw manifest JSON from a URL.
  static Future<String?> getManifestJsonFromUrl(
    String url, {
    String? format,
  }) async {
    final response = await http.get(Uri.parse(url));
    return getManifestWithValidation(
      fileBytes: response.bodyBytes,
      format: response.headers['content-type'] ?? format ?? 'image/jpeg',
    );
  }

  /// Get raw manifest JSON from bytes.
  static String? getManifestJsonFromBytes({
    required List<int> fileBytes,
    required String format,
  }) =>
      getManifestWithValidation(fileBytes: fileBytes, format: format);

  /// Load a [ManifestStore] from a local file path.
  static ManifestStore? loadFromFile(String path) {
    final json = getManifestJsonFromFile(path);
    if (json == null) return null;
    return ManifestStore.fromJson(jsonDecode(json));
  }

  /// Load a [ManifestStore] from a URL.
  static Future<ManifestStore?> loadFromUrl(
    String url, {
    String? format,
  }) async {
    final json = await getManifestJsonFromUrl(url, format: format);
    if (json == null) return null;
    return ManifestStore.fromJson(jsonDecode(json));
  }

  /// Load a [ManifestStore] from raw bytes.
  static ManifestStore? loadFromBytes({
    required List<int> fileBytes,
    required String format,
  }) {
    final json = getManifestJsonFromBytes(fileBytes: fileBytes, format: format);
    if (json == null) return null;
    return ManifestStore.fromJson(jsonDecode(json));
  }
}
