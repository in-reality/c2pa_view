import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';

import 'widgets/tree_edge_painter.dart';
import 'widgets/tree_node_card.dart';
import 'widgets/zoom_controls.dart';

/// Displays a provenance DAG as a zoomable, pannable diagram.
///
/// Nodes with multiple parents (shared ingredients) appear once with
/// edges from every parent.
class ProvenanceTreeViewer extends StatefulWidget {
  final ProvenanceGraph graph;
  final String? selectedNodeId;
  final ValueChanged<ProvenanceNode>? onNodeSelected;
  final Color? backgroundColor;
  final ImageProvider? mediaImage;

  const ProvenanceTreeViewer({
    super.key,
    required this.graph,
    this.selectedNodeId,
    this.onNodeSelected,
    this.backgroundColor,
    this.mediaImage,
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
    if (oldWidget.graph != widget.graph) {
      _computeLayout();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  void _computeLayout() {
    final theme = C2paViewerThemeData.defaults;
    final graph = widget.graph;

    final depthMap = _assignDepths(graph);

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

    // Build edge lines from the graph's edge list.
    final edges = <EdgeLine>[];
    for (final edge in graph.edges) {
      final parentPos = nodePositions[edge.parentId];
      final childPos = nodePositions[edge.childId];
      if (parentPos == null || childPos == null) continue;
      edges.add(EdgeLine(
        from: Offset(parentPos.dx + nodeW / 2, parentPos.dy + nodeH),
        to: Offset(childPos.dx + nodeW / 2, childPos.dy),
      ));
    }

    _layoutNodes = layoutNodes;
    _edges = edges;
    _treeSize = Size(
      totalWidth + padding * 2,
      totalHeight + padding * 2,
    );
  }

  /// Assign each node a depth using BFS.  A shared node's depth is the
  /// maximum depth any of its parents places it at (i.e. max-parent-depth + 1),
  /// ensuring it sits below all parents.
  Map<int, List<ProvenanceNode>> _assignDepths(ProvenanceGraph graph) {
    final depths = <String, int>{};
    final queue = Queue<String>();

    depths[graph.rootId] = 0;
    queue.add(graph.rootId);

    // Build a quick child lookup.
    final childrenOf = <String, List<String>>{};
    for (final edge in graph.edges) {
      childrenOf.putIfAbsent(edge.parentId, () => []).add(edge.childId);
    }

    // BFS, but re-enqueue a child when we discover a deeper path.
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

  // ---------------------------------------------------------------------------
  // Selection path highlighting
  // ---------------------------------------------------------------------------

  /// Walk edges backwards from the selected node to the root, collecting
  /// all nodes on any path.
  Set<String> _pathToSelected() {
    if (widget.selectedNodeId == null) return {};
    final graph = widget.graph;

    // Build parent lookup.
    final parentsOf = <String, List<String>>{};
    for (final edge in graph.edges) {
      parentsOf.putIfAbsent(edge.childId, () => []).add(edge.parentId);
    }

    final onPath = <String>{};
    _collectAncestors(widget.selectedNodeId!, parentsOf, onPath);
    return onPath;
  }

  void _collectAncestors(
    String nodeId,
    Map<String, List<String>> parentsOf,
    Set<String> result,
  ) {
    if (!result.add(nodeId)) return;
    for (final parentId in parentsOf[nodeId] ?? <String>[]) {
      _collectAncestors(parentId, parentsOf, result);
    }
  }

  // ---------------------------------------------------------------------------
  // Zoom controls
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                        mediaImage: layoutNode.node.id == widget.graph.rootId
                            ? widget.mediaImage
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
