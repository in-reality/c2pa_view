import 'package:equatable/equatable.dart';

/// Represents a link between manifests or assertions.
class Link extends Equatable {
  /// The predicate of the link (e.g., 'c2pa.prevManifest').
  final String predicate;

  /// The target URI of the linked resource.
  final String target;

  const Link({
    required this.predicate,
    required this.target,
  });

  /// Creates a Link from a JSON map.
  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      predicate: json['predicate'] as String,
      target: json['target'] as String,
    );
  }

  @override
  List<Object?> get props => [predicate, target];
}
