import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';

/// A key-value table widget that renders custom fields.
///
/// All values are flattened into dotted-key rows so that nested
/// Maps and Lists are shown inline without popups.
class CustomFieldsTable extends StatelessWidget {
  final List<CustomField> fields;

  const CustomFieldsTable({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final rows = <MapEntry<String, String>>[];
    for (final field in fields) {
      rows.addAll(field.toFlatEntries());
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.borderColor),
        borderRadius: theme.sectionRadius,
      ),
      child: ClipRRect(
        borderRadius: theme.sectionRadius,
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: theme.borderColor, indent: 0),
              _FlatRow(entry: rows[i], theme: theme),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlatRow extends StatelessWidget {
  final MapEntry<String, String> entry;
  final C2paViewerThemeData theme;

  const _FlatRow({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.key,
              style: theme.bodySmallStyle.copyWith(
                color: theme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.value,
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
