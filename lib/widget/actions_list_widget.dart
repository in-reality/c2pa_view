import 'package:flutter/material.dart';
import 'package:c2pa_view/domain/entities/action.dart' as c2pa;

class ActionsListWidget extends StatelessWidget {
  final List<c2pa.Action>? actions;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentStyle;

  const ActionsListWidget({
    super.key,
    required this.actions,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (actions == null || actions!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...actions!.map((action) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            '- ${action.action}',
            style: contentStyle,
          ),
        )),
      ],
    );
  }
}
