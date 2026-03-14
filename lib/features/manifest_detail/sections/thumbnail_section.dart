import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/features/shared/widgets/c2pa_thumbnail.dart';

/// Large thumbnail section at the top of the detail panel.
class ThumbnailSection extends StatelessWidget {
  final ImageProvider? thumbnail;
  final String? mimeType;
  final VoidCallback? onTapFullScreen;

  const ThumbnailSection({
    super.key,
    this.thumbnail,
    this.mimeType,
    this.onTapFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: MouseRegion(
        cursor: onTapFullScreen != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTapFullScreen,
          child: Stack(
            children: [
              C2paThumbnail(
                image: thumbnail,
                size: theme.thumbnailSize,
                mimeType: mimeType,
                borderRadius: theme.cardRadius,
                fit: BoxFit.contain,
              ),
              if (onTapFullScreen != null && thumbnail != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
