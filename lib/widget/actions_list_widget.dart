import 'package:c2pa_view/domain/entities/action.dart' as c2pa;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays a list of actions from a C2PA manifest.
class ActionsListWidget extends StatelessWidget {

  /// Creates an instance of [ActionsListWidget].
  const ActionsListWidget({
    required this.actions, super.key,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  /// The list of actions to display.
  final List<c2pa.Action>? actions;

  /// The style for the section title.
  final TextStyle? sectionTitleStyle;

  /// The style for the content text.
  final TextStyle? contentStyle;

  @override
  Widget build(final BuildContext context) {
    if (actions == null || actions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...actions!.map((final action) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '- ${action.action}',
            style: contentStyle,
          ),
        ),),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IterableProperty<c2pa.Action>('actions', actions))
    ..add(DiagnosticsProperty<TextStyle?>(
        'sectionTitleStyle', sectionTitleStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>('contentStyle', contentStyle));
  }
}
