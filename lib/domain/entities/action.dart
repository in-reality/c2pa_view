import 'package:equatable/equatable.dart';

/// Represents an action performed in the C2PA provenance chain.
class Action extends Equatable {
  /// The type of action (e.g., 'capture', 'edit', 'transcode').
  final String type;

  /// The actor who performed the action (e.g., tool or person).
  final String actor;

  /// The timestamp when the action occurred.
  final DateTime timestamp;

  /// Additional details about the action.
  final Map<String, dynamic>? details;

  const Action({
    required this.type,
    required this.actor,
    required this.timestamp,
    this.details,
  });

  /// Creates an Action from a JSON map.
  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      type: json['type'] as String,
      actor: json['actor'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [type, actor, timestamp, details];
}
