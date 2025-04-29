import 'dart:convert';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/widget/signature_info_widget.dart';
import 'package:flutter/material.dart';

import 'assertions_list_widget.dart';
import 'ingredients_list_widget.dart';
import 'actions_list_widget.dart';


/// A widget that displays a content credentials based on the provided source.
/// `source` can be a local path or File pointing at the source-file.
class ContentCredentialsWidget extends StatelessWidget {
  final dynamic source;
  final Widget? contentPreview;
  final TextStyle? titleStyle;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentLabelStyle;
  final TextStyle? contentStyle;

  const ContentCredentialsWidget({
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

    // Get the active manifest
    final activeManifest = manifestStore.manifests[manifestStore.activeManifest];
    if (activeManifest == null) {
      return const Text('No active manifest found');
    }

    // Get styles
    final titleStyle = this.titleStyle ?? Theme.of(context).textTheme.headlineMedium;
    final sectionTitleStyle = this.sectionTitleStyle ?? Theme.of(context).textTheme.titleMedium;
    final contentLabelStyle = this.contentLabelStyle ?? Theme.of(context).textTheme.titleSmall;
    final contentStyle = this.contentStyle ?? Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content preview
        if (contentPreview != null) ...[
          contentPreview!,
          const SizedBox(height: 16),
        ],

        // General Info
        if (activeManifest.title != null) ...[
          Text(activeManifest.title!, style: titleStyle),
          const SizedBox(height: 8),
        ],
        if (activeManifest.format != null) ...[
          Text('Format: ${activeManifest.format}', style: contentStyle),
          const SizedBox(height: 4),
        ],
        if (activeManifest.claimGenerator != null) ...[
          Text('Claim Generator: ${activeManifest.claimGenerator}', style: contentStyle),
          const SizedBox(height: 4),
        ],

        const SizedBox(height: 16),

        // Actions
        ActionsListWidget(
          actions: activeManifest.actions,
          sectionTitleStyle: sectionTitleStyle,
          contentStyle: contentStyle,
        ),

        const SizedBox(height: 16),

        // Ingredients
        IngredientListWidget(
          ingredients: activeManifest.ingredients,
          sectionTitleStyle: sectionTitleStyle,
          contentStyle: contentStyle,
        ),

        const SizedBox(height: 16),

        // Assertions
        AssertionsListWidget(
          assertions: activeManifest.assertions,
          sectionTitleStyle: sectionTitleStyle,
          contentStyle: contentStyle,
        ),

        const SizedBox(height: 16),

        // Signature Info
        SignatureInfoWidget(
          signatureInfo: activeManifest.signatureInfo,
          sectionTitleStyle: sectionTitleStyle,
          contentLabelStyle: contentLabelStyle,
          contentStyle: contentStyle,
        ),
      ],
    );
  }
}
