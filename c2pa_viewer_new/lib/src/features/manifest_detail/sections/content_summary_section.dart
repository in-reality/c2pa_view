import 'package:flutter/material.dart';

import '../../../domain/models/manifest_view_data.dart';
import '../../../theme/c2pa_theme.dart';

/// Content summary section showing AI generation information.
///
/// Only rendered when the manifest indicates AI-generated or
/// AI-composite content.
class ContentSummarySection extends StatelessWidget {
  final GenerativeInfo? generativeInfo;

  const ContentSummarySection({super.key, this.generativeInfo});

  @override
  Widget build(BuildContext context) {
    if (generativeInfo == null) return const SizedBox.shrink();

    final theme = C2paViewerTheme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: theme.sectionRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: theme.iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  generativeInfo!.description,
                  style: theme.bodySmallStyle.copyWith(
                    color: theme.textPrimaryColor,
                  ),
                ),
                if (generativeInfo!.softwareAgents.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    generativeInfo!.softwareAgents.join(', '),
                    style: theme.bodySmallStyle.copyWith(
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
