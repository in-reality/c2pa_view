import 'package:flutter/material.dart';

import '../../../domain/models/validation_result.dart';
import '../../../theme/c2pa_theme.dart';

/// A small indicator showing credential status with icon and text.
class CredentialIndicator extends StatelessWidget {
  final ValidationResult result;
  final bool compact;

  const CredentialIndicator({
    super.key,
    required this.result,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final color = theme.colorForStatus(result.status);

    final IconData icon;
    final String text;

    switch (result.status) {
      case ValidationStatus.valid:
        icon = Icons.verified;
        text = 'Content Credential';
      case ValidationStatus.invalid:
        icon = Icons.dangerous;
        text = 'Invalid';
      case ValidationStatus.unrecognized:
        icon = Icons.warning_amber_rounded;
        text = 'Unrecognized';
      case ValidationStatus.noCredential:
        icon = Icons.remove_circle_outline;
        text = 'No Content Credential';
    }

    if (compact) {
      return Icon(icon, size: 16, color: color);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.bodySmallStyle.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
