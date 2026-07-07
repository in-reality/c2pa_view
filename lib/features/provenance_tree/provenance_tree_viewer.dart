import 'dart:collection';
import 'dart:math' as math;

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/graph_highlight.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:c2pa_view/domain/models/provenance_interaction.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/features/provenance_tree/node_attachment_integrity.dart';
import 'package:c2pa_view/features/provenance_tree/node_attachment_layout.dart';
import 'package:c2pa_view/features/provenance_tree/provenance_fit_transform.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_edge_painter.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/tree_node_card.dart';
import 'package:c2pa_view/features/provenance_tree/widgets/zoom_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays a provenance DAG as a zoomable, pannable diagram.
///
/// Nodes with multiple parents (shared ingredients) appear once with
/// edges from every parent.
class ProvenanceTreeViewer extends StatefulWidget {
  const ProvenanceTreeViewer({
    required this.graph,
    super.key,
    this.selectedNodeId,
    this.onNodeSelected,
    this.backgroundColor,
    this.mediaImage,
    this.nodeThumbnailProvider,
    this.annotations = ProvenanceAnnotations.empty,
    this.highlights = GraphHighlights.empty,
    this.nodeDecorator,
    this.edgeDecorator,
    this.interactionHandler,
    this.attachmentContentBuilder,
  });

  final ProvenanceGraph graph;
  final String? selectedNodeId;
  final ValueChanged<ProvenanceNode>? onNodeSelected;
  final Color? backgroundColor;
  final ImageProvider? mediaImage;
  final ProvenanceNodeThumbnailProvider? nodeThumbnailProvider;
  final ProvenanceAnnotations annotations;
  final GraphHighlights highlights;
  final ProvenanceNodeDecorator? nodeDecorator;
  final ProvenanceEdgeDecorator? edgeDecorator;
  final ProvenanceInteractionHandler? interactionHandler;
  final ProvenanceAttachmentContentBuilder? attachmentContentBuilder;

  @override
  State<ProvenanceTreeViewer> createState() => _ProvenanceTreeViewerState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ProvenanceGraph>('graph', graph))
      ..add(StringProperty('selectedNodeId', selectedNodeId))
      ..add(
        ObjectFlagProperty<ValueChanged<ProvenanceNode>?>.has(
          'onNodeSelected',
          onNodeSelected,
        ),
      )
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty<ImageProvider<Object>?>('mediaImage', mediaImage))
      ..add(
        ObjectFlagProperty<ProvenanceNodeThumbnailProvider?>.has(
          'nodeThumbnailProvider',
          nodeThumbnailProvider,
        ),
      )
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
      )
      ..add(
        ObjectFlagProperty<ProvenanceAttachmentContentBuilder?>.has(
          'attachmentContentBuilder',
          attachmentContentBuilder,
        ),
      );
  }
}

class _ProvenanceTreeViewerState extends State<ProvenanceTreeViewer> {
  final TransformationController _transformController =
      TransformationController();

  late List<_LayoutNode> _layoutNodes;
  late List<_LayoutAttachment> _layoutAttachments;
  late List<Rect> _attachmentBounds;
  late List<EdgeLine> _edges;
  late Size _treeSize;
  Size _viewportSize = Size.zero;
  bool _autoFitPending = true;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(final ProvenanceTreeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _computeLayout();
      _scheduleFitToView();
    } else if (oldWidget.annotations.attachments != widget.annotations.attachments) {
      _computeLayout();
      _scheduleFitToView();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _computeLayout() {
    const theme = C2paViewerThemeData.defaults;
    final graph = widget.graph;

    final depthMap = _assignDepths(graph);

    final maxNodesAtDepth = depthMap.values
        .map((final list) => list.length)
        .fold(0, math.max);

    final nodeW = theme.nodeWidth;
    final nodeH = theme.nodeHeight;
    final spacingX = theme.nodeSpacingX;
    final spacingY = theme.nodeSpacingY;

    final totalWidth = maxNodesAtDepth * (nodeW + spacingX) - spacingX;
    final totalHeight = depthMap.length * (nodeH + spacingY) - spacingY;

    const padding = 80.0;

    final nodePositions = <String, Offset>{};
    final layoutNodes = <_LayoutNode>[];

    for (final entry in depthMap.entries) {
      final depth = entry.key;
      final nodesAtDepth = entry.value;
      final rowWidth = nodesAtDepth.length * (nodeW + spacingX) - spacingX;
      final startX = (totalWidth - rowWidth) / 2 + padding;
      final y = depth * (nodeH + spacingY) + padding;

      for (var i = 0; i < nodesAtDepth.length; i++) {
        final node = nodesAtDepth[i];
        final x = startX + i * (nodeW + spacingX);
        nodePositions[node.id] = Offset(x, y);
        layoutNodes.add(_LayoutNode(node: node, position: Offset(x, y)));
      }
    }

    final edges = <EdgeLine>[];
    for (final edge in graph.edges) {
      final parentPos = nodePositions[edge.parentId];
      final childPos = nodePositions[edge.childId];
      if (parentPos == null || childPos == null) {
        continue;
      }
      edges.add(
        EdgeLine(
          parentId: edge.parentId,
          childId: edge.childId,
          from: Offset(parentPos.dx + nodeW / 2, parentPos.dy + nodeH),
          to: Offset(childPos.dx + nodeW / 2, childPos.dy),
        ),
      );
    }

    _layoutNodes = layoutNodes;
    _edges = edges;
    _computeAttachmentLayout(
      nodeWidth: nodeW,
      nodeHeight: nodeH,
      nodePadding: padding,
      nodeTotalWidth: totalWidth,
      nodeTotalHeight: totalHeight,
    );
    _autoFitPending = true;
  }

  void _computeAttachmentLayout({
    required final double nodeWidth,
    required final double nodeHeight,
    required final double nodePadding,
    required final double nodeTotalWidth,
    required final double nodeTotalHeight,
  }) {
    final graphNodeIds = widget.graph.nodes.keys.toSet();
    assertNoOrphanAttachmentMapKeys(
      attachmentsByAnchor: widget.annotations.attachments,
      graphNodeIds: graphNodeIds,
    );

    final anchorNodeSize = Size(nodeWidth, nodeHeight);
    final layoutAttachments = <_LayoutAttachment>[];
    final attachmentBounds = <Rect>[];

    for (final layoutNode in _layoutNodes) {
      final matchedAttachments = paintableNodeAttachmentsForAnchor(
        anchorNodeId: layoutNode.node.id,
        attachmentsByAnchor: widget.annotations.attachments,
        graphNodeIds: graphNodeIds,
      );
      if (matchedAttachments.isEmpty) {
        continue;
      }

      final offsets = nodeAttachmentFanOffsets(
        count: matchedAttachments.length,
        anchorNodeSize: anchorNodeSize,
      );

      for (var i = 0; i < matchedAttachments.length; i++) {
        final attachment = matchedAttachments[i];
        final position = layoutNode.position + offsets[i];
        layoutAttachments.add(
          _LayoutAttachment(
            attachment: attachment,
            position: position,
          ),
        );
        attachmentBounds.add(
          Rect.fromLTWH(
            position.dx,
            position.dy,
            kNodeAttachmentWidth,
            kNodeAttachmentHeight,
          ),
        );
      }
    }

    _layoutAttachments = layoutAttachments;
    _attachmentBounds = attachmentBounds;

    _normalizeLayoutToIncludeAttachments(
      nodeWidth: nodeWidth,
      nodeHeight: nodeHeight,
      nodePadding: nodePadding,
      nodeTotalWidth: nodeTotalWidth,
      nodeTotalHeight: nodeTotalHeight,
    );
  }

  /// Shifts node/edge/attachment positions when satellites extend above or left
  /// of the padded node grid so nothing is clipped by the stack origin.
  void _normalizeLayoutToIncludeAttachments({
    required final double nodeWidth,
    required final double nodeHeight,
    required final double nodePadding,
    required final double nodeTotalWidth,
    required final double nodeTotalHeight,
  }) {
    if (_layoutNodes.isEmpty) {
      _treeSize = Size(
        nodeTotalWidth + nodePadding * 2,
        nodeTotalHeight + nodePadding * 2,
      );
      return;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;

    for (final layoutNode in _layoutNodes) {
      final left = layoutNode.position.dx;
      final top = layoutNode.position.dy;
      minX = math.min(minX, left);
      minY = math.min(minY, top);
      maxX = math.max(maxX, left + nodeWidth);
      maxY = math.max(maxY, top + nodeHeight);
    }

    for (final rect in _attachmentBounds) {
      minX = math.min(minX, rect.left);
      minY = math.min(minY, rect.top);
      maxX = math.max(maxX, rect.right);
      maxY = math.max(maxY, rect.bottom);
    }

    final shiftX = minX < nodePadding ? nodePadding - minX : 0.0;
    final shiftY = minY < nodePadding ? nodePadding - minY : 0.0;

    if (shiftX != 0 || shiftY != 0) {
      final shift = Offset(shiftX, shiftY);
      _layoutNodes = [
        for (final layoutNode in _layoutNodes)
          _LayoutNode(
            node: layoutNode.node,
            position: layoutNode.position + shift,
          ),
      ];
      _layoutAttachments = [
        for (final layoutAttachment in _layoutAttachments)
          _LayoutAttachment(
            attachment: layoutAttachment.attachment,
            position: layoutAttachment.position + shift,
          ),
      ];
      _attachmentBounds = [
        for (final rect in _attachmentBounds) rect.shift(shift),
      ];
      _edges = [
        for (final edge in _edges)
          EdgeLine(
            parentId: edge.parentId,
            childId: edge.childId,
            from: edge.from + shift,
            to: edge.to + shift,
          ),
      ];
      minX += shiftX;
      minY += shiftY;
      maxX += shiftX;
      maxY += shiftY;
    }

    _treeSize = Size(
      math.max(nodeTotalWidth + nodePadding * 2, maxX + nodePadding),
      math.max(nodeTotalHeight + nodePadding * 2, maxY + nodePadding),
    );
  }

  GraphHighlights _selectionHighlights(final C2paViewerThemeData theme) {
    if (widget.selectedNodeId == null) {
      return GraphHighlights.empty;
    }

    final pathNodeIds = _pathToSelected();
    final nodeHighlights = <String, List<GraphHighlight>>{};

    for (final nodeId in pathNodeIds) {
      if (nodeId == widget.selectedNodeId) {
        nodeHighlights[nodeId] = [
          GraphHighlight(
            layerId: C2paHighlightLayers.selected,
            style: HighlightStyle(borderColor: theme.selectedNodeBorderColor),
          ),
        ];
      } else {
        nodeHighlights[nodeId] = [
          GraphHighlight(
            layerId: C2paHighlightLayers.selectionPath,
            style: HighlightStyle(borderColor: theme.pathNodeBorderColor),
          ),
        ];
      }
    }

    return GraphHighlights(nodeHighlights: nodeHighlights);
  }

  Map<int, List<ProvenanceNode>> _assignDepths(final ProvenanceGraph graph) {
    final depths = <String, int>{};
    final queue = Queue<String>();

    depths[graph.rootId] = 0;
    queue.add(graph.rootId);

    final childrenOf = <String, List<String>>{};
    for (final edge in graph.edges) {
      childrenOf.putIfAbsent(edge.parentId, () => []).add(edge.childId);
    }

    while (queue.isNotEmpty) {
      final id = queue.removeFirst();
      final myDepth = depths[id]!;
      for (final childId in childrenOf[id] ?? <String>[]) {
        final proposedDepth = myDepth + 1;
        if (!depths.containsKey(childId) || depths[childId]! < proposedDepth) {
          depths[childId] = proposedDepth;
          queue.add(childId);
        }
      }
    }

    final depthMap = <int, List<ProvenanceNode>>{};
    for (final entry in depths.entries) {
      final node = graph.nodes[entry.key];
      if (node != null) {
        depthMap.putIfAbsent(entry.value, () => []).add(node);
      }
    }
    return depthMap;
  }

  Set<String> _pathToSelected() {
    if (widget.selectedNodeId == null) {
      return {};
    }
    final graph = widget.graph;

    final parentsOf = <String, List<String>>{};
    for (final edge in graph.edges) {
      parentsOf.putIfAbsent(edge.childId, () => []).add(edge.parentId);
    }

    final onPath = <String>{};
    _collectAncestors(widget.selectedNodeId!, parentsOf, onPath);
    return onPath;
  }

  void _collectAncestors(
    final String nodeId,
    final Map<String, List<String>> parentsOf,
    final Set<String> result,
  ) {
    if (!result.add(nodeId)) {
      return;
    }
    for (final parentId in parentsOf[nodeId] ?? <String>[]) {
      _collectAncestors(parentId, parentsOf, result);
    }
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.25).clamp(0.1, 5.0);
    final ratio = newScale / currentScale;
    matrix.scale(ratio);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.25).clamp(0.1, 5.0);
    final ratio = newScale / currentScale;
    matrix.scale(ratio);
    _transformController.value = matrix;
  }

  void _scheduleFitToView() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fitToView();
    });
  }

  void _fitToView() {
    if (_viewportSize.isEmpty || _layoutNodes.isEmpty || !mounted) {
      return;
    }

    final theme = C2paViewerTheme.of(context);
    final contentBounds = provenanceGraphBounds(
      nodePositions: _layoutNodes.map((final node) => node.position),
      nodeWidth: theme.nodeWidth,
      nodeHeight: theme.nodeHeight,
      attachmentRects: _attachmentBounds,
    ).inflate(8);

    _transformController.value = provenanceFitToViewTransform(
      contentBounds: contentBounds,
      viewportSize: _viewportSize,
    );
    _autoFitPending = false;
  }

  void _handleNodeTap(final ProvenanceNode node) {
    final decoration = widget.annotations.nodeDecorations[node.id];
    if (widget.interactionHandler != null) {
      widget.interactionHandler!.onNodeTap(node, decoration: decoration);
      return;
    }
    widget.onNodeSelected?.call(node);
  }

  void _handleBadgeTap(
    final String nodeId,
    final DecorationBadge badge,
  ) {
    final handler = widget.interactionHandler;
    if (handler == null) {
      return;
    }
    if (badge.icon != null) {
      handler.onIconTap(nodeId, badge.id, payload: badge.payload);
    } else {
      handler.onBadgeTap(nodeId, badge.id, payload: badge.payload);
    }
  }

  void _handleAttachmentTap(final NodeAttachment attachment) {
    widget.interactionHandler?.onAttachmentTap(
      attachment.anchorNodeId,
      attachment.id,
      payload: attachment.payload,
    );
  }

  Widget _buildAttachmentContent(final NodeAttachment attachment) {
    final builder = widget.attachmentContentBuilder;
    if (builder != null) {
      return builder(context, attachment: attachment);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: attachment.color, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final pathNodeIds = _pathToSelected();
    final resolvedHighlights = widget.highlights.mergedWith(
      _selectionHighlights(theme),
    );

    return ColoredBox(
      color: widget.backgroundColor ?? theme.surfaceVariantColor,
      child: LayoutBuilder(
        builder: (final context, final constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (_autoFitPending && !_viewportSize.isEmpty) {
            _scheduleFitToView();
          }

          return Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.1,
                maxScale: 5,
                child: SizedBox(
                  width: _treeSize.width,
                  height: _treeSize.height,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: CustomPaint(
                          size: _treeSize,
                          painter: TreeEdgePainter(
                            edges: _edges,
                            theme: theme,
                            edgeHighlights: resolvedHighlights.edgeHighlights,
                            edgeDecorations: widget.annotations.edgeDecorations,
                            edgeDecorator: widget.edgeDecorator,
                          ),
                        ),
                      ),
                      for (final layoutNode in _layoutNodes)
                        Positioned(
                          left: layoutNode.position.dx,
                          top: layoutNode.position.dy,
                          child: TreeNodeCard(
                            key: ValueKey(layoutNode.node.id),
                            node: layoutNode.node,
                            isSelected:
                                layoutNode.node.id == widget.selectedNodeId,
                            isOnPath:
                                pathNodeIds.contains(layoutNode.node.id) &&
                                layoutNode.node.id != widget.selectedNodeId,
                            highlights:
                                resolvedHighlights.forNode(layoutNode.node.id),
                            decoration:
                                widget.annotations
                                    .nodeDecorations[layoutNode.node.id],
                            nodeDecorator: widget.nodeDecorator,
                            onTap:
                                widget.onNodeSelected != null ||
                                    widget.interactionHandler != null
                                    ? () => _handleNodeTap(layoutNode.node)
                                    : null,
                            onBadgeTap:
                                widget.interactionHandler != null
                                    ? (final badge) => _handleBadgeTap(
                                      layoutNode.node.id,
                                      badge,
                                    )
                                    : null,
                            thumbnailOverride: resolveProvenanceNodeThumbnail(
                              node: layoutNode.node,
                              rootId: widget.graph.rootId,
                              thumbnailProvider: widget.nodeThumbnailProvider,
                              mediaImage: widget.mediaImage,
                            ),
                          ),
                        ),
                      for (final layoutAttachment in _layoutAttachments)
                        Positioned(
                          left: layoutAttachment.position.dx,
                          top: layoutAttachment.position.dy,
                          width: kNodeAttachmentWidth,
                          height: kNodeAttachmentHeight,
                          child:
                              widget.interactionHandler != null
                                  ? GestureDetector(
                                    key: ValueKey(
                                      'attachment:${layoutAttachment.attachment.id}',
                                    ),
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        () => _handleAttachmentTap(
                                          layoutAttachment.attachment,
                                        ),
                                    child: _buildAttachmentContent(
                                      layoutAttachment.attachment,
                                    ),
                                  )
                                  : IgnorePointer(
                                    key: ValueKey(
                                      'attachment:${layoutAttachment.attachment.id}',
                                    ),
                                    child: _buildAttachmentContent(
                                      layoutAttachment.attachment,
                                    ),
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: ZoomControls(
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onFit: _fitToView,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LayoutNode {
  const _LayoutNode({required this.node, required this.position});
  final ProvenanceNode node;
  final Offset position;
}

class _LayoutAttachment {
  const _LayoutAttachment({
    required this.attachment,
    required this.position,
  });

  final NodeAttachment attachment;
  final Offset position;
}
