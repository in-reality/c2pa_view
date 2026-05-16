import 'dart:io';

import 'package:c2pa_view/src/rust/api/c2pa.dart';
import 'package:http/http.dart' as http;

/// Get the manifest from a file.
///
/// When [trustAnchorsPem] is provided, validation runs against that trust
/// list (concatenated C2PA CA + TSA PEM bundle); otherwise the underlying
/// `c2pa-rs` defaults are used and certificates report as `untrusted`.
// ignore: type_annotate_public_apis
String? getManifestJsonFromFile(
  final String path, {
  final String? trustAnchorsPem,
}) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  if (trustAnchorsPem != null && trustAnchorsPem.isNotEmpty) {
    return getManifestWithTrustValidationFromPath(
      fileBytes: bytes,
      path: file.path,
      trustAnchorsPem: trustAnchorsPem,
    );
  }
  return getManifestWithValidationFromPath(
    fileBytes: bytes,
    path: file.path,
  );
}

/// Get the manifest from a URL.
///
/// Optionally specify the format (mime type) if not in the header.
/// See [getManifestJsonFromFile] for the meaning of [trustAnchorsPem].
Future<String?> getManifestJsonFromURL(
  final String url, {
  final String? format,
  final String? trustAnchorsPem,
}) async {
  final response = await http.get(Uri.parse(url));
  final mime = response.headers['content-type'] ?? format ?? 'image/jpeg';
  if (trustAnchorsPem != null && trustAnchorsPem.isNotEmpty) {
    return getManifestWithTrustValidation(
      fileBytes: response.bodyBytes,
      format: mime,
      trustAnchorsPem: trustAnchorsPem,
    );
  }
  return getManifestWithValidation(
    fileBytes: response.bodyBytes,
    format: mime,
  );
}

/// Get the manifest from bytes and format (mime type).
///
/// See [getManifestJsonFromFile] for the meaning of [trustAnchorsPem].
String? getManifestJsonFromBytes({
  required final List<int> fileBytes,
  required final String format,
  final String? trustAnchorsPem,
}) {
  if (trustAnchorsPem != null && trustAnchorsPem.isNotEmpty) {
    return getManifestWithTrustValidation(
      fileBytes: fileBytes,
      format: format,
      trustAnchorsPem: trustAnchorsPem,
    );
  }
  return getManifestWithValidation(fileBytes: fileBytes, format: format);
}
