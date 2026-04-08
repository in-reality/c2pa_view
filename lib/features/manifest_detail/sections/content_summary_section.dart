import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Content summary section showing AI generation information.
class ContentSummarySection extends StatelessWidget {

  const ContentSummarySection({super.key, this.generativeInfo});
  final GenerativeInfo? generativeInfo;

  @override
  Widget build(final BuildContext context) {
    if (generativeInfo == null) {
      return const SizedBox.shrink();
    }

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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GenerativeInfo?>('generativeInfo', generativeInfo));
  }
}
