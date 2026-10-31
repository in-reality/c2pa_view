import 'package:c2pa_view/domain/entities/action.dart';
import 'package:c2pa_view/domain/entities/claim_generator_info.dart';
import 'package:c2pa_view/domain/entities/creative_work.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/domain/entities/exif_data.dart';
import 'package:c2pa_view/domain/entities/ingredient.dart';
import 'package:c2pa_view/domain/entities/manifest_assertion.dart';
import 'package:c2pa_view/domain/entities/signature_info.dart';
import 'package:c2pa_view/domain/entities/thumbnail_data.dart';
import 'package:c2pa_view/domain/entities/training_mining.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:equatable/equatable.dart';

/// Labels of known assertions that get routed to structured fields.
const _routedAssertionLabels = {
  'c2pa.actions',
  'c2pa.actions.v2',
  'stds.exif',
  'stds.schema-org.CreativeWork',
  'c2pa.training-mining',
};

/// Prefixes for assertions that are not custom.
const _internalAssertionPrefixes = ['c2pa.thumbnail.', 'c2pa.hash.'];

/// Domain entity representing a C2PA Content Credential Manifest.
class Manifest extends Equatable {
  const Manifest({
    this.claimGenerator,
    this.title,
    this.format,
    this.label,
    this.instanceId,
    this.ingredients = const [],
    this.assertions = const [],
    this.actions,
    this.signatureInfo,
    this.claimGeneratorInfo = const [],
    this.thumbnail,
    this.exifData,
    this.creativeWork,
    this.trainingMining,
    this.validationStatus = const [],
    this.validationStatusComputed = false,
    this.customFields = const [],
  });

  /// Parses a Manifest from a JSON map.
  factory Manifest.fromJson(
    final Map<String, dynamic> json, {
    final bool previewsTruncated = false,
  }) {
    // Parse all assertions
    final allAssertions = <ManifestAssertion>[];
    if (json['assertions'] is List) {
      for (final item in json['assertions'] as List) {
        if (item is Map<String, dynamic>) {
          allAssertions.add(ManifestAssertion.fromJson(item));
        } else if (item is Map) {
          allAssertions.add(
            ManifestAssertion.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // Extract c2pa.actions or c2pa.actions.v2 assertion
    final actionsAssertion = allAssertions
        .where(
          (final a) =>
              a.label == 'c2pa.actions' || a.label == 'c2pa.actions.v2',
        )
        .toList();
    List<Action>? actions;
    if (actionsAssertion.isNotEmpty) {
      actions = (actionsAssertion.first.data['actions'] as List?)
          ?.map((final e) => Action.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Extract EXIF data
    ExifData? exifData;
    final exifAssertions = allAssertions
        .where((final a) => a.label == 'stds.exif')
        .toList();
    if (exifAssertions.isNotEmpty) {
      exifData = ExifData.fromAssertionData(exifAssertions.first.data);
    }

    // Extract CreativeWork
    CreativeWork? creativeWork;
    final cwAssertions = allAssertions
        .where((final a) => a.label == 'stds.schema-org.CreativeWork')
        .toList();
    if (cwAssertions.isNotEmpty) {
      creativeWork = CreativeWork.fromAssertionData(cwAssertions.first.data);
    }

    // Extract TrainingMining
    TrainingMining? trainingMining;
    final tmAssertions = allAssertions
        .where((final a) => a.label == 'c2pa.training-mining')
        .toList();
    if (tmAssertions.isNotEmpty) {
      trainingMining = TrainingMining.fromAssertionData(
        tmAssertions.first.data,
      );
    }

    // Extract thumbnail from assertions
    ThumbnailData? thumbnail;
    if (json['thumbnail'] is Map<String, dynamic>) {
      thumbnail = ThumbnailData.fromJson(
        json['thumbnail'] as Map<String, dynamic>,
        previewsTruncated: previewsTruncated,
      );
    } else {
      final thumbAssertions = allAssertions
          .where((final a) => a.label.startsWith('c2pa.thumbnail.'))
          .toList();
      if (thumbAssertions.isNotEmpty) {
        thumbnail = ThumbnailData(
          format: thumbAssertions.first.label.replaceFirst(
            'c2pa.thumbnail.claim.',
            'image/',
          ),
          identifier: thumbAssertions.first.label,
          resolution: previewsTruncated ? 'limit' : null,
        );
      }
    }

    // Filter assertions: keep only custom/unknown ones
    final filteredAssertions = allAssertions.where((final a) {
      if (_routedAssertionLabels.contains(a.label)) {
        return false;
      }
      for (final prefix in _internalAssertionPrefixes) {
        if (a.label.startsWith(prefix)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Collect custom fields from remaining (unknown) assertions only
    final customFields = <CustomField>[];
    for (final assertion in filteredAssertions) {
      customFields.add(
        CustomField(
          key: assertion.label,
          value: assertion.data,
          source: 'assertion',
        ),
      );
    }

    // Parse structured signature info
    SignatureInfo? signatureInfo;
    if (json['signature_info'] is Map<String, dynamic>) {
      signatureInfo = SignatureInfo.fromJson(
        json['signature_info'] as Map<String, dynamic>,
      );
    }

    // Parse claim_generator_info
    final claimGeneratorInfo = <ClaimGeneratorInfo>[];
    if (json['claim_generator_info'] is List) {
      for (final item in json['claim_generator_info'] as List) {
        if (item is Map<String, dynamic>) {
          claimGeneratorInfo.add(ClaimGeneratorInfo.fromJson(item));
        }
      }
    }

    // Parse validation status
    final validationStatus = <ValidationStatusEntry>[];
    final rawValidationStatus = json['validation_status'];
    var validationStatusComputed = rawValidationStatus is List;
    if (rawValidationStatus is List) {
      for (final item in rawValidationStatus) {
        // Partial diagnostics cannot attest a clean check. Retain well-formed
        // failure/untrusted evidence even when another entry is malformed.
        if (item is! Map<String, dynamic> ||
            item['code'] is! String ||
            (item['code'] as String).trim().isEmpty ||
            (item['url'] != null && item['url'] is! String) ||
            (item['explanation'] != null && item['explanation'] is! String)) {
          validationStatusComputed = false;
          continue;
        }
        validationStatus.add(ValidationStatusEntry.fromJson(item));
      }
    }

    return Manifest(
      claimGenerator: json['claim_generator'] as String?,
      title: json['title'] as String?,
      format: json['format'] as String?,
      label: json['label'] as String?,
      instanceId: json['instance_id'] as String?,
      ingredients:
          (json['ingredients'] as List?)
              ?.map(
                (final e) => Ingredient.fromJson(
                  e as Map<String, dynamic>,
                  previewsTruncated: previewsTruncated,
                ),
              )
              .toList() ??
          [],
      assertions: filteredAssertions,
      actions: actions,
      signatureInfo: signatureInfo,
      claimGeneratorInfo: claimGeneratorInfo,
      thumbnail: thumbnail,
      exifData: exifData,
      creativeWork: creativeWork,
      trainingMining: trainingMining,
      validationStatus: validationStatus,
      validationStatusComputed: validationStatusComputed,
      customFields: customFields,
    );
  }

  /// A User Agent formatted string identifying the software/hardware/system
  /// that produced this claim.
  final String? claimGenerator;

  /// A human-readable title, generally source filename.
  final String? title;

  /// The format of the source file as a MIME type.
  final String? format;

  /// Label identifying this manifest in the manifest store.
  final String? label;

  /// Instance ID of this manifest.
  final String? instanceId;

  /// List of ingredients referenced by this manifest.
  final List<Ingredient> ingredients;

  /// List of remaining assertions (custom/vendor-specific only).
  final List<ManifestAssertion> assertions;

  /// List of actions parsed from the c2pa.actions assertion.
  final List<Action>? actions;

  /// Structured signature information.
  final SignatureInfo? signatureInfo;

  /// Claim generator info entries.
  final List<ClaimGeneratorInfo> claimGeneratorInfo;

  /// Thumbnail data reference.
  final ThumbnailData? thumbnail;

  /// Parsed EXIF data from stds.exif assertion.
  final ExifData? exifData;

  /// Parsed creative work metadata from stds.schema-org.CreativeWork.
  final CreativeWork? creativeWork;

  /// Parsed training/mining preferences from c2pa.training-mining.
  final TrainingMining? trainingMining;

  /// Validation status entries.
  final List<ValidationStatusEntry> validationStatus;

  /// Whether a complete, well-formed current diagnostic list was supplied.
  /// Empty is a clean check; absent, malformed or partial lists are uncomputed.
  /// Well-formed failure/untrusted evidence is retained even for partial lists.
  final bool validationStatusComputed;

  /// Custom fields from unknown assertions; custom action parameters remain on [actions].
  final List<CustomField> customFields;

  @override
  List<Object?> get props => [
    claimGenerator,
    title,
    format,
    label,
    instanceId,
    ingredients,
    assertions,
    actions,
    signatureInfo,
    claimGeneratorInfo,
    thumbnail,
    exifData,
    creativeWork,
    trainingMining,
    validationStatus,
    validationStatusComputed,
    customFields,
  ];
}
