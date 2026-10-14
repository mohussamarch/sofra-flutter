import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';

const manifestPath = 'data/recipes/curated-local/flutter-manifest.json';
const localPath = 'data/recipes/curated-local/test/normalized.json';
const sourcePath = 'data/recipes/curated-local/test/source.json';
const creatorPath = 'data/recipes/arabic-youtube/test.json';
String digest(String value) => sha256.convert(utf8.encode(value)).toString();
Map<String, dynamic> owned(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class LibraryFixture {
  final assets = <String, String>{};
  final source = <String, dynamic>{
    'schemaVersion': 1,
    'sourceRecord': {
      'recordId': 'record-1',
      'sourceId': 'source-1',
      'sourceRevision': 'r1',
      'sourceRevisionTimestamp': null,
      'sourceUrl': 'https://example.org/recipe',
      'sourceSha256': 'source-body-hash',
      'license': {'id': 'CC BY-SA', 'pageExceptionStatus': 'not-reviewed'},
      'sourceRevisionUser': 'original contributor',
    },
  };
  late Map<String, dynamic> local;
  late Map<String, dynamic> creator;
  late Map<String, dynamic> manifest;
  LibraryFixture() {
    assets[sourcePath] = jsonEncode(source);
    local = {
      'schemaVersion': 1,
      'reviewer': 'test curation',
      'recipes': [
        {
          'id': 'local:one',
          'nameAr': 'وصفة محلية',
          'name': 'Local recipe',
          'familyId': 'family:one',
          'methodId': 'method:one',
          'runtimeReady': false,
          'nutrition': null,
          'yield': {'amount': null, 'min': 2, 'max': 4, 'sourceText': '2–4'},
          'time': {'prepMinutes': null, 'declaredTotalMinutes': null},
          'ingredients': [
            {
              'nameAr': 'دقيق',
              'amount': 2,
              'unit': 'cup',
              'sourceText': 'two cups',
              'optional': false,
              'included': true,
            },
          ],
          'supplementalIngredients': [
            {
              'nameAr': 'دهن',
              'amount': null,
              'unit': null,
              'sourceText': 'greased pan',
            },
          ],
          'steps': [
            {'textAr': 'اخلط المقادير', 'duration': null},
          ],
          'cuisines': [
            {
              'id': 'test',
              'nameAr': 'مطبخ الاختبار',
              'evidenceText': 'source label',
              'sourceRecordId': 'record-1',
              'reviewStatus': 'pending',
            },
          ],
          'gates': {
            'inventoryIdentityApproved': false,
            'perPageLicenseApproved': false,
          },
          'provenance': {
            ...owned(source['sourceRecord'] as Map<String, dynamic>),
            'sourceSnapshotFile': sourcePath,
            'sourceSnapshotSha256': digest(assets[sourcePath]!),
          },
        },
      ],
    };
    creator = {
      'schemaVersion': 1,
      'sourcePolicy': {'sourceApproval': null, 'reuseRights': null},
      'creators': [
        {'creatorId': 'chef', 'name': 'الطاهي'},
      ],
      'recipes': [
        {
          'recipeId': 'creator:one',
          'title': 'وصفة طاه',
          'sourceKind': 'creator-website',
          'creatorId': 'chef',
          'sourceUrl': 'https://example.org/chef',
          'sourceApproval': null,
          'reuseRights': null,
          'yield': null,
          'cookTime': null,
          'ingredients': [
            {
              'labelAr': 'ملح',
              'label': 'salt',
              'sourceQuantityText': 'as needed',
              'amount': null,
              'unit': null,
            },
          ],
          'steps': [
            {'textAr': 'أضف الملح', 'text': 'Add salt'},
          ],
          'cuisine': {
            'value': null,
            'evidence': null,
            'reviewStatus': 'pending',
          },
        },
      ],
      'partialYoutubeRecipes': [
        {
          'recipeId': 'partial:one',
          'title': 'فيديو ناقص',
          'ingredients': [],
          'steps': [],
        },
      ],
    };
    rebuild();
  }
  void rebuild() {
    assets[localPath] = jsonEncode(local);
    assets[creatorPath] = jsonEncode(creator);
    manifest = {
      'schemaVersion': 1,
      'runtimeReady': false,
      'packs': [
        {
          'kind': 'curated-local',
          'file': localPath,
          'sha256': digest(assets[localPath]!),
          'sourceSnapshots': [
            {'file': sourcePath, 'sha256': digest(assets[sourcePath]!)},
          ],
        },
        {
          'kind': 'creator-website',
          'file': creatorPath,
          'sha256': digest(assets[creatorPath]!),
          'sourceSnapshots': [],
        },
      ],
    };
    pinManifest();
  }

  void pinManifest() => assets[manifestPath] = jsonEncode(manifest);
  RecipeLibraryRepository repository() => RecipeLibraryRepository(
    expectedManifestSha256: digest(assets[manifestPath]!),
    read: (path) async {
      if (!assets.containsKey(path)) {
        throw StateError('Missing fixture asset $path');
      }
      return assets[path]!;
    },
  );
}

void main() {
  test('reads both pinned packs as an unknown-aware cookbook, excluding partial videos', () async {
    final f = LibraryFixture();
    final entries = await f.repository().all();
    expect(entries.map((e) => e.id), ['local:one', 'creator:one']);
    final local = entries.first, creator = entries.last;
    expect(local.titleAr, 'وصفة محلية');
    expect(local.ingredients.first.amount, 2);
    expect(local.ingredients.first.unit, 'cup');
    expect(local.ingredients.first.sourceQuantityText, 'two cups');
    expect(local.ingredients.last.amount, isNull);
    expect(local.ingredients.last.supplemental, isTrue);
    expect(creator.ingredients.single.amount, isNull);
    expect(creator.ingredients.single.unit, isNull);
    expect(creator.stepsArabic, ['أضف الملح']);
    for (final entry in entries) {
      expect(entry.runtimeReady, isFalse);
      expect(entry.nutrition, isNull);
    }
    expect(local.sourceUrls, ['https://example.org/recipe']);
    expect(local.toJson()['sourceRecord']['yield'], {
      'amount': null,
      'min': 2,
      'max': 4,
      'sourceText': '2–4',
    });
    expect(
      local.sourceSnapshot!['sourceRecord']['sourceRevisionUser'],
      'original contributor',
    );
    expect(creator.packMetadata['sourcePolicy']['reuseRights'], isNull);
  });
  test(
    'search, cuisine and family candidates use only explicit labels',
    () async {
      final repo = LibraryFixture().repository();
      expect((await repo.search('دقيق')).single.id, 'local:one');
      expect((await repo.filterByCuisine('test')).single.id, 'local:one');
      expect(await repo.filterByCuisine('Egyptian'), isEmpty);
      expect(
        (await repo.familyCandidates('family:one')).single.methodId,
        'method:one',
      );
    },
  );
  test(
    'caller snapshots and collection mutations cannot alter cached entries',
    () async {
      final repo = LibraryFixture().repository(),
          entry = (await LibraryFixture().repository().all()).first;
      final raw = entry.sourceRecord;
      (raw['gates'] as Map)['inventoryIdentityApproved'] = true;
      final json = entry.toJson();
      (json['sourceSnapshot']['sourceRecord']['license'] as Map).clear();
      (entry.packMetadata['reviewer'] = 'changed');
      expect(entry.sourceRecord['gates']['inventoryIdentityApproved'], isFalse);
      expect(
        entry.sourceSnapshot!['sourceRecord']['license']['id'],
        'CC BY-SA',
      );
      expect(() => entry.ingredients.clear(), throwsUnsupportedError);
      final list = await repo.all();
      expect(() => list.clear(), throwsUnsupportedError);
    },
  );
  test(
    'rejects changed manifest, pack and source UTF8 bytes before parsing',
    () async {
      final f = LibraryFixture(), repo = f.repository();
      f.assets[manifestPath] = '${f.assets[manifestPath]} ';
      await expectLater(repo.all(), throwsFormatException);
      final pack = LibraryFixture();
      pack.assets[localPath] = 'invalid-json';
      await expectLater(pack.repository().all(), throwsFormatException);
      final source = LibraryFixture();
      source.assets[sourcePath] = '${source.assets[sourcePath]}\r\n';
      await expectLater(source.repository().all(), throwsFormatException);
    },
  );
  test('rejects traversal, absolute, query and unapproved paths', () async {
    for (final path in [
      '../secret.json',
      '/secret.json',
      'C:/secret.json',
      'data/recipes/curated-local/../secret.json',
      'data/recipes/curated-local/x.json?raw',
      'data/recipes/curated-local/x.json#part',
      'data/recipes/curated-local/x\\y.json',
      'data/recipes/other/x.json',
    ]) {
      final f = LibraryFixture();
      (f.manifest['packs'] as List).first['file'] = path;
      f.pinManifest();
      await expectLater(
        f.repository().all(),
        throwsFormatException,
        reason: path,
      );
    }
  });
  test('requires exact declared source provenance and rejects unused/missing source members', () async {
    final missing = LibraryFixture();
    (missing.manifest['packs'] as List).first['sourceSnapshots'] = [];
    missing.pinManifest();
    await expectLater(missing.repository().all(), throwsFormatException);
    final changed = LibraryFixture();
    (changed.local['recipes'] as List).first['provenance']['sourceRevision'] =
        'another';
    changed.rebuild();
    await expectLater(changed.repository().all(), throwsFormatException);
    final license = LibraryFixture();
    (license.local['recipes'] as List).first['provenance']['license']['id'] =
        'different';
    license.rebuild();
    await expectLater(license.repository().all(), throwsFormatException);
    final extra = LibraryFixture();
    (extra.manifest['packs'] as List).first['sourceSnapshots'].add({
      'file': 'data/recipes/curated-local/test/extra.json',
      'sha256': digest('{}'),
    });
    extra.assets['data/recipes/curated-local/test/extra.json'] = '{}';
    extra.pinManifest();
    await expectLater(extra.repository().all(), throwsFormatException);
  });
  test('duplicate IDs and runtime promotion are rejected', () async {
    final duplicate = LibraryFixture();
    (duplicate.creator['recipes'] as List).first['recipeId'] = 'local:one';
    duplicate.rebuild();
    await expectLater(duplicate.repository().all(), throwsFormatException);
    final promoted = LibraryFixture();
    (promoted.local['recipes'] as List).first['runtimeReady'] = true;
    promoted.rebuild();
    await expectLater(promoted.repository().all(), throwsFormatException);
    final manifest = LibraryFixture();
    manifest.manifest['runtimeReady'] = true;
    manifest.pinManifest();
    await expectLater(manifest.repository().all(), throwsFormatException);
  });
  test('creator Arabic fallback preserves original source wording and unknown quantities', () async {
    final f = LibraryFixture();
    final recipe = (f.creator['recipes'] as List).first;
    (recipe['ingredients'] as List).first.remove('labelAr');
    (recipe['steps'] as List).first.remove('textAr');
    f.rebuild();
    final e = (await f.repository().all()).last;
    expect(e.ingredients.single.labelAr, 'salt');
    expect(e.stepsArabic, ['Add salt']);
    expect(e.ingredients.single.amount, isNull);
    expect(e.cuisineLabels, isEmpty);
  });
}
