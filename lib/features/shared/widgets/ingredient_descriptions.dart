import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Plain, fully wrapped payload text with its recorded ingredient-edge context.
class IngredientDescriptions extends StatelessWidget {
  /// Renders already projected evidence without deriving a check or verdict.
  const IngredientDescriptions({required this.descriptions, super.key});

  /// Verbatim prose and structural attribution from the shared projection.
  final List<IngredientDescription> descriptions;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final note in descriptions) ...[
          Text(note.sourceLabel, style: theme.bodySmallStyle),
          Text(note.description, style: theme.bodySmallStyle),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty<IngredientDescription>('descriptions', descriptions),
    );
  }
}
