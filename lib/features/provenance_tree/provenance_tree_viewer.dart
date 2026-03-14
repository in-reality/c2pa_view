import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';

import 'widgets/tree_edge_painter.dart';
import 'widgets/tree_node_card.dart';
import 'widgets/zoom_controls.dart';

/// The central provenance tree viewer showing an asset and its ingredients
/// in a hierarchical tree layout.
///
/// This is one of the two primary widgets in this package, mirroring the
/// TreeView from the C2PA verify-site. It displays a zoomable, pannable
/// tree where the root is the main asset and children are ingredients,
/// each showing a thumbnail and credential status.
///
/// When a node is tapped, [onNodeSelected] is called with the selected
/// [ProvenanceNode], which can be used to update the sidebar detail panel.
class ProvenanceTreeViewer extends StatefulWidget {
  final ProvenanceNode rootNode;
  final String? selectedNodeId;
  final ValueChanged<ProvenanceNode>? onNodeSelected;
  final Color? backgroundColor;

  const ProvenanceTreeViewer({
    super.key,
    required this.rootNode,
    this.selectedNodeId,
    this.onNodeSelected,
    this.backgroundColor,
  });

  @override
  State<ProvenanceTreeViewer> createState() => _ProvenanceTreeViewerState();
}

class _ProvenanceTreeViewerState extends State<ProvenanceTreeViewer> {
  final TransformationController _transformController =
      TransformationController();

  late List<_LayoutNode> _layoutNodes;
  late List<EdgeLine> _edges;
  late Size _treeSize;

  @override
  void initState() {
    super.initState();
    _computeLayout();
  }

  @override
  void didUpdateWidget(ProvenanceTreeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootNode != widget.rootNode) {
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _computeLayout() {
    final theme = C2paViewerThemeData.defaults;
    final nodes = <_LayoutNode>[];
    final edges = <EdgeLine>[];

    final depthMap = <int, List<ProvenanceNode>>{};
    _groupByDepth(widget.rootNode, 0, depthMap);

    final maxNodesAtDepth = depthMap.values
        .map((list) => list.length)
        .fold(0, (a, b) => math.max(a, b));

    final nodeW = theme.nodeWidth;
    final nodeH = theme.nodeHeight;
    final spacingX = theme.nodeSpacingX;
    final spacingY = theme.nodeSpacingY;

    final totalWidth = maxNodesAtDepth * (nodeW + spacingX) - spacingX;
    final totalHeight = depthMap.length * (nodeH + spacingY) - spacingY;

    const padding = 80.0;

    final nodePositions = <String, Offset>{};

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
        nodes.add(_LayoutNode(node: node, position: Offset(x, y)));
      }
    }

    _buildEdges(widget.rootNode, nodePositions, edges, nodeW, nodeH);

    _layoutNodes = nodes;
    _edges = edges;
    _treeSize = Size(
      totalWidth + padding * 2,
      totalHeight + padding * 2,
    );
  }

  void _groupByDepth(
    ProvenanceNode node,
    int depth,
    Map<int, List<ProvenanceNode>> map,
  ) {
    map.putIfAbsent(depth, () => []).add(node);
    for (final child in node.children) {
      _groupByDepth(child, depth + 1, map);
    }
  }

  void _buildEdges(
    ProvenanceNode node,
    Map<String, Offset> positions,
    List<EdgeLine> edges,
    double nodeW,
    double nodeH,
  ) {
    final parentPos = positions[node.id];
    if (parentPos == null) return;

    for (final child in node.children) {
      final childPos = positions[child.id];
      if (childPos == null) continue;

      edges.add(EdgeLine(
        from: Offset(parentPos.dx + nodeW / 2, parentPos.dy + nodeH),
        to: Offset(childPos.dx + nodeW / 2, childPos.dy),
      ));

      _buildEdges(child, positions, edges, nodeW, nodeH);
    }
  }

  Set<String> _pathToSelected() {
    if (widget.selectedNodeId == null) return {};
    final path = <String>{};
    _findPath(widget.rootNode, widget.selectedNodeId!, path);
    return path;
  }

  bool _findPath(ProvenanceNode node, String targetId, Set<String> path) {
    if (node.id == targetId) {
      path.add(node.id);
      return true;
    }
    for (final child in node.children) {
      if (_findPath(child, targetId, path)) {
        path.add(node.id);
        return true;
      }
    }
    return false;
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

  void _fitToView() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final pathNodeIds = _pathToSelected();

    return Container(
      color: widget.backgroundColor ?? theme.surfaceVariantColor,
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.1,
            maxScale: 5.0,
            child: SizedBox(
              width: _treeSize.width,
              height: _treeSize.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: _treeSize,
                    painter: TreeEdgePainter(
                      edges: _edges,
                      color: theme.edgeColor,
                    ),
                  ),
                  for (final layoutNode in _layoutNodes)
                    Positioned(
                      left: layoutNode.position.dx,
                      top: layoutNode.position.dy,
                      child: TreeNodeCard(
                        node: layoutNode.node,
                        isSelected:
                            layoutNode.node.id == widget.selectedNodeId,
                        isOnPath:
                            pathNodeIds.contains(layoutNode.node.id) &&
                                layoutNode.node.id != widget.selectedNodeId,
                        onTap: widget.onNodeSelected != null
                            ? () => widget.onNodeSelected!(layoutNode.node)
                            : null,
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
      ),
    );
  }
}

class _LayoutNode {
  final ProvenanceNode node;
  final Offset position;

  const _LayoutNode({required this.node, required this.position});
}
