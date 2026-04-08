import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A labelled sub-section within a collapsible section.
/// Displays a small label above its content.
class SubSection extends StatelessWidget {

  const SubSection({
    required this.label, required this.child, super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });
  final String label;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.labelStyle.copyWith(color: theme.textSecondaryColor),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('label', label))
    ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}
