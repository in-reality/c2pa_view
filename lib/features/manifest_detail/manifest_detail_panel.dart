import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Fixed-width sidebar panel displaying detailed manifest information.
///
/// This is a thin shell that applies a fixed width and themed background
/// around [ManifestDetailContent]. For popup usage, see
/// [showManifestDetailPopup]. To embed the content in a custom layout,
/// use [ManifestDetailContent] directly.
class ManifestDetailPanel extends StatelessWidget {

  const ManifestDetailPanel({
    required this.data, super.key,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.width,
    this.mediaImage,
  });
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final double? width;
  final ImageProvider? mediaImage;

  @override
  Widget build(final BuildContext context) {
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(StringProperty('mimeType', mimeType))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onThumbnailTap', onThumbnailTap))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap))
    ..add(DoubleProperty('width', width))
    ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage));
  }
}
