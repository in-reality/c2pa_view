import 'package:equatable/equatable.dart';

/// Structured signature information from a C2PA manifest.
class SignatureInfo extends Equatable {
  final String? issuer;
  final String? certSerialNumber;
  final DateTime? time;
  final String? algorithm;
  final List<CertificateInfo>? certificateChain;

  const SignatureInfo({
    this.issuer,
    this.certSerialNumber,
    this.time,
    this.algorithm,
    this.certificateChain,
  });

  factory SignatureInfo.fromJson(final Map<String, dynamic> json) {
    DateTime? time;
    if (json['time'] != null) {
      time = DateTime.tryParse(json['time'] as String);
    }

    List<CertificateInfo>? chain;
    if (json['cert_chain'] is List) {
      chain =
          (json['cert_chain'] as List)
              .whereType<Map<String, dynamic>>()
              .map(CertificateInfo.fromJson)
              .toList();
    }

    return SignatureInfo(
      issuer: json['issuer'] as String?,
      certSerialNumber: json['cert_serial_number'] as String?,
      time: time,
      algorithm: json['alg'] as String?,
      certificateChain: chain,
    );
  }

  @override
  List<Object?> get props => [
    issuer,
    certSerialNumber,
    time,
    algorithm,
    certificateChain,
  ];
}

/// Information about a certificate in the signing chain.
class CertificateInfo extends Equatable {
  final String? subject;
  final String? issuer;
  final DateTime? notBefore;
  final DateTime? notAfter;
  final String? serialNumber;

  const CertificateInfo({
    this.subject,
    this.issuer,
    this.notBefore,
    this.notAfter,
    this.serialNumber,
  });

  factory CertificateInfo.fromJson(final Map<String, dynamic> json) =>
      CertificateInfo(
        subject: json['subject'] as String?,
        issuer: json['issuer'] as String?,
        notBefore:
            json['not_before'] != null
                ? DateTime.tryParse(json['not_before'] as String)
                : null,
        notAfter:
            json['not_after'] != null
                ? DateTime.tryParse(json['not_after'] as String)
                : null,
        serialNumber: json['serial_number'] as String?,
      );

  @override
  List<Object?> get props => [
    subject,
    issuer,
    notBefore,
    notAfter,
    serialNumber,
  ];
}
