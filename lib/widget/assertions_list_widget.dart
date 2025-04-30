import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays a list of assertions from a C2PA manifest.
class AssertionsListWidget extends StatelessWidget {

  /// Creates an instance of [AssertionsListWidget].
  const AssertionsListWidget({
    required this.assertions, super.key,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  /// The list of assertions to display.
  final List<ManifestAssertion> assertions;

  /// The style for the section title.
  final TextStyle? sectionTitleStyle;

  /// The style for the content text.
  final TextStyle? contentStyle;

  @override
  Widget build(final BuildContext context) {
    if (assertions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assertions:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...assertions.map((final assertion) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '- ${assertion.label}',
            style: contentStyle,
          ),
        ),),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IterableProperty<ManifestAssertion>(
        'assertions', assertions,),)
    ..add(DiagnosticsProperty<TextStyle?>(
        'sectionTitleStyle', sectionTitleStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>('contentStyle', contentStyle));
  }
}
