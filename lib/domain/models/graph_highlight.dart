import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/provenance_annotations.dart';
import 'package:flutter/material.dart';

/// Visual style for one highlight layer on a node or edge.
class HighlightStyle {
  const HighlightStyle({
    this.borderColor,
    this.fillColor,
    this.edgeColor,
    this.strokeWidth,
  });

  final Color? borderColor;
  final Color? fillColor;
  final Color? edgeColor;
  final double? strokeWidth;
}

/// One highlight layer applied to a node or edge.
///
/// Multiple layers on the same target render in list order; later layers
/// paint on top.
class GraphHighlight {
  const GraphHighlight({
    required this.layerId,
    required this.style,
  });

  final String layerId;
  final HighlightStyle style;
}

/// Resolved highlight maps keyed by node id and edge id.
class GraphHighlights {
  const GraphHighlights({
    this.nodeHighlights = const {},
    this.edgeHighlights = const {},
  });

  static const GraphHighlights empty = GraphHighlights();

  final Map<String, List<GraphHighlight>> nodeHighlights;
  final Map<String, List<GraphHighlight>> edgeHighlights;

  List<GraphHighlight> forNode(final String nodeId) =>
      nodeHighlights[nodeId] ?? const [];

  List<GraphHighlight> forEdge(final String edgeId) =>
      edgeHighlights[edgeId] ?? const [];

  GraphHighlights mergedWith(final GraphHighlights other) {
    return GraphHighlights(
      nodeHighlights: _mergeMaps(nodeHighlights, other.nodeHighlights),
      edgeHighlights: _mergeMaps(edgeHighlights, other.edgeHighlights),
    );
  }

  static Map<String, List<GraphHighlight>> _mergeMaps(
    final Map<String, List<GraphHighlight>> a,
    final Map<String, List<GraphHighlight>> b,
  ) {
    if (a.isEmpty) {
      return b;
    }
    if (b.isEmpty) {
      return a;
    }
    final merged = Map<String, List<GraphHighlight>>.from(a);
    for (final entry in b.entries) {
      merged[entry.key] = [...merged[entry.key] ?? const [], ...entry.value];
    }
    return merged;
  }
}

/// Built-in highlight layer ids used for selection-path painting.
abstract final class C2paHighlightLayers {
  static const String selected = 'c2pa:selected';
  static const String selectionPath = 'c2pa:selection-path';
}

/// Resolves paint properties from stacked highlights and decorations.
class HighlightResolver {
  const HighlightResolver._();

  static Color resolveNodeBorder({
    required final List<GraphHighlight> highlights,
    required final bool isSelected,
    required final bool isOnPath,
    required final C2paViewerThemeData theme,
    final NodeDecoration? decoration,
  }) {
    if (isSelected) {
      return theme.selectedNodeBorderColor;
    }
    if (decoration?.borderColor != null) {
      return decoration!.borderColor!;
    }
    for (final highlight in highlights.reversed) {
      final color = highlight.style.borderColor;
      if (color != null) {
        return color;
      }
    }
    if (isOnPath) {
      return theme.pathNodeBorderColor;
    }
    return theme.defaultNodeBorderColor;
  }

  static double resolveNodeBorderWidth({
    required final List<GraphHighlight> highlights,
    required final bool isSelected,
    final NodeDecoration? decoration,
  }) {
    if (isSelected) {
      return 2.5;
    }
    if (decoration?.borderWidth != null) {
      return decoration!.borderWidth!;
    }
    for (final highlight in highlights.reversed) {
      final width = highlight.style.strokeWidth;
      if (width != null) {
        return width;
      }
    }
    return 1.5;
  }

  static Color? resolveNodeFill({
    required final List<GraphHighlight> highlights,
    required final C2paViewerThemeData theme,
  }) {
    for (final highlight in highlights.reversed) {
      final fill = highlight.style.fillColor;
      if (fill != null) {
        return fill;
      }
    }
    return null;
  }

  static Color resolveEdgeColor({
    required final List<GraphHighlight> highlights,
    required final C2paViewerThemeData theme,
    final EdgeDecoration? decoration,
  }) {
    if (decoration?.strokeColor != null) {
      return decoration!.strokeColor!;
    }
    for (final highlight in highlights.reversed) {
      final color = highlight.style.edgeColor ?? highlight.style.borderColor;
      if (color != null) {
        return color;
      }
    }
    return theme.edgeColor;
  }

  static double resolveEdgeStrokeWidth({
    required final List<GraphHighlight> highlights,
    final EdgeDecoration? decoration,
  }) {
    if (decoration?.strokeWidth != null) {
      return decoration!.strokeWidth!;
    }
    for (final highlight in highlights.reversed) {
      final width = highlight.style.strokeWidth;
      if (width != null) {
        return width;
      }
    }
    return 2.0;
  }
}
