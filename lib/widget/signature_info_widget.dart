import 'package:flutter/material.dart';

class SignatureInfoWidget extends StatelessWidget {
  final Map<String, dynamic>? signatureInfo;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentLabelStyle;
  final TextStyle? contentStyle;

  const SignatureInfoWidget({
    super.key,
    required this.signatureInfo,
    this.sectionTitleStyle,
    this.contentLabelStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (signatureInfo == null) return const SizedBox.shrink();

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
}
