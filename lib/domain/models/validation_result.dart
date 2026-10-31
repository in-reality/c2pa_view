import 'package:flutter/widgets.dart';

/// Presentation of current credential diagnostics, separate from preview success.
enum ValidationStatus {
  /// Current diagnostics report a clean credential.
  valid,

  /// Current or recorded binding/signature diagnostics report a failure.
  invalid,

  /// The signing certificate is outside the supplied trust list.
  untrusted,

  /// No credential is available, as on an unresolved ingredient leaf.
  noCredential,

  /// A credential is present, but current diagnostics were not computed.
  notVerified,
}

@immutable
class ValidationResult {
  const ValidationResult({required this.status, this.message});

  const ValidationResult.valid() : this(status: ValidationStatus.valid);

  const ValidationResult.invalid([final String? message])
    : this(status: ValidationStatus.invalid, message: message);

  /// The credential is structurally valid but the signing certificate is not
  /// in any trusted certificate list.
  const ValidationResult.untrusted() : this(status: ValidationStatus.untrusted);

  /// A present credential without current diagnostics; this is not a trust result.
  const ValidationResult.notVerified()
    : this(status: ValidationStatus.notVerified);

  const ValidationResult.noCredential()
    : this(status: ValidationStatus.noCredential);
  final ValidationStatus status;
  final String? message;

  bool get isValid => status == ValidationStatus.valid;
  bool get isInvalid => status == ValidationStatus.invalid;
  bool get isUntrusted => status == ValidationStatus.untrusted;

  /// Whether a present credential lacks current verification diagnostics.
  bool get isNotVerified => status == ValidationStatus.notVerified;

  bool get hasCredential => status != ValidationStatus.noCredential;
}
