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
  /// Projects supplied claim data without fetching ancestors or inferring checks.
  /// [containingLabel] supplies store-key identity when the payload lacks a label.
  static ManifestViewData map(
    final Manifest manifest, {
    final Map<String, dynamic>? rawJson,
    final Map<String, ManifestSummary>? summaries,
    final ManifestSummary? previewSummary,
    final String? containingLabel,
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
    ingredientDescriptions:
        previewSummary?.ingredientDescriptions ??
        _directDescriptions(manifest, label: containingLabel),
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
    ingredients: _mapIngredients(manifest, summaries, containingLabel),
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
    final reachable = _reachableLabels(store, store.activeManifest);
    final direct = {
      for (final label in labels)
        label: _directDescriptions(store.manifests[label]!, label: label),
    };
    final descriptions = <String, List<IngredientDescription>>{};
    for (final label in labels) {
      final ancestry = _reachableLabels(store, label);
      descriptions[label] = mergeIngredientDescriptions([
        for (final ancestor in ancestry) ...direct[ancestor]!,
        for (final consumer in reachable)
          for (final note in direct[consumer]!)
            if (note.targetManifest == label)
              IngredientDescription(
                containingManifest: note.containingManifest,
                ingredientIndex: note.ingredientIndex,
                description: note.description,
                ingredientLabel: note.ingredientLabel,
                ingredientTitle: note.ingredientTitle,
                targetManifest: note.targetManifest,
                isExternalIncomingEdge: true,
              ),
      ]);
    }
    for (final label in labels) {
      final manifest = store.manifests[label]!;
      final image = imageProvider(manifest.thumbnail);
      result[label] = ManifestSummary(
        title: manifest.title,
        ingredientDescriptions: descriptions[label]!,
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
          ingredientDescriptions: summary.ingredientDescriptions,
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
          ingredientDescriptions: summary.ingredientDescriptions,
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
  /// Without an explicit index, only a unique identical containing object
  /// establishes an edge. Equal values and detached objects cannot invent one.
  static ManifestSummary ingredientSummary(
    final Ingredient ingredient,
    final Manifest containing, {
    final String? containingLabel,
    final int? ingredientIndex,
  }) {
    final positions = [
      for (var index = 0; index < containing.ingredients.length; index++)
        if (identical(containing.ingredients[index], ingredient)) index,
    ];
    final index =
        ingredientIndex ?? (positions.length == 1 ? positions.single : null);
    final image = imageProvider(ingredient.thumbnail);
    return ManifestSummary(
      title: ingredient.title,
      ingredientDescriptions: [
        if (index != null &&
            index >= 0 &&
            index < containing.ingredients.length &&
            containing.ingredients[index] == ingredient)
          if (_description(
                ingredient,
                containing,
                index,
                label: containingLabel,
                externalIncoming: true,
              )
              case final note?)
            note,
      ],
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
    final String? containingLabel,
  ) => [
    for (var index = 0; index < manifest.ingredients.length; index++)
      _mapIngredient(manifest, index, summaries, containingLabel),
  ];

  static IngredientDisplayInfo _mapIngredient(
    final Manifest manifest,
    final int index,
    final Map<String, ManifestSummary>? summaries,
    final String? containingLabel,
  ) {
    final ingredient = manifest.ingredients[index];
    final relationship = switch (ingredient.relationship) {
      'parentOf' => IngredientRelationship.parentOf,
      'componentOf' => IngredientRelationship.componentOf,
      'inputTo' => IngredientRelationship.inputTo,
      _ => null,
    };
    final resolved = summaries?[ingredient.activeManifest];
    final base =
        resolved ??
        ingredientSummary(
          ingredient,
          manifest,
          ingredientIndex: index,
          containingLabel: containingLabel,
        );
    final descriptions = mergeIngredientDescriptions([
      if (_description(ingredient, manifest, index, label: containingLabel)
          case final note?)
        note,
      ...base.ingredientDescriptions.where(
        (final note) => !note.isExternalIncomingEdge,
      ),
    ]);
    return IngredientDisplayInfo(
      summary: ManifestSummary(
        title: base.title,
        thumbnail: base.thumbnail,
        previewSource: base.previewSource,
        inputValidationEvidence: base.inputValidationEvidence,
        ingredientDescriptions: descriptions,
        validationResult: base.validationResult,
        issuer: base.issuer,
      ),
      hasManifest: resolved != null || ingredient.activeManifest != null,
      format: ingredient.format,
      relationship: relationship,
    );
  }

  static IngredientDescription? _description(
    final Ingredient ingredient,
    final Manifest containing,
    final int index, {
    final String? label,
    final bool externalIncoming = false,
  }) {
    final text = ingredient.description;
    if (text == null || text.isEmpty) {
      return null;
    }
    return IngredientDescription(
      containingManifest: label ?? containing.label ?? '',
      ingredientIndex: index,
      description: text,
      ingredientLabel: ingredient.label,
      ingredientTitle: ingredient.title,
      targetManifest: ingredient.activeManifest,
      isExternalIncomingEdge: externalIncoming,
    );
  }

  static List<IngredientDescription> _directDescriptions(
    final Manifest manifest, {
    final String? label,
  }) => [
    for (var index = 0; index < manifest.ingredients.length; index++)
      if (_description(
            manifest.ingredients[index],
            manifest,
            index,
            label: label,
          )
          case final note?)
        note,
  ];

  static Set<String> _reachableLabels(
    final ManifestStore store,
    final String? start,
  ) {
    final visited = <String>{};
    final pending = [if (start != null) start];
    while (pending.isNotEmpty) {
      final label = pending.removeLast();
      final manifest = store.manifests[label];
      if (manifest == null || !visited.add(label)) {
        continue;
      }
      pending.addAll(
        manifest.ingredients
            .map((final ingredient) => ingredient.activeManifest)
            .whereType<String>(),
      );
    }
    return visited;
  }

  /// Unions recorded edges without combining equal prose on distinct edges.
  static List<IngredientDescription> mergeIngredientDescriptions(
    final Iterable<IngredientDescription> notes,
  ) {
    final seen = <(String, int)>{};
    return List.unmodifiable([
      for (final note in notes)
        if (seen.add((note.containingManifest, note.ingredientIndex))) note,
    ]);
  }

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
