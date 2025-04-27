import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:c2pa_view/c2pa_view.dart';

// Decent introduction: https://medium.com/flutter-community/how-to-create-publish-and-manage-flutter-packages-b4f2cd2c6b90

// Run with:
// flutter_rust_bridge_codegen build-web
// flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp

// I have worked on getting 'flutter_rust_bridge_codegen build-web' to run
//    before the main-run in Android Studio, but it seems it runs the pre-script
//    without knowledge about path variables. Should be fixable (see
//    Run main.dart configuration)

const String testURL = 'https://c2pa.org/public-testfiles/image/jpeg/manifests/'
  'adobe-20220124-CACAICAICICA/manifest_store.json';

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
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Column(
            children: [
              Text(
                'Action: Call Rust `greet("Jeppe")`\nResult: `${greet(name: "Jeppe")}`',
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                padding: const EdgeInsets.all(16),
                child: ManifestViewer(
                  manifestUrl: testURL,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManifestViewer extends StatelessWidget {
  final String manifestUrl;

  const ManifestViewer({super.key, required this.manifestUrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchManifest(manifestUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return ContentCredentialWidget(manifestData: snapshot.data!);
        } else {
          return Text('No data found.');
        }
      },
    );
  }
}

Future<Map<String, dynamic>> fetchManifest(String url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load manifest');
  }
}
