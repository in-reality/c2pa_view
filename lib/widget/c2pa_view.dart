import 'package:flutter/material.dart';

// Look at tmp/manifest_store_concat.json
// The assertions-labels in all examples are:
//    c2pa.actions                  <-- important
//    stds.schema-org.CreativeWork  <-- important
//    com.truepic.libc2pa           <-- not important
//    com.truepic.custom.odometry   <-- not important
//    stds.exif                     <-- what is this?

// Examples from:
//    https://c2pa.org/public-testfiles/image/
// Specifications:
//    https://c2pa.org/specifications/specifications/2.1/specs/C2PA_Specification.html#_assertions
// Example verify app:
//    https://contentcredentials.org/verify

class ContentCredentialWidget extends StatelessWidget {
  final Map<String, dynamic> manifestData;
  final Widget? contentPreview;
  final TextStyle? titleStyle;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentLabelStyle;
  final TextStyle? contentStyle;

  const ContentCredentialWidget({
    super.key,
    required this.manifestData,
    this.contentPreview,
    this.titleStyle,
    this.sectionTitleStyle,
    this.contentLabelStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Get styles
    final titleStyle = this.titleStyle ?? Theme.of(context).textTheme.headlineMedium;
    final sectionTitleStyle = this.sectionTitleStyle ?? Theme.of(context).textTheme.titleMedium;
    final contentLabelStyle = this.contentLabelStyle ?? Theme.of(context).textTheme.titleSmall;
    final contentStyle = this.contentStyle ?? Theme.of(context).textTheme.bodySmall;

    // Get active manifest tag
    final activeTag = manifestData['active_manifest'] as String;

    // Manifests
    final manifests = manifestData['manifests'] as Map<String, dynamic>;

    // Get active manifest data
    final activeManifest = manifests[activeTag] as Map<String, dynamic>;

    // Get top level information
    final title = activeManifest['title'] as String? ?? 'Unknown';

    // // Thumbnail info
    // final thumbnail = activeManifest['thumbnail'] as Map<String, dynamic>? ?? {};

    // Signature info
    final signature = activeManifest['signature_info']
      as Map<String, dynamic>? ?? {};
    final issuer = signature['issuer'] as String? ?? 'Unknown';
    // final certSerialNumber = signature['cert_serial_number	'] as String?
    //   ?? 'Unknown';
    final signTime = signature['time'] as String? ?? 'Unknown';


    final credit = manifestData['credit'] ?? 'Unknown';
    final process = manifestData['process'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (contentPreview != null) contentPreview!,
        SizedBox(height: 16),
        Text('Credit: $credit', style: contentStyle),
        SizedBox(height: 16),
        Text('Process:', style: sectionTitleStyle),
        if (process.isNotEmpty) ...[
          if (process['appOrDevice'] != null)
            Text('App/Device: ${process['appOrDevice']}', style: contentStyle),
          if (process['actions'] != null)
            Text('Actions: ${process['actions'].join(', ')}', style: contentStyle),
          if (process['ingredients'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingredients:', style: contentStyle),
                ...List<Widget>.from(
                  (process['ingredients'] as List).map((ingredient) => Text(
                    '- ${ingredient['filename']} (${ingredient['extension']})',
                    style: contentStyle,
                  )),
                ),
              ],
            ),
        ],
        SizedBox(height: 16),
        Text('About this Content Credential:', style: sectionTitleStyle),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Issued by', style: contentLabelStyle),
        ),
        Text(issuer, style: contentStyle),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Issued on', style: contentLabelStyle),
        ),
        Text(signTime, style: contentStyle)
      ],
    );
  }
}
