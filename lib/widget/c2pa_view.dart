import 'dart:convert';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/material.dart';

class IngredientListWidget extends StatelessWidget {
  final List<Ingredient> ingredients;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentStyle;

  const IngredientListWidget({
    super.key,
    required this.ingredients,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...ingredients.map((ingredient) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            '- ${ingredient.title ?? 'Unknown'}',
            style: contentStyle,
          ),
        )),
      ],
    );
  }
}

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
            '- ${assertion.label ?? 'Unknown'}',
            style: contentStyle,
          ),
        )),
      ],
    );
  }
}

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
