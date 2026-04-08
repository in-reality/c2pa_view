import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/features/custom_fields/custom_fields_table.dart';
import 'package:c2pa_view/features/shared/widgets/collapsible_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Collapsible section for displaying custom (non-standard) fields.
class CustomFieldsSection extends StatelessWidget {

  const CustomFieldsSection({required this.fields, super.key});
  final List<CustomField> fields;

  @override
  Widget build(final BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return CollapsibleSection(
      title: 'Custom Fields',
      description:
          'Additional vendor-specific or non-standard data '
          'found in this Content Credential.',
      initiallyExpanded: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CustomFieldsTable(fields: fields),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<CustomField>('fields', fields));
  }
}
