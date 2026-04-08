import 'package:equatable/equatable.dart';

/// Information about the software that generated a C2PA claim.
class ClaimGeneratorInfo extends Equatable {
  final String name;
  final String? version;
  final Map<String, dynamic>? icon;

  const ClaimGeneratorInfo({required this.name, this.version, this.icon});

  factory ClaimGeneratorInfo.fromJson(final Map<String, dynamic> json) =>
      ClaimGeneratorInfo(
        name: json['name'] as String? ?? 'Unknown',
        version: json['version'] as String?,
        icon: json['icon'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [name, version, icon];
}
