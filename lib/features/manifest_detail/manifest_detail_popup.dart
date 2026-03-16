import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';

import 'manifest_detail_content.dart';

/// Default width of the popup when no override is given.
const _kDefaultPopupWidth = 360.0;

/// Margin kept between the popup edges and the screen edges.
const _kScreenMargin = 16.0;

/// Shows a positioned popup with manifest detail information.
///
/// The popup is anchored next to the widget whose [BuildContext] is provided.
/// It prefers to appear to the right of the trigger; if there is not enough
/// room it falls back to the left, and finally centers horizontally.
///
/// Tap outside the popup or press the back button to dismiss.
Future<void> showManifestDetailPopup(
  BuildContext context, {
  required ManifestViewData data,
  String? mimeType,
  VoidCallback? onThumbnailTap,
  ValueChanged<IngredientDisplayInfo>? onIngredientTap,
  ImageProvider? mediaImage,
  double? width,
  double? maxHeight,
}) {
  final renderBox = context.findRenderObject() as RenderBox;
  final triggerSize = renderBox.size;
  final triggerPosition = renderBox.localToGlobal(Offset.zero);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss manifest details',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) {
      return _ManifestDetailPopupLayout(
        triggerPosition: triggerPosition,
        triggerSize: triggerSize,
        data: data,
        mimeType: mimeType,
        onThumbnailTap: onThumbnailTap,
        onIngredientTap: onIngredientTap,
        mediaImage: mediaImage,
        popupWidth: width,
        maxHeight: maxHeight,
      );
    },
  );
}

class _ManifestDetailPopupLayout extends StatelessWidget {
  final Offset triggerPosition;
  final Size triggerSize;
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final ImageProvider? mediaImage;
  final double? popupWidth;
  final double? maxHeight;

  const _ManifestDetailPopupLayout({
    required this.triggerPosition,
    required this.triggerSize,
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mediaImage,
    this.popupWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final theme = C2paViewerTheme.of(context);
    final w = popupWidth ?? _kDefaultPopupWidth;

    final popupMaxH = maxHeight ??
        (screen.height - 2 * _kScreenMargin);
    final popupH = math.min(popupMaxH, screen.height - 2 * _kScreenMargin);

    // Horizontal: prefer right of trigger, fall back to left, then center.
    final rightOfTrigger = triggerPosition.dx + triggerSize.width + 8;
    final leftOfTrigger = triggerPosition.dx - w - 8;

    double left;
    if (rightOfTrigger + w + _kScreenMargin <= screen.width) {
      left = rightOfTrigger;
    } else if (leftOfTrigger >= _kScreenMargin) {
      left = leftOfTrigger;
    } else {
      left = (screen.width - w) / 2;
    }

    // Vertical: align top with trigger, clamped to screen bounds.
    final top = triggerPosition.dy
        .clamp(_kScreenMargin, screen.height - popupH - _kScreenMargin);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: w,
          height: popupH,
          child: Material(
            elevation: 8,
            borderRadius: theme.cardRadius,
            color: theme.surfaceColor,
            clipBehavior: Clip.antiAlias,
            child: ManifestDetailContent(
              data: data,
              mimeType: mimeType,
              onThumbnailTap: onThumbnailTap,
              onIngredientTap: onIngredientTap,
              mediaImage: mediaImage,
            ),
          ),
        ),
      ],
    );
  }
}
