import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    final Widget leading;
    final String text;

    switch (result.status) {
      case ValidationStatus.valid:
        leading = SvgPicture.asset(
          'assets/icons/cr_pin.svg',
          package: 'c2pa_view',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          placeholderBuilder:
              (_) => Icon(Icons.verified, size: 16, color: color),
        );
        text = 'CR';
      case ValidationStatus.invalid:
        leading = Icon(Icons.dangerous, size: 16, color: color);
        text = 'Invalid';
      case ValidationStatus.untrusted:
        leading = Icon(Icons.verified_outlined, size: 16, color: color);
        text = 'Untrusted';
      case ValidationStatus.noCredential:
        leading = Icon(Icons.remove_circle_outline, size: 16, color: color);
        text = 'No CR';
    }

    if (compact) {
      return SizedBox(width: 16, height: 16, child: leading);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
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
