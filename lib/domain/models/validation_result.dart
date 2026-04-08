import 'package:flutter/widgets.dart';

enum ValidationStatus { valid, invalid, untrusted, unrecognized, noCredential }

@immutable
class ValidationResult {
  final ValidationStatus status;
  final String? message;

  const ValidationResult({required this.status, this.message});

  const ValidationResult.valid() : this(status: ValidationStatus.valid);

  const ValidationResult.invalid([String? message])
    : this(status: ValidationStatus.invalid, message: message);

  /// The credential is structurally valid but the signing certificate is not
  /// in any trusted certificate list.
  const ValidationResult.untrusted() : this(status: ValidationStatus.untrusted);

  const ValidationResult.unrecognized([String? message])
    : this(status: ValidationStatus.unrecognized, message: message);

  const ValidationResult.noCredential()
    : this(status: ValidationStatus.noCredential);

  bool get isValid => status == ValidationStatus.valid;
  bool get isInvalid => status == ValidationStatus.invalid;
  bool get isUntrusted => status == ValidationStatus.untrusted;
  bool get isUnrecognized => status == ValidationStatus.unrecognized;
  bool get hasCredential => status != ValidationStatus.noCredential;
}
