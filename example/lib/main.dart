import 'package:c2pa_view/c2pa_view.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await RustLib.init().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('RustLib.init timed out after 15s'),
    );
  } catch (e, st) {
    initError = e.toString();
    debugPrint('RustLib.init failed: $e\n$st');
  }
  runApp(C2paExampleApp(initError: initError));
}

/// Root app with [C2paViewerTheme] so viewer widgets resolve theme.
class C2paExampleApp extends StatelessWidget {
  const C2paExampleApp({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InReality C2PA Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: C2paViewerTheme(
        data: const C2paViewerThemeData(),
        child: SelectionArea(
          child: HomePage(initError: initError),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initError});

  final String? initError;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isDragging = false;
  String? _error;

  void _clearFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _error = null;
    });
  }

  Future<void> _chooseAnotherFile() async {
    _clearFile();
    await _pickFile();
  }

  Future<void> _loadFile(Uint8List bytes, String name) async {
    setState(() {
      _fileBytes = bytes;
      _fileName = name;
      _error = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes == null) {
      setState(() {
        _error = 'Could not read file bytes (try a smaller file on web).';
      });
      return;
    }
    await _loadFile(bytes, f.name);
  }

  DropItem? _firstLeafFile(List<DropItem> items) {
    for (final item in items) {
      if (item is DropItemDirectory) {
        final nested = _firstLeafFile(item.children);
        if (nested != null) {
          return nested;
        }
      } else {
        return item;
      }
    }
    return null;
  }

  Future<void> _onDropDone(DropDoneDetails detail) async {
    setState(() => _isDragging = false);
    if (detail.files.isEmpty) {
      return;
    }
    final file = _firstLeafFile(detail.files);
    if (file == null) {
      setState(() {
        _error = 'No file found in the drop (folders are not supported).';
      });
      return;
    }
    try {
      final bytes = await file.readAsBytes();
      await _loadFile(bytes, file.name);
    } catch (e) {
      setState(() {
        _error = 'Failed to read dropped file: $e';
      });
    }
  }

  String _mimeTypeForFileName(String name) {
    return lookupMimeType(name) ?? 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    if (_fileBytes != null && _fileName != null) {
      return _ManifestViewScaffold(
        fileBytes: _fileBytes!,
        fileName: _fileName!,
        initError: widget.initError,
        onBack: _clearFile,
        onChooseAnother: _chooseAnotherFile,
        mimeTypeForFileName: _mimeTypeForFileName,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('InReality C2PA Viewer')),
      body: Column(
        children: [
          if (widget.initError != null)
            _InitErrorBanner(message: widget.initError!),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: DropTarget(
                onDragEntered: (_) {
                  setState(() => _isDragging = true);
                },
                onDragExited: (_) {
                  setState(() => _isDragging = false);
                },
                onDragDone: _onDropDone,
                child: GestureDetector(
                  onTap: _pickFile,
                  behavior: HitTestBehavior.opaque,
                  child: _SelectFilePanel(isDragging: _isDragging),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitErrorBanner extends StatelessWidget {
  const _InitErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.orange.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rust library failed to load',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade900,
                ),
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'On web, the Rust/WASM build may be missing or CORS may '
                'block loading. See flutter_rust_bridge web documentation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Center "Select file" area with dashed border and drag-hover styling.
class _SelectFilePanel extends StatelessWidget {
  const _SelectFilePanel({required this.isDragging});

  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDragging ? Colors.blue : Colors.grey.shade400;
    final bgColor =
        isDragging ? Colors.blue.shade50 : Colors.grey.shade100;
    final iconColor =
        isDragging ? Colors.blue : Colors.grey.shade600;

    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: borderColor,
        strokeWidth: 2,
        radius: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 304,
          height: 204,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              'Select file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Click to choose a file, or drag and drop here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 8.0;
    const gapLength = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double len = dashLength;
        final double next = (distance + len).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

class _ManifestViewScaffold extends StatelessWidget {
  const _ManifestViewScaffold({
    required this.fileBytes,
    required this.fileName,
    required this.initError,
    required this.onBack,
    required this.onChooseAnother,
    required this.mimeTypeForFileName,
  });

  final Uint8List fileBytes;
  final String fileName;
  final String? initError;
  final VoidCallback onBack;
  final VoidCallback onChooseAnother;
  final String Function(String name) mimeTypeForFileName;

  @override
  Widget build(BuildContext context) {
    final mimeType = mimeTypeForFileName(fileName);
    final store = ManifestStore.fromBytes(fileBytes, mimeType);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(fileName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (initError != null)
            _InitErrorBanner(message: initError!),
          Expanded(
            child: _buildBody(context, store, mimeType),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ManifestStore? store,
    String mimeType,
  ) {
    if (store == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No C2PA manifest found in this file.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onChooseAnother,
                child: const Text('Choose another file'),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final graph = ProvenanceMapper.mapToGraph(store);
      final mediaImage = MemoryImage(fileBytes);
      return C2paManifestViewer(
        graph: graph,
        mimeType: mimeType,
        mediaImage: mediaImage,
      );
    } catch (e, st) {
      debugPrint('C2paManifestViewer build error: $e\n$st');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SelectableText(
            'Could not build manifest viewer:\n$e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
  }
}
