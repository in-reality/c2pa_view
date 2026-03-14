import 'package:c2pa_manifest_viewer/c2pa_manifest_viewer.dart';
import 'package:flutter/material.dart';

import 'sample_data.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C2PA Manifest Viewer',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3366FF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3366FF),
        brightness: Brightness.dark,
      ),
      home: HomePage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page — scenario picker + viewer
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedScenarioIndex = 0;
  int _viewMode = 0; // 0 = combined, 1 = tree only, 2 = detail only

  SampleScenario get _scenario => allScenarios[_selectedScenarioIndex];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewerTheme =
        widget.isDark ? C2paViewerThemeData.dark() : const C2paViewerThemeData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('C2PA Manifest Viewer'),
        centerTitle: false,
        actions: [
          _ViewModeToggle(
            mode: _viewMode,
            onChanged: (m) => setState(() => _viewMode = m),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip:
                widget.isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Scenario picker strip
          _ScenarioPicker(
            scenarios: allScenarios,
            selectedIndex: _selectedScenarioIndex,
            onSelected: (i) => setState(() => _selectedScenarioIndex = i),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // Viewer area
          Expanded(
            child: C2paViewerTheme(
              data: viewerTheme,
              child: _buildViewer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    switch (_viewMode) {
      case 1:
        return _TreeOnlyView(scenario: _scenario);
      case 2:
        return _DetailOnlyView(scenario: _scenario);
      default:
        return _CombinedView(scenario: _scenario);
    }
  }
}

// ---------------------------------------------------------------------------
// Scenario picker — horizontal scrollable chip strip
// ---------------------------------------------------------------------------

class _ScenarioPicker extends StatelessWidget {
  final List<SampleScenario> scenarios;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ScenarioPicker({
    required this.scenarios,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < scenarios.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _ScenarioChip(
                scenario: scenarios[i],
                isSelected: i == selectedIndex,
                onTap: () => onSelected(i),
                colorScheme: cs,
                textTheme: tt,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  final SampleScenario scenario;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ScenarioChip({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  IconData get _icon {
    final label = scenario.label.toLowerCase();
    if (label.contains('camera')) return Icons.camera_alt;
    if (label.contains('photoshop') || label.contains('edit')) {
      return Icons.auto_fix_high;
    }
    if (label.contains('ai')) return Icons.auto_awesome;
    if (label.contains('composite') || label.contains('complex')) {
      return Icons.layers;
    }
    if (label.contains('tamper') || label.contains('invalid')) {
      return Icons.dangerous;
    }
    if (label.contains('unrecognized')) return Icons.help_outline;
    return Icons.description;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                scenario.label,
                style: textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View mode toggle
// ---------------------------------------------------------------------------

class _ViewModeToggle extends StatelessWidget {
  final int mode;
  final ValueChanged<int> onChanged;

  const _ViewModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      segments: const [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.view_sidebar, size: 18),
          tooltip: 'Combined view',
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.account_tree, size: 18),
          tooltip: 'Tree only',
        ),
        ButtonSegment(
          value: 2,
          icon: Icon(Icons.info_outline, size: 18),
          tooltip: 'Detail only',
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined view — tree + sidebar (the default, full experience)
// ---------------------------------------------------------------------------

class _CombinedView extends StatelessWidget {
  final SampleScenario scenario;
  const _CombinedView({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return C2paManifestViewer(
      key: ValueKey(scenario.label),
      rootNode: scenario.root,
      mimeType: scenario.mimeType,
      onNodeSelected: (node) => _showSnackBar(context, 'Selected: ${node.title}'),
      onIngredientTap: (ing) =>
          _showSnackBar(context, 'Ingredient tapped: ${ing.title}'),
      onThumbnailTap: () =>
          _showSnackBar(context, 'Thumbnail tapped (lightbox would open)'),
    );
  }
}

// ---------------------------------------------------------------------------
// Tree-only view — just the provenance tree, full width
// ---------------------------------------------------------------------------

class _TreeOnlyView extends StatefulWidget {
  final SampleScenario scenario;
  const _TreeOnlyView({required this.scenario});

  @override
  State<_TreeOnlyView> createState() => _TreeOnlyViewState();
}

class _TreeOnlyViewState extends State<_TreeOnlyView> {
  String? _selectedId;

  @override
  void didUpdateWidget(_TreeOnlyView old) {
    super.didUpdateWidget(old);
    if (old.scenario.label != widget.scenario.label) _selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    return ProvenanceTreeViewer(
      key: ValueKey(widget.scenario.label),
      rootNode: widget.scenario.root,
      selectedNodeId: _selectedId ?? widget.scenario.root.id,
      onNodeSelected: (node) {
        setState(() => _selectedId = node.id);
        _showSnackBar(context, 'Selected: ${node.title ?? node.id}');
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Detail-only view — just the manifest detail panel, centered
// ---------------------------------------------------------------------------

class _DetailOnlyView extends StatefulWidget {
  final SampleScenario scenario;
  const _DetailOnlyView({required this.scenario});

  @override
  State<_DetailOnlyView> createState() => _DetailOnlyViewState();
}

class _DetailOnlyViewState extends State<_DetailOnlyView> {
  late ManifestViewData _data;
  late List<ProvenanceNode> _allNodes;
  late String _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _initNodes();
  }

  @override
  void didUpdateWidget(_DetailOnlyView old) {
    super.didUpdateWidget(old);
    if (old.scenario.label != widget.scenario.label) _initNodes();
  }

  void _initNodes() {
    _allNodes = widget.scenario.root.flatten();
    _selectedNodeId = widget.scenario.root.id;
    _data = widget.scenario.root.manifestViewData ??
        const ManifestViewData(title: '(no data)');
  }

  void _selectNode(String id) {
    final node = _allNodes.firstWhere((n) => n.id == id);
    setState(() {
      _selectedNodeId = id;
      _data = node.manifestViewData ?? const ManifestViewData(title: '(no data)');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        // Node list on the left
        if (_allNodes.length > 1)
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: cs.surfaceContainerLow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Nodes in tree',
                      style: tt.titleSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                Expanded(
                  child: ListView.separated(
                    itemCount: _allNodes.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: cs.outlineVariant),
                    itemBuilder: (context, i) {
                      final n = _allNodes[i];
                      final selected = n.id == _selectedNodeId;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
                        leading: Icon(
                          _validationIcon(n.validationResult),
                          size: 18,
                          color: _validationColor(n.validationResult, cs),
                        ),
                        title: Text(
                          n.title ?? n.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium,
                        ),
                        subtitle: n.issuer != null
                            ? Text(n.issuer!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall)
                            : null,
                        onTap: () => _selectNode(n.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_allNodes.length > 1)
          VerticalDivider(width: 1, color: cs.outlineVariant),

        // Detail panel
        Expanded(
          child: Center(
            child: ManifestDetailPanel(
              key: ValueKey(_selectedNodeId),
              data: _data,
              mimeType: widget.scenario.mimeType,
              onThumbnailTap: () =>
                  _showSnackBar(context, 'Thumbnail tapped'),
              onIngredientTap: (ing) =>
                  _showSnackBar(context, 'Ingredient: ${ing.title}'),
            ),
          ),
        ),
      ],
    );
  }

  IconData _validationIcon(ValidationResult r) {
    switch (r.status) {
      case ValidationStatus.valid:
        return Icons.verified;
      case ValidationStatus.invalid:
        return Icons.dangerous;
      case ValidationStatus.unrecognized:
        return Icons.warning_amber_rounded;
      case ValidationStatus.noCredential:
        return Icons.remove_circle_outline;
    }
  }

  Color _validationColor(ValidationResult r, ColorScheme cs) {
    switch (r.status) {
      case ValidationStatus.valid:
        return Colors.green;
      case ValidationStatus.invalid:
        return cs.error;
      case ValidationStatus.unrecognized:
        return Colors.orange;
      case ValidationStatus.noCredential:
        return cs.outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        width: 400,
      ),
    );
}
