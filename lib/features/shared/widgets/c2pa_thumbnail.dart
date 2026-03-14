import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';

/// A thumbnail widget with fallback placeholder based on media type.
class C2paThumbnail extends StatelessWidget {
  final ImageProvider? image;
  final double size;
  final String? mimeType;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const C2paThumbnail({
    super.key,
    this.image,
    this.size = 48,
    this.mimeType,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  IconData get _placeholderIcon {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType!.startsWith('image/')) return Icons.image_outlined;
    if (mimeType!.startsWith('video/')) return Icons.videocam_outlined;
    if (mimeType!.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mimeType!.startsWith('application/pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(8);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: image != null
            ? Image(
                image: image!,
                width: size,
                height: size,
                fit: fit,
                errorBuilder: (_, __, ___) => _placeholder(theme),
              )
            : _placeholder(theme),
      ),
    );
  }

  Widget _placeholder(C2paViewerThemeData theme) {
    return Container(
      color: theme.surfaceVariantColor,
      child: Center(
        child: Icon(
          _placeholderIcon,
          size: size * 0.4,
          color: theme.iconColor,
        ),
      ),
    );
  }
}
