import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A collapsible section with a header, optional description, and expandable
/// content.
class CollapsibleSection extends StatefulWidget {

  const CollapsibleSection({
    required this.title, required this.child, super.key,
    this.description,
    this.initiallyExpanded = true,
  });
  final String title;
  final String? description;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(StringProperty('title', title))
    ..add(StringProperty('description', description))
    ..add(DiagnosticsProperty<bool>('initiallyExpanded', initiallyExpanded));
  }
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconTurns = _controller.drive(
      Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).chain(CurveTween(curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: theme.borderColor),
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.titleMediumStyle.copyWith(
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (final context, final child) => Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.description != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      widget.description!,
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                widget.child,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
