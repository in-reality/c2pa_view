import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/manifest_view_data.dart';
import '../../../theme/c2pa_theme.dart';
import '../../shared/widgets/collapsible_section.dart';
import '../../shared/widgets/sub_section.dart';

/// Collapsible "Camera capture details" section showing EXIF data.
class CameraCaptureSection extends StatelessWidget {
  final ExifDisplayData? exifData;

  const CameraCaptureSection({super.key, this.exifData});

  @override
  Widget build(BuildContext context) {
    if (exifData == null) return const SizedBox.shrink();

    final exif = exifData!;

    return CollapsibleSection(
      title: 'Camera capture details',
      description: 'Additional data sourced from the camera used to take an '
          'image or video. EXIF data can be edited by the content producer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (exif.creator != null)
            _TextSubSection(label: 'Creator', value: exif.creator!),
          if (exif.copyright != null)
            _TextSubSection(label: 'Copyright', value: exif.copyright!),
          if (exif.captureDate != null)
            _TextSubSection(
              label: 'Capture date',
              value: DateFormat.yMMMd().add_jm().format(exif.captureDate!),
            ),
          _CameraInfoCard(exif: exif),
          if (exif.hasLocation) _LocationInfo(exif: exif),
        ],
      ),
    );
  }
}

class _TextSubSection extends StatelessWidget {
  final String label;
  final String value;

  const _TextSubSection({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: label,
      child: Text(
        value,
        style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
      ),
    );
  }
}

class _CameraInfoCard extends StatelessWidget {
  final ExifDisplayData exif;
  const _CameraInfoCard({required this.exif});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    final rows = <_InfoRow>[];

    if (exif.cameraLabel != null) {
      rows.add(_InfoRow('Camera', exif.cameraLabel!));
    }
    if (exif.lensLabel != null) {
      rows.add(_InfoRow('Lens', exif.lensLabel!));
    }
    if (exif.dimensionsLabel != null) {
      rows.add(_InfoRow('Dimensions', exif.dimensionsLabel!));
    }
    if (exif.iso != null) rows.add(_InfoRow('ISO', exif.iso!));
    if (exif.focalLength != null) {
      rows.add(_InfoRow('Focal length', '${exif.focalLength}mm'));
    }
    if (exif.fNumber != null) {
      rows.add(_InfoRow('F-number', 'f/${exif.fNumber}'));
    }
    if (exif.exposureTime != null) {
      rows.add(_InfoRow('Exposure', exif.exposureTime!));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: theme.sectionRadius,
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: theme.borderColor),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      rows[i].label,
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _LocationInfo extends StatelessWidget {
  final ExifDisplayData exif;
  const _LocationInfo({required this.exif});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return SubSection(
      label: 'Approximate location',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: theme.sectionRadius,
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 18, color: theme.iconColor),
            const SizedBox(width: 8),
            Text(
              '${exif.latitude!.toStringAsFixed(4)}, '
              '${exif.longitude!.toStringAsFixed(4)}',
              style: theme.bodySmallStyle.copyWith(
                color: theme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
