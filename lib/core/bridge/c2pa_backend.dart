import 'dart:async';

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
