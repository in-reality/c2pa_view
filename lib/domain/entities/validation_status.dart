import 'package:equatable/equatable.dart';

/// A single validation status entry from C2PA manifest validation.
class ValidationStatusEntry extends Equatable {
  final String code;
  final String? url;
  final String? explanation;

  const ValidationStatusEntry({
    required this.code,
    this.url,
    this.explanation,
  });

  factory ValidationStatusEntry.fromJson(final Map<String, dynamic> json) =>
      ValidationStatusEntry(
        code: json['code'] as String,
        url: json['url'] as String?,
        explanation: json['explanation'] as String?,
      );

  bool get isError =>
      !code.contains('.validated') && !code.contains('.trusted');

  @override
  List<Object?> get props => [code, url, explanation];
}
