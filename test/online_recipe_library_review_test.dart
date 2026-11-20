import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/online_recipe_library.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/data/state_store.dart';

import 'support/library_fixture.dart';

/// An account whose saved-recipe writes can hang (Firestore offline: a write
/// only completes once the server has it).
class SlowAccount implements StateStore, HasSavedRecipeArchive {
  Map<String, dynamic>? data;
  final archive = SlowArchive();
  @override
  String get label => 'account';
  @override
  Future<Map<String, dynamic>?> load() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> value) async =>
      data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  @override
  SavedRecipeArchive get savedRecipes => archive;
}

class SlowArchive implements SavedRecipeArchive {
  final docs = <String, SavedRecipeCopy>{};
  bool hang = false;
  @override
  Future<Map<String, SavedRecipeCopy>> list() async => {...docs};
  @override
  Future<void> put(String id, SavedRecipeCopy copy) {
    // Never completes, like an offline Firestore write.
    if (hang) return Completer<void>().future;
    docs[id] = copy;
    return Future.value();
  }

  @override
  Future<void> remove(String id) async => docs.remove(id);
}

void main() {
  final seed = readSeed();
  Future<String> readSeedFile(String path) async =>
      seed[path] ?? (throw FileSystemException('not bundled', path));
  late FakeLibrarySite site;
  late MemoryLibraryStore store;
  var now = DateTime.utc(2026, 11, 20, 9);

  OnlineRecipeLibrary library([MemoryLibraryStore? on]) => OnlineRecipeLibrary(
    store: on ?? store,
    baseUrl: Uri.parse('https://library.test/'),
    fetch: site.fetch,
    clock: () => now,
  );
  RecipeRepository repository([MemoryLibraryStore? on]) =>
      RecipeRepository(read: readSeedFile, library: library(on));

  setUp(() {
    site = FakeLibrarySite();
    store = MemoryLibraryStore();
    now = DateTime.utc(2026, 11, 20, 9);
  });

  void hold(List<Map<String, dynamic>> rows, String id, String status) {
    final row = rows.firstWhere((r) => r['id'] == id);
    row['catalogStatus'] = status;
    row.remove('cuisineGroup');
  }

  test('a saved recipe the library holds back still lists and opens from '
      'its pinned copy', () async {
    site.files = publishLibrary(seed);
    final repo = repository();
    expect(await repo.library!.update(), isTrue);
    await repo.pin('eg-koshari');
    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-22T00:00:00Z',
      edit: (rows, _) => hold(rows, 'eg-koshari', 'held-content'),
    );
    expect(await repo.library!.update(force: true), isTrue);
    expect(
      (await repo.index).map((r) => r['id']),
      isNot(contains('eg-koshari')),
    );
    final listed = (await repo.search()).where((r) => r['id'] == 'eg-koshari');
    expect(listed.single['pinnedOnly'], isTrue);
    expect((await repo.get('eg-koshari')).id, 'eg-koshari');
    // Unsaved held recipes stay off the catalog.
    await expectLater(repo.get('lv-shakshuka'), completes);
  });

  test('a library index the app rejects is downloaded once, not on every '
      'check; a failed check waits before the next automatic one', () async {
    site.files = publishLibrary(seed);
    final repo = repository();
    expect(await repo.library!.update(), isTrue);
    now = now.add(const Duration(hours: 7));
    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-22T00:00:00Z',
      edit: (rows, _) {
        // A held row in a group: the app's catalog check rejects it.
        rows.firstWhere((r) => r['catalogStatus'] != 'active')['cuisineGroup'] =
            'other';
      },
    );
    site.requests.clear();
    expect(await repo.library!.update(), isFalse);
    expect(repo.library!.lastCheckFailed, isTrue);
    expect(site.count((p) => p == 'index.json'), 1);
    for (var i = 0; i < 5; i++) {
      await repo.library!.update();
    }
    expect(site.requests, ['manifest.json', 'index.json'], reason: 'backoff');
    now = now.add(const Duration(hours: 1));
    await repo.library!.update();
    // The manifest is read again, but the rejected version is not fetched.
    expect(site.count((p) => p == 'index.json'), 1);
    expect(site.count((p) => p == 'manifest.json'), 2);
    // A relaunch remembers the rejection.
    now = now.add(const Duration(hours: 1));
    await library().update();
    expect(site.count((p) => p == 'index.json'), 1);
    // The button still tries.
    await repo.library!.update(force: true);
    expect(site.count((p) => p == 'index.json'), 2);
    // A newer, valid publish is taken automatically.
    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-23T00:00:00Z',
      edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
    );
    now = now.add(const Duration(hours: 1));
    expect(await repo.library!.update(), isTrue);

    // Offline: one attempt, then automatic checks wait.
    site.offline = true;
    now = now.add(const Duration(hours: 7));
    site.requests.clear();
    await repo.library!.update();
    await repo.library!.update();
    expect(site.requests, ['manifest.json']);
  });

  test('a clock set back never stops the automatic checks', () async {
    site.files = publishLibrary(seed);
    final lib = library();
    expect(await lib.update(), isTrue);
    now = now.subtract(const Duration(days: 365));
    site.requests.clear();
    await lib.update();
    expect(site.requests, ['manifest.json']);
  });

  test('a saved copy older than the catalog opens offline, and is pinned '
      'again from the catalog when online', () async {
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
    );
    final old = repository(MemoryLibraryStore());
    expect(await old.library!.update(), isTrue);
    await old.pin('eg-new');
    final copy = (await old.library!.pinnedCopy('eg-new'))!;

    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-22T00:00:00Z',
      edit: (rows, bodies) {
        addRecipe(rows, bodies, 'eg-koshari', 'eg-new');
        final servings = (bodies['eg-new']!['servings'] as int) + 2;
        bodies['eg-new']!['servings'] = servings;
        rows.firstWhere((r) => r['id'] == 'eg-new')['servings'] = servings;
      },
    );
    final phone = repository();
    expect(await phone.library!.update(), isTrue);
    await phone.library!.restorePinned('eg-new', copy);
    site.offline = true;
    expect((await phone.get('eg-new')).id, 'eg-new');
    await phone.refreshPin('eg-new');
    expect((await phone.library!.pinnedCopy('eg-new'))!.sha256, copy.sha256);

    site.offline = false;
    await phone.refreshPin('eg-new');
    final fresh = (await phone.library!.pinnedCopy('eg-new'))!;
    expect(fresh.sha256, isNot(copy.sha256));
    final row = (await phone.index).firstWhere((r) => r['id'] == 'eg-new');
    expect(fresh.sha256, row['body']);
  });

  test('a recipe changed since the catalog on the phone opens online: the '
      'catalog is taken and the new body fetched', () async {
    site.files = publishLibrary(
      seed,
      edit: (rows, bodies) => addRecipe(rows, bodies, 'eg-koshari', 'eg-new'),
    );
    final repo = repository();
    expect(await repo.library!.update(), isTrue);
    // A new publish removes the old body file before the phone checks.
    site.files = publishLibrary(
      seed,
      generatedAt: '2026-11-22T00:00:00Z',
      edit: (rows, bodies) {
        addRecipe(rows, bodies, 'eg-koshari', 'eg-new');
        bodies['eg-new']!['description'] = 'نسخة أحدث';
      },
    );
    final recipe = await repo.get('eg-new');
    expect(recipe.description, 'نسخة أحدث');
  });

  test('saving offline never waits on the account; another phone with an '
      'older saved list never deletes a copy', () async {
    site.files = publishLibrary(seed);
    final account = SlowAccount();
    SofraController controller(RecipeRepository recipes) => SofraController(
      store: account,
      recipes: recipes,
      readAsset: (path) => File(path).readAsString(),
      reminders: SilentReminders(),
    );
    final first = repository(MemoryLibraryStore());
    final c1 = controller(first);
    await c1.load();
    await c1.checkLibrary(force: true);
    await c1.syncSavedRecipes();
    account.archive.hang = true;
    await c1.updateProfile((p) => p.copyWith(saved: {'eg-koshari'}));
    await c1.syncSavedRecipes().timeout(const Duration(seconds: 5));
    await c1
        .updateProfile((p) => p.copyWith(saved: {'eg-koshari', 'lv-shakshuka'}))
        .timeout(const Duration(seconds: 5));
    await c1.syncSavedRecipes().timeout(const Duration(seconds: 5));
    expect(await first.library!.pinnedIds(), {'eg-koshari', 'lv-shakshuka'});

    // Firestore sends the queued writes itself once online.
    account.archive.hang = false;

    // A second phone whose state does not yet list a saved recipe.
    account.archive.docs['eg-extra'] = (await first.library!.pinnedCopy(
      'eg-koshari',
    ))!;
    final second = repository(MemoryLibraryStore());
    final c2 = controller(second);
    await c2.load();
    await c2.syncSavedRecipes();
    await pumpEventQueue();
    expect(account.archive.docs.keys, contains('eg-extra'));
  });
}
