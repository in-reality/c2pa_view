import 'package:c2pa_view/core/bridge/c2pa_backend.dart';
import 'package:http/http.dart' as http;

/// Get the manifest from a file.
///
/// When [trustAnchorsPem], [timestampTrustAnchorsPem] and/or [allowedListPem] is provided, validation
/// runs against those PEM bundles (Manifest anchors, separate TSA anchors and Manifest end-entity allow-list);
/// otherwise the underlying `c2pa-rs` defaults are used and certificates
/// report as `untrusted`.
// ignore: type_annotate_public_apis
Future<String?> getManifestJsonFromFile(
  final String path, {
  final String? trustAnchorsPem,
  final String? timestampTrustAnchorsPem,
  final String? allowedListPem,
}) async {
  await initializeC2paBackend();
  return c2paBackend.validatePath(
    path: path,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );
}

/// Get the manifest from a URL.
///
/// Optionally specify the format (mime type) if not in the header.
/// See [getManifestJsonFromFile] for the meaning of [trustAnchorsPem] /
/// [allowedListPem].
Future<String?> getManifestJsonFromURL(
  final String url, {
  final String? format,
  final String? trustAnchorsPem,
  final String? timestampTrustAnchorsPem,
  final String? allowedListPem,
}) async {
  // Select and initialize before network I/O so an in-flight or failed fetch
  // cannot leave execution ownership replaceable.
  await initializeC2paBackend();
  final response = await http.get(Uri.parse(url));
  final mime = response.headers['content-type'] ?? format ?? 'image/jpeg';
  return getManifestJsonFromBytes(
    fileBytes: response.bodyBytes,
    format: mime,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );
}

/// Get the manifest from bytes and format (mime type).
///
/// See [getManifestJsonFromFile] for the meaning of [trustAnchorsPem] /
/// [allowedListPem].
Future<String?> getManifestJsonFromBytes({
  required final List<int> fileBytes,
  required final String format,
  final String? trustAnchorsPem,
  final String? timestampTrustAnchorsPem,
  final String? allowedListPem,
}) async {
  await initializeC2paBackend();
  return c2paBackend.validateBytes(
    fileBytes: fileBytes,
    format: format,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );
}

/// Reads a detached C2PA manifest **store** (JUMBF bytes) without binding it
/// to an asset.
///
/// Hash binding and signature checks against the referenced media are **not**
/// performed (`verify_after_reading: false`). Prefer [getDetachedManifestJsonFromBytes]
/// when the sidecar must be validated against known asset bytes.
Future<String?> getManifestStoreJsonFromBytes({
  required final List<int> fileBytes,
  required final String format,
}) async {
  await initializeC2paBackend();
  return c2paBackend.readManifestStore(fileBytes: fileBytes, format: format);
}

/// Validates a detached manifest store against asset bytes.
///
/// [manifestBytes] is the sidecar JUMBF. [manifestFormat] must be a C2PA
/// manifest-store MIME (`application/c2pa` by default). [assetBytes] and
/// [assetFormat] are the bound media. When [trustAnchorsPem] and/or
/// [allowedListPem] is provided, signing credentials are checked against
/// those PEM bundles; otherwise certificates report as
/// `signingCredential.untrusted`.
Future<String?> getDetachedManifestJsonFromBytes({
  required final List<int> manifestBytes,
  required final List<int> assetBytes,
  required final String assetFormat,
  final String manifestFormat = 'application/c2pa',
  final String? trustAnchorsPem,
  final String? timestampTrustAnchorsPem,
  final String? allowedListPem,
}) async {
  await initializeC2paBackend();
  return c2paBackend.validateDetached(
    manifestBytes: manifestBytes,
    assetBytes: assetBytes,
    assetFormat: assetFormat,
    manifestFormat: manifestFormat,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );
}
