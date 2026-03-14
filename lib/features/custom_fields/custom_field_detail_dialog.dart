import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';

/// A dialog that renders nested JSON structures in a readable tree format.
class CustomFieldDetailDialog extends StatelessWidget {
  final CustomField field;

  const CustomFieldDetailDialog({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Dialog(
      child: SelectionArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.key,
                          style: theme.titleMediumStyle.copyWith(
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        if (field.parentLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Source: ${field.source} (${field.parentLabel})',
                            style: theme.bodySmallStyle.copyWith(
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            'Source: ${field.source}',
                            style: theme.bodySmallStyle.copyWith(
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildValue(field.value, theme, 0),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValue(dynamic value, C2paViewerThemeData theme, int depth) {
    if (value is Map) {
      return _buildMap(value, theme, depth);
    }
    if (value is List) {
      return _buildList(value, theme, depth);
    }
    return Text(
      value?.toString() ?? 'null',
      style: theme.bodySmallStyle.copyWith(color: theme.textPrimaryColor),
    );
  }

  Widget _buildMap(Map map, C2paViewerThemeData theme, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in map.entries)
          Padding(
            padding: EdgeInsets.only(left: depth * 12.0, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toString(),
                  style: theme.bodySmallStyle.copyWith(
                    color: theme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildValue(entry.value, theme, depth + 1),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildList(List list, C2paViewerThemeData theme, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < list.length; i++)
          Padding(
            padding: EdgeInsets.only(left: depth * 12.0, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[$i] ',
                  style: theme.bodySmallStyle.copyWith(
                    color: theme.textSecondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildValue(list[i], theme, depth + 1),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
