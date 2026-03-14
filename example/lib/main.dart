import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:c2pa_view/c2pa_view.dart';

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
  final String contents =
      await rootBundle.loadString('assets/c2pa_test_data.dsv');
  final lines = contents.split('\n');
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
      home: C2paViewerTheme(
        data: const C2paViewerThemeData(),
        child: Scaffold(
          appBar: AppBar(title: const Text('C2PA Test Cases')),
          body: Column(
            children: [
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManifestViewerPage(
                        filePath: localPath,
                        title: testCase.title,
                      ),
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

/// Full-screen page showing the provenance tree and manifest details.
class ManifestViewerPage extends StatelessWidget {
  final String filePath;
  final String title;

  const ManifestViewerPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final store = ManifestStore.fromLocalPath(filePath);

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('No manifest found in this file.')),
      );
    }

    try {
      final rootNode = ProvenanceMapper.mapToTree(store);

      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: C2paViewerTheme(
          data: const C2paViewerThemeData(),
          child: C2paManifestViewer(
            rootNode: rootNode,
            mimeType: File(filePath).path.endsWith('.jpg')
                ? 'image/jpeg'
                : null,
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text('Error building provenance tree: $e')),
      );
    }
  }
}
