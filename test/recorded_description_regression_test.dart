import 'dart:convert';
import 'dart:io';

import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/features/manifest_detail/sections/process_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recorded ingredient prose remains visible beside valid CR', (
    final tester,
  ) async {
    final raw = jsonDecode(
      File('test/fixtures/recorded_description_store.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final store = ManifestStore.fromJson(raw);
    final manifest = store.manifests[store.activeManifest]!;
    final description = manifest.ingredients.single.description!;
    expect(description, contains('Source media binding validation'));
    final summaries = ManifestViewDataMapper.buildSummaries(store);
    final data = ManifestViewDataMapper.map(manifest, summaries: summaries);
    expect(data.validationResult.isValid, isTrue);
    expect(data.ingredients.single.credentialResult.isValid, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ProcessSection(data: data)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Synthetic source.mp4'), findsOneWidget);
    expect(find.text('CR'), findsOneWidget);
    expect(find.text(description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
