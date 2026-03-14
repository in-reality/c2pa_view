import 'package:flutter/material.dart';

import '../../domain/models/manifest_view_data.dart';
import '../../theme/c2pa_theme.dart';
import 'sections/about_section.dart';
import 'sections/camera_capture_section.dart';
import 'sections/content_summary_section.dart';
import 'sections/detail_header.dart';
import 'sections/error_banner.dart';
import 'sections/process_section.dart';
import 'sections/thumbnail_section.dart';

/// The right sidebar panel displaying detailed manifest information.
///
/// This is one of the two primary widgets in this package, mirroring
/// the DetailedInfo panel from the C2PA verify-site. It shows:
///
/// - A sticky header with title, issuer, and date
/// - Error/warning banners for invalid or unrecognized credentials
/// - A large thumbnail
/// - Content summary (AI generation info)
/// - Process section (app/device, AI tools, actions, ingredients)
/// - Camera capture details (EXIF data)
/// - About section (issuer, signing date, producer, social accounts)
///
/// Use [ManifestDetailPanel] with a [ManifestViewData] to display
/// manifest details for a selected asset.
class ManifestDetailPanel extends StatelessWidget {
  /// The manifest data to display.
  final ManifestViewData data;

  /// The MIME type of the asset, used for thumbnail placeholder selection.
  final String? mimeType;

  /// Called when the user taps the thumbnail for full-screen viewing.
  final VoidCallback? onThumbnailTap;

  /// Called when the user taps an ingredient card.
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;

  /// Optional width override (defaults to theme's sidebarWidth).
  final double? width;

  const ManifestDetailPanel({
    super.key,
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.width,
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

  const _ScrollBody({
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
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
                thumbnail: widget.data.thumbnail,
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
              CameraCaptureSection(exifData: widget.data.exifData),
              AboutSection(data: widget.data),
              Divider(height: 1, color: theme.borderColor),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
