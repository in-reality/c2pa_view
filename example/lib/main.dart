import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:c2pa_view/c2pa_view.dart';

// Decent introduction: https://medium.com/flutter-community/how-to-create-publish-and-manage-flutter-packages-b4f2cd2c6b90

// Run with:
// flutter_rust_bridge_codegen build-web
// flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp

// I have worked on getting 'flutter_rust_bridge_codegen build-web' to run
//    before the main-run in Android Studio, but it seems it runs the pre-script
//    without knowledge about path variables. Should be fixable (see
//    Run main.dart configuration)

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
                      title: Text(testCase.title),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            ContentCredentialWidget(
                              source: localPath,
                              contentPreview: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(localPath),
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: Icon(Icons.error_outline, size: 48),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
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
