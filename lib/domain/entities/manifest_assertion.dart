import 'package:equatable/equatable.dart';

/// Represents a generic C2PA assertion with a predicate and associated content.
class ManifestAssertion extends Equatable {
  /// An assertion label in reverse domain format
  final String label;

  /// The data of the assertion
  final Map<String, dynamic> data;

  /// There can be more than one assertion for any label
  final int? instance;

  /// The [ManifestAssertionKind] for this assertion (as stored in c2pa content)
  final String? kind;

  const ManifestAssertion(
    this.label,
    this.data, {
    this.instance,
    this.kind,
  });

  /// Creates an Assertion from a JSON map.
  factory ManifestAssertion.fromJson(Map<String, dynamic> json) {
    return ManifestAssertion(
      json['label'] as String,
      json['data'] as Map<String, dynamic>,
      instance: json['instance'] as int?,
      kind: json['kind'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    label,
    data,
    instance,
    kind,
  ];
}
