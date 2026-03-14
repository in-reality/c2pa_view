import 'package:flutter/material.dart';

import '../domain/models/manifest_view_data.dart';
import '../domain/models/provenance_node.dart';
import '../theme/c2pa_theme.dart';
import 'manifest_detail/manifest_detail_panel.dart';
import 'provenance_tree/provenance_tree_viewer.dart';

/// A combined viewer widget that shows the provenance tree on the left
/// and the manifest detail panel on the right, mirroring the layout of
/// the C2PA verify-site.
///
/// This is a convenience widget that composes [ProvenanceTreeViewer] and
/// [ManifestDetailPanel]. You can also use those widgets independently
/// for more flexible layouts.
class C2paManifestViewer extends StatefulWidget {
  /// The root provenance node representing the main asset.
  final ProvenanceNode rootNode;

  /// Initially selected node ID. Defaults to [rootNode.id].
  final String? initialSelectedNodeId;

  /// Called when a tree node is selected.
  final ValueChanged<ProvenanceNode>? onNodeSelected;

  /// Called when the user taps the thumbnail for full-screen viewing.
  final VoidCallback? onThumbnailTap;

  /// Called when the user taps an ingredient card.
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;

  /// The MIME type of the root asset.
  final String? mimeType;

  /// Whether to show the detail panel. Defaults to true.
  final bool showDetailPanel;

  const C2paManifestViewer({
    super.key,
    required this.rootNode,
    this.initialSelectedNodeId,
    this.onNodeSelected,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mimeType,
    this.showDetailPanel = true,
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
    _selectedNodeId = widget.initialSelectedNodeId ?? widget.rootNode.id;
    _selectedData = _findNode(_selectedNodeId)?.manifestViewData;
  }

  @override
  void didUpdateWidget(C2paManifestViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode) {
      _selectedNodeId = widget.initialSelectedNodeId ?? widget.rootNode.id;
      _selectedData = _findNode(_selectedNodeId)?.manifestViewData;
    }
  }

  ProvenanceNode? _findNode(String id) {
    for (final node in widget.rootNode.flatten()) {
      if (node.id == id) return node;
    }
    return null;
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

    return Row(
      children: [
        Expanded(
          child: ProvenanceTreeViewer(
            rootNode: widget.rootNode,
            selectedNodeId: _selectedNodeId,
            onNodeSelected: _onNodeSelected,
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
          ),
        ],
      ],
    );
  }
}
