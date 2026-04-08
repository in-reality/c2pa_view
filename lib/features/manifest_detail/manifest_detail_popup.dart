import 'dart:math' as math;

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final BuildContext context, {
  required final ManifestViewData data,
  final String? mimeType,
  final VoidCallback? onThumbnailTap,
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap,
  final ImageProvider? mediaImage,
  final double? width,
  final double? maxHeight,
}) {
  final renderBox = context.findRenderObject()! as RenderBox;
  final triggerSize = renderBox.size;
  final triggerPosition = renderBox.localToGlobal(Offset.zero);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss manifest details',
    barrierColor: Colors.black26,
    transitionBuilder: (final context, final animation, _, final child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    pageBuilder: (final context, _, final __) => _ManifestDetailPopupLayout(
        triggerPosition: triggerPosition,
        triggerSize: triggerSize,
        data: data,
        mimeType: mimeType,
        onThumbnailTap: onThumbnailTap,
        onIngredientTap: onIngredientTap,
        mediaImage: mediaImage,
        popupWidth: width,
        maxHeight: maxHeight,
      ),
  );
}

class _ManifestDetailPopupLayout extends StatelessWidget {

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
  final Offset triggerPosition;
  final Size triggerSize;
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final ImageProvider? mediaImage;
  final double? popupWidth;
  final double? maxHeight;

  @override
  Widget build(final BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final theme = C2paViewerTheme.of(context);
    final w = popupWidth ?? _kDefaultPopupWidth;

    final popupMaxH = maxHeight ?? (screen.height - 2 * _kScreenMargin);
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
    final top = triggerPosition.dy.clamp(
      _kScreenMargin,
      screen.height - popupH - _kScreenMargin,
    );

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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<Offset>('triggerPosition', triggerPosition))
    ..add(DiagnosticsProperty<Size>('triggerSize', triggerSize))
    ..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(StringProperty('mimeType', mimeType))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onThumbnailTap', onThumbnailTap))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap))
    ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage))
    ..add(DoubleProperty('popupWidth', popupWidth))
    ..add(DoubleProperty('maxHeight', maxHeight));
  }
}
