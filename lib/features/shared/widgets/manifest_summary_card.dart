import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_node_card.dart' show TreeNodeCard;
import 'package:c2pa_view/features/shared/widgets/c2pa_thumbnail.dart';
import 'package:c2pa_view/features/shared/widgets/credential_indicator.dart';
import 'package:c2pa_view/features/shared/widgets/ingredient_card.dart' show IngredientCard;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controls the visual variant of [ManifestSummaryCard].
enum ManifestSummaryCardVariant {
  /// Fixed-size card for a provenance-tree node.
  /// Width and height come from [C2paViewerThemeData.nodeWidth/nodeHeight].
  treeNode,

  /// Full-width card for an ingredient list item.
  listItem,
}

/// A unified card that renders a [ManifestSummary] (thumbnail, title, and
/// credential status) in either a tree-node or an ingredient-list style.
///
/// Both variants render *exactly the same data from the same source*, making
/// it structurally impossible for a tree node and its corresponding ingredient
/// list item to show different information.
///
/// The widget is deliberately minimal: it knows nothing about parent nodes,
/// child nodes, or selection state.  Those concerns are handled by the callers
/// ([TreeNodeCard] and [IngredientCard]).
class ManifestSummaryCard extends StatelessWidget {

  const ManifestSummaryCard({
    required this.summary, required this.variant, super.key,
  });
  final ManifestSummary summary;
  final ManifestSummaryCardVariant variant;

  @override
  Widget build(final BuildContext context) => _SummaryContent(summary: summary, variant: variant);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestSummary>('summary', summary))
    ..add(EnumProperty<ManifestSummaryCardVariant>('variant', variant));
  }
}

// ---------------------------------------------------------------------------
// Unified content widget (used by both tree-node and list-item variants)
// ---------------------------------------------------------------------------

class _SummaryContent extends StatelessWidget {

  const _SummaryContent({required this.summary, required this.variant});
  final ManifestSummary summary;
  final ManifestSummaryCardVariant variant;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final isTreeNode = variant == ManifestSummaryCardVariant.treeNode;

    final thumbnail = _Thumbnail(
      image: summary.thumbnail,
      size: isTreeNode ? theme.nodeHeight : 48,
      square: isTreeNode,
      theme: theme,
    );

    return Row(
      children: [
        thumbnail,
        if (!isTreeNode) const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding:
                isTreeNode
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                    : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment:
                  isTreeNode
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary.title ?? 'Untitled',
                  style: theme.titleSmallStyle.copyWith(
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                CredentialIndicator(result: summary.validationResult),
                if (summary.issuer != null &&
                    (summary.validationResult.isValid ||
                        summary.validationResult.isUntrusted)) ...[
                  const SizedBox(height: 2),
                  Text(
                    summary.issuer!,
                    style: theme.bodySmallStyle.copyWith(
                      color: theme.textSecondaryColor,
                      fontSize: isTreeNode ? 10 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestSummary>('summary', summary))
    ..add(EnumProperty<ManifestSummaryCardVariant>('variant', variant));
  }
}

// ---------------------------------------------------------------------------
// Shared thumbnail helper
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {

  const _Thumbnail({
    required this.image,
    required this.size,
    required this.square,
    required this.theme,
  });
  final ImageProvider? image;
  final double size;

  /// When true, the thumbnail is rendered without any border-radius clipping
  /// (the parent card handles that).  When false a rounded C2paThumbnail is
  /// used (list-item style).
  final bool square;

  final C2paViewerThemeData theme;

  @override
  Widget build(final BuildContext context) {
    if (square) {
      // Full-bleed square thumbnail for tree nodes (parent clips corners).
      return SizedBox(
        width: size,
        height: size,
        child:
            image != null
                ? Image(
                  image: image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, final __, final ___) => _placeholder(),
                )
                : _placeholder(),
      );
    }

    return C2paThumbnail(
      image: image,
      size: size,
      borderRadius: BorderRadius.circular(6),
    );
  }

  Widget _placeholder() => ColoredBox(
      color: theme.surfaceVariantColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: size * 0.4,
          color: theme.iconColor,
        ),
      ),
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ImageProvider<Object>?>('image', image))
    ..add(DoubleProperty('size', size))
    ..add(DiagnosticsProperty<bool>('square', square))
    ..add(DiagnosticsProperty<C2paViewerThemeData>('theme', theme));
  }
}
