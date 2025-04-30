import 'package:c2pa_view/domain/entities/action.dart';
import 'package:c2pa_view/domain/entities/ingredient.dart';
import 'package:c2pa_view/domain/entities/manifest_assertion.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing a C2PA Content Credential Manifest.
class Manifest extends Equatable {

  /// Creates a new instance of [Manifest].
  const Manifest({
    this.claimGenerator,
    this.title,
    this.format,
    this.signatureInfo,
    this.label,
    this.ingredients = const [],
    this.assertions = const [],
    this.actions = const [],
  });

  /// Parses a Manifest from a JSON map.
  factory Manifest.fromJson(final Map<String, dynamic> json) {
    // All assertions
    final allAssertions = (json['assertions'] as List?)
        ?.map((final e) => ManifestAssertion
        .fromJson(e as Map<String, dynamic>),)
        .toList() ?? [];

    // Check for the c2pa.actions assertion
    final actionsIndex = allAssertions.indexWhere(
      (final a) => a.label == 'c2pa.actions',
    );

    // Take the actions assertion out
    final actionsAssertion =
        actionsIndex != -1 ? allAssertions[actionsIndex] : null;

    // Parse the actions from the c2pa.actions assertion
    final actions = actionsAssertion != null
        ? (actionsAssertion.data['actions'] as List?)
            ?.map((final e) => Action.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    // Filter out the c2pa.actions assertion from the regular assertions list
    final filteredAssertions = allAssertions
        .where((final a) => a.label != 'c2pa.actions')
        .toList();

    return Manifest(
      claimGenerator: json['claim_generator'] as String?,
      title: json['title'] as String?,
      format: json['format'] as String?,
      signatureInfo: json['signature_info'] as Map<String, dynamic>?,
      label: json['label'] as String?,
      ingredients: (json['ingredients'] as List?)
          ?.map((final e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      assertions: filteredAssertions,
      actions: actions,
    );
  }
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

  /// List of actions parsed from the c2pa.actions assertion
  final List<Action>? actions;

  /// Signature info
  final Map<String, dynamic>? signatureInfo;

  /// Label
  final String? label;

  @override
  List<Object?> get props => [
        claimGenerator,
        title,
        format,
        signatureInfo,
        label,
        ingredients,
        assertions,
        actions,
      ];
}
