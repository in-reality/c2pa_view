import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:c2pa_view/src/rust/api/c2pa.dart';

/// Get the manifest from a file
String getC2PAManifest(dynamic source) {
  // source must be either path String or File
  if (source is! String && source is! File) {
    throw ArgumentError('source must be either path String or File');
  }

  // File
  File? file;

  // If path, then load to File
  if (source is String) {
    file = File(source);
  } else {
    file = source as File;
  }

  // Get manifest
  return getFileManifest(fileBytes: file.readAsBytesSync(), path: file.path);
}

/// Get the manifest from a URL
/// Optionally specify the format (mime type) if not in the header
Future<String> getC2PAManifestURL(String url, {String? format}) async {
  // Download from url
  final response = await http.get(Uri.parse(url));

  // Get manifest
  return getFileManifestFormat(
    fileBytes: response.bodyBytes,
    format: response.headers['content-type'] ?? format ?? 'image/jpeg',
  );
}

/// Get the manifest from bytes and format (mime type)
String getC2PAManifestBytes({
  required List<int> fileBytes,
  required String format,
}) {
  return getFileManifestFormat(fileBytes: fileBytes, format: format);
}
