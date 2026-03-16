import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_panel.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_tree_viewer.dart';

/// A combined viewer widget that shows the provenance DAG on the left
/// and the manifest detail panel on the right, mirroring the layout of
/// the C2PA verify-site.
///
/// This is a convenience widget that composes [ProvenanceTreeViewer] and
/// [ManifestDetailPanel]. You can also use those widgets independently
/// for more flexible layouts.
class C2paManifestViewer extends StatefulWidget {
  final ProvenanceGraph graph;
  final String? initialSelectedNodeId;
  final ValueChanged<ProvenanceNode>? onNodeSelected;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final String? mimeType;
  final bool showDetailPanel;
  /// Optional image for the actual media file. When the manifest has no
  /// embedded thumbnail, this is shown instead (detail panel and root tree node).
  final ImageProvider? mediaImage;

  const C2paManifestViewer({
    super.key,
    required this.graph,
    this.initialSelectedNodeId,
    this.onNodeSelected,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mimeType,
    this.showDetailPanel = true,
    this.mediaImage,
  });

  @override
  State<C2paManifestViewer> createState() => _C2paManifestViewerState();
}

class _C2paManifestViewerState extends State<C2paManifestViewer> {
  late String _selectedNodeId;
  late ManifestViewData? _selectedData;

  @override
  void initState() {
    super.initState();
    _selectedNodeId =
        widget.initialSelectedNodeId ?? widget.graph.rootId;
    _selectedData = widget.graph.findNode(_selectedNodeId)?.manifestViewData;
  }

  @override
  void didUpdateWidget(C2paManifestViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _selectedNodeId =
          widget.initialSelectedNodeId ?? widget.graph.rootId;
      _selectedData = widget.graph.findNode(_selectedNodeId)?.manifestViewData;
    }
  }

  void _onNodeSelected(ProvenanceNode node) {
    setState(() {
      _selectedNodeId = node.id;
      _selectedData = node.manifestViewData;
    });
    widget.onNodeSelected?.call(node);
  }

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return SelectionArea(
      child: Row(
        children: [
        Expanded(
          child: ProvenanceTreeViewer(
            graph: widget.graph,
            selectedNodeId: _selectedNodeId,
            onNodeSelected: _onNodeSelected,
            mediaImage: widget.mediaImage,
          ),
        ),
        if (widget.showDetailPanel && _selectedData != null) ...[
          Container(
            width: 1,
            color: theme.borderColor,
          ),
          ManifestDetailPanel(
            data: _selectedData!,
            mimeType: widget.mimeType,
            onThumbnailTap: widget.onThumbnailTap,
            onIngredientTap: widget.onIngredientTap,
            mediaImage: _selectedNodeId == widget.graph.rootId
                ? widget.mediaImage
                : null,
          ),
        ],
      ],
      ),
    );
  }
}
