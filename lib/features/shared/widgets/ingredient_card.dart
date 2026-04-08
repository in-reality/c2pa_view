import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';

import 'manifest_summary_card.dart';

/// A compact card showing an ingredient with thumbnail, title, and credential
/// status, rendered via [ManifestSummaryCard] (listItem variant).
///
/// The card receives only [ingredient] -- an [IngredientDisplayInfo] whose
/// [ManifestSummary] is the *same object* used to render the corresponding
/// tree node.  Passing the same data to both widgets guarantees they always
/// agree.
class IngredientCard extends StatelessWidget {
  final IngredientDisplayInfo ingredient;
  final VoidCallback? onTap;

  const IngredientCard({super.key, required this.ingredient, this.onTap});

  @override
  Widget build(BuildContext context) {
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
}
