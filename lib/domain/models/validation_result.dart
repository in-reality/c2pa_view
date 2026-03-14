import 'package:flutter/widgets.dart';

enum ValidationStatus {
  valid,
  invalid,
  unrecognized,
  noCredential,
}

@immutable
class ValidationResult {
  final ValidationStatus status;
  final String? message;

  const ValidationResult({
    required this.status,
    this.message,
  });

  const ValidationResult.valid() : this(status: ValidationStatus.valid);

  const ValidationResult.invalid([String? message])
      : this(status: ValidationStatus.invalid, message: message);

  const ValidationResult.unrecognized([String? message])
      : this(status: ValidationStatus.unrecognized, message: message);

  const ValidationResult.noCredential()
      : this(status: ValidationStatus.noCredential);

  bool get isValid => status == ValidationStatus.valid;
  bool get isInvalid => status == ValidationStatus.invalid;
  bool get isUnrecognized => status == ValidationStatus.unrecognized;
  bool get hasCredential => status != ValidationStatus.noCredential;
}
