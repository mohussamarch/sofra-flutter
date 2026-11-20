import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/online_recipe_library.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

import 'support/library_fixture.dart';

void main() {
  final seed = readSeed();
  Future<String> readSeedFile(String path) async =>
      seed[path] ?? (throw FileSystemException('not bundled', path));
  late FakeLibrarySite site;
  late MemoryLibraryStore store;
  var now = DateTime.utc(2026, 11, 20, 9);

  OnlineRecipeLibrary library() => OnlineRecipeLibrary(
    store: store,
    baseUrl: Uri.parse('https://library.test/'),
    fetch: site.fetch,
    clock: () => now,
  );
  RecipeRepository repository([OnlineRecipeLibrary? lib]) =>
      RecipeRepository(read: readSeedFile, library: lib ?? library());

  setUp(() {
    site = FakeLibrarySite();
    store = MemoryLibraryStore();
    now = DateTime.utc(2026, 11, 20, 9);
  });

  test('first launch offline: the bundled seed is the catalog', () async {
    site.offline = true;
    final repo = repository();
    expect(await repo.library!.update(), isFalse);
    expect(repo.library!.lastCheckFailed, isTrue);
    expect((await repo.index).length, 495);
    expect((await repo.get('eg-koshari')).name, isNotEmpty);
    expect((await repo.library!.usage()).onDevice, 0);
    expect(await repo.catalogDate, DateTime.parse('2026-10-22'));
  });

  test('a new library arrives without an app update; opened recipes are '
      'kept, the rest open from the seed offline', () async {
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
    );
    var repo = repository();
    expect(await repo.index, hasLength(495));
    expect(await repo.library!.update(), isTrue);
    expect((await repo.index).map((r) => r['id']), contains('eg-new'));
    expect(await repo.catalogDate, DateTime.utc(2026, 11, 20, 8));
    expect(site.bodyRequests, 0, reason: 'the catalog alone downloads');
    expect((await repo.get('eg-new')).id, 'eg-new');
    expect(site.bodyRequests, 1);
    expect((await repo.library!.usage()).onDevice, 1);

    // Relaunch offline: the device's catalog and the opened recipe.
    site.offline = true;
    repo = repository();
    expect((await repo.index).map((r) => r['id']), contains('eg-new'));
    expect((await repo.get('eg-new')).id, 'eg-new');
    expect((await repo.get('lv-shakshuka')).id, 'lv-shakshuka');
    final unopened = (await repo.index)
        .map((r) => r['id'] as String)
        .firstWhere((id) => id != 'eg-new');
    expect((await repo.get(unopened)).id, unopened, reason: 'seed fallback');
    // A library recipe never opened and not bundled cannot open offline.
    site.offline = false;
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) {
        addRecipe(rows, bodies, 'eg-koshari', 'eg-new');
        addRecipe(rows, bodies, 'eg-koshari', 'eg-other');
      },
    );
    expect(await repo.library!.update(force: true), isTrue);
    site.offline = true;
    await expectLater(repo.get('eg-other'), throwsA(isA<RecipeNotOnDevice>()));
    site.offline = false;
    expect((await repo.get('eg-other')).id, 'eg-other', reason: 'retry works');
  });

  test('manifest diff: unchanged versions download nothing more; a changed '
      'one swaps the catalog and refreshes kept recipes', () async {
    site.files = publishLibrary(seed);
    final repo = repository();
    final lib = repo.library!;
    expect(await lib.update(), isTrue);
    await repo.get('eg-koshari');
    final generation = repo.catalogGeneration;

    site.requests.clear();
    expect(await lib.update(force: true), isFalse);
    expect(site.requests, ['manifest.json']);

    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-21T08:00:00.000Z',
      edit: (rows, bodies) =>
          bodies['eg-koshari']!['description'] = 'وصف معدّل من المكتبة',
    );
    site.requests.clear();
    expect(await lib.update(force: true), isTrue);
    expect(site.requests, contains('index.json'));
    expect(repo.catalogGeneration, generation + 1);
    expect(await repo.catalogDate, DateTime.utc(2026, 11, 21, 8));
    site.offline = true;
    // The kept recipe was refreshed during the update: offline it is new.
    expect((await repo.get('eg-koshari')).description, 'وصف معدّل من المكتبة');
    expect((await lib.usage()).onDevice, 1);
  });

  test('checks at most every 6 hours unless forced', () async {
    site.files = publishLibrary(seed);
    final lib = library();
    expect(await lib.update(), isTrue);
    site.requests.clear();
    now = now.add(const Duration(hours: 5));
    expect(await lib.update(), isFalse);
    expect(site.requests, isEmpty);
    now = now.add(const Duration(hours: 2));
    await lib.update();
    expect(site.requests, ['manifest.json']);
    // A relaunch remembers the last check.
    site.requests.clear();
    await library().update();
    expect(site.requests, isEmpty);
  });

  test(
    'a file that does not match its sha256 never replaces the catalog',
    () async {
      site.files = publishLibrary(seed);
      final repo = repository();
      expect(await repo.library!.update(), isTrue);
      final before = await store.read('manifest');

      site.files = publishLibrary(
        seed,
        edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
      );
      site.tampered.add('index.json');
      expect(await repo.library!.update(force: true), isFalse);
      expect(repo.library!.lastCheckFailed, isTrue);
      expect(await store.read('manifest'), before);
      expect((await repo.index).map((r) => r['id']), isNot(contains('eg-new')));

      // A tampered recipe body is not kept or shown either.
      site.tampered
        ..clear()
        ..addAll(site.files.keys.where((p) => p.startsWith('r/')));
      expect(await repo.library!.update(force: true), isTrue);
      await expectLater(repo.get('eg-new'), throwsA(isA<RecipeNotOnDevice>()));
      // A bundled recipe still opens from the seed.
      expect((await repo.get('eg-koshari')).id, 'eg-koshari');
      expect((await repo.library!.usage()).onDevice, 0);
    },
  );

  test('a recipe the library drops is hidden unless saved; the saved one '
      'still lists and opens from its pinned copy', () async {
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) {
        addRecipe(rows, bodies, 'eg-koshari', 'eg-saved');
        addRecipe(rows, bodies, 'eg-koshari', 'eg-gone');
      },
    );
    final repo = repository();
    expect(await repo.library!.update(), isTrue);
    await repo.pin('eg-saved');
    await repo.get('eg-gone');
    site.files = publishLibrary(seed, generatedAt: '2026-11-22T00:00:00Z');
    expect(await repo.library!.update(force: true), isTrue);

    final ids = (await repo.index).map((r) => r['id']);
    expect(ids, isNot(contains('eg-saved')));
    expect(ids, isNot(contains('eg-gone')));
    final listed = await repo.search();
    final saved = listed.where((r) => r['id'] == 'eg-saved').single;
    expect(saved['pinnedOnly'], isTrue);
    expect(listed.where((r) => r['id'] == 'eg-gone'), isEmpty);
    site.offline = true;
    expect((await repo.get('eg-saved')).id, 'eg-saved');
    await expectLater(repo.get('eg-gone'), throwsArgumentError);
    final usage = await repo.library!.usage();
    expect(usage.saved, 1);
  });

  test(
    'listing, ingredient search and stock matching need no recipe body',
    () async {
      site.files = publishLibrary(seed);
      final repo = repository();
      expect(await repo.library!.update(), isTrue);
      final listing = await repo.listingRecipes();
      expect(listing, hasLength(495));
      final koshari = listing.firstWhere((r) => r.id == 'eg-koshari');
      expect(koshari.ingredients.map((i) => i.id), contains('brown-lentils'));
      expect(koshari.servings, 4);
      final found = await repo.search(query: 'عدس بني');
      expect(found.map((r) => r['id']), contains('eg-koshari'));
      expect(site.bodyRequests, 0);
    },
  );

  /// The published library's active recipe ids and each one's body file.
  (List<String>, String Function(String)) bodies() {
    final rows =
        (jsonDecode(site.files['index.json']!) as Map)['recipes'] as List;
    final sha = {for (final r in rows) r['id'] as String: r['body'] as String};
    return (
      [
        for (final r in rows)
          if (r['catalogStatus'] == 'active') r['id'] as String,
      ],
      (id) => sha[id]!,
    );
  }

  int bytesOf(String sha) => utf8.encode(site.files['r/$sha.json']!).length;
  int charsOf(String sha) => site.files['r/$sha.json']!.length;

  test('opened recipes are capped by size, least recently used evicted '
      'first; saved ones are never evicted', () async {
    site.files = publishLibrary(seed);
    final (all, shaOf) = bodies();
    int size(String id) => bytesOf(shaOf(id));
    // Smallest first: b is no larger than d, p is the largest.
    final [a, b, c, d, p, ...] = [...all]
      ..sort((x, y) => size(x).compareTo(size(y)));
    final lib = OnlineRecipeLibrary(
      store: store,
      baseUrl: Uri.parse('https://library.test/'),
      fetch: site.fetch,
      clock: () => now,
      maxBodyBytes: size(a) + size(c) + size(d),
    );
    final repo = repository(lib);
    expect(await lib.update(), isTrue);
    Future<void> open(String id, [RecipeRepository? on]) async {
      now = now.add(const Duration(minutes: 1));
      await (on ?? repo).get(id);
      await lib.unpin('none'); // waits for the recency write
    }

    await open(a);
    await open(b);
    await open(c);
    await open(a); // a is recent again: b is now the oldest
    await open(d);
    bool kept(String id) => store.data.containsKey('body.${shaOf(id)}');
    expect(kept(a), isTrue);
    expect(kept(b), isFalse, reason: 'least recently used');
    expect(kept(c), isTrue);
    expect(kept(d), isTrue);

    // A saved recipe stays even past the cap; opened ones make room.
    // (A fresh repository each time: nothing is held in memory.)
    await repo.pin(p);
    for (final id in [b, c, d]) {
      await open(id, repository(lib));
    }
    expect(kept(p), isTrue);
    final usage = await lib.usage();
    expect(usage.saved, 1);
    expect(kept(d), isTrue, reason: 'the recipe just opened is kept');
    expect(kept(a), isFalse);
  });

  test('a full device store (web localStorage) still opens recipes and '
      'keeps the old catalog when a new one does not fit', () async {
    site.files = publishLibrary(seed);
    final (all, shaOf) = bodies();
    // The two largest recipes, so half of one is more than the bookkeeping.
    final ids = [...all]
      ..sort((x, y) => charsOf(shaOf(y)).compareTo(charsOf(shaOf(x))));
    final first = charsOf(shaOf(ids[0])), second = charsOf(shaOf(ids[1]));
    expect(second, greaterThan(3000));
    // The catalog, its bookkeeping and one body and a half.
    final full = QuotaLibraryStore(
      site.files['index.json']!.length +
          site.files['dishes.json']!.length +
          site.files['manifest.json']!.length +
          1000 +
          first +
          second ~/ 2,
    );
    final lib = OnlineRecipeLibrary(
      store: full,
      baseUrl: Uri.parse('https://library.test/'),
      fetch: site.fetch,
      clock: () => now,
    );
    final repo = repository(lib);
    expect(await lib.update(), isTrue);
    expect((await repo.get(ids[0])).id, ids[0]);
    // No room for a second body: the opened one gives way, the new one stays.
    expect((await repo.get(ids[1])).id, ids[1]);
    expect((await lib.usage()).onDevice, 1);

    final before = await full.read('manifest');
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
    );
    expect(await lib.update(force: true), isFalse);
    expect(lib.lastCheckFailed, isTrue);
    expect(await full.read('manifest'), before);
    final relaunched = repository(
      OnlineRecipeLibrary(
        store: full,
        baseUrl: Uri.parse('https://library.test/'),
        fetch: site.fetch,
      ),
    );
    expect(await relaunched.index, hasLength(495));
  });

  test('index rows carry optional image references, resolved against the '
      'library; bad ones are dropped, never the catalog', () async {
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) {
        rows.firstWhere((r) => r['id'] == 'eg-koshari')
          ..['thumbnail'] = 'img/eg-koshari.webp'
          ..['photos'] = ['img/eg-koshari-1.webp', 'javascript:alert(1)'];
        rows.firstWhere((r) => r['id'] == 'lv-shakshuka')['thumbnail'] =
            'http://insecure.test/x.jpg';
      },
    );
    final repo = repository();
    expect(await repo.library!.update(), isTrue);
    final rows = {for (final r in await repo.index) r['id']: r};
    expect(rows, hasLength(495));
    expect(
      repo.thumbnailOf(rows['eg-koshari']!),
      Uri.parse('https://library.test/img/eg-koshari.webp'),
    );
    expect(repo.photosOf(rows['eg-koshari']!), [
      Uri.parse('https://library.test/img/eg-koshari-1.webp'),
    ]);
    expect(repo.thumbnailOf(rows['lv-shakshuka']!), isNull);
    expect(site.count((p) => p.startsWith('img/')), 0, reason: 'never fetched');
  });
}

/// A device store that refuses writes past [limit] characters, like the
/// web's localStorage quota.
class QuotaLibraryStore extends MemoryLibraryStore {
  QuotaLibraryStore(this.limit);
  final int limit;
  @override
  Future<void> write(String key, String value) async {
    final used = data.entries
        .where((e) => e.key != key)
        .fold<int>(0, (a, e) => a + e.value.length);
    if (used + value.length > limit) {
      throw StateError('QuotaExceededError');
    }
    data[key] = value;
  }
}
