import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Thumbnail data from a C2PA manifest.
class ThumbnailData extends Equatable {
  const ThumbnailData({
    required this.format,
    this.identifier,
    this.data,
    this.resolution,
    this.containingManifest,
  });

  factory ThumbnailData.fromJson(
    final Map<String, dynamic> json, {
    final bool previewsTruncated = false,
  }) => ThumbnailData(
    format: json['format'] as String? ?? 'image/jpeg',
    identifier: json['identifier'] as String?,
    resolution:
        json['resolution'] as String? ?? (previewsTruncated ? 'limit' : null),
    containingManifest: json['containing_manifest'] as String?,
    data: _bytes(json),
  );
  static Uint8List? _bytes(final Map<String, dynamic> json) {
    final bytes = json['data'];
    if (json['resolution'] != 'resolved' ||
        bytes is! List ||
        bytes.isEmpty ||
        bytes.length > 1024 * 1024 ||
        bytes.any((final b) => b is! int || b < 0 || b > 255)) {
      return null;
    }
    return Uint8List.fromList(bytes.cast<int>());
  }

  /// Reader hydration outcome; absent for legacy reference-only JSON.
  final String? resolution;

  /// Claim resource store which supplied these bytes, not the depicted asset.
  final String? containingManifest;

  final String format;
  final String? identifier;
  final Uint8List? data;

  @override
  List<Object?> get props => [
    format,
    identifier,
    data,
    resolution,
    containingManifest,
  ];
}
