import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:c2pa_view/c2pa_view.dart';

/// showManifest is an example of hot to use the C2PAView package to show a
/// (image) file manifest.
Future<SingleChildScrollView> showManifest(File file) async {
  // We make a preview (optional) for showing the content with the manifest
  final preview = Image.file(
    file,
    height: 200,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return const Text('Error loading image');
    },
  );

  // Get manifest store from file
  final manifestStore = ManifestStore.fromLocalPath(file.path);

  // Check if manifest store is null (if there is no manifest)
  if (manifestStore == null) {
    return const SingleChildScrollView(
      child: Text('No manifest found'),
    );
  }

  // Make content credentials widget with manifest store and preview
  // We wrap in scrollable as the manifest can be long
  final ccw = SingleChildScrollView(
    child: ContentCredentialsWidget(
      manifestStore: manifestStore,
      contentPreview: preview,
    ),
  );

  return ccw;
}

/// TestCase is used to show the test cases from the C2PA test file repository.
class TestCase {
  final String title;
  final String imageUrl;
  final String manifestUrl;
  final String detailedManifestUrl;
  String? localImagePath;

  TestCase({
    required this.title,
    required this.imageUrl,
    required this.manifestUrl,
    required this.detailedManifestUrl,
    this.localImagePath,
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

  Future<String> downloadImage() async {
    if (localImagePath != null) {
      return localImagePath!;
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.jpg';
    final filePath = '${tempDir.path}/$fileName';

    final dio = Dio();
    await dio.download(imageUrl, filePath);
    
    localImagePath = filePath;
    return filePath;
  }
}

Future<List<TestCase>> loadTestCases() async {
  final String contents = await rootBundle.loadString('assets/c2pa_test_data.dsv');
  final lines = contents.split('\n');
  // Skip header and empty lines
  return lines
      .skip(1)
      .where((line) => line.isNotEmpty)
      .map(TestCase.fromDsv)
      .toList();
}

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('C2PA Test Cases')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select file from the C2PA JPEG test files to show it\'s manifest data.',
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
                    return TestCaseList(testCases: snapshot.data!);
                  } else {
                    return const Center(child: Text('No test cases found.'));
                  }
                },
              ),
            ),
          ],
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
              onTap: () async {
                try {
                  final localPath = await testCase.downloadImage();
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(File(localPath).path.split('/').last),
                      content: FutureBuilder<SingleChildScrollView>(
                        future: showManifest(File(localPath)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            return snapshot.data!;
                          } else {
                            return const Text('No manifest data available');
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error downloading image: $e')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
