import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Validator conformance corpus extensions (must stay aligned with
/// `frontend/c2pa_view/rust/tests/validate_evidence.rs` and the task AC).
const _mediaExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'heic',
  'heif',
  'dng',
  'mp4',
  'm4a',
  'm4v',
  'mov',
};

String _mimeForExtension(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'heic':
    case 'heif':
      return 'image/heif';
    case 'png':
      return 'image/png';
    case 'dng':
      return 'image/x-adobe-dng';
    case 'mp4':
    case 'm4v':
      return 'video/mp4';
    case 'm4a':
      return 'audio/mp4';
    case 'mov':
      return 'video/quicktime';
    default:
      throw StateError('unknown extension: $ext');
  }
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i++) {
    final probe = Directory(
      '${dir.path}${Platform.pathSeparator}c2pa${Platform.pathSeparator}'
      'evidence${Platform.pathSeparator}validator${Platform.pathSeparator}'
      'conformance-samples',
    );
    if (probe.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  fail(
    'Could not find repo root (directory containing '
    'c2pa/evidence/validator/conformance-samples). cwd=${Directory.current.path}',
  );
}

Directory _evidenceDir() {
  final fromEnv = Platform.environment['EVIDENCE_DIR'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return Directory(fromEnv);
  }
  return Directory(
    '${_findRepoRoot().path}${Platform.pathSeparator}c2pa${Platform.pathSeparator}'
    'evidence',
  );
}

String _trustAnchorsPemPath() {
  final fromEnv = Platform.environment['C2PA_TRUST_ANCHORS_PEM'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  return '${_evidenceDir().path}${Platform.pathSeparator}validator${Platform.pathSeparator}'
      'trust-list${Platform.pathSeparator}anchors.pem';
}

String _pngOutputName(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot <= 0) {
    return '$filename.png';
  }
  return '${filename.substring(0, dot)}.png';
}

bool _stemEndsWithUnsigned(String filename) {
  final dot = filename.lastIndexOf('.');
  final stem = dot > 0 ? filename.substring(0, dot) : filename;
  return stem.endsWith('_unsigned');
}

bool _isMediaFile(FileSystemEntity e) {
  if (e is! File) {
    return false;
  }
  final name = e.uri.pathSegments.last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot >= name.length - 1) {
    return false;
  }
  final ext = name.substring(dot + 1).toLowerCase();
  return _mediaExtensions.contains(ext);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Validator corpus screenshots', () {
    late String trustPem;
    late Directory screenshotsDir;
    late Directory rawJsonDir;
    late List<File> assets;

    setUpAll(() async {
      await RustLib.init();

      final evidence = _evidenceDir();
      final samplesDir = Directory(
        '${evidence.path}${Platform.pathSeparator}validator${Platform.pathSeparator}'
        'conformance-samples',
      );
      screenshotsDir = Directory(
        '${evidence.path}${Platform.pathSeparator}validator${Platform.pathSeparator}'
        'screenshots',
      );
      rawJsonDir = Directory(
        '${evidence.path}${Platform.pathSeparator}validator${Platform.pathSeparator}'
        'raw-json',
      );

      if (!samplesDir.existsSync()) {
        fail('Conformance samples missing: ${samplesDir.path}');
      }
      screenshotsDir.createSync(recursive: true);

      final pemPath = _trustAnchorsPemPath();
      final pemFile = File(pemPath);
      if (!pemFile.existsSync()) {
        fail('Trust PEM missing: $pemPath');
      }
      trustPem = pemFile.readAsStringSync().trim();
      if (trustPem.isEmpty) {
        fail('Trust PEM empty: $pemPath');
      }

      assets =
          samplesDir
              .listSync()
              .whereType<File>()
              .where(_isMediaFile)
              .where((f) => !_stemEndsWithUnsigned(f.uri.pathSegments.last))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(
        assets,
        isNotEmpty,
        reason: 'No media files under ${samplesDir.path}',
      );
    });

    testWidgets('capture one PNG per conformance sample', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final captureKey = GlobalKey();

      for (final file in assets) {
        final filename = file.uri.pathSegments.last;
        final dot = filename.lastIndexOf('.');
        final ext = dot > 0 ? filename.substring(dot + 1) : '';
        final mime = _mimeForExtension(ext);
        final bytes = await file.readAsBytes();

        final expectedJsonFile = File(
          '${rawJsonDir.path}${Platform.pathSeparator}$filename.json',
        );
        expect(
          expectedJsonFile.existsSync(),
          isTrue,
          reason: 'Missing raw-json sidecar for $filename',
        );
        final expectedMap =
            json.decode(expectedJsonFile.readAsStringSync())
                as Map<String, dynamic>;
        final expectedState = expectedMap['validation_state'];
        expect(expectedState, isA<String>());

        final trustJson = getManifestJsonFromBytes(
          fileBytes: bytes,
          format: mime,
          trustAnchorsPem: trustPem,
        );
        expect(trustJson, isNotNull, reason: 'No manifest JSON for $filename');
        final actualMap = json.decode(trustJson!) as Map<String, dynamic>;
        expect(
          actualMap['validation_state'],
          expectedState,
          reason: 'validation_state mismatch for $filename',
        );

        final store = ManifestStore.fromBytes(
          bytes,
          mime,
          trustAnchorsPem: trustPem,
        );
        expect(store, isNotNull, reason: 'ManifestStore null for $filename');

        final graph = ProvenanceMapper.mapToGraph(store!);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: captureKey,
                child: C2paViewerTheme(
                  data: const C2paViewerThemeData(),
                  child: C2paManifestViewer(
                    graph: graph,
                    mimeType: mime,
                    mediaImage: MemoryImage(Uint8List.fromList(bytes)),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 45),
        );

        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final bd = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bd, isNotNull);
        final pngBytes = bd!.buffer.asUint8List(
          bd.offsetInBytes,
          bd.lengthInBytes,
        );
        expect(pngBytes.length, greaterThan(8));
        expect(pngBytes[0], 0x89);
        expect(pngBytes[1], 0x50);
        expect(pngBytes[2], 0x4e);
        expect(pngBytes[3], 0x47);

        final outName = _pngOutputName(filename);
        final written = File(
          '${screenshotsDir.path}${Platform.pathSeparator}$outName',
        );
        await written.writeAsBytes(pngBytes, flush: true);
        expect(written.existsSync(), isTrue);
      }
    });
  });
}
