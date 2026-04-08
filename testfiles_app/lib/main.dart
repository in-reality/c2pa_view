
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:c2pa_view/c2pa_view.dart';

class TestCase {
  final String title;
  final String imageUrl;
  final String manifestUrl;
  final String detailedManifestUrl;

  TestCase({
    required this.title,
    required this.imageUrl,
    required this.manifestUrl,
    required this.detailedManifestUrl,
  });

  factory TestCase.fromDsv(String line) {
    final parts = line.split('|');
    return TestCase(
      title: parts[0],
      imageUrl: parts[1],
      manifestUrl: parts[2],
      detailedManifestUrl: parts[3],
    );
  }

  String get mimeType {
    final lower = imageUrl.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

Future<List<TestCase>> loadTestCases() async {
  final String contents = await rootBundle.loadString(
    'assets/c2pa_test_data.dsv',
  );
  final lines = contents.split('\n');
  return lines
      .skip(1)
      .where((line) => line.isNotEmpty)
      .map(TestCase.fromDsv)
      .toList();
}

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
  runApp(MyApp(initError: initError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: C2paViewerTheme(
        data: const C2paViewerThemeData(),
        child: Scaffold(
          appBar: AppBar(title: const Text('C2PA Test Cases')),
          body: SelectionArea(
            child: Column(
              children: [
                if (initError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.orange.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rust library failed to load',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          initError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.orange.shade900),
                        ),
                        if (kIsWeb)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'On web, the Rust/WASM build may be missing or '
                              'CORS may block loading. See flutter_rust_bridge '
                              'web documentation.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select a file from the C2PA JPEG test files to view its '
                    'manifest data using the new provenance tree viewer.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<TestCase>>(
                    future: loadTestCases(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        return Column(
                          children: [
                            if (snapshot.data!.length >= 4)
                              _PopupDemoCard(testCase: snapshot.data![3]),
                            Expanded(
                              child: TestCaseList(testCases: snapshot.data!),
                            ),
                          ],
                        );
                      } else {
                        return const Center(
                          child: Text('No test cases found.'),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TestCaseList extends StatelessWidget {
  final List<TestCase> testCases;

  const TestCaseList({super.key, required this.testCases});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: testCases.length,
      itemBuilder: (context, index) {
        final testCase = testCases[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(testCase.title),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ManifestViewerPage(testCase: testCase),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Demo card showing an image thumbnail with a content-credentials button
/// that opens a [showManifestDetailPopup].
class _PopupDemoCard extends StatefulWidget {
  final TestCase testCase;

  const _PopupDemoCard({required this.testCase});

  @override
  State<_PopupDemoCard> createState() => _PopupDemoCardState();
}

class _PopupDemoCardState extends State<_PopupDemoCard> {
  late Future<({ManifestStore? store, Uint8List? bytes})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchManifestAndBytes(
      widget.testCase.imageUrl,
      widget.testCase.mimeType,
    );
  }

  static Future<({ManifestStore? store, Uint8List? bytes})>
  _fetchManifestAndBytes(String url, String format) async {
    final response = await http.get(Uri.parse(url));
    final bytes = Uint8List.fromList(response.bodyBytes);
    final store = ManifestStore.fromBytes(response.bodyBytes, format);
    return (store: store, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder<({ManifestStore? store, Uint8List? bytes})>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading popup demo...'),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data?.store == null) {
                return SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      snapshot.hasError
                          ? 'Demo load error: ${snapshot.error}'
                          : 'No manifest found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }

              final store = snapshot.data!.store!;
              final bytes = snapshot.data!.bytes;
              final manifest = store.manifests[store.activeManifest]!;
              final viewData = ManifestViewDataMapper.map(manifest);
              final mediaImage =
                  bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;

              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image:
                          viewData.thumbnail ??
                          mediaImage ??
                          const AssetImage(''),
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const SizedBox(
                            height: 120,
                            width: 120,
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.testCase.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the icon to open manifest details as a popup',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (buttonContext) {
                      return IconButton(
                        icon: const Icon(Icons.verified_user),
                        tooltip: 'View Content Credentials',
                        iconSize: 32,
                        onPressed: () {
                          showManifestDetailPopup(
                            buttonContext,
                            data: viewData,
                            mimeType: widget.testCase.mimeType,
                            mediaImage: mediaImage,
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Full-screen page that fetches bytes from the URL, then parses the manifest.
class ManifestViewerPage extends StatefulWidget {
  final TestCase testCase;

  const ManifestViewerPage({super.key, required this.testCase});

  @override
  State<ManifestViewerPage> createState() => _ManifestViewerPageState();
}

class _ManifestViewerPageState extends State<ManifestViewerPage> {
  late Future<({ManifestStore? store, Uint8List? bytes})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchManifestAndBytes(
      widget.testCase.imageUrl,
      widget.testCase.mimeType,
    );
  }

  static Future<({ManifestStore? store, Uint8List? bytes})>
  _fetchManifestAndBytes(String url, String format) async {
    final response = await http.get(Uri.parse(url));
    final bytes = Uint8List.fromList(response.bodyBytes);
    final store = ManifestStore.fromBytes(response.bodyBytes, format);
    return (store: store, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.testCase.title;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<({ManifestStore? store, Uint8List? bytes})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading manifest:\n${snapshot.error}'),
              ),
            );
          }

          final store = snapshot.data?.store;
          final bytes = snapshot.data?.bytes;
          if (store == null) {
            return const Center(child: Text('No manifest found in this file.'));
          }

          try {
            final graph = ProvenanceMapper.mapToGraph(store);
            final mediaImage =
                bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
            return C2paViewerTheme(
              data: const C2paViewerThemeData(),
              child: C2paManifestViewer(
                graph: graph,
                mimeType: widget.testCase.mimeType,
                mediaImage: mediaImage,
              ),
            );
          } catch (e) {
            return Center(child: Text('Error building provenance graph: $e'));
          }
        },
      ),
    );
  }
}
