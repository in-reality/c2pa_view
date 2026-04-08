import 'package:equatable/equatable.dart';

/// Information about the software that generated a C2PA claim.
class ClaimGeneratorInfo extends Equatable {

  const ClaimGeneratorInfo({required this.name, this.version, this.icon});

  factory ClaimGeneratorInfo.fromJson(final Map<String, dynamic> json) =>
      ClaimGeneratorInfo(
        name: json['name'] as String? ?? 'Unknown',
        version: json['version'] as String?,
        icon: json['icon'] as Map<String, dynamic>?,
      );
  final String name;
  final String? version;
  final Map<String, dynamic>? icon;

  @override
  List<Object?> get props => [name, version, icon];
}
