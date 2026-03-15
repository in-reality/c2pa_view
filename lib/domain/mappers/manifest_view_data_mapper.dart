import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide Action;

import 'package:c2pa_view/domain/entities/action.dart';
import 'package:c2pa_view/domain/entities/creative_work.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/domain/entities/exif_data.dart';
import 'package:c2pa_view/domain/entities/ingredient.dart';
import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/thumbnail_data.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';

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
  static ManifestViewData map(Manifest manifest) {
    return ManifestViewData(
      title: manifest.title,
      thumbnail: _toImageProvider(manifest.thumbnail),
      validationResult: mapValidation(manifest.validationStatus),
      issuer: manifest.signatureInfo?.issuer,
      signedDate: manifest.signatureInfo?.time,
      generativeInfo: _extractGenerativeInfo(manifest),
      claimGenerator: _mapClaimGenerator(manifest),
      actions: _mapActions(manifest.actions),
      ingredients: _mapIngredients(manifest.ingredients),
      aiToolsUsed: _extractAiTools(manifest),
      exifData: _mapExif(manifest.exifData),
      producer: manifest.creativeWork?.producer,
      socialAccounts: _mapSocial(manifest.creativeWork?.socialAccounts),
      doNotTrain: manifest.trainingMining?.doNotTrain ?? false,
      website: manifest.creativeWork?.website,
      customFields: manifest.customFields,
      exifCustomFields: manifest.exifData?.customFields ?? const [],
      creativeWorkCustomFields: manifest.creativeWork?.customFields ?? const [],
    );
  }

  static ValidationResult mapValidation(
    List<ValidationStatusEntry> statuses,
  ) {
    if (statuses.isEmpty) return const ValidationResult.noCredential();
    final hasError = statuses.any((s) => s.isError);
    if (hasError) {
      final msg =
          statuses.where((s) => s.isError).map((s) => s.explanation).join('; ');
      return ValidationResult.invalid(msg.isEmpty ? null : msg);
    }
    return const ValidationResult.valid();
  }

  static ImageProvider? _toImageProvider(ThumbnailData? thumbnailData) {
    if (thumbnailData == null) return null;
    if (thumbnailData.data != null && thumbnailData.data!.isNotEmpty) {
      return MemoryImage(thumbnailData.data!);
    }
    if (thumbnailData.identifier != null) {
      final id = thumbnailData.identifier!;
      if (id.startsWith('data:')) {
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

  static GenerativeInfo? _extractGenerativeInfo(Manifest manifest) {
    if (manifest.actions == null) return null;

    var hasAiGeneration = false;
    var hasComposite = false;
    final agents = <String>[];

    for (final action in manifest.actions!) {
      final sourceType = action.sourceType ??
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

  static ClaimGeneratorDisplayInfo? _mapClaimGenerator(Manifest manifest) {
    if (manifest.claimGeneratorInfo.isNotEmpty) {
      final info = manifest.claimGeneratorInfo.first;
      return ClaimGeneratorDisplayInfo(
        name: info.name,
        version: info.version,
      );
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

  static List<ActionDisplayInfo> _mapActions(List<Action>? actions) {
    if (actions == null) return [];
    return actions.map<ActionDisplayInfo>((a) {
      final sourceType =
          a.sourceType ?? a.parameters?['digitalSourceType'] as String?;
      final isAi = sourceType != null &&
          (sourceType.toLowerCase().contains('trainedalgorithmicmedia') ||
              sourceType.toLowerCase().contains('algorithmicmedia'));

      final customParams = <CustomField>[];
      if (a.parameters != null) {
        for (final entry in a.parameters!.entries) {
          if (!_knownActionParams.contains(entry.key)) {
            customParams.add(CustomField(
              key: entry.key,
              value: entry.value,
              source: 'action_parameter',
              parentLabel: a.action,
            ));
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
    List<Ingredient> ingredients,
  ) {
    return ingredients.map((i) {
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

      return IngredientDisplayInfo(
        title: i.title,
        thumbnail: _toImageProvider(i.thumbnail),
        format: i.format,
        relationship: relationship,
        hasManifest: i.activeManifest != null,
      );
    }).toList();
  }

  static List<String> _extractAiTools(Manifest manifest) {
    if (manifest.actions == null) return [];
    final tools = <String>{};
    for (final action in manifest.actions!) {
      final sourceType =
          action.sourceType ?? action.parameters?['digitalSourceType'] as String?;
      if (sourceType != null &&
          sourceType.toLowerCase().contains('trainedalgorithmicmedia')) {
        final agent = action.parameters?['softwareAgent'] as String?;
        if (agent != null) tools.add(agent);
      }
    }
    return tools.toList();
  }

  static ExifDisplayData? _mapExif(ExifData? exifData) {
    if (exifData == null) return null;
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
    List<SocialAccount>? accounts,
  ) {
    if (accounts == null) return [];
    return accounts
        .map((a) => SocialAccountDisplayInfo(platform: a.platform, url: a.url))
        .toList();
  }
}
