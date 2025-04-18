import 'package:flutter/material.dart';
import 'package:c2pa_view/c2pa_view.dart';

// Decent introduction: https://medium.com/flutter-community/how-to-create-publish-and-manage-flutter-packages-b4f2cd2c6b90

// Run with:
// flutter_rust_bridge_codegen build-web
// flutter run --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp

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
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
