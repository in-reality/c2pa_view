import 'dart:convert';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/widget/actions_list_widget.dart';
import 'package:c2pa_view/widget/assertions_list_widget.dart';
import 'package:c2pa_view/widget/ingredients_list_widget.dart';
import 'package:c2pa_view/widget/signature_info_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


/// A widget that displays a content credentials based on the provided source.
/// `source` can be a local path or File pointing at the source-file.
class ContentCredentialsWidget extends StatelessWidget {

  /// Creates an instance of [ContentCredentialsWidget].
  const ContentCredentialsWidget({
    required this.source, super.key,
    this.contentPreview,
    this.titleStyle,
    this.sectionTitleStyle,
    this.contentLabelStyle,
    this.contentStyle,
  });

  /// The source of the content credentials, which can be a local path or File.
  final dynamic source;

  /// The widget to display as a preview of the content.
  final Widget? contentPreview;

  /// The style for the title text.
  final TextStyle? titleStyle;

  /// The style for the section title text.
  final TextStyle? sectionTitleStyle;

  /// The style for the content label text.
  final TextStyle? contentLabelStyle;

  /// The style for the content text.
  final TextStyle? contentStyle;

  @override
  Widget build(final BuildContext context) {
    // Get manifest
    final manifest = getC2PAManifest(source);

    // Check if manifest is null
    if (manifest == null) {
      return const Text('No manifest found');
    }

    // Parse to entity
    final manifestStore = ManifestStore.fromJson(
      json.decode(manifest),
    );

    // Get the active manifest
    final activeManifest = manifestStore
      .manifests[manifestStore.activeManifest];
    if (activeManifest == null) {
      return const Text('No active manifest found');
    }

    // Get styles
    final titleStyle = this.titleStyle ?? Theme.of(context)
      .textTheme.headlineMedium;
    final sectionTitleStyle = this.sectionTitleStyle ?? Theme.of(context)
      .textTheme.titleMedium;
    final contentLabelStyle = this.contentLabelStyle ?? Theme.of(context)
      .textTheme.titleSmall;
    final contentStyle = this.contentStyle ?? Theme.of(context)
      .textTheme.bodyMedium;

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
          Text(
            'Claim Generator: ${activeManifest.claimGenerator}',
            style: contentStyle,
          ),
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

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('source', source))
    ..add(DiagnosticsProperty<TextStyle?>('titleStyle', titleStyle))
    ..add(DiagnosticsProperty<TextStyle?>(
        'sectionTitleStyle', sectionTitleStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>(
        'contentLabelStyle', contentLabelStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>('contentStyle', contentStyle));
  }
}
