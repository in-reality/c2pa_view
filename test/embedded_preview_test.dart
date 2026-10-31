import 'dart:convert';
import 'dart:ui' as ui;

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/manifest_store.dart';
import 'package:c2pa_view/domain/entities/manifest.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:c2pa_view/domain/entities/thumbnail_data.dart';
import 'package:c2pa_view/domain/mappers/provenance_mapper.dart';
import 'package:c2pa_view/domain/mappers/manifest_view_data_mapper.dart';
import 'package:c2pa_view/features/shared/widgets/credential_indicator.dart';
import 'package:c2pa_view/domain/models/provenance_node.dart';
import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/features/shared/widgets/c2pa_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A deterministic 2x2 opaque red PNG. Browser-safe, no files or network.
const redPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfqCh4TOwXTxazXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTEwLTMwVDE5OjU5OjA1KzAwOjAwjXAfAQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0xMC0zMFQxOTo1OTowNSswMDowMPwtp70AAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMTAtMzBUMTk6NTk6MDUrMDA6MDCrOIZiAAAAFklEQVQI12P8z8DAwMDAxMDAwMDAAAANHQEDK+mmyAAAAABJRU5ErkJggg==';

Map<String, dynamic> preview({String source = 'edited'}) => {
  'format': 'image/png',
  'identifier': 'embedded',
  'resolution': 'resolved',
  'containing_manifest': source,
  'data': base64Decode(redPng),
};

ManifestStore previewStore({bool ownAncestorPreview = false}) =>
    ManifestStore.fromJson({
      'active_manifest': 'edited',
      'manifests': {
        'edited': {
          'label': 'edited',
          'title': 'edited',
          'thumbnail': preview(),
          'validation_status': [
            {'code': 'signingCredential.untrusted'},
          ],
          'ingredients': [
            {
              'title': 'middle',
              'active_manifest': 'middle',
              'relationship': 'parentOf',
            },
            {
              'title': 'unsigned video',
              'relationship': 'componentOf',
              'format': 'video/mp4',
              'thumbnail': preview(),
            },
            {
              'title': 'second component',
              'relationship': 'componentOf',
              'thumbnail': preview(),
            },
          ],
        },
        'middle': {
          'label': 'middle',
          'title': 'middle',
          'validation_status': [
            {'code': 'signingCredential.untrusted'},
          ],
          'ingredients': [
            {
              'title': 'original',
              'active_manifest': 'original',
              'relationship': 'parentOf',
              'thumbnail': preview(source: 'middle'),
            },
          ],
        },
        'original': {
          'label': 'original',
          'title': 'original',
          'validation_status': [],
          if (ownAncestorPreview) 'thumbnail': preview(source: 'original'),
        },
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final validationCases = <String, List<Map<String, String>>?>{
    'notVerified': null,
    'valid': [],
    'untrusted': [
      {'code': 'signingCredential.untrusted'},
    ],
    'invalid': [
      {'code': 'signingCredential.untrusted'},
      {'code': 'assertion.dataHash.mismatch'},
    ],
  };
  for (final entry in validationCases.entries) {
    ManifestStore diagnosticStore() => ManifestStore.fromJson({
      'active_manifest': 'root',
      'manifests': {
        'root': {
          'label': 'root',
          'signature_info': {'issuer': 'Synthetic issuer'},
          'thumbnail': preview(source: 'root'),
          if (entry.value != null) 'validation_status': entry.value,
        },
      },
    });

    for (final view in ['summary', 'graph detail', 'direct detail']) {
      test('current diagnostics map $view to ${entry.key}', () {
        final store = diagnosticStore();
        final node = ProvenanceMapper.mapToGraph(store).rootNode!;
        final result = switch (view) {
          'summary' => node.summary.validationResult,
          'graph detail' => node.manifestViewData!.validationResult,
          _ => ManifestViewDataMapper.map(
            store.manifests['root']!,
          ).validationResult,
        };
        expect(result.status.name, entry.key);
        expect(result.hasCredential, isTrue);
        expect(result.isValid, entry.key == 'valid');
      });
    }

    testWidgets('credential indicator renders ${entry.key}', (tester) async {
      final node = ProvenanceMapper.mapToGraph(diagnosticStore()).rootNode!;
      await tester.pumpWidget(
        MaterialApp(
          home: C2paViewerTheme(
            data: C2paViewerThemeData.defaults,
            child: CredentialIndicator(result: node.summary.validationResult),
          ),
        ),
      );
      final label = switch (entry.key) {
        'notVerified' => 'Not verified',
        'valid' => 'CR',
        'invalid' => 'Invalid',
        _ => 'Untrusted',
      };
      expect(find.text(label), findsOneWidget);
      if (entry.key == 'notVerified') {
        final text = tester.widget<Text>(find.text(label));
        expect(
          text.style!.color,
          C2paViewerThemeData.defaults.noCredentialColor,
        );
        expect(find.text('No CR'), findsNothing);
        await tester.pumpWidget(
          MaterialApp(
            home: C2paViewerTheme(
              data: C2paViewerThemeData.defaults,
              child: CredentialIndicator(
                result: node.summary.validationResult,
                compact: true,
              ),
            ),
          ),
        );
        expect(find.text('Not verified'), findsNothing);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.help_outline)).color,
          C2paViewerThemeData.defaults.noCredentialColor,
        );
      }
    });
  }

  final attributionTargets = <String, (bool, Object?, bool)>{
    'missing': (false, null, false),
    'null': (true, null, false),
    'string': (true, 'not a manifest', false),
    'number': (true, 42, false),
    'boolean': (true, false, false),
    'empty list': (true, <dynamic>[], false),
    'list of maps': (
      true,
      [
        {'label': 'other'},
      ],
      false,
    ),
    'map': (true, {'label': 'other'}, true),
    'generic string-key map': (
      true,
      <Object?, Object?>{'label': 'other'},
      true,
    ),
  };
  for (final target in attributionTargets.entries) {
    test(
      'R5 target eligibility ${target.key} retains negative and incomplete evidence',
      () {
        for (final activeClean in [false, true]) {
          for (final code in [
            null,
            'assertion.dataHash.mismatch',
            'signingCredential.untrusted',
          ]) {
            final store = ManifestStore.fromJson({
              'active_manifest': 'root',
              'manifests': {
                'root': {
                  'label': 'root',
                  if (activeClean) 'validation_status': [],
                },
                if (target.value.$1) 'other': target.value.$2,
              },
              'validation_status': [
                {
                  'url': 'self#jumbf=/c2pa/other/c2pa.signature',
                  if (code != null) 'code': code,
                },
              ],
            });
            final summaries = ManifestViewDataMapper.buildSummaries(store);
            final receivingLabel = target.value.$3 ? 'other' : 'root';
            final expected = switch (code) {
              'assertion.dataHash.mismatch' => 'invalid',
              'signingCredential.untrusted' => 'untrusted',
              _ => 'notVerified',
            };
            expect(
              summaries[receivingLabel]!.validationResult.status.name,
              expected,
              reason: '${target.key}, activeClean=$activeClean, code=$code',
            );
            expect(
              store.manifests[receivingLabel]!.validationStatusComputed,
              code != null,
            );
            expect(store.manifests.containsKey('other'), target.value.$3);
            if (target.value.$3) {
              expect(
                summaries['root']!.validationResult.status.name,
                activeClean ? 'valid' : 'notVerified',
              );
            }
          }
        }
      },
    );
    test(
      'R5 wrong-claim success ${target.key} cannot verify absent active evidence',
      () {
        final store = ManifestStore.fromJson({
          'active_manifest': 'root',
          'manifests': {
            'root': {'label': 'root'},
            if (target.value.$1) 'other': target.value.$2,
          },
          'validation_status': [
            {
              'code': 'claimSignature.validated',
              'url': 'self#jumbf=/c2pa/other/c2pa.signature',
            },
          ],
        });
        final summaries = ManifestViewDataMapper.buildSummaries(store);
        expect(summaries['root']!.validationResult.status.name, 'notVerified');
        expect(store.manifests['root']!.validationStatusComputed, isFalse);
        expect(
          store.rawManifestJsons['root']!.containsKey('validation_status'),
          isFalse,
        );
        expect(store.validationStatus.single.code, 'claimSignature.validated');
        if (target.value.$3)
          expect(summaries['other']!.validationResult.isValid, isTrue);
      },
    );
  }
  for (final badTarget in <String, Map>{
    'non-string keys': <Object?, Object?>{42: 'bad'},
    'invalid typed field': {'title': 42},
  }.entries) {
    test(
      'R5 protection strict loader rejection ${badTarget.key} stays rejection',
      () {
        expect(
          () => ManifestStore.fromJson({
            'active_manifest': 'root',
            'manifests': {
              'root': {'validation_status': []},
              'other': badTarget.value,
            },
            'validation_status': [
              {
                'code': 'assertion.dataHash.mismatch',
                'url': 'self#jumbf=/c2pa/other/c2pa.signature',
              },
            ],
          }),
          throwsA(isA<TypeError>()),
        );
      },
    );
  }
  test(
    'R5 skipped target cannot strand failure behind explicit active clean list',
    () {
      for (final target in attributionTargets.values.where(
        (value) => !value.$3,
      )) {
        for (final code in [
          'assertion.dataHash.mismatch',
          'signingCredential.untrusted',
        ]) {
          final store = ManifestStore.fromJson({
            'active_manifest': 'root',
            'manifests': {
              'root': {'validation_status': []},
              if (target.$1) 'other': target.$2,
            },
            'validation_status': [
              {'code': code, 'url': 'self#jumbf=/c2pa/other/c2pa.signature'},
            ],
          });
          expect(
            ManifestViewDataMapper.buildSummaries(
              store,
            )['root']!.validationResult.status.name,
            code == 'signingCredential.untrusted' ? 'untrusted' : 'invalid',
          );
        }
      }
    },
  );
  test(
    'R5 protection unmatched success preserves genuine active clean evidence',
    () {
      for (final target in attributionTargets.values) {
        final store = ManifestStore.fromJson({
          'active_manifest': 'root',
          'manifests': {
            'root': {'validation_status': []},
            if (target.$1) 'other': target.$2,
          },
          'validation_status': [
            {
              'code': 'claimSignature.validated',
              'url': 'self#jumbf=/c2pa/other/c2pa.signature',
            },
          ],
        });
        expect(
          ManifestViewDataMapper.buildSummaries(
            store,
          )['root']!.validationResult.isValid,
          isTrue,
        );
      }
    },
  );
  test(
    'R5 protection matched and existing unscoped active successes stay supported',
    () {
      for (final code in [
        'claimSignature.validated',
        'vendor.future.validated',
        'signingCredential.trusted',
      ]) {
        for (final target in [null, 'root', 'other']) {
          final store = ManifestStore.fromJson({
            'active_manifest': 'root',
            'manifests': {
              'root': {'label': 'root'},
              'other': {'label': 'other'},
            },
            'validation_status': [
              {
                'code': code,
                if (target != null)
                  'url': 'self#jumbf=/c2pa/$target/c2pa.signature',
              },
            ],
          });
          final summaries = ManifestViewDataMapper.buildSummaries(store);
          expect(summaries[target ?? 'root']!.validationResult.isValid, isTrue);
          if (target == 'other') {
            expect(
              summaries['root']!.validationResult.status.name,
              'notVerified',
            );
          }
        }
      }
    },
  );
  test('R5 matched success never erases fallback failure precedence', () {
    for (final code in [
      'assertion.dataHash.mismatch',
      'signingCredential.untrusted',
    ]) {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {
          'root': {'label': 'root'},
          'other': null,
        },
        'validation_status': [
          {
            'code': 'claimSignature.validated',
            'url': 'self#jumbf=/c2pa/root/c2pa.signature',
          },
          {'code': code, 'url': 'self#jumbf=/c2pa/other/c2pa.signature'},
        ],
      });
      expect(
        ManifestViewDataMapper.buildSummaries(
          store,
        )['root']!.validationResult.status.name,
        code == 'signingCredential.untrusted' ? 'untrusted' : 'invalid',
      );
    }
  });
  test(
    'R5 protection non-map manifest collection cannot produce active validity',
    () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': 42,
        'validation_status': [
          {'code': 'claimSignature.validated'},
        ],
      });
      expect(store.manifests, isEmpty);
      expect(() => ProvenanceMapper.mapToGraph(store), throwsStateError);
    },
  );

  final malformedCases = <String, (List<dynamic>, String)>{
    'null item': ([null], 'notVerified'),
    'generic map row': (
      [
        <Object?, Object?>{'code': 'claimSignature.validated'},
      ],
      'notVerified',
    ),
    'scalar items': ([42, false, 'bad'], 'notVerified'),
    'missing code': ([<String, dynamic>{}], 'notVerified'),
    'wrong code type': (
      [
        {'code': 42},
      ],
      'notVerified',
    ),
    'empty code': (
      [
        {'code': ''},
      ],
      'notVerified',
    ),
    'wrong optional field type': (
      [
        {'code': 'claimSignature.validated', 'url': 42},
      ],
      'notVerified',
    ),
    'partial informational': (
      [
        null,
        {'code': 'claimSignature.validated'},
      ],
      'notVerified',
    ),
    'partial untrusted': (
      [
        null,
        {'code': 'signingCredential.untrusted'},
      ],
      'untrusted',
    ),
    'partial invalid': (
      [
        null,
        {'code': 'assertion.dataHash.mismatch'},
      ],
      'invalid',
    ),
  };
  for (final entry in malformedCases.entries) {
    for (final level in ['claim', 'store']) {
      test('malformed diagnostics $level ${entry.key} cannot become clean', () {
        final store = ManifestStore.fromJson({
          'active_manifest': 'root',
          'manifests': {
            'root': {
              'label': 'root',
              'signature_info': {'issuer': 'Synthetic issuer'},
              if (level == 'claim') 'validation_status': entry.value.$1,
            },
          },
          if (level == 'store') 'validation_status': entry.value.$1,
        });
        final manifest = store.manifests['root']!;
        expect(manifest.validationStatusComputed, isFalse);
        final node = ProvenanceMapper.mapToGraph(store).rootNode!;
        for (final result in [
          node.summary.validationResult,
          node.manifestViewData!.validationResult,
          ManifestViewDataMapper.map(manifest).validationResult,
        ]) {
          expect(result.status.name, entry.value.$2);
          expect(result.isValid, isFalse);
          expect(result.hasCredential, isTrue);
        }
      });
    }
  }

  for (final raw in [
    <String, dynamic>{},
    'bad',
    42,
    {'code': 'claimSignature.validated'},
    {'code': 'signingCredential.untrusted'},
  ]) {
    test('non-list diagnostic container $raw remains unverified', () {
      for (final level in ['claim', 'store']) {
        final store = ManifestStore.fromJson({
          'active_manifest': 'root',
          'manifests': {
            'root': {
              'label': 'root',
              if (level == 'claim') 'validation_status': raw,
            },
          },
          if (level == 'store') 'validation_status': raw,
        });
        expect(store.manifests['root']!.validationStatusComputed, isFalse);
        expect(
          ProvenanceMapper.mapToGraph(
            store,
          ).rootNode!.summary.validationResult.status.name,
          'notVerified',
        );
      }
    });
  }
  test('null optional diagnostic fields are a complete computed check', () {
    final manifest = Manifest.fromJson({
      'validation_status': [
        {'code': 'claimSignature.validated', 'url': null, 'explanation': null},
      ],
    });
    expect(manifest.validationStatusComputed, isTrue);
    expect(
      ManifestViewDataMapper.map(manifest).validationResult.isValid,
      isTrue,
    );
  });

  test(
    'unattributable malformed store row only taints active claim completeness',
    () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {
          'root': {'validation_status': []},
          'ancestor': {'validation_status': []},
        },
        'validation_status': [
          null,
          {
            'code': 'signingCredential.untrusted',
            'url': 'self#jumbf=/c2pa/ancestor/c2pa.signature',
          },
        ],
      });
      final summaries = ManifestViewDataMapper.buildSummaries(store);
      expect(store.manifests['root']!.validationStatusComputed, isFalse);
      expect(summaries['root']!.validationResult.status.name, 'notVerified');
      expect(store.manifests['ancestor']!.validationStatusComputed, isTrue);
      expect(summaries['ancestor']!.validationResult.isUntrusted, isTrue);
    },
  );
  test('attributable malformed store row preserves other computed claims', () {
    final store = ManifestStore.fromJson({
      'active_manifest': 'root',
      'manifests': {
        'root': {'validation_status': []},
        'ancestor': {'validation_status': []},
      },
      'validation_status': [
        {'url': 'self#jumbf=/c2pa/ancestor/c2pa.signature'},
      ],
    });
    final summaries = ManifestViewDataMapper.buildSummaries(store);
    expect(summaries['root']!.validationResult.isValid, isTrue);
    expect(store.manifests['ancestor']!.validationStatusComputed, isFalse);
    expect(summaries['ancestor']!.validationResult.status.name, 'notVerified');
  });
  test(
    'unknown labels retain active fallback completeness and negative evidence',
    () {
      for (final code in [
        null,
        'signingCredential.untrusted',
        'assertion.dataHash.mismatch',
      ]) {
        final store = ManifestStore.fromJson({
          'active_manifest': 'root',
          'manifests': {
            'root': {'validation_status': []},
          },
          'validation_status': [
            {
              'url': 'self#jumbf=/c2pa/missing/c2pa.signature',
              if (code != null) 'code': code,
            },
          ],
        });
        expect(store.manifests['root']!.validationStatusComputed, code != null);
        expect(
          ProvenanceMapper.mapToGraph(
            store,
          ).rootNode!.summary.validationResult.status.name,
          switch (code) {
            'signingCredential.untrusted' => 'untrusted',
            'assertion.dataHash.mismatch' => 'invalid',
            _ => 'notVerified',
          },
        );
      }
    },
  );
  test('positive store row cannot hide malformed claim container', () {
    for (final raw in [
      'bad',
      {'code': 'claimSignature.validated'},
    ]) {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {
          'root': {'validation_status': raw},
        },
        'validation_status': [
          {'code': 'claimSignature.validated'},
        ],
      });
      expect(store.manifests['root']!.validationStatusComputed, isFalse);
      expect(
        ProvenanceMapper.mapToGraph(
          store,
        ).rootNode!.summary.validationResult.status.name,
        'notVerified',
      );
    }
  });
  for (final code in ['vendor.future.validated', 'vendor.future.failure']) {
    test(
      'extensible diagnostic code $code and unknown fields remain supported',
      () {
        final manifest = Manifest.fromJson({
          'validation_status': [
            {
              'code': code,
              'future_metadata': [null],
            },
          ],
        });
        expect(manifest.validationStatusComputed, isTrue);
        expect(
          ManifestViewDataMapper.map(manifest).validationResult.status.name,
          code.endsWith('.validated') ? 'valid' : 'invalid',
        );
      },
    );
  }

  for (final code in [
    'signingCredential.untrusted',
    'claimSignature.mismatch',
    'claimSignature.validated',
  ]) {
    test('uncomputed flag preserves $code evidence', () {
      final manifest = Manifest(
        validationStatus: [ValidationStatusEntry(code: code)],
      );
      expect(manifest.validationStatusComputed, isFalse);
      final result = ManifestViewDataMapper.map(manifest).validationResult;
      expect(result.status.name, switch (code) {
        'signingCredential.untrusted' => 'untrusted',
        'claimSignature.mismatch' => 'invalid',
        _ => 'notVerified',
      });
      expect(result.hasCredential, isTrue);
    });
  }

  testWidgets('absent credential remains distinct from not verified', (
    tester,
  ) async {
    final leaf = ProvenanceMapper.mapToGraph(
      previewStore(),
    ).nodes['edited/unsigned video']!;
    expect(leaf.summary.validationResult.hasCredential, isFalse);
    expect(leaf.summary.validationResult.status.name, 'noCredential');
    await tester.pumpWidget(
      MaterialApp(
        home: C2paViewerTheme(
          data: C2paViewerThemeData.defaults,
          child: CredentialIndicator(result: leaf.summary.validationResult),
        ),
      ),
    );
    expect(find.text('No CR'), findsOneWidget);
    expect(find.text('Not verified'), findsNothing);
  });

  test(
    'two hops, real components, own precedence and separate preview trust',
    () {
      final graph = ProvenanceMapper.mapToGraph(previewStore());
      expect(graph.nodes.length, 5);
      expect(graph.edges.length, 4);
      final original = graph.nodes['original']!;
      expect(original.summary.thumbnail, isA<MemoryImage>());
      expect(original.summary.validationResult.isValid, isTrue);
      expect(original.summary.previewSource!.containingManifest, 'middle');
      expect(
        original.summary.previewSource!.validationResult!.isUntrusted,
        isTrue,
      );
      expect(original.summary.previewSource!.isIngredient, isTrue);
      expect(
        original.manifestViewData!.previewSource,
        original.summary.previewSource,
      );
      final leaf = graph.nodes['edited/unsigned video']!;
      expect(leaf.summary.validationResult.hasCredential, isFalse);
      expect(leaf.summary.previewSource!.containingManifest, 'edited');
      expect(leaf.summary.previewSource!.validationResult!.isUntrusted, isTrue);
      expect(leaf.summary.thumbnail, isA<MemoryImage>());
      final own = ProvenanceMapper.mapToGraph(
        previewStore(ownAncestorPreview: true),
      );
      expect(
        own.nodes['original']!.summary.previewSource!.containingManifest,
        'original',
      );
      expect(
        own.nodes['original']!.summary.previewSource!.isIngredient,
        isFalse,
      );
      final host = MemoryImage(base64Decode(redPng));
      expect(
        resolveProvenanceNodeThumbnail(
          node: original,
          rootId: graph.rootId,
          thumbnailProvider: (_) => host,
        ),
        same(host),
      );
      final absent = const ProvenanceNode(
        id: 'absent',
        summary: ManifestSummary(),
      );
      expect(
        resolveProvenanceNodeThumbnail(
          node: absent,
          rootId: graph.rootId,
          mediaImage: host,
        ),
        isNull,
      );
    },
  );

  test('truthful outcomes reject unsafe or missing byte payloads', () {
    for (final outcome in [
      'missing',
      'malformed',
      'oversize',
      'unsupported',
      'limit',
    ]) {
      final thumbnail = ThumbnailData.fromJson({
        ...preview(),
        'resolution': outcome,
      });
      expect(thumbnail.data, isNull);
      expect(thumbnail.resolution, outcome);
    }
    expect(
      ThumbnailData.fromJson({
        'format': 'image/png',
        'identifier': 'resource',
      }).data,
      isNull,
    );
    expect(
      ThumbnailData.fromJson({
        ...preview(),
        'data': [-1, 999],
      }).data,
      isNull,
    );
    expect(
      ThumbnailData.fromJson({
        ...preview(),
        'data': List.filled(1024 * 1024 + 1, 0),
      }).data,
      isNull,
    );
    final invalid = ManifestStore.fromJson({
      'active_manifest': 'invalid',
      'manifests': {
        'invalid': {
          'label': 'invalid',
          'thumbnail': preview(),
          'validation_status': [
            {'code': 'assertion.dataHash.mismatch'},
          ],
        },
      },
    });
    expect(
      ProvenanceMapper.mapToGraph(
        invalid,
      ).rootNode!.summary.validationResult.isInvalid,
      isTrue,
    );
  });

  test(
    'claim-local empty projection cannot hide a fresh top-level failure',
    () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {
          'root': {
            'label': 'root',
            'validation_status': [],
            'thumbnail': preview(),
          },
        },
        'validation_status': [
          {
            'code': 'assertion.dataHash.mismatch',
            'url': 'self#jumbf=/c2pa/root/c2pa.hash.data',
          },
        ],
      });
      final root = ProvenanceMapper.mapToGraph(store).rootNode!;
      expect(root.summary.validationResult.isInvalid, isTrue);
      expect(root.summary.previewSource!.validationResult!.isInvalid, isTrue);
    },
  );

  test(
    'absent source diagnostics remain unknown instead of inferred clean',
    () {
      final store = ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {
          'root': {'label': 'root', 'thumbnail': preview()},
        },
      });
      expect(
        ProvenanceMapper.mapToGraph(
          store,
        ).rootNode!.summary.previewSource!.validationResult,
        isNull,
      );
    },
  );

  test('unvisited resource references expose the store traversal limit', () {
    final store = ManifestStore.fromJson({
      'active_manifest': 'root',
      'preview_resources_truncated': true,
      'manifests': {
        'root': {
          'label': 'root',
          'thumbnail': {
            'identifier': 'self#jumbf=unvisited',
            'format': 'image/png',
          },
        },
      },
    });
    expect(store.previewResourcesTruncated, isTrue);
    expect(store.manifests['root']!.thumbnail!.resolution, 'limit');
    expect(ProvenanceMapper.mapToGraph(store).rootNode!.thumbnail, isNull);
  });

  test(
    'recorded input binding failure is separate from a current clean signature',
    () {
      final original = previewStore();
      final raw = original.rawManifestJsons;
      raw['original']!['validation_status'] = [];
      final input =
          (raw['middle']!['ingredients'] as List).single
              as Map<String, dynamic>;
      input['validation_status'] = [
        {
          'code': 'assertion.dataHash.mismatch',
          'explanation': 'recorded input did not bind',
        },
      ];
      final store = ManifestStore.fromJson({
        'active_manifest': 'edited',
        'manifests': raw,
      });
      final graph = ProvenanceMapper.mapToGraph(store);
      final node = graph.nodes['original']!;
      expect(store.manifests['original']!.validationStatus, isEmpty);
      expect(node.summary.validationResult.isInvalid, isTrue);
      expect(
        node.summary.inputValidationEvidence.single.containingManifest,
        'middle',
      );
      expect(
        node
            .summary
            .inputValidationEvidence
            .single
            .containingValidation!
            .isUntrusted,
        isTrue,
      );
      expect(node.manifestViewData!.validationResult.isInvalid, isTrue);
      expect(
        node.manifestViewData!.validationFailures.single.code,
        'assertion.dataHash.mismatch',
      );
      expect(node.summary.thumbnail, isA<MemoryImage>());
    },
  );

  test(
    'historical input trust is superseded by current trust, not binding evidence',
    () {
      final original = previewStore();
      final raw = original.rawManifestJsons;
      raw['original']!['validation_status'] = [];
      raw['middle']!['validation_status'] = [];
      final input =
          (raw['middle']!['ingredients'] as List).single
              as Map<String, dynamic>;
      input['validation_results'] = {
        'activeManifest': {
          'failure': [
            {'code': 'signingCredential.untrusted'},
          ],
        },
      };
      final node = ProvenanceMapper.mapToGraph(
        ManifestStore.fromJson({'active_manifest': 'edited', 'manifests': raw}),
      ).nodes['original']!;
      expect(node.summary.inputValidationEvidence, isEmpty);
      expect(node.summary.validationResult.isValid, isTrue);
      expect(node.summary.previewSource!.validationResult!.isValid, isTrue);
    },
  );

  testWidgets('embedded bytes decode and render red pixels', (tester) async {
    final graph = ProvenanceMapper.mapToGraph(previewStore());
    final image = graph.nodes['original']!.summary.thumbnail!;
    const contextKey = ValueKey('preview-context');
    await tester.pumpWidget(const MaterialApp(home: SizedBox(key: contextKey)));
    await tester.runAsync(() async {
      // Start decoding outside fake async before Image requests the provider.
      await precacheImage(
        image,
        tester.element(find.byKey(contextKey)),
      ).timeout(const Duration(seconds: 10));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: C2paViewerTheme(
          data: C2paViewerThemeData.defaults,
          child: C2paThumbnail(image: image),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rendered = tester
        .widgetList<RawImage>(find.byType(RawImage))
        .where((i) => i.image != null);
    expect(rendered, isNotEmpty);
    await tester.runAsync(() async {
      final pixels = await rendered.first.image!
          .toByteData(format: ui.ImageByteFormat.rawRgba)
          .timeout(const Duration(seconds: 10));
      expect(pixels!.buffer.asUint8List().take(4), [255, 0, 0, 255]);
    });
    expect(tester.takeException(), isNull);
  });
}
