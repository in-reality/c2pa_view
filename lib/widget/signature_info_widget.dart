import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays information about the signature of a C2PA manifest.
class SignatureInfoWidget extends StatelessWidget {

  /// Creates an instance of [SignatureInfoWidget].
  const SignatureInfoWidget({
    required this.signatureInfo, super.key,
    this.sectionTitleStyle,
    this.contentLabelStyle,
    this.contentStyle,
  });

  /// The information about the signature of the C2PA manifest.
  final Map<String, dynamic>? signatureInfo;

  /// The style for the section title text.
  final TextStyle? sectionTitleStyle;

  /// The style for the content label text.
  final TextStyle? contentLabelStyle;

  /// The style for the content text.
  final TextStyle? contentStyle;

  @override
  Widget build(final BuildContext context) {
    if (signatureInfo == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this Content Credential:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        if (signatureInfo!['issuer'] != null) ...[
          Text('Issued by', style: contentLabelStyle),
          Text(signatureInfo!['issuer'] as String, style: contentStyle),
          const SizedBox(height: 4),
        ],
        if (signatureInfo!['time'] != null) ...[
          Text('Issued on', style: contentLabelStyle),
          Text(signatureInfo!['time'] as String, style: contentStyle),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<Map<String, dynamic>?>(
        'signatureInfo', signatureInfo,),)
    ..add(DiagnosticsProperty<TextStyle?>(
        'sectionTitleStyle', sectionTitleStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>(
        'contentLabelStyle', contentLabelStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>('contentStyle', contentStyle));
  }
}
