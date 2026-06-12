import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_interaction.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/features/shared/widgets/manifest_summary_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A card representing a single node in the provenance tree.
///
/// Displays a [ManifestSummaryCard] (treeNode variant) inside a container
/// whose border changes based on selection state and stacked highlight layers.
class TreeNodeCard extends StatelessWidget {
  const TreeNodeCard({
    required this.node,
    super.key,
    this.isSelected = false,
    this.isOnPath = false,
    this.highlights = const [],
    this.decoration,
    this.nodeDecorator,
    this.onTap,
    this.onBadgeTap,
    this.mediaImage,
  });

  final ProvenanceNode node;
  final bool isSelected;
  final bool isOnPath;
  final List<GraphHighlight> highlights;
  final NodeDecoration? decoration;
  final ProvenanceNodeDecorator? nodeDecorator;
  final VoidCallback? onTap;
  final void Function(DecorationBadge badge)? onBadgeTap;
  final ImageProvider? mediaImage;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final borderColor = HighlightResolver.resolveNodeBorder(
      highlights: highlights,
      isSelected: isSelected,
      isOnPath: isOnPath,
      theme: theme,
      decoration: decoration,
    );
    final borderWidth = HighlightResolver.resolveNodeBorderWidth(
      highlights: highlights,
      isSelected: isSelected,
      decoration: decoration,
    );
    final fillColor = HighlightResolver.resolveNodeFill(
      highlights: highlights,
      theme: theme,
    );

    final summary =
        (mediaImage != null && node.summary.thumbnail == null)
            ? ManifestSummary(
              title: node.summary.title,
              thumbnail: mediaImage,
              validationResult: node.summary.validationResult,
              issuer: node.summary.issuer,
            )
            : node.summary;

    final innerCard = ManifestSummaryCard(
      summary: summary,
      variant: ManifestSummaryCardVariant.treeNode,
    );

    Widget card = Container(
      width: theme.nodeWidth,
      height: theme.nodeHeight,
      decoration: BoxDecoration(
        color: fillColor ?? theme.surfaceColor,
        borderRadius: theme.cardRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: theme.cardRadius,
        child: innerCard,
      ),
    );

    final badges = decoration?.badges ?? const [];
    if (badges.isNotEmpty) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -6,
            right: -6,
            child: Wrap(
              spacing: 4,
              children: [
                for (final badge in badges)
                  _DecorationBadgeChip(
                    badge: badge,
                    onTap: onBadgeTap == null ? null : () => onBadgeTap!(badge),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    if (nodeDecorator != null) {
      card = nodeDecorator!(
        context,
        node: node,
        decoration: decoration,
        highlights: highlights,
        isSelected: isSelected,
        child: card,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ProvenanceNode>('node', node))
      ..add(DiagnosticsProperty<bool>('isSelected', isSelected))
      ..add(DiagnosticsProperty<bool>('isOnPath', isOnPath))
      ..add(IterableProperty<GraphHighlight>('highlights', highlights))
      ..add(DiagnosticsProperty<NodeDecoration?>('decoration', decoration))
      ..add(
        ObjectFlagProperty<ProvenanceNodeDecorator?>.has(
          'nodeDecorator',
          nodeDecorator,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(
        ObjectFlagProperty<void Function(DecorationBadge)?>.has(
          'onBadgeTap',
          onBadgeTap,
        ),
      )
      ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage));
  }
}

class _DecorationBadgeChip extends StatelessWidget {
  const _DecorationBadgeChip({
    required this.badge,
    this.onTap,
  });

  final DecorationBadge badge;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Semantics(
      label: badge.label,
      button: onTap != null,
      child: Material(
        color: theme.highlightAccentColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge.icon != null) ...[
                  Icon(
                    badge.icon,
                    size: 12,
                    color: theme.highlightBadgeTextColor,
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  badge.label,
                  style: theme.labelStyle.copyWith(
                    color: theme.highlightBadgeTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
