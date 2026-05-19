import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A coloured banner warning that the signing certificate is outside any
/// trusted certificate list.
///
/// Renders only when [result.isUntrusted]. Invalid manifests render via
/// the [TamperedPlaceholder] widget instead; valid and missing-credential
/// states show nothing.
class ErrorBanner extends StatelessWidget {

  const ErrorBanner({required this.result, super.key});
  final ValidationResult result;

  @override
  Widget build(final BuildContext context) {
    if (!result.isUntrusted) {
      return const SizedBox.shrink();
    }

    final theme = C2paViewerTheme.of(context);
    final backgroundColor = theme.unrecognizedColor.withValues(alpha: 0.1);
    final borderColor = theme.unrecognizedColor.withValues(alpha: 0.3);
    final iconColor = theme.unrecognizedColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "The Content Credential's signing certificate is not in any "
              'trust list. Verify the issuer before trusting this content.',
              style: theme.bodySmallStyle.copyWith(
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ValidationResult>('result', result));
  }
}
