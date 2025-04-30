import 'package:equatable/equatable.dart';

/// Represents an ingredient (e.g., original asset or intermediate) in the
/// manifest.
class Ingredient extends Equatable {

  /// Creates an instance of [Ingredient].
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
  });

  /// Creates an Ingredient from a JSON map.
  factory Ingredient.fromJson(final Map<String, dynamic> json) => Ingredient(
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
    );
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
  ///
  /// If this ingredient has a [`ManifestStore`],
  /// this will hold the label of the active [`Manifest`].
  ///
  /// [`Manifest`]: crate::Manifest
  /// [`ManifestStore`]: crate::ManifestStore
  final String? activeManifest;

  /// Additional description of the ingredient.
  final String? description;

  /// URI to an informational page about the ingredient or its data.
  final String? informationalUri;

  /// The ingredient's label as assigned in the manifest.
  final String? label;

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
  ];
}
