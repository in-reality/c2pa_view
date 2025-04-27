import 'package:equatable/equatable.dart';

/// Represents a generic C2PA assertion with a predicate and associated content.
class Assertion extends Equatable {
  /// The assertion predicate (e.g., 'c2pa.metadata', 'c2pa.hash.data').
  final String predicate;

  /// The content of the assertion, typically a JSON-like map.
  final Map<String, dynamic> value;

  /// Optional identifier for this assertion.
  final String? id;

  const Assertion({
    required this.predicate,
    required this.value,
    this.id,
  });

  /// Creates an Assertion from a JSON map.
  factory Assertion.fromJson(Map<String, dynamic> json) {
    return Assertion(
      predicate: json['predicate'] as String,
      value: Map<String, dynamic>.from(json['value'] as Map),
      id: json['id'] as String?,
    );
  }

  @override
  List<Object?> get props => [predicate, value, id];
}
