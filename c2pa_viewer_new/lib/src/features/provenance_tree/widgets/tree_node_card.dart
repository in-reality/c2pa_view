import 'package:flutter/material.dart';

import '../../../domain/models/provenance_node.dart';
import '../../../theme/c2pa_theme.dart';
import '../../shared/widgets/credential_indicator.dart';

/// A card representing a single node in the provenance tree.
///
/// Shows a thumbnail, asset title, and credential status indicator.
/// The border color changes based on selection state.
class TreeNodeCard extends StatelessWidget {
  final ProvenanceNode node;
  final bool isSelected;
  final bool isOnPath;
  final VoidCallback? onTap;

  const TreeNodeCard({
    super.key,
    required this.node,
    this.isSelected = false,
    this.isOnPath = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final borderColor = isSelected
        ? theme.selectedNodeBorderColor
        : isOnPath
            ? theme.pathNodeBorderColor
            : theme.defaultNodeBorderColor;

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
          child: Row(
            children: [
              _NodeThumbnail(node: node, theme: theme),
              Expanded(child: _NodeInfo(node: node, theme: theme)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeThumbnail extends StatelessWidget {
  final ProvenanceNode node;
  final C2paViewerThemeData theme;

  const _NodeThumbnail({required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: theme.nodeHeight,
      height: theme.nodeHeight,
      child: node.thumbnail != null
          ? Image(
              image: node.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: theme.surfaceVariantColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: theme.iconColor,
        ),
      ),
    );
  }
}

class _NodeInfo extends StatelessWidget {
  final ProvenanceNode node;
  final C2paViewerThemeData theme;

  const _NodeInfo({required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (node.title != null)
            Text(
              node.title!,
              style: theme.titleSmallStyle.copyWith(
                color: theme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          CredentialIndicator(result: node.validationResult),
          if (node.validationResult.isValid && node.issuer != null) ...[
            const SizedBox(height: 2),
            Text(
              node.issuer!,
              style: theme.bodySmallStyle.copyWith(
                color: theme.textSecondaryColor,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
