import 'package:equatable/equatable.dart';

/// A single validation status entry from C2PA manifest validation.
class ValidationStatusEntry extends Equatable {
  final String code;
  final String? url;
  final String? explanation;

  const ValidationStatusEntry({required this.code, this.url, this.explanation});

  factory ValidationStatusEntry.fromJson(final Map<String, dynamic> json) =>
      ValidationStatusEntry(
        code: json['code'] as String,
        url: json['url'] as String?,
        explanation: json['explanation'] as String?,
      );

  static const _nonErrorSuffixes = {'.validated', '.trusted', '.untrusted'};

  /// True when this entry represents a genuine validation failure.
  /// Informational codes (*.validated, *.trusted, *.untrusted) are not errors.
  bool get isError => !_nonErrorSuffixes.any((s) => code.endsWith(s));

  /// True when the signing certificate is valid but not in any trust list.
  bool get isUntrusted => code.endsWith('.untrusted');

  @override
  List<Object?> get props => [code, url, explanation];
}
