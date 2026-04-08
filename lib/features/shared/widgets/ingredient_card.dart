import 'package:c2pa_view/c2pa_view.dart' show ManifestSummary;
import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart' show ManifestSummary;
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/shared/widgets/manifest_summary_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A compact card showing an ingredient with thumbnail, title, and credential
/// status, rendered via [ManifestSummaryCard] (listItem variant).
///
/// The card receives only [ingredient] -- an [IngredientDisplayInfo] whose
/// [ManifestSummary] is the *same object* used to render the corresponding
/// tree node.  Passing the same data to both widgets guarantees they always
/// agree.
class IngredientCard extends StatelessWidget {

  const IngredientCard({required this.ingredient, super.key, this.onTap});
  final IngredientDisplayInfo ingredient;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: theme.sectionRadius,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: theme.sectionRadius,
        ),
        child: ManifestSummaryCard(
          summary: ingredient.summary,
          variant: ManifestSummaryCardVariant.listItem,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IngredientDisplayInfo>('ingredient', ingredient))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
}
