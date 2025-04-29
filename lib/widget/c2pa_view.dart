import 'dart:convert';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/material.dart';

/// A widget that displays a content credential based on the provided source.
/// `source` can be a local path or File pointing at the source-file.
class ContentCredentialWidget extends StatelessWidget {
  final dynamic source;
  final Widget? contentPreview;
  final TextStyle? titleStyle;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentLabelStyle;
  final TextStyle? contentStyle;

  const ContentCredentialWidget({
    super.key,
    required this.source,
    this.contentPreview,
    this.titleStyle,
    this.sectionTitleStyle,
    this.contentLabelStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Get manifest
    String? manifest = getC2PAManifest(source);

    // Check if manifest is null
    if (manifest == null) {
      return const Text('No manifest found');
    }

    // Parse to entity
    ManifestStore manifestStore = ManifestStore.fromJson(
      json.decode(manifest),
    );

    // Parse
    Map<String, dynamic> manifestData = json.decode(manifest);

    // Get styles
    final titleStyle = this.titleStyle ?? Theme.of(context).textTheme.headlineMedium;
    final sectionTitleStyle = this.sectionTitleStyle ?? Theme.of(context).textTheme.titleMedium;
    final contentLabelStyle = this.contentLabelStyle ?? Theme.of(context).textTheme.titleSmall;
    final contentStyle = this.contentStyle ?? Theme.of(context).textTheme.bodyMedium;

    // Get active manifest tag
    final activeTag = manifestData['active_manifest'] as String;

    // Manifests
    final manifests = manifestData['manifests'] as Map<String, dynamic>;

    // Get active manifest data
    final activeManifest = manifests[activeTag] as Map<String, dynamic>;

    // Get top level information
    final title = activeManifest['title'] as String? ?? 'Unknown';

    // Ingredients
    final ingredients = activeManifest['ingredients'] as List<dynamic>? ?? [];

    // Signature info
    final signature = activeManifest['signature_info']
      as Map<String, dynamic>? ?? {};
    final issuer = signature['issuer'] as String? ?? 'Unknown';
    // final certSerialNumber = signature['cert_serial_number	'] as String?
    //   ?? 'Unknown';
    final signTime = signature['time'] as String? ?? 'Unknown';

    // Credit
    final credit = manifestData['credit'] ?? 'Unknown';

    // Build
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(title, style: titleStyle),

        // Content preview
        if (contentPreview != null) ...[
          SizedBox(height: 16),
          contentPreview!,
        ],

        // Credit
        SizedBox(height: 16),
        Text('Credit: $credit', style: contentStyle),

        // Ingredients
        if (ingredients.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('Ingredients:', style: sectionTitleStyle),
          ...List<Widget>.from(
            ingredients.map((ingredient) => Text(
              '- ${ingredient['title']}',
              style: contentStyle,
            )),
          ),
        ],

        // Signing
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
