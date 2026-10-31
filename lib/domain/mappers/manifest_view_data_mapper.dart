import 'dart:convert';
import 'dart:typed_data';

import 'package:c2pa_view/domain/entities/action.dart';
import 'package:c2pa_view/domain/entities/creative_work.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/domain/entities/exif_data.dart';
import 'package:c2pa_view/domain/entities/ingredient.dart';
import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/entities/thumbnail_data.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/widgets.dart' hide Action;

/// Action parameter keys that are already represented as structured fields
/// on [ActionDisplayInfo] and should not be treated as custom params.
const _knownActionParams = {
  'name',
  'description',
  'softwareAgent',
  'digitalSourceType',
  'when',
  'changed',
  'instanceId',
};

/// Converts a [Manifest] domain entity into a [ManifestViewData] view model.
class ManifestViewDataMapper {
  static ManifestViewData map(
    final Manifest manifest, {
    final Map<String, dynamic>? rawJson,
    final Map<String, ManifestSummary>? summaries,
    final ManifestSummary? previewSummary,
  }) => ManifestViewData(
    title: manifest.title,
    thumbnail: previewSummary?.thumbnail ?? imageProvider(manifest.thumbnail),
    previewSource:
        previewSummary?.previewSource ??
        (imageProvider(manifest.thumbnail) == null
            ? null
            : PreviewSource(
                containingManifest:
                    manifest.thumbnail?.containingManifest ??
                    manifest.label ??
                    '',
                validationResult: _previewValidation(manifest),
              )),
    inputValidationEvidence:
        previewSummary?.inputValidationEvidence ?? const [],
    validationResult:
        previewSummary?.validationResult ??
        mapValidation(
          manifest.validationStatus,
          isComputed: manifest.validationStatusComputed,
        ),
    validationFailures: [
      ...manifest.validationStatus.where((final s) => s.isError),
      ...?previewSummary?.inputValidationEvidence.expand(
        (final evidence) => evidence.failures,
      ),
    ],
    issuer: manifest.signatureInfo?.issuer,
    signedDate: manifest.signatureInfo?.time,
    generativeInfo: _extractGenerativeInfo(manifest),
    claimGenerator: _mapClaimGenerator(manifest),
    actions: _mapActions(manifest.actions),
    ingredients: _mapIngredients(manifest, summaries),
    aiToolsUsed: _extractAiTools(manifest),
    exifData: _mapExif(manifest.exifData),
    producer: manifest.creativeWork?.producer,
    socialAccounts: _mapSocial(manifest.creativeWork?.socialAccounts),
    doNotTrain: manifest.trainingMining?.doNotTrain ?? false,
    website: manifest.creativeWork?.website,
    customFields: manifest.customFields,
    exifCustomFields: manifest.exifData?.customFields ?? const [],
    creativeWorkCustomFields: manifest.creativeWork?.customFields ?? const [],
    rawJson: rawJson,
  );

  /// Summaries shared by the portable graph and InReality backbone.
  /// Own images always win. Shared ancestors use the first consuming claim in
  /// sorted label order so fallback attribution is stable across map ordering.
  static Map<String, ManifestSummary> buildSummaries(
    final ManifestStore store,
  ) {
    final result = <String, ManifestSummary>{};
    final labels = store.manifests.keys.toList()..sort();
    for (final label in labels) {
      final manifest = store.manifests[label]!;
      final image = imageProvider(manifest.thumbnail);
      result[label] = ManifestSummary(
        title: manifest.title,
        thumbnail: image,
        previewSource: image == null
            ? null
            : PreviewSource(
                containingManifest: label,
                validationResult: _previewValidation(manifest),
              ),
        validationResult: mapValidation(
          manifest.validationStatus,
          isComputed: manifest.validationStatusComputed,
        ),
        issuer: manifest.signatureInfo?.issuer,
      );
    }
    for (final label in labels) {
      for (final ingredient in store.manifests[label]!.ingredients) {
        final target = ingredient.activeManifest;
        final summary = result[target];
        final failures = ingredient.inputValidationFailures;
        if (summary == null || failures.isEmpty) continue;
        final evidence = [
          ...summary.inputValidationEvidence,
          InputValidationEvidence(
            containingManifest: label,
            failures: failures,
            containingValidation: _previewValidation(store.manifests[label]!),
          ),
        ];
        result[target!] = ManifestSummary(
          title: summary.title,
          thumbnail: summary.thumbnail,
          previewSource: summary.previewSource,
          issuer: summary.issuer,
          inputValidationEvidence: evidence,
          validationResult: mapValidation([
            ...store.manifests[target]!.validationStatus,
            ...evidence.expand((final item) => item.failures),
          ], isComputed: store.manifests[target]!.validationStatusComputed),
        );
      }
    }
    for (final label in labels) {
      final manifest = store.manifests[label]!;
      for (final ingredient in manifest.ingredients) {
        final target = ingredient.activeManifest;
        final summary = result[target];
        if (summary == null || summary.thumbnail != null) continue;
        final fallback = ingredientSummary(
          ingredient,
          manifest,
          containingLabel: label,
        );
        if (fallback.thumbnail == null) continue;
        result[target!] = ManifestSummary(
          title: summary.title,
          thumbnail: fallback.thumbnail,
          previewSource: fallback.previewSource,
          inputValidationEvidence: summary.inputValidationEvidence,
          validationResult: summary.validationResult,
          issuer: summary.issuer,
        );
      }
    }
    return result;
  }

  /// An unresolved leaf keeps no credential; its preview belongs to its parent.
  static ManifestSummary ingredientSummary(
    final Ingredient ingredient,
    final Manifest containing, {
    final String? containingLabel,
  }) {
    final image = imageProvider(ingredient.thumbnail);
    return ManifestSummary(
      title: ingredient.title,
      inputValidationEvidence: ingredient.inputValidationFailures.isEmpty
          ? const []
          : [
              InputValidationEvidence(
                containingManifest: containingLabel ?? containing.label ?? '',
                failures: ingredient.inputValidationFailures,
                containingValidation: _previewValidation(containing),
              ),
            ],
      thumbnail: image,
      previewSource: image == null
          ? null
          : PreviewSource(
              containingManifest:
                  containingLabel ??
                  ingredient.thumbnail?.containingManifest ??
                  containing.label ??
                  '',
              validationResult: _previewValidation(containing),
              isIngredient: true,
            ),
    );
  }

  static ValidationResult? _previewValidation(final Manifest manifest) =>
      manifest.validationStatusComputed == true ||
          manifest.validationStatus.isNotEmpty
      ? mapValidation(
          manifest.validationStatus,
          isComputed: manifest.validationStatusComputed,
        )
      : null;

  /// Maps supplied diagnostics without inferring a check from an absent list.
  ///
  /// Bare-list callers retain the historical computed-list contract. Callers
  /// holding a Manifest must pass its validationStatusComputed flag. Nonempty
  /// failure/untrusted evidence takes precedence even when that flag is false.
  static ValidationResult mapValidation(
    final List<ValidationStatusEntry> statuses, {
    final bool isComputed = true,
  }) {
    if (statuses.isEmpty) {
      return isComputed
          ? const ValidationResult.valid()
          : const ValidationResult.notVerified();
    }
    final hasError = statuses.any((final s) => s.isError);
    if (hasError) {
      final msg = statuses
          .where((final s) => s.isError)
          .map((final s) => s.explanation)
          .join('; ');
      return ValidationResult.invalid(msg.isEmpty ? null : msg);
    }
    // No genuine errors — check whether the signer is outside a trust list.
    final hasUntrusted = statuses.any((final s) => s.isUntrusted);
    if (hasUntrusted) {
      return const ValidationResult.untrusted();
    }
    return isComputed
        ? const ValidationResult.valid()
        : const ValidationResult.notVerified();
  }

  /// Builds a local image only from bounded embedded bytes or legacy data URIs.
  static ImageProvider? imageProvider(final ThumbnailData? thumbnailData) {
    if (thumbnailData == null ||
        !const ['image/jpeg', 'image/png'].contains(thumbnailData.format) ||
        (thumbnailData.resolution != null &&
            thumbnailData.resolution != 'resolved')) {
      return null;
    }
    if (thumbnailData.data != null &&
        thumbnailData.data!.isNotEmpty &&
        thumbnailData.data!.length <= 1024 * 1024) {
      return MemoryImage(thumbnailData.data!);
    }
    if (thumbnailData.identifier != null) {
      final id = thumbnailData.identifier!;
      if (id.startsWith('data:') && id.length <= 1400000) {
        final commaIndex = id.indexOf(',');
        if (commaIndex != -1) {
          try {
            final bytes = base64Decode(id.substring(commaIndex + 1));
            return MemoryImage(Uint8List.fromList(bytes));
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  static GenerativeInfo? _extractGenerativeInfo(final Manifest manifest) {
    if (manifest.actions == null) {
      return null;
    }

    var hasAiGeneration = false;
    var hasComposite = false;
    final agents = <String>[];

    for (final action in manifest.actions!) {
      final sourceType =
          action.sourceType ??
          action.parameters?['digitalSourceType'] as String?;

      if (sourceType != null) {
        final lower = sourceType.toLowerCase();
        if (lower.contains('trainedalgorithmicmedia') ||
            lower.contains('algorithmicmedia') ||
            lower.contains('digitalart')) {
          hasAiGeneration = true;
        }
        if (lower.contains('compositewithtrained') ||
            lower.contains('composite')) {
          hasComposite = true;
        }
      }

      final agent = action.parameters?['softwareAgent'] as String?;
      if (agent != null && !agents.contains(agent)) {
        agents.add(agent);
      }
    }

    if (hasAiGeneration && hasComposite) {
      return GenerativeInfo(
        type: GenerativeType.compositeWithAi,
        softwareAgents: agents,
      );
    }
    if (hasAiGeneration) {
      return GenerativeInfo(
        type: GenerativeType.aiGenerated,
        softwareAgents: agents,
      );
    }

    return null;
  }

  static ClaimGeneratorDisplayInfo? _mapClaimGenerator(
    final Manifest manifest,
  ) {
    if (manifest.claimGeneratorInfo.isNotEmpty) {
      final info = manifest.claimGeneratorInfo.first;
      return ClaimGeneratorDisplayInfo(name: info.name, version: info.version);
    }
    if (manifest.claimGenerator != null) {
      final parts = manifest.claimGenerator!.split('/');
      return ClaimGeneratorDisplayInfo(
        name: parts.first.replaceAll('_', ' '),
        version: parts.length > 1 ? parts.sublist(1).join('/') : null,
      );
    }
    return null;
  }

  static List<ActionDisplayInfo> _mapActions(final List<Action>? actions) {
    if (actions == null) {
      return [];
    }
    return actions.map<ActionDisplayInfo>((final a) {
      final sourceType =
          a.sourceType ?? a.parameters?['digitalSourceType'] as String?;
      final isAi =
          sourceType != null &&
          (sourceType.toLowerCase().contains('trainedalgorithmicmedia') ||
              sourceType.toLowerCase().contains('algorithmicmedia'));

      final customParams = <CustomField>[];
      if (a.parameters != null) {
        for (final entry in a.parameters!.entries) {
          if (!_knownActionParams.contains(entry.key)) {
            customParams.add(
              CustomField(
                key: entry.key,
                value: entry.value,
                source: 'action_parameter',
                parentLabel: a.action,
              ),
            );
          }
        }
      }

      return ActionDisplayInfo(
        actionType: a.action,
        label: ActionDisplayInfo.humanLabel(a.action),
        when: a.when != null ? DateTime.tryParse(a.when!) : null,
        softwareAgent: a.parameters?['softwareAgent'] as String?,
        isAiGenerated: isAi,
        customParams: customParams,
      );
    }).toList();
  }

  static List<IngredientDisplayInfo> _mapIngredients(
    final Manifest manifest,
    final Map<String, ManifestSummary>? summaries,
  ) => manifest.ingredients.map((final i) {
    IngredientRelationship? relationship;
    if (i.relationship != null) {
      switch (i.relationship) {
        case 'parentOf':
          relationship = IngredientRelationship.parentOf;
        case 'componentOf':
          relationship = IngredientRelationship.componentOf;
        case 'inputTo':
          relationship = IngredientRelationship.inputTo;
      }
    }

    // Look up the pre-computed summary for this ingredient's manifest.
    // This is the same ManifestSummary that the corresponding ProvenanceNode
    // carries, ensuring the ingredient list item and the tree node always
    // show identical data.
    // When no manifest is resolved we still build a summary with the
    // ingredient's title so that it shows the name rather than "Untitled".
    final resolvedSummary = (i.activeManifest != null && summaries != null)
        ? summaries[i.activeManifest]
        : null;
    final hasManifest = resolvedSummary != null || i.activeManifest != null;

    return IngredientDisplayInfo(
      summary: resolvedSummary ?? ingredientSummary(i, manifest),
      hasManifest: hasManifest,
      format: i.format,
      relationship: relationship,
    );
  }).toList();

  static List<String> _extractAiTools(final Manifest manifest) {
    if (manifest.actions == null) {
      return [];
    }
    final tools = <String>{};
    for (final action in manifest.actions!) {
      final sourceType =
          action.sourceType ??
          action.parameters?['digitalSourceType'] as String?;
      if (sourceType != null &&
          sourceType.toLowerCase().contains('trainedalgorithmicmedia')) {
        final agent = action.parameters?['softwareAgent'] as String?;
        if (agent != null) {
          tools.add(agent);
        }
      }
    }
    return tools.toList();
  }

  static ExifDisplayData? _mapExif(final ExifData? exifData) {
    if (exifData == null) {
      return null;
    }
    return ExifDisplayData(
      creator: exifData.creator,
      copyright: exifData.copyright,
      captureDate: exifData.captureDate,
      cameraMake: exifData.cameraMake,
      cameraModel: exifData.cameraModel,
      lensMake: exifData.lensMake,
      lensModel: exifData.lensModel,
      exposureTime: exifData.exposureTime,
      fNumber: exifData.fNumber,
      focalLength: exifData.focalLength,
      iso: exifData.iso,
      width: exifData.width,
      height: exifData.height,
      latitude: exifData.latitude,
      longitude: exifData.longitude,
    );
  }

  static List<SocialAccountDisplayInfo> _mapSocial(
    final List<SocialAccount>? accounts,
  ) {
    if (accounts == null) {
      return [];
    }
    return accounts
        .map(
          (final a) =>
              SocialAccountDisplayInfo(platform: a.platform, url: a.url),
        )
        .toList();
  }
}
