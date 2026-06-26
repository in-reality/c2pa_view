import 'package:equatable/equatable.dart';

/// Represents a generic C2PA assertion with a predicate and associated content.
class ManifestAssertion extends Equatable {
  /// Creates an instance of [ManifestAssertion].
  const ManifestAssertion(this.label, this.data, {this.instance, this.kind});

  /// Creates an Assertion from a JSON map.
  factory ManifestAssertion.fromJson(final Map<String, dynamic> json) =>
      ManifestAssertion(
        json['label'] as String,
        _coerceAssertionData(json['data']),
        instance: json['instance'] as int?,
        kind: json['kind'] as String?,
      );

  /// c2pa-rs JSON sometimes embeds assertion bodies as base64 strings (e.g.
  /// `cawg.identity`); coerce to a map so downstream parsers do not throw on web.
  static Map<String, dynamic> _coerceAssertionData(final Object? raw) {
    if (raw == null) {
      return const {};
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      return {'_c2pa_inline': raw};
    }
    return const {};
  }

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
