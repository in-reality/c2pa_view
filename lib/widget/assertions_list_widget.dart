import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/material.dart';

class AssertionsListWidget extends StatelessWidget {
  final List<ManifestAssertion> assertions;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentStyle;

  const AssertionsListWidget({
    super.key,
    required this.assertions,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (assertions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assertions:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...assertions.map((assertion) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            '- ${assertion.label}',
            style: contentStyle,
          ),
        )),
      ],
    );
  }
}
