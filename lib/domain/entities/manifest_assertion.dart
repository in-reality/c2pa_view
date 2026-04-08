import 'package:equatable/equatable.dart';

/// Represents a generic C2PA assertion with a predicate and associated content.
class ManifestAssertion extends Equatable {
  /// Creates an instance of [ManifestAssertion].
  const ManifestAssertion(this.label, this.data, {this.instance, this.kind});

  /// Creates an Assertion from a JSON map.
  factory ManifestAssertion.fromJson(final Map<String, dynamic> json) =>
      ManifestAssertion(
        json['label'] as String,
        json['data'] as Map<String, dynamic>,
        instance: json['instance'] as int?,
        kind: json['kind'] as String?,
      );

  /// An assertion label in reverse domain format
  final String label;

  /// The data of the assertion
  final Map<String, dynamic> data;

  /// There can be more than one assertion for any label
  final int? instance;

  /// The kind of assertion
  final String? kind;

  @override
  List<Object?> get props => [label, data, instance, kind];
}
