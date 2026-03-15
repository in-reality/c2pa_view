import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';

import 'sections/about_section.dart';
import 'sections/camera_capture_section.dart';
import 'sections/content_summary_section.dart';
import 'sections/custom_fields_section.dart';
import 'sections/detail_header.dart';
import 'sections/error_banner.dart';
import 'sections/process_section.dart';
import 'sections/thumbnail_section.dart';

/// The right sidebar panel displaying detailed manifest information.
class ManifestDetailPanel extends StatelessWidget {
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final double? width;
  final ImageProvider? mediaImage;

  const ManifestDetailPanel({
    super.key,
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.width,
    this.mediaImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final panelWidth = width ?? theme.sidebarWidth;

    return Container(
      width: panelWidth,
      color: theme.surfaceColor,
      child: Column(
        children: [
          DetailHeader(data: data),
          Expanded(
            child: _ScrollBody(
              data: data,
              mimeType: mimeType,
              onThumbnailTap: onThumbnailTap,
              onIngredientTap: onIngredientTap,
              mediaImage: mediaImage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollBody extends StatefulWidget {
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final ImageProvider? mediaImage;

  const _ScrollBody({
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mediaImage,
  });

  @override
  State<_ScrollBody> createState() => _ScrollBodyState();
}

class _ScrollBodyState extends State<_ScrollBody> {
  final _scrollController = ScrollController();
  bool _showHeaderShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 0;
    if (shouldShow != _showHeaderShadow) {
      setState(() => _showHeaderShadow = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Column(
      children: [
        if (_showHeaderShadow)
          Container(
            height: 1,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                ErrorBanner(result: widget.data.validationResult),
                ThumbnailSection(
                  thumbnail: widget.data.thumbnail ?? widget.mediaImage,
                  mimeType: widget.mimeType,
                  onTapFullScreen: widget.onThumbnailTap,
                ),
                ContentSummarySection(
                  generativeInfo: widget.data.generativeInfo,
                ),
                ProcessSection(
                  data: widget.data,
                  onIngredientTap: widget.onIngredientTap,
                ),
                CameraCaptureSection(
                  exifData: widget.data.exifData,
                  exifCustomFields: widget.data.exifCustomFields,
                ),
                AboutSection(
                  data: widget.data,
                  creativeWorkCustomFields:
                      widget.data.creativeWorkCustomFields,
                ),
                if (widget.data.customFields.isNotEmpty)
                  CustomFieldsSection(fields: widget.data.customFields),
                Divider(height: 1, color: theme.borderColor),
                const SizedBox(height: 24),
              ],
          ),
        ),
      ],
    );
  }
}
