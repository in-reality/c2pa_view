import 'package:c2pa_view/domain/entities/thumbnail_data.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:equatable/equatable.dart';

/// Represents an ingredient (e.g., original asset or intermediate) in the
/// manifest.
class Ingredient extends Equatable {
  const Ingredient({
    this.title,
    this.format,
    this.documentId,
    this.instanceId,
    this.provenance,
    this.hash,
    this.activeManifest,
    this.description,
    this.informationalUri,
    this.label,
    this.relationship,
    this.thumbnail,
    this.validationStatus = const [],
    this.metadata,
  });

  /// Creates an Ingredient from a JSON map.
  factory Ingredient.fromJson(final Map<String, dynamic> json) {
    ThumbnailData? thumbnail;
    if (json['thumbnail'] is Map<String, dynamic>) {
      thumbnail = ThumbnailData.fromJson(
        json['thumbnail'] as Map<String, dynamic>,
      );
    }

    final validationStatus = <ValidationStatusEntry>[];
    if (json['validation_status'] is List) {
      for (final item in json['validation_status'] as List) {
        if (item is Map<String, dynamic>) {
          validationStatus.add(ValidationStatusEntry.fromJson(item));
        }
      }
    }

    return Ingredient(
      title: json['title'] as String?,
      format: json['format'] as String?,
      documentId: json['document_id'] as String?,
      instanceId: json['instance_id'] as String?,
      provenance: json['provenance'] as String?,
      hash: json['hash'] as String?,
      activeManifest: json['active_manifest'] as String?,
      description: json['description'] as String?,
      informationalUri: json['informational_uri'] as String?,
      label: json['label'] as String?,
      relationship: json['relationship'] as String?,
      thumbnail: thumbnail,
      validationStatus: validationStatus,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// A human-readable title, generally source filename.
  final String? title;

  /// The format of the source file as a MIME type.
  final String? format;

  /// Document ID from `xmpMM:DocumentID` in XMP metadata.
  final String? documentId;

  /// Instance ID from `xmpMM:InstanceID` in XMP metadata.
  final String? instanceId;

  /// URI from `dcterms:provenance` in XMP metadata.
  final String? provenance;

  /// An optional hash of the asset to prevent duplicates.
  final String? hash;

  /// The active manifest label (if one exists).
  final String? activeManifest;

  /// Additional description of the ingredient.
  final String? description;

  /// URI to an informational page about the ingredient or its data.
  final String? informationalUri;

  /// The ingredient's label as assigned in the manifest.
  final String? label;

  /// Relationship type: "parentOf", "componentOf", "inputTo".
  final String? relationship;

  /// Ingredient thumbnail data.
  final ThumbnailData? thumbnail;

  /// Validation status entries for this ingredient.
  final List<ValidationStatusEntry> validationStatus;

  /// Vendor-specific metadata.
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
    title,
    format,
    documentId,
    instanceId,
    provenance,
    hash,
    activeManifest,
    description,
    informationalUri,
    label,
    relationship,
    thumbnail,
    validationStatus,
    metadata,
  ];
}
