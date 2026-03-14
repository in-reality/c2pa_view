import 'dart:io';

import 'package:c2pa_view/src/rust/api/c2pa.dart';
import 'package:http/http.dart' as http;

/// Get the manifest from a file
// ignore: type_annotate_public_apis
String? getManifestJsonFromFile(final String path) {
  final file = File(path);
  return getManifestWithValidationFromPath(
    fileBytes: file.readAsBytesSync(),
    path: file.path,
  );
}

/// Get the manifest from a URL
/// Optionally specify the format (mime type) if not in the header
Future<String?> getManifestJsonFromURL(
  final String url, {
  final String? format,
}) async {
  final response = await http.get(Uri.parse(url));
  return getManifestWithValidation(
    fileBytes: response.bodyBytes,
    format: response.headers['content-type'] ?? format ?? 'image/jpeg',
  );
}

/// Get the manifest from bytes and format (mime type)
String? getManifestJsonFromBytes({
  required final List<int> fileBytes,
  required final String format,
}) =>
    getManifestWithValidation(fileBytes: fileBytes, format: format);
