import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _claim(
  final String label, [
  final List<Map<String, dynamic>> ingredients = const [],
]) => {
  'label': label,
  'title': label,
  'validation_status': [],
  'ingredients': ingredients,
};

Map<String, dynamic> _edge(final String target, final String description) => {
  'label': 'same-label',
  'title': 'same-title',
  'active_manifest': target,
  'relationship': 'parentOf',
  'description': description,
};

ManifestStore _sharedStore({final bool cycle = false}) =>
    ManifestStore.fromJson({
      'active_manifest': 'root',
      'manifests': {
        'root': _claim('root', [_edge('left', ''), _edge('right', '')]),
        'left': _claim('left', [_edge('shared', 'left import')]),
        'right': _claim('right', [_edge('shared', 'right import')]),
        'shared': _claim('shared', [
          _edge('missing', 'Earlier source <not markup>\nFull final line.'),
          if (cycle) _edge('left', 'cycle edge'),
        ]),
        'unrelated': _claim('unrelated', [_edge('shared', 'unrelated import')]),
      },
    });

void main() {
  test(
    'shared ancestry preserves exact edges without unrelated contamination',
    () {
      final store = _sharedStore();
      final summaries = ManifestViewDataMapper.buildSummaries(store);
      expect(
        summaries['root']!.ingredientDescriptions.map(
          (final n) => n.description,
        ),
        unorderedEquals([
          'left import',
          'right import',
          'Earlier source <not markup>\nFull final line.',
        ]),
      );
      final shared = summaries['shared']!.ingredientDescriptions;
      expect(
        shared.map((final n) => n.containingManifest),
        unorderedEquals(['shared', 'left', 'right']),
      );
      final left = ManifestViewDataMapper.map(
        store.manifests['left']!,
        summaries: summaries,
        containingLabel: 'left',
      );
      expect(
        left.ingredients.single.summary.ingredientDescriptions.map(
          (final n) => n.description,
        ),
        unorderedEquals([
          'left import',
          'Earlier source <not markup>\nFull final line.',
        ]),
      );
      expect(left.validationResult.isValid, isTrue);
      expect(left.ingredients.single.credentialResult.isValid, isTrue);
    },
  );

  test('cycles visit each recorded edge once', () {
    final notes = ManifestViewDataMapper.buildSummaries(
      _sharedStore(cycle: true),
    )['root']!.ingredientDescriptions;
    expect(notes.length, 4);
    expect(
      notes
          .map((final n) => (n.containingManifest, n.ingredientIndex))
          .toSet()
          .length,
      notes.length,
    );
  });

  test('parallel equal-label edges and unresolved leaves remain distinct', () {
    final store = ManifestStore.fromJson({
      'active_manifest': 'root',
      'manifests': {
        'root': _claim('root', [
          _edge('missing', 'first'),
          _edge('missing', 'second'),
        ]),
      },
    });
    final graph = ProvenanceMapper.mapToGraph(store);
    expect(graph.nodes.length, 3);
    final leaves = graph.nodes.values.where((final n) => n.id != graph.rootId);
    expect(
      leaves.map(
        (final n) => n.summary.ingredientDescriptions.single.ingredientIndex,
      ),
      unorderedEquals([0, 1]),
    );
    for (final leaf in leaves) {
      expect(leaf.summary.validationResult.hasCredential, isFalse);
      expect(
        leaf.manifestViewData!.ingredientDescriptions.single.containingManifest,
        'root',
      );
    }
  });

  test(
    'default helper infers actual object identity rather than equal values',
    () {
      final first = Ingredient.fromJson(_edge('missing', 'same prose'));
      final second = Ingredient.fromJson(_edge('missing', 'same prose'));
      expect(first, equals(second));
      expect(identical(first, second), isFalse);
      final containing = Manifest(
        label: 'consumer',
        ingredients: [first, second],
      );
      final inferred = ManifestViewDataMapper.ingredientSummary(
        second,
        containing,
      );
      expect(inferred.ingredientDescriptions.single.ingredientIndex, 1);
      expect(
        inferred.ingredientDescriptions.single.containingManifest,
        'consumer',
      );
      final explicit = ManifestViewDataMapper.ingredientSummary(
        second,
        containing,
        ingredientIndex: 1,
      );
      expect(explicit.ingredientDescriptions.single.ingredientIndex, 1);
      final detached = Ingredient.fromJson(_edge('missing', 'same prose'));
      expect(
        ManifestViewDataMapper.ingredientSummary(
          detached,
          containing,
        ).ingredientDescriptions,
        isEmpty,
      );
      expect(
        ManifestViewDataMapper.ingredientSummary(
          detached,
          const Manifest(label: 'other'),
        ).ingredientDescriptions,
        isEmpty,
      );
      final repeated = Manifest(label: 'consumer', ingredients: [first, first]);
      expect(
        ManifestViewDataMapper.ingredientSummary(
          first,
          repeated,
        ).ingredientDescriptions,
        isEmpty,
      );
      expect(
        ManifestViewDataMapper.ingredientSummary(
          first,
          repeated,
          ingredientIndex: 1,
        ).ingredientDescriptions.single.ingredientIndex,
        1,
      );
    },
  );

  test('absent, empty and malformed optional prose remain absent', () {
    for (final value in [null, '', 42, false, <String, dynamic>{}]) {
      final manifest = Manifest.fromJson(
        _claim('root', [
          {..._edge('missing', ''), 'description': value},
        ]),
      );
      expect(
        ManifestViewDataMapper.map(
          manifest,
        ).ingredients.single.summary.ingredientDescriptions,
        isEmpty,
      );
    }
    const oldSummary = ManifestSummary();
    const oldView = ManifestViewData();
    expect(oldSummary.ingredientDescriptions, isEmpty);
    expect(oldView.ingredientDescriptions, isEmpty);
  });

  test(
    'recorded prose does not change incomplete, untrusted or invalid states',
    () {
      for (final code in [
        null,
        'signingCredential.untrusted',
        'assertion.dataHash.mismatch',
      ]) {
        final raw = _claim('root', [_edge('missing', 'not a check result')])
          ..remove('validation_status');
        if (code != null) {
          raw['validation_status'] = [
            {'code': code},
          ];
        }
        final view = ManifestViewDataMapper.map(Manifest.fromJson(raw));
        expect(view.validationResult.status.name, switch (code) {
          'signingCredential.untrusted' => 'untrusted',
          'assertion.dataHash.mismatch' => 'invalid',
          _ => 'notVerified',
        });
        expect(
          view.ingredientDescriptions.single.description,
          'not a check result',
        );
      }
    },
  );
  test('invalid active root retains prose without walking its ingredients', () {
    final raw = _claim('root', [_edge('original', 'Recorded invalid payload')])
      ..['validation_status'] = [
        {'code': 'claimSignature.mismatch'},
      ];
    final graph = ProvenanceMapper.mapToGraph(
      ManifestStore.fromJson({
        'active_manifest': 'root',
        'manifests': {'root': raw, 'original': _claim('original')},
      }),
    );
    expect(graph.nodes.length, 1);
    expect(graph.edges, isEmpty);
    final root = graph.rootNode!;
    expect(root.summary.validationResult.isInvalid, isTrue);
    expect(root.manifestViewData!.validationResult.isInvalid, isTrue);
    expect(
      root.summary.ingredientDescriptions.single.description,
      'Recorded invalid payload',
    );
    expect(
      root.manifestViewData!.ingredientDescriptions.single.description,
      'Recorded invalid payload',
    );
    expect(
      root.summary.ingredientDescriptions.single.sourceLabel,
      'root → same-label [0]',
    );
  });
}
