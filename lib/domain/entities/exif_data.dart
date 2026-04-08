import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:equatable/equatable.dart';

/// Parsed EXIF data from the `stds.exif` assertion.
class ExifData extends Equatable {

  const ExifData({
    this.creator,
    this.copyright,
    this.captureDate,
    this.cameraMake,
    this.cameraModel,
    this.lensMake,
    this.lensModel,
    this.exposureTime,
    this.fNumber,
    this.focalLength,
    this.iso,
    this.width,
    this.height,
    this.latitude,
    this.longitude,
    this.customFields = const [],
  });

  factory ExifData.fromAssertionData(final Map<String, dynamic> data) {
    final customEntries =
        data.entries
            .where((final e) => !_knownKeys.contains(e.key))
            .map(
              (final e) => CustomField(
                key: e.key,
                value: e.value,
                source: 'exif_extension',
              ),
            )
            .toList();

    return ExifData(
      creator: _extractString(data['dc:creator']),
      copyright: _extractString(data['dc:rights']),
      captureDate:
          data['exif:DateTimeOriginal'] != null
              ? DateTime.tryParse(data['exif:DateTimeOriginal'] as String)
              : null,
      cameraMake: data['tiff:Make'] as String?,
      cameraModel: data['tiff:Model'] as String?,
      lensMake: data['exif:LensMake'] as String?,
      lensModel: data['exif:LensModel'] as String?,
      exposureTime: data['exif:ExposureTime']?.toString(),
      fNumber: data['exif:FNumber']?.toString(),
      focalLength: data['exif:FocalLength']?.toString(),
      iso: data['exif:ISOSpeedRatings']?.toString(),
      width: _toInt(data['exif:PixelXDimension']),
      height: _toInt(data['exif:PixelYDimension']),
      latitude: _toDouble(data['exif:GPSLatitude']),
      longitude: _toDouble(data['exif:GPSLongitude']),
      customFields: customEntries,
    );
  }
  final String? creator;
  final String? copyright;
  final DateTime? captureDate;
  final String? cameraMake;
  final String? cameraModel;
  final String? lensMake;
  final String? lensModel;
  final String? exposureTime;
  final String? fNumber;
  final String? focalLength;
  final String? iso;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
  final List<CustomField> customFields;

  static const _knownKeys = {
    '@context',
    'dc:creator',
    'dc:rights',
    'exif:DateTimeOriginal',
    'tiff:Make',
    'tiff:Model',
    'exif:LensMake',
    'exif:LensModel',
    'exif:ExposureTime',
    'exif:FNumber',
    'exif:FocalLength',
    'exif:ISOSpeedRatings',
    'exif:PixelXDimension',
    'exif:PixelYDimension',
    'exif:GPSLatitude',
    'exif:GPSLongitude',
    'exif:GPSLatitudeRef',
    'exif:GPSLongitudeRef',
  };

  static String? _extractString(final value) {
    if (value is String) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    return value?.toString();
  }

  static int? _toInt(final value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _toDouble(final value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    creator,
    copyright,
    captureDate,
    cameraMake,
    cameraModel,
    lensMake,
    lensModel,
    exposureTime,
    fNumber,
    focalLength,
    iso,
    width,
    height,
    latitude,
    longitude,
    customFields,
  ];
}
