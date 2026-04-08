import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A small indicator showing credential status with icon and text.
class CredentialIndicator extends StatelessWidget {

  const CredentialIndicator({
    required this.result, super.key,
    this.compact = false,
  });
  final ValidationResult result;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
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
      case ValidationStatus.untrusted:
        icon = Icons.verified_outlined;
        text = 'Untrusted signer';
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ValidationResult>('result', result))
    ..add(DiagnosticsProperty<bool>('compact', compact));
  }
}
