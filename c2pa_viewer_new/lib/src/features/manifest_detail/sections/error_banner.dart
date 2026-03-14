import 'package:flutter/material.dart';

import '../../../domain/models/validation_result.dart';
import '../../../theme/c2pa_theme.dart';

/// A colored banner displaying validation errors or warnings.
///
/// Red for invalid manifests, orange for unrecognized issuers.
class ErrorBanner extends StatelessWidget {
  final ValidationResult result;

  const ErrorBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.isValid || !result.hasCredential) return const SizedBox.shrink();

    final theme = C2paViewerTheme.of(context);
    final isInvalid = result.isInvalid;

    final backgroundColor =
        isInvalid ? theme.invalidColor.withValues(alpha: 0.1) : theme.unrecognizedColor.withValues(alpha: 0.1);
    final borderColor =
        isInvalid ? theme.invalidColor.withValues(alpha: 0.3) : theme.unrecognizedColor.withValues(alpha: 0.3);
    final iconColor = isInvalid ? theme.invalidColor : theme.unrecognizedColor;

    final icon = isInvalid ? Icons.error : Icons.warning_amber_rounded;

    final message = result.message ??
        (isInvalid
            ? 'This file may have been tampered with after the Content '
                'Credential was issued, or the Content Credential has errors.'
            : 'The Content Credential issuer could not be recognized. '
                'Verify the issuer before trusting this content.');

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
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.bodySmallStyle.copyWith(
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
