import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';

import 'c2pa_thumbnail.dart';

/// A compact card showing an ingredient with thumbnail, title, and metadata.
class IngredientCard extends StatelessWidget {
  final IngredientDisplayInfo ingredient;
  final VoidCallback? onTap;

  const IngredientCard({
    super.key,
    required this.ingredient,
    this.onTap,
  });

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
        child: Row(
          children: [
            C2paThumbnail(
              image: ingredient.thumbnail,
              size: 48,
              mimeType: ingredient.format,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ingredient.title ?? 'Untitled',
                    style: theme.titleSmallStyle.copyWith(
                      color: theme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ingredient.issuer != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      ingredient.issuer!,
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (ingredient.hasManifest)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: theme.validColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Has credentials',
                            style: theme.bodySmallStyle.copyWith(
                              color: theme.validColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
