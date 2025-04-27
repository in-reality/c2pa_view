import 'package:equatable/equatable.dart';

/// Represents an ingredient (e.g., original asset or intermediate) in the manifest.
class Ingredient extends Equatable {
  /// URI pointing to the ingredient data.
  final String uri;

  /// The media type of the ingredient (e.g., 'image/jpeg').
  final String mediaType;

  /// The byte length of the ingredient.
  final int length;

  /// Map of hashes, keyed by algorithm.
  final Map<String, String> hashes;

  const Ingredient({
    required this.uri,
    required this.mediaType,
    required this.length,
    required this.hashes,
  });

  /// Creates an Ingredient from a JSON map.
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      uri: json['uri'] as String,
      mediaType: json['mediaType'] as String,
      length: json['length'] as int,
      hashes: Map<String, String>.from(json['hashes'] as Map),
    );
  }

  @override
  List<Object?> get props => [uri, mediaType, length, hashes];
}
