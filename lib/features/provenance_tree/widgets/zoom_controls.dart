import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Floating zoom control buttons (zoom in, fit, zoom out).
class ZoomControls extends StatelessWidget {

  const ZoomControls({
    required this.onZoomIn, required this.onZoomOut, required this.onFit, super.key,
  });
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add,
            onTap: onZoomIn,
            tooltip: 'Zoom in',
            theme: theme,
          ),
          Container(height: 1, width: 32, color: theme.borderColor),
          _ZoomButton(
            icon: Icons.fit_screen_outlined,
            onTap: onFit,
            tooltip: 'Fit to view',
            theme: theme,
          ),
          Container(height: 1, width: 32, color: theme.borderColor),
          _ZoomButton(
            icon: Icons.remove,
            onTap: onZoomOut,
            tooltip: 'Zoom out',
            theme: theme,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(ObjectFlagProperty<VoidCallback>.has('onZoomIn', onZoomIn))
    ..add(ObjectFlagProperty<VoidCallback>.has('onZoomOut', onZoomOut))
    ..add(ObjectFlagProperty<VoidCallback>.has('onFit', onFit));
  }
}

class _ZoomButton extends StatelessWidget {

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.theme,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final C2paViewerThemeData theme;

  @override
  Widget build(final BuildContext context) => Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(child: Icon(icon, size: 18, color: theme.iconColor)),
        ),
      ),
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<IconData>('icon', icon))
    ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
    ..add(StringProperty('tooltip', tooltip))
    ..add(DiagnosticsProperty<C2paViewerThemeData>('theme', theme));
  }
}
