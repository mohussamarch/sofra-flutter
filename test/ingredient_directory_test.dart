import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/demo_data.dart';
import 'package:tabkha_demo/domain/ingredient_directory.dart';

Future<String> _read(String path) => File(path).readAsString();

/// Active catalog lines as (rawId, name) pairs.
Future<List<(String, String)>> _activeLines() async {
  final index = jsonDecode(await _read('recipes/data/index.json')) as Map;
  final active = [
    for (final row in index['recipes'] as List)
      if ((row as Map)['catalogStatus'] == 'active') row,
  ];
  final ids = {for (final row in active) row['id']};
  final files = {for (final row in active) row['file'] as String};
  final lines = <(String, String)>[];
  for (final file in files) {
    final data = jsonDecode(await _read('recipes/data/$file')) as Map;
    for (final recipe in data['recipes'] as List) {
      if (!ids.contains((recipe as Map)['id'])) continue;
      for (final line in recipe['ingredients'] as List) {
        lines.add(((line as Map)['id'] as String, line['name'] as String));
      }
    }
  }
  return lines;
}

void main() {
  late IngredientDirectory directory;

  setUpAll(() async {
    directory = await IngredientDirectory.load(_read);
  });

  test('vocabulary ids are unique and in range', () {
    final ids = directory.entries.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.length, inInclusiveRange(150, 400));
  });

  test('no name or alias is shared by two entries', () {
    final owners = <String, String>{};
    for (final entry in directory.entries) {
      for (final term in {entry.name, ...entry.aliases}) {
        final key = IngredientDirectory.normalizeArabic(term);
        final owner = owners.putIfAbsent(key, () => entry.id);
        expect(owner, entry.id, reason: '"$term" is shared');
      }
    }
  });

  test('generated directory matches the vocabulary sha', () async {
    final vocabulary = (await _read(IngredientDirectory.vocabularyPath))
        .replaceAll('\r\n', '\n');
    final generated =
        jsonDecode(await _read(IngredientDirectory.directoryPath)) as Map;
    expect(
      generated['vocabularySha256'],
      sha256.convert(utf8.encode(vocabulary)).toString(),
    );
    final stats = generated['stats'] as Map;
    expect(stats['mappedLines'] / stats['lines'], greaterThanOrEqualTo(0.55));
  });

  test('a stale directory is rejected', () async {
    Future<String> read(String path) async =>
        path == IngredientDirectory.vocabularyPath
        ? '${await _read(path)} '
        : _read(path);
    await expectLater(
      IngredientDirectory.load(read),
      throwsA(isA<FormatException>()),
    );
  });

  test('every demo ingredient id is in the vocabulary', () {
    for (final id in demoIngredients.keys) {
      expect(directory.entry(id), isNotNull, reason: id);
      expect(directory.stockId(id), id);
    }
  });

  test('known catalog lines map to their canonical ingredient', () async {
    final lines = await _activeLines();
    const expected = {
      'ماء': 'water',
      'ملح': 'salt',
      'بصل مفروم': 'onion',
      'زيت زيتون': 'olive-oil',
    };
    for (final MapEntry(key: name, value: canonical) in expected.entries) {
      final raw = [
        for (final (id, lineName) in lines)
          if (lineName == name && directory.entry(id) == null) id,
      ];
      expect(raw, isNotEmpty, reason: 'no unique-id catalog line "$name"');
      for (final id in raw) {
        expect(directory.stockId(id), canonical, reason: '$id ($name)');
      }
    }
    expect(directory.entry('olive-oil'), isNotNull);
    expect(directory.entry('oil'), isNotNull);
    expect(directory.stockId('oil'), 'oil');
    expect(directory.stockId('olive-oil'), 'olive-oil');
  });

  test('lines offering two products accept either in stock', () {
    final text = File(IngredientDirectory.directoryPath).readAsStringSync();
    final alternatives =
        (jsonDecode(text) as Map)['alternatives'] as Map<String, dynamic>;
    expect(alternatives, isNotEmpty);
    final MapEntry(:key, :value) = alternatives.entries.first;
    expect(directory.stockOptions(key), value);
    expect(directory.stockId(key), (value as List).first);
    expect(directory.stockOptions('onion'), ['onion']);
  });

  test('unknown raw ids fall back to themselves', () {
    expect(directory.stockId('no-such-raw-id'), 'no-such-raw-id');
  });

  test('search normalizes alef and ta marbuta and ranks names first', () {
    expect(directory.search('ارز').map((e) => e.id), contains('rice'));
    expect(directory.search('أرز').map((e) => e.id), contains('rice'));
    expect(directory.search('بصله').map((e) => e.id), contains('onion'));
    expect(directory.search('طحينه').map((e) => e.id), contains('tahini'));
    final garlic = directory.search('ثوم');
    expect(garlic.first.id, 'garlic');
    expect(directory.search('توم').map((e) => e.id), contains('garlic'));
    expect(directory.search('  '), isEmpty);
  });
}
