import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/features/shared/widgets/manifest_summary_card.dart';

/// A card representing a single node in the provenance tree.
///
/// Displays a [ManifestSummaryCard] (treeNode variant) inside a container
/// whose border changes based on the selection state.  The card itself
/// only knows about [node.summary] -- it has no access to parent or child
/// information.
class TreeNodeCard extends StatelessWidget {
  final ProvenanceNode node;
  final bool isSelected;
  final bool isOnPath;
  final VoidCallback? onTap;
  final ImageProvider? mediaImage;

  const TreeNodeCard({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isOnPath = false,
    this.onTap,
    this.mediaImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final borderColor = isSelected
        ? theme.selectedNodeBorderColor
        : isOnPath
            ? theme.pathNodeBorderColor
            : theme.defaultNodeBorderColor;

    // If a live media image is provided (for the root node) and the summary
    // has no thumbnail yet, substitute it so the card still shows an image.
    final summary = (mediaImage != null && node.summary.thumbnail == null)
        ? ManifestSummary(
            title: node.summary.title,
            thumbnail: mediaImage,
            validationResult: node.summary.validationResult,
            issuer: node.summary.issuer,
          )
        : node.summary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: theme.nodeWidth,
        height: theme.nodeHeight,
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: theme.cardRadius,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
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
          child: ManifestSummaryCard(
            summary: summary,
            variant: ManifestSummaryCardVariant.treeNode,
          ),
        ),
      ),
    );
  }
}
