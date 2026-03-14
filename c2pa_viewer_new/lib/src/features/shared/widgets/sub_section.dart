import 'package:flutter/material.dart';

import '../../../theme/c2pa_theme.dart';

/// A labelled sub-section within a collapsible section.
/// Displays a small label above its content.
class SubSection extends StatelessWidget {
  final String label;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SubSection({
    super.key,
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.labelStyle.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
