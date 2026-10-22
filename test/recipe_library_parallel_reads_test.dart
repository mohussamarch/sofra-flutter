import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';

const manifestPath = 'data/recipes/curated-local/flutter-manifest.json';
String digest(String text) => sha256.convert(utf8.encode(text)).toString();

class ParallelLibraryFixture {
  final assets = <String, String>{};
  late final String manifest;

  ParallelLibraryFixture({int recipeCount = 12}) {
    final packs = <Map<String, Object?>>[];
    final snapshotFiles = <Map<String, String>>[];
    final recipes = <Map<String, Object?>>[];
    for (var index = 0; index < recipeCount; index++) {
      final sourcePath = 'data/recipes/curated-local/test/source_$index.json';
      final source = jsonEncode({
        'schemaVersion': 1,
        'sourceRecord': {
          'recordId': 'record-$index',
          'sourceId': 'source-$index',
          'sourceRevision': 'r1',
          'sourceRevisionTimestamp': null,
          'sourceUrl': 'https://example.org/$index',
          'sourceSha256': 'source-body-$index',
          'details': {
            'numericValues': [1, 1.25],
            'nested': [
              {'enabled': true, 'note': null},
            ],
          },
          'license': {'id': 'CC BY-SA', 'pageExceptionStatus': 'pending'},
        },
      });
      assets[sourcePath] = source;
      snapshotFiles.add({'file': sourcePath, 'sha256': digest(source)});
      recipes.add({
        'id': 'local:$index',
        'nameAr': 'وصفة $index',
        'name': 'source-name-$index',
        'sourceEvidence': {
          'numericValues': [7, 2.5],
          'nested': [
            {'enabled': false, 'note': 'original'},
          ],
        },
        'runtimeReady': false,
        'nutrition': null,
        'ingredients': [
          {'nameAr': 'ملح', 'amount': null, 'unit': null},
        ],
        'steps': [
          {'textAr': 'أضف الملح'},
        ],
        'cuisines': [],
        'provenance': {
          'recordId': 'record-$index',
          'sourceId': 'source-$index',
          'sourceRevision': 'r1',
          'sourceRevisionTimestamp': null,
          'sourceUrl': 'https://example.org/$index',
          'sourceSha256': 'source-body-$index',
          'license': {'id': 'CC BY-SA', 'pageExceptionStatus': 'pending'},
          'sourceSnapshotFile': sourcePath,
          'sourceSnapshotSha256': digest(source),
        },
      });
    }
    const packPath = 'data/recipes/curated-local/test/normalized.json';
    final pack = jsonEncode({
      'schemaVersion': 1,
      'context': {
        'numericValues': [3, 4.75],
      },
      'recipes': recipes,
    });
    assets[packPath] = pack;
    packs.add({
      'kind': 'curated-local',
      'file': packPath,
      'sha256': digest(pack),
      'sourceSnapshots': snapshotFiles,
    });
    manifest = jsonEncode({
      'schemaVersion': 1,
      'runtimeReady': false,
      'packs': packs,
    });
    assets[manifestPath] = manifest;
  }

  RecipeLibraryRepository repository({
    Future<String> Function(String path)? read,
  }) => RecipeLibraryRepository(
    expectedManifestSha256: digest(assets[manifestPath]!),
    read: read ?? (path) async => assets[path]!,
  );
}

void main() {
  test(
    'public copies recursively own JSON maps, lists and numeric values',
    () async {
      final entry = (await ParallelLibraryFixture().repository().all()).first;

      final sourceRecord = entry.sourceRecord;
      ((sourceRecord['sourceEvidence'] as Map)['numericValues'] as List)[0] =
          70;
      ((sourceRecord['sourceEvidence'] as Map)['nested'] as List).clear();
      final sourceSnapshot = entry.sourceSnapshot!;
      ((sourceSnapshot['sourceRecord']['details'] as Map)['numericValues']
              as List)[1] =
          9.5;
      final packMetadata = entry.packMetadata;
      ((packMetadata['context'] as Map)['numericValues'] as List)[0] = 30;
      final serialized = entry.toJson();
      ((serialized['sourceRecord']['sourceEvidence'] as Map)['numericValues']
              as List)[1] =
          25.0;

      final freshSource = entry.sourceRecord['sourceEvidence'] as Map;
      expect(freshSource['numericValues'], [7, 2.5]);
      expect(freshSource['numericValues'][0], isA<int>());
      expect(freshSource['numericValues'][1], isA<double>());
      expect(freshSource['nested'], [
        {'enabled': false, 'note': 'original'},
      ]);
      final freshSnapshot =
          entry.sourceSnapshot!['sourceRecord']['details'] as Map;
      expect(freshSnapshot['numericValues'], [1, 1.25]);
      expect(freshSnapshot['numericValues'][0], isA<int>());
      expect(freshSnapshot['numericValues'][1], isA<double>());
      expect(entry.packMetadata['context']['numericValues'], [3, 4.75]);
      expect(
        (entry.toJson()['sourceRecord']['sourceEvidence']
            as Map)['numericValues'],
        [7, 2.5],
      );
    },
  );

  test(
    'reads snapshots concurrently with a bound and preserves entry order',
    () async {
      final fixture = ParallelLibraryFixture(recipeCount: 19);
      var active = 0, peak = 0;
      final repo = fixture.repository(
        read: (path) async {
          if (path.contains('source_')) {
            active++;
            if (active > peak) peak = active;
            await Future<void>.delayed(const Duration(milliseconds: 2));
            active--;
          }
          return fixture.assets[path]!;
        },
      );

      final entries = await repo.all();
      expect(peak, greaterThan(1));
      expect(peak, lessThanOrEqualTo(8));
      expect(
        entries.map((entry) => entry.id),
        List.generate(19, (index) => 'local:$index'),
      );
      expect((await repo.search('source-name-7')).single.id, 'local:7');
      final externalCopy = entries[7].sourceRecord;
      externalCopy['name'] = 'changed outside repository';
      expect((await repo.search('source-name-7')).single.id, 'local:7');
    },
  );

  test(
    'rejects invalid snapshot manifest metadata before reading snapshots',
    () async {
      final fixture = ParallelLibraryFixture();
      final manifest = jsonDecode(fixture.manifest) as Map<String, dynamic>;
      final snapshots =
          (manifest['packs'] as List).first['sourceSnapshots'] as List;
      snapshots[1]['sha256'] = 'not-a-sha256';
      final text = jsonEncode(manifest);
      fixture.assets[manifestPath] = text;
      var snapshotReads = 0;
      final repo = RecipeLibraryRepository(
        expectedManifestSha256: digest(text),
        read: (path) async {
          if (path.contains('source_')) snapshotReads++;
          return fixture.assets[path]!;
        },
      );

      await expectLater(repo.all(), throwsFormatException);
      expect(snapshotReads, 0);
    },
  );

  test(
    'awaits failed read batches, clears cache and succeeds on clean retry',
    () async {
      final fixture = ParallelLibraryFixture(recipeCount: 16);
      var fail = true, active = 0, started = 0, finished = 0;
      final repo = fixture.repository(
        read: (path) async {
          if (path.contains('source_')) {
            active++;
            started++;
            if (fail && path.endsWith('source_0.json')) {
              await Future<void>.delayed(const Duration(milliseconds: 3));
              active--;
              finished++;
              throw StateError('synthetic snapshot failure');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
            active--;
            finished++;
          }
          return fixture.assets[path]!;
        },
      );

      await expectLater(repo.all(), throwsStateError);
      expect(active, 0);
      expect(finished, started);
      fail = false;
      expect(
        (await repo.all()).map((entry) => entry.id),
        List.generate(16, (index) => 'local:$index'),
      );
    },
  );
}
