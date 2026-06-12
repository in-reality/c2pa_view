import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_interaction.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/features/manifest_detail/manifest_detail_panel.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_tree_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A combined viewer widget that shows the provenance DAG on the left
/// and the manifest detail panel on the right, mirroring the layout of
/// the C2PA verify-site.
///
/// This is a convenience widget that composes [ProvenanceTreeViewer] and
/// [ManifestDetailPanel]. You can also use those widgets independently
/// for more flexible layouts.
class C2paManifestViewer extends StatefulWidget {

  const C2paManifestViewer({
    required this.graph,
    super.key,
    this.initialSelectedNodeId,
    this.onNodeSelected,
    this.onThumbnailTap,
    this.onIngredientTap,
    this.mimeType,
    this.showDetailPanel = true,
    this.mediaImage,
    this.annotations = ProvenanceAnnotations.empty,
    this.highlights = GraphHighlights.empty,
    this.nodeDecorator,
    this.edgeDecorator,
    this.interactionHandler,
  });
  final ProvenanceGraph graph;
  final String? initialSelectedNodeId;
  final ValueChanged<ProvenanceNode>? onNodeSelected;
  final VoidCallback? onThumbnailTap;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;
  final String? mimeType;
  final bool showDetailPanel;
  final ProvenanceAnnotations annotations;
  final GraphHighlights highlights;
  final ProvenanceNodeDecorator? nodeDecorator;
  final ProvenanceEdgeDecorator? edgeDecorator;
  final ProvenanceInteractionHandler? interactionHandler;

  /// Optional image for the actual media file. When the manifest has no
  /// embedded thumbnail, this is shown instead (detail panel and root tree node).
  final ImageProvider? mediaImage;

  @override
  State<C2paManifestViewer> createState() => _C2paManifestViewerState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ProvenanceGraph>('graph', graph))
    ..add(StringProperty('initialSelectedNodeId', initialSelectedNodeId))
    ..add(ObjectFlagProperty<ValueChanged<ProvenanceNode>?>.has('onNodeSelected', onNodeSelected))
    ..add(ObjectFlagProperty<VoidCallback?>.has('onThumbnailTap', onThumbnailTap))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap))
    ..add(StringProperty('mimeType', mimeType))
    ..add(DiagnosticsProperty<bool>('showDetailPanel', showDetailPanel))
    ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage))
    ..add(DiagnosticsProperty<ProvenanceAnnotations>('annotations', annotations))
    ..add(DiagnosticsProperty<GraphHighlights>('highlights', highlights))
    ..add(
      ObjectFlagProperty<ProvenanceNodeDecorator?>.has(
        'nodeDecorator',
        nodeDecorator,
      ),
    )
    ..add(
      ObjectFlagProperty<ProvenanceEdgeDecorator?>.has(
        'edgeDecorator',
        edgeDecorator,
      ),
    )
    ..add(
      ObjectFlagProperty<ProvenanceInteractionHandler?>.has(
        'interactionHandler',
        interactionHandler,
      ),
    );
  }
}

class _C2paManifestViewerState extends State<C2paManifestViewer> {
  late String _selectedNodeId;
  late ManifestViewData? _selectedData;

  @override
  void initState() {
    super.initState();
    _selectedNodeId = widget.initialSelectedNodeId ?? widget.graph.rootId;
    _selectedData = widget.graph.findNode(_selectedNodeId)?.manifestViewData;
  }

  @override
  void didUpdateWidget(final C2paManifestViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _selectedNodeId = widget.initialSelectedNodeId ?? widget.graph.rootId;
      _selectedData = widget.graph.findNode(_selectedNodeId)?.manifestViewData;
    }
  }

  void _onNodeSelected(final ProvenanceNode node) {
    setState(() {
      _selectedNodeId = node.id;
      _selectedData = node.manifestViewData;
    });
    widget.onNodeSelected?.call(node);
  }

  ProvenanceInteractionHandler? _treeInteractionHandler() {
    final handler = widget.interactionHandler;
    if (handler == null) {
      return null;
    }
    return ComposingProvenanceInteractionHandler(
      delegate: handler,
      onSelect: _onNodeSelected,
    );
  }

  @override
  Widget build(final BuildContext context) {
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
              annotations: widget.annotations,
              highlights: widget.highlights,
              nodeDecorator: widget.nodeDecorator,
              edgeDecorator: widget.edgeDecorator,
              interactionHandler: _treeInteractionHandler(),
            ),
          ),
          if (widget.showDetailPanel && _selectedData != null) ...[
            Container(width: 1, color: theme.borderColor),
            ManifestDetailPanel(
              data: _selectedData!,
              mimeType: widget.mimeType,
              onThumbnailTap: widget.onThumbnailTap,
              onIngredientTap: widget.onIngredientTap,
              extraSections:
                  widget.annotations.detailSections[_selectedNodeId] ??
                  const [],
              mediaImage:
                  _selectedNodeId == widget.graph.rootId
                      ? widget.mediaImage
                      : null,
            ),
          ],
        ],
      ),
    );
  }
}
