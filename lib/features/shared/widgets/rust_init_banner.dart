import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Categories of `RustLib.init` failures that the banner can recognise.
///
/// Visible for testing so the categorisation logic can be exercised without
/// a full widget pump.
@visibleForTesting
enum RustInitErrorCategory { contentHashMismatch, webLoadFailure, timeout, unknown }

/// Categorise [message] into one of [RustInitErrorCategory] using a
/// case-insensitive substring match. The underlying error strings come from
/// flutter_rust_bridge and are stable across releases.
@visibleForTesting
RustInitErrorCategory categoriseRustInitError(final String message) {
  final lower = message.toLowerCase();
  if (lower.contains('content hash on dart side') ||
      lower.contains('out-of-sync code')) {
    return RustInitErrorCategory.contentHashMismatch;
  }
  if (lower.contains('wasm') ||
      lower.contains('cors') ||
      lower.contains('fetch')) {
    return RustInitErrorCategory.webLoadFailure;
  }
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return RustInitErrorCategory.timeout;
  }
  return RustInitErrorCategory.unknown;
}

/// Debug-only banner explaining a `RustLib.init` failure with actionable
/// remediation commands.
///
/// Hidden entirely in profile/release builds (where the raw exception
/// strings have no place); in debug builds it categorises [message] into
/// one of [RustInitErrorCategory] and renders the matching remediation
/// block as selectable text so the operator can copy/paste straight into
/// a fish prompt.
class RustInitErrorBanner extends StatelessWidget {
  const RustInitErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(final BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final category = categoriseRustInitError(message);
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      color: Colors.orange.shade900,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = textTheme.bodySmall?.copyWith(
      color: Colors.orange.shade900,
    );
    final commandStyle = textTheme.bodySmall?.copyWith(
      color: Colors.orange.shade900,
      fontFamily: 'monospace',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rust library failed to load', style: titleStyle),
          const SizedBox(height: 4),
          SelectableText(message, style: bodyStyle),
          const SizedBox(height: 12),
          ..._remediationFor(
            category,
            bodyStyle: bodyStyle,
            commandStyle: commandStyle,
          ),
        ],
      ),
    );
  }

  List<Widget> _remediationFor(
    final RustInitErrorCategory category, {
    required final TextStyle? bodyStyle,
    required final TextStyle? commandStyle,
  }) {
    switch (category) {
      case RustInitErrorCategory.contentHashMismatch:
        return _block(
          intro:
              'Dart bindings are out of sync with the Rust binary. '
              'Regenerate bindings, then rebuild for the current target:',
          commands: const [
            'cd frontend/c2pa_view',
            'flutter_rust_bridge_codegen generate',
            '',
            'Web (Chrome):',
            '  ./scripts/sync_web_pkg.sh',
            '  cd example',
            r'  flutter run -d chrome \',
            r'    --web-header=Cross-Origin-Opener-Policy=same-origin \',
            '    --web-header=Cross-Origin-Embedder-Policy=require-corp',
            '',
            'Native (Linux / macOS / Windows / iOS / Android):',
            '  cd frontend/c2pa_view/example   # or testfiles_app',
            '  flutter clean',
            '  flutter run -d <target>',
          ],
          bodyStyle: bodyStyle,
          commandStyle: commandStyle,
        );
      case RustInitErrorCategory.webLoadFailure:
        return _block(
          intro:
              'The Rust/WASM artefact under web/pkg/ is missing or '
              'unreachable. Rebuild and serve with the COOP/COEP headers '
              'flutter_rust_bridge requires:',
          commands: const [
            'cd frontend/c2pa_view',
            './scripts/sync_web_pkg.sh',
            '',
            'cd example   # or testfiles_app',
            r'flutter run -d chrome \',
            r'  --web-header=Cross-Origin-Opener-Policy=same-origin \',
            '  --web-header=Cross-Origin-Embedder-Policy=require-corp',
          ],
          bodyStyle: bodyStyle,
          commandStyle: commandStyle,
        );
      case RustInitErrorCategory.timeout:
        return _block(
          intro:
              'RustLib.init exceeded its 15s deadline. Most often the '
              'native library is stale or missing for the current platform. '
              'Rebuild for the current target:',
          commands: const [
            'cd frontend/c2pa_view/example   # or testfiles_app',
            'flutter clean',
            'flutter run -d <target>',
            '',
            'For web, rebuild WASM first:',
            '  cd frontend/c2pa_view',
            '  ./scripts/sync_web_pkg.sh',
          ],
          bodyStyle: bodyStyle,
          commandStyle: commandStyle,
        );
      case RustInitErrorCategory.unknown:
        return _block(
          intro:
              "RustLib.init failed for a reason this banner doesn't "
              'recognise. The raw message is above. As a generic fix, '
              'rebuild for the current target:',
          commands: const [
            'cd frontend/c2pa_view/example   # or testfiles_app',
            'flutter clean',
            'flutter run -d <target>',
            '',
            'For web, rebuild WASM first:',
            '  cd frontend/c2pa_view',
            '  ./scripts/sync_web_pkg.sh',
          ],
          bodyStyle: bodyStyle,
          commandStyle: commandStyle,
        );
    }
  }

  List<Widget> _block({
    required final String intro,
    required final List<String> commands,
    required final TextStyle? bodyStyle,
    required final TextStyle? commandStyle,
  }) => [
        SelectableText(intro, style: bodyStyle),
        const SizedBox(height: 8),
        for (final line in commands) SelectableText(line, style: commandStyle),
      ];

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}
