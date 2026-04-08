import 'package:equatable/equatable.dart';

/// Represents an action performed in the C2PA provenance chain.
class Action extends Equatable {
  /// Creates an instance of [Action].
  const Action({
    required this.action,
    this.when,
    this.changed,
    this.parameters,
    this.creators,
    this.sourceType,
    this.related,
    this.reason,
    this.description,
  });

  /// Creates an Action from a JSON map.
  factory Action.fromJson(final Map<String, dynamic> json) => Action(
    action: json['action'] as String,
    when: json['when'] as String?,
    changed: json['changed'] as String?,
    parameters: json['parameters'] as Map<String, dynamic>?,
    creators:
        (json['creators'] as List?)?.map((final e) => e as String).toList(),
    sourceType: json['source_type'] as String?,
    related:
        (json['related'] as List?)
            ?.map((final e) => Action.fromJson(e as Map<String, dynamic>))
            .toList(),
    reason: json['reason'] as String?,
    description: json['description'] as String?,
  );

  /// The label associated with this action. See ([`c2pa_action`]).
  final String action;

  /// Timestamp of when the action occurred.
  final String? when;

  /// A semicolon-delimited list of the parts of the resource that were changed
  /// since the previous event history.
  final String? changed;

  /// Additional parameters of the action. These vary by the type of action.
  final Map<String, dynamic>? parameters;

  /// An array of the creators that undertook this action.
  final List<String>? creators;

  /// One of the defined URI values at `<https://cv.iptc.org/newscodes/digitalsourcetype/>`
  final String? sourceType;

  /// List of related actions.
  final List<Action>? related;

  /// The reason why this action was performed, required when the action is
  /// `c2pa.redacted`
  final String? reason;

  /// A human-readable description of the action.
  final String? description;

  @override
  List<Object?> get props => [
    action,
    when,
    changed,
    parameters,
    creators,
    sourceType,
    related,
    reason,
    description,
  ];
}
