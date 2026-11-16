import 'dart:async';
import 'dart:typed_data';

import 'package:c2pa_view/core/bridge/standalone_c2pa_backend.dart';

/// Generic C2PA execution boundary for standalone and host-provided readers.
///
/// Implementations preserve the SDK JSON (including preview annotations and
/// unperformed/failed evidence), nullable missing-manifest results and errors.
/// Manifest CA anchors, TSA CA anchors and signing-leaf allow-lists have distinct
/// purposes. No adapter may combine them or infer trust from preview resolution.
abstract interface class C2paBackend {
  /// Initializes this execution backend without loading another backend.
  Future<void> initialize();

  /// Reads and validates embedded credentials at a local path.
  Future<String?> validatePath({
    required final String path,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  });

  /// Reads and validates embedded credentials, including bounded previews.
  Future<String?> validateBytes({
    required final List<int> fileBytes,
    required final String format,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  });

  /// Reads a manifest store without verifying media binding or signatures.
  Future<String?> readManifestStore({
    required final List<int> fileBytes,
    required final String format,
  });

  /// Validates a detached store against the supplied asset and trust inputs.
  Future<String?> validateDetached({
    required final List<int> manifestBytes,
    required final List<int> assetBytes,
    required final String assetFormat,
    final String manifestFormat = 'application/c2pa',
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  });
}

/// Optional capability; existing host adapters need not implement binary reads.
// An optional capability must be distinct from the existing host interface.
// ignore: one_member_abstracts
abstract interface class C2paResourceBackend {
  /// Resolves bytes independently of validation/trust, using current input only.
  Future<C2paResourceRead> readEmbeddedResource({
    required final Uint8List fileBytes,
    required final String format,
    required final Uint8List expectedInputSha256,
    required final String manifestLabel,
    required final String identifier,
    required final Uint8List expectedPayloadSha256,
    final int maxBytes = 32 * 1024 * 1024,
    final String? trustAnchorsPem,
    final String? timestampTrustAnchorsPem,
    final String? allowedListPem,
  });
}

/// Binary resource result. Resolution grants no signature or trust status.
class C2paResourceRead {
  /// Creates a resource outcome with separate current validation metadata.
  const C2paResourceRead({
    required this.resolution,
    required this.bytes,
    required this.inputSha256,
    required this.currentValidationJson,
  });

  /// `resolved`, `unsupported`, or an explicit admission/resolution failure.
  final String resolution;

  /// Bounded encoded payload; never hydrated through thumbnail JSON arrays.
  final Uint8List bytes;

  /// SHA-256 of the exact asset bytes used for this read.
  final Uint8List inputSha256;

  /// Current SDK checks, distinct from recorded statuses and payload resolution.
  final Uint8List currentValidationJson;
}

/// Uses the selected backend's optional capability; never switches execution.
Future<C2paResourceRead> readEmbeddedC2paResource({
  required final Uint8List fileBytes,
  required final String format,
  required final Uint8List expectedInputSha256,
  required final String manifestLabel,
  required final String identifier,
  required final Uint8List expectedPayloadSha256,
  final int maxBytes = 32 * 1024 * 1024,
  final String? trustAnchorsPem,
  final String? timestampTrustAnchorsPem,
  final String? allowedListPem,
}) async {
  final backend = c2paBackend;
  if (backend is! C2paResourceBackend) {
    return C2paResourceRead(
      resolution: 'unsupported',
      bytes: Uint8List(0),
      inputSha256: Uint8List(0),
      currentValidationJson: Uint8List(0),
    );
  }
  await initializeC2paBackend();
  return (backend as C2paResourceBackend).readEmbeddedResource(
    fileBytes: fileBytes,
    format: format,
    expectedInputSha256: expectedInputSha256,
    manifestLabel: manifestLabel,
    identifier: identifier,
    expectedPayloadSha256: expectedPayloadSha256,
    maxBytes: maxBytes,
    trustAnchorsPem: trustAnchorsPem,
    timestampTrustAnchorsPem: timestampTrustAnchorsPem,
    allowedListPem: allowedListPem,
  );
}

C2paBackend _backend = const StandaloneC2paBackend();
Future<void>? _initialization;
bool _hostBackendInstalled = false;

/// Installs a host backend once, before any initialization or facade read.
///
/// Repeated or late registration fails rather than replacing execution ownership.
/// There is no fallback to the standalone library if the selected backend fails.
void installC2paBackend(final C2paBackend backend) {
  if (_hostBackendInstalled || _initialization != null) {
    throw StateError(
      'Install C2paBackend once, before first initialization or read',
    );
  }
  _backend = backend;
  _hostBackendInstalled = true;
}

/// The selected backend; facade callers initialize it before dispatch.
C2paBackend get c2paBackend => _backend;

/// Coalesces initialization and retains failures/timeouts until process reload.
///
/// The first caller selects the timeout, matching the existing bridge behavior.
Future<void> initializeC2paBackend({
  final Duration timeout = const Duration(seconds: 15),
}) {
  final existing = _initialization;
  if (existing != null) {
    return existing;
  }
  final completion = Completer<void>();
  final initialization = completion.future.timeout(timeout);
  // Publish before host code runs: synchronous reentry must see the same future.
  _initialization = initialization;
  completion.complete(Future<void>.sync(_backend.initialize));
  return initialization;
}
