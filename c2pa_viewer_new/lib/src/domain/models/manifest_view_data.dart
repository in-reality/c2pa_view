import 'package:flutter/widgets.dart';

import 'validation_result.dart';

/// Display-ready data for the manifest detail panel.
///
/// This is the primary view model for the right sidebar. Construct it
/// directly, or use [ManifestViewData.fromC2paManifest] for convenience
/// when working with raw C2PA model classes.
@immutable
class ManifestViewData {
  final String? title;
  final ImageProvider? thumbnail;
  final ValidationResult validationResult;

  // Signature
  final String? issuer;
  final DateTime? signedDate;

  // Content summary / AI
  final GenerativeInfo? generativeInfo;

  // Process
  final ClaimGeneratorDisplayInfo? claimGenerator;
  final List<ActionDisplayInfo> actions;
  final List<IngredientDisplayInfo> ingredients;
  final List<String> aiToolsUsed;

  // Camera / EXIF
  final ExifDisplayData? exifData;

  // About
  final String? producer;
  final List<SocialAccountDisplayInfo> socialAccounts;
  final bool doNotTrain;
  final String? website;

  const ManifestViewData({
    this.title,
    this.thumbnail,
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
    this.signedDate,
    this.generativeInfo,
    this.claimGenerator,
    this.actions = const [],
    this.ingredients = const [],
    this.aiToolsUsed = const [],
    this.exifData,
    this.producer,
    this.socialAccounts = const [],
    this.doNotTrain = false,
    this.website,
  });
}

/// AI generation information.
@immutable
class GenerativeInfo {
  final GenerativeType type;
  final List<String> softwareAgents;

  const GenerativeInfo({
    required this.type,
    this.softwareAgents = const [],
  });

  String get description {
    switch (type) {
      case GenerativeType.aiGenerated:
        return 'This content was generated with an AI tool.';
      case GenerativeType.compositeWithAi:
        return 'This content combines multiple pieces of content. '
            'At least one was generated with an AI tool.';
      case GenerativeType.legacy:
        return 'This content may include AI-generated elements.';
    }
  }
}

enum GenerativeType {
  aiGenerated,
  compositeWithAi,
  legacy,
}

/// Display info for the claim generator (app/device).
@immutable
class ClaimGeneratorDisplayInfo {
  final String name;
  final String? version;
  final ImageProvider? icon;

  const ClaimGeneratorDisplayInfo({
    required this.name,
    this.version,
    this.icon,
  });

  String get displayLabel =>
      version != null ? '$name $version' : name;
}

/// Display info for a single action in the process section.
@immutable
class ActionDisplayInfo {
  final String actionType;
  final String label;
  final DateTime? when;
  final String? softwareAgent;
  final bool isAiGenerated;

  const ActionDisplayInfo({
    required this.actionType,
    required this.label,
    this.when,
    this.softwareAgent,
    this.isAiGenerated = false,
  });

  static String humanLabel(String actionType) {
    const labels = {
      'c2pa.created': 'Created',
      'c2pa.opened': 'Opened',
      'c2pa.placed': 'Placed',
      'c2pa.edited': 'Edited',
      'c2pa.cropped': 'Cropped',
      'c2pa.resized': 'Resized',
      'c2pa.color_adjustments': 'Color adjustments',
      'c2pa.drawing': 'Drawing',
      'c2pa.filtered': 'Filtered',
      'c2pa.orientation': 'Orientation changed',
      'c2pa.published': 'Published',
      'c2pa.transcoded': 'Transcoded',
      'c2pa.unknown': 'Unknown action',
    };
    return labels[actionType] ?? actionType.replaceAll('c2pa.', '');
  }
}

/// Display info for an ingredient in the process section.
@immutable
class IngredientDisplayInfo {
  final String? title;
  final ImageProvider? thumbnail;
  final String? format;
  final IngredientRelationship? relationship;
  final bool hasManifest;
  final String? issuer;
  final DateTime? signedDate;

  const IngredientDisplayInfo({
    this.title,
    this.thumbnail,
    this.format,
    this.relationship,
    this.hasManifest = false,
    this.issuer,
    this.signedDate,
  });
}

enum IngredientRelationship {
  parentOf,
  componentOf,
  inputTo,
}

/// Display-ready EXIF / camera capture data.
@immutable
class ExifDisplayData {
  final String? creator;
  final String? copyright;
  final DateTime? captureDate;
  final String? cameraMake;
  final String? cameraModel;
  final String? lensMake;
  final String? lensModel;
  final String? exposureTime;
  final String? fNumber;
  final String? focalLength;
  final String? iso;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;

  const ExifDisplayData({
    this.creator,
    this.copyright,
    this.captureDate,
    this.cameraMake,
    this.cameraModel,
    this.lensMake,
    this.lensModel,
    this.exposureTime,
    this.fNumber,
    this.focalLength,
    this.iso,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String? get dimensionsLabel =>
      (width != null && height != null) ? '$width x $height' : null;

  String? get cameraLabel {
    if (cameraMake != null && cameraModel != null) {
      if (cameraModel!.startsWith(cameraMake!)) return cameraModel;
      return '$cameraMake $cameraModel';
    }
    return cameraModel ?? cameraMake;
  }

  String? get lensLabel {
    if (lensMake != null && lensModel != null) {
      if (lensModel!.startsWith(lensMake!)) return lensModel;
      return '$lensMake $lensModel';
    }
    return lensModel ?? lensMake;
  }
}

/// Social account display info.
@immutable
class SocialAccountDisplayInfo {
  final String platform;
  final String url;

  const SocialAccountDisplayInfo({
    required this.platform,
    required this.url,
  });
}
