import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:flutter/material.dart';

/// Host-supplied detail panel section inserted into [ManifestDetailContent].
class ManifestDetailSection {
  const ManifestDetailSection({
    required this.id,
    required this.builder,
    this.order = 0,
  });

  final String id;

  /// Lower values render earlier among host sections.
  final int order;

  final Widget Function(BuildContext context, ManifestViewData data) builder;
}
