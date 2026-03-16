import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';

import 'manifest_detail_content.dart';

/// Fixed-width sidebar panel displaying detailed manifest information.
///
/// This is a thin shell that applies a fixed width and themed background
/// around [ManifestDetailContent]. For popup usage, see
/// [showManifestDetailPopup]. To embed the content in a custom layout,
/// use [ManifestDetailContent] directly.
class ManifestDetailPanel extends StatelessWidget {
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final double? width;
  final ImageProvider? mediaImage;

  const ManifestDetailPanel({
    super.key,
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.width,
    this.mediaImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Container(
      width: width ?? theme.sidebarWidth,
      color: theme.surfaceColor,
      child: ManifestDetailContent(
        data: data,
        mimeType: mimeType,
        onThumbnailTap: onThumbnailTap,
        onIngredientTap: onIngredientTap,
        mediaImage: mediaImage,
      ),
    );
  }
}
