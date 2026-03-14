import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';

import 'custom_field_detail_dialog.dart';

/// A key-value table widget that renders custom fields.
///
/// Simple values (string, number, bool) are displayed inline.
/// Complex values (Map, List) show a summary with a "tap to expand"
/// detail dialog that renders the nested structure.
class CustomFieldsTable extends StatelessWidget {
  final List<CustomField> fields;

  const CustomFieldsTable({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.borderColor),
        borderRadius: theme.sectionRadius,
      ),
      child: ClipRRect(
        borderRadius: theme.sectionRadius,
        child: Column(
          children: [
            _HeaderRow(theme: theme),
            for (int i = 0; i < fields.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: theme.borderColor, indent: 0),
              _FieldRow(field: fields[i], theme: theme),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final C2paViewerThemeData theme;

  const _HeaderRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surfaceVariantColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'KEY',
              style: theme.labelStyle.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'VALUE',
              style: theme.labelStyle.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final CustomField field;
  final C2paViewerThemeData theme;

  const _FieldRow({required this.field, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isComplex = field.isMap || field.isList;

    return InkWell(
      onTap: isComplex
          ? () => showDialog(
                context: context,
                builder: (_) => CustomFieldDetailDialog(field: field),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                field.key,
                style: theme.bodySmallStyle.copyWith(
                  color: theme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: isComplex
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            field.isMap
                                ? '{...} ${(field.value as Map).length} fields'
                                : '[...] ${(field.value as List).length} items',
                            style: theme.bodySmallStyle.copyWith(
                              color: theme.textSecondaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: theme.iconColor,
                        ),
                      ],
                    )
                  : Text(
                      field.value?.toString() ?? 'null',
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textPrimaryColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
