import 'package:equatable/equatable.dart';

import 'manifest_assertion.dart';
import 'ingredient.dart';

/// Domain entity representing a C2PA Content Credential Manifest.
class Manifest extends Equatable {
  /// A User Agent formatted string identifying the software/hardware/system produced this claim
  /// Spaces are not allowed in names, versions can be specified with product/1.0 syntax
  final String? claimGenerator;

  /// A human-readable title, generally source filename.
  final String? title;

  /// The format of the source file as a MIME type.
  final String? format;

  /// List of ingredients referenced by this manifest.
  final List<Ingredient> ingredients;

  /// List of assertions applied to the asset.
  final List<ManifestAssertion> assertions;

  /// Signature info
  final Map<String, dynamic>? signatureInfo;

  /// Label
  final String? label;

  const Manifest({
    this.claimGenerator,
    this.title,
    this.format,
    this.signatureInfo,
    this.label,
    this.ingredients = const [],
    this.assertions = const [],
  });

  /// Parses a Manifest from a JSON map.
  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      claimGenerator: json['claim_generator'] as String?,
      title: json['title'] as String?,
      format: json['format'] as String?,
      signatureInfo: json['signature_info'] as Map<String, dynamic>?,
      label: json['label'] as String?,
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      assertions: (json['assertions'] as List?)
          ?.map((e) => ManifestAssertion.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
        claimGenerator,
        title,
        format,
        signatureInfo,
        label,
        ingredients,
        assertions,
      ];
}
