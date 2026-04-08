import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Thumbnail data from a C2PA manifest.
class ThumbnailData extends Equatable {
  final String format;
  final String? identifier;
  final Uint8List? data;

  const ThumbnailData({required this.format, this.identifier, this.data});

  factory ThumbnailData.fromJson(final Map<String, dynamic> json) =>
      ThumbnailData(
        format: json['format'] as String? ?? 'image/jpeg',
        identifier: json['identifier'] as String?,
      );

  @override
  List<Object?> get props => [format, identifier, data];
}
