import 'package:equatable/equatable.dart';

import 'assertion.dart';
import 'action.dart';
import 'ingredient.dart';
import 'link.dart';

/// Root domain entity representing a C2PA Content Credential Manifest.
class Manifest extends Equatable {
  /// Unique identifier for the manifest.
  final String id;

  /// Version of the manifest schema.
  final String version;

  /// List of ingredients referenced by this manifest.
  final List<Ingredient> ingredients;

  /// List of assertions applied to the asset.
  final List<Assertion> assertions;

  /// Sequence of actions that form the provenance chain.
  final List<Action> actions;

  /// Optional links to related manifests or resources.
  final List<Link>? links;

  const Manifest({
    required this.id,
    required this.version,
    required this.ingredients,
    required this.assertions,
    required this.actions,
    this.links,
  });

  /// Parses a Manifest from a JSON map.
  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      id: json['id'] as String,
      version: json['version'] as String,
      ingredients: (json['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      assertions: (json['assertions'] as List)
          .map((e) => Assertion.fromJson(e as Map<String, dynamic>))
          .toList(),
      actions: (json['actions'] as List)
          .map((e) => Action.fromJson(e as Map<String, dynamic>))
          .toList(),
      links: json['links'] != null
          ? (json['links'] as List)
          .map((e) => Link.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
    );
  }

  @override
  List<Object?> get props => [id, version, ingredients, assertions, actions, links];
}
