import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A thumbnail widget with fallback placeholder based on media type.
class C2paThumbnail extends StatelessWidget {

  const C2paThumbnail({
    super.key,
    this.image,
    this.size = 48,
    this.mimeType,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });
  final ImageProvider? image;
  final double size;
  final String? mimeType;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  IconData get _placeholderIcon {
    if (mimeType == null) {
      return Icons.insert_drive_file_outlined;
    }
    if (mimeType!.startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (mimeType!.startsWith('video/')) {
      return Icons.videocam_outlined;
    }
    if (mimeType!.startsWith('audio/')) {
      return Icons.audiotrack_outlined;
    }
    if (mimeType!.startsWith('application/pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(8);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child:
            image != null
                ? Image(
                  image: image!,
                  width: size,
                  height: size,
                  fit: fit,
                  errorBuilder: (_, final __, final ___) => _placeholder(theme),
                )
                : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(final C2paViewerThemeData theme) => ColoredBox(
      color: theme.surfaceVariantColor,
      child: Center(
        child: Icon(_placeholderIcon, size: size * 0.4, color: theme.iconColor),
      ),
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ImageProvider<Object>?>('image', image))
    ..add(DoubleProperty('size', size))
    ..add(StringProperty('mimeType', mimeType))
    ..add(DiagnosticsProperty<BorderRadius?>('borderRadius', borderRadius))
    ..add(EnumProperty<BoxFit>('fit', fit));
  }
}
