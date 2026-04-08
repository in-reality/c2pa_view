import 'package:c2pa_view/c2pa_view.dart' show ManifestDetailPanel;
import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_panel.dart' show ManifestDetailPanel;
import 'package:c2pa_view/features/manifest_detail/sections/about_section.dart';
import 'package:c2pa_view/features/manifest_detail/sections/camera_capture_section.dart';
import 'package:c2pa_view/features/manifest_detail/sections/content_summary_section.dart';
import 'package:c2pa_view/features/manifest_detail/sections/custom_fields_section.dart';
import 'package:c2pa_view/features/manifest_detail/sections/detail_header.dart';
import 'package:c2pa_view/features/manifest_detail/sections/error_banner.dart';
import 'package:c2pa_view/features/manifest_detail/sections/process_section.dart';
import 'package:c2pa_view/features/manifest_detail/sections/thumbnail_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The reusable content of the manifest detail view.
///
/// Renders a sticky [DetailHeader] above a scrollable list of detail sections.
/// This widget expects a parent with bounded height (e.g. inside an [Expanded],
/// a [SizedBox] with a fixed height, or a dialog with [maxHeight]).
///
/// Use this directly when you need full control over the surrounding chrome
/// (background color, width, shape). For common use cases, prefer
/// [ManifestDetailPanel] (sidebar) or [showManifestDetailPopup] (popup).
class ManifestDetailContent extends StatelessWidget {

  const ManifestDetailContent({
    required this.data, super.key,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mediaImage,
  });
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final ImageProvider? mediaImage;

  @override
  Widget build(final BuildContext context) => Column(
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
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(StringProperty('mimeType', mimeType))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onThumbnailTap', onThumbnailTap))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap))
    ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage));
  }
}

class _ScrollBody extends StatefulWidget {

  const _ScrollBody({
    required this.data,
    this.mimeType,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mediaImage,
  });
  final ManifestViewData data;
  final String? mimeType;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final ImageProvider? mediaImage;

  @override
  State<_ScrollBody> createState() => _ScrollBodyState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(StringProperty('mimeType', mimeType))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onThumbnailTap', onThumbnailTap))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap))
    ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage));
  }
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
  Widget build(final BuildContext context) {
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
              ContentSummarySection(generativeInfo: widget.data.generativeInfo),
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
                creativeWorkCustomFields: widget.data.creativeWorkCustomFields,
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
