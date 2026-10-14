import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/imported_recipe_candidate.dart';

Map<String, dynamic> _fixture() {
  final result = Process.runSync('node', [
    'tool/recipes/runtime-adapter.emit-fixture.mjs',
    '--transport',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return jsonDecode(result.stdout as String) as Map<String, dynamic>;
}

Map<String, dynamic> _payload(Map<String, dynamic> transport) =>
    jsonDecode(transport['payload'] as String) as Map<String, dynamic>;

// Re-pinning distinguishes structural validation from an ordinary stale hash.
Map<String, dynamic> _changed(void Function(Map<String, dynamic>) edit) {
  final wrapper = _fixture();
  final payload = _payload(wrapper);
  edit(payload);
  wrapper['payload'] = jsonEncode(payload);
  wrapper['sha256'] = sha256
      .convert(utf8.encode(wrapper['payload'] as String))
      .toString();
  return wrapper;
}

ImportedRecipeCandidate _read(Map<String, dynamic> wrapper) =>
    ImportedRecipeCandidate.fromTransport(
      wrapper,
      expectedSha256: wrapper['sha256'] as String,
    );

void main() {
  test('Node transport reads split lines and excluded optional provenance', () {
    final wrapper = _fixture();
    final candidate = _read(wrapper);
    expect(candidate.recipe.id, 'import:fixture');
    expect(candidate.recipe.ingredients.map((i) => i.id), ['flour', 'water']);
    expect(candidate.recipe.ingredients.first.amount, 100);
    expect(candidate.recipe.steps.last.minutes, 10);
    expect(candidate.sourceId, 'fixture-source');
    expect(candidate.sourceRecipeId, 'wikibooks:1');
    final lines = candidate.provenance['lines'] as List;
    expect(lines.first['runtimeLineIndices'], [0, 1]);
    expect(lines.last['runtimeLineIndices'], isEmpty);
    expect(candidate.remainingGates, hasLength(4));
  });

  test(
    'trusted reference, reported digest and exact payload bytes must agree',
    () {
      final original = _fixture();
      expect(
        () => ImportedRecipeCandidate.fromTransport(
          original,
          expectedSha256: 'b' * 64,
        ),
        throwsFormatException,
      );
      final corrupt = Map<String, dynamic>.from(original)
        ..['payload'] = '${original['payload']} ';
      expect(() => _read(corrupt), throwsFormatException);
      final report = Map<String, dynamic>.from(original)..['sha256'] = 'c' * 64;
      expect(() => _read(report), throwsFormatException);
    },
  );

  test('catalog conversion cannot silently trim reviewed identity or text', () {
    for (final edit in <void Function(Map<String, dynamic>)>[
      (p) {
        p['recipe']['ingredients'][0]['id'] = ' flour ';
        p['provenance']['lines'][0]['components'][0]['runtimeIngredientId'] =
            ' flour ';
      },
      (p) => p['recipe']['name'] = ' Recipe ',
      (p) => p['recipe']['ingredients'][0]['name'] = ' Flour ',
      (p) => p['recipe']['steps'][0]['text'] = ' Mix ',
    ]) {
      expect(() => _read(_changed(edit)), throwsFormatException);
    }
  });

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'missing provenance': (p) => p.remove('provenance'),
    'approval field': (p) => p['approved'] = true,
    'runtime ready': (p) => p['runtimeReady'] = true,
    'approved nutrition': (p) => p['nutrition']['status'] = 'approved',
    'food binding': (p) =>
        p['nutrition']['runtimeBindings'].add({'foodId': 'usda:1'}),
    'omitted remaining gate': (p) => p['remainingGates'].removeLast(),
    'source SHA': (p) => p['provenance']['source']['sourceSha256'] = 'bad',
    'source URL': (p) =>
        p['provenance']['source']['sourceUrl'] = 'file:///recipe',
    'licence omitted': (p) => p['provenance']['source']['license'] = {},
    'invalid review date': (p) =>
        p['provenance']['adapterReview']['reviewedAt'] = '2026-02-30T10:00:00Z',
    'wrong source target': (p) =>
        p['provenance']['lines'][0]['target']['sourceId'] = 'another-source',
    'stale source fingerprint': (p) =>
        p['provenance']['lines'][0]['target']['derivedRecipeSha256'] = 'd' * 64,
    'duplicate source line': (p) =>
        p['provenance']['lines'][1]['target']['lineId'] = 'one',
    'reordered runtime map': (p) =>
        p['provenance']['lines'][0]['runtimeLineIndices'] = [1, 0],
    'unmapped runtime line': (p) {
      p['provenance']['lines'][0]['runtimeLineIndices'].removeLast();
      p['provenance']['lines'][0]['components'].removeLast();
    },
    'mismatched component identity': (p) =>
        p['provenance']['lines'][0]['components'][0]['runtimeIngredientId'] =
            'oil',
    'mismatched component form': (p) =>
        p['provenance']['lines'][0]['components'][0]['form'] = 'cooked',
    'bad raw food SHA': (p) =>
        p['provenance']['lines'][0]['components'][0]['rawFoodReference']['foodSnapshotSha256'] =
            'bad',
    'excluded optional mapped': (p) =>
        p['provenance']['lines'][1]['runtimeLineIndices'] = [1],
    'implicit scaling': (p) => p['recipe']['ingredients'][0].remove('scale'),
    'optional disposition mismatch': (p) =>
        p['recipe']['ingredients'][0]['optional'] = true,
    'fractional step sequence': (p) => p['recipe']['steps'][0]['n'] = 1.5,
    'unmeasured imported ingredient': (p) =>
        p['recipe']['ingredients'][0]['amount'] = null,
    'unknown preparation time': (p) => p['recipe']['prepTime'] = null,
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} even with a freshly pinned transport', () {
      expect(() => _read(_changed(entry.value)), throwsFormatException);
    });
  }

  test(
    'ownership and persistence retain original JSON and unknown licence facts',
    () {
      final wrapper = _changed((p) {
        p['recipe']['ingredients'][0]['amount'] = 0.0000001;
        p['provenance']['source']['license']['scientificUnknown'] = null;
        p['provenance']['source']['license']['attribution'] = [
          'Synthetic only',
        ];
      });
      final candidate = _read(wrapper);
      final originalPayload = wrapper['payload'];
      wrapper['payload'] = '{}';
      candidate.provenance['source']['license']['attribution'].clear();
      final saved = candidate.toJson();
      expect(saved['transport']['payload'], originalPayload);
      expect(
        candidate.provenance['source']['license']['scientificUnknown'],
        isNull,
      );
      expect(candidate.provenance['source']['license']['attribution'], [
        'Synthetic only',
      ]);
      expect(() => candidate.remainingGates.clear(), throwsUnsupportedError);
      final restored = ImportedRecipeCandidate.fromJson(saved);
      saved['transport']['payload'] = '{}';
      expect(restored.toJson()['transport']['payload'], originalPayload);
      expect(restored.recipe.ingredients.first.amount, 0.0000001);
      expect(restored.provenance, candidate.provenance);
      expect(
        () => ImportedRecipeCandidate.fromJson({
          ...restored.toJson(),
          'approved': true,
        }),
        throwsFormatException,
      );
      final damaged = restored.toJson();
      damaged['transport']['payload'] = '{}';
      expect(
        () => ImportedRecipeCandidate.fromJson(damaged),
        throwsFormatException,
      );
    },
  );
}
