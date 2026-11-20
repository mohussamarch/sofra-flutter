import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/online_recipe_library.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/features/library_settings.dart';
import 'package:tabkha_demo/l10n/l10n.dart';

import 'support/library_fixture.dart';

/// An account: its state document plus one document per saved recipe.
class AccountStore implements StateStore, HasSavedRecipeArchive {
  Map<String, dynamic>? data;
  final archive = MemoryArchive();
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

class MemoryArchive implements SavedRecipeArchive {
  final docs = <String, SavedRecipeCopy>{};
  @override
  Future<Map<String, SavedRecipeCopy>> list() async => {...docs};
  @override
  Future<void> put(String id, SavedRecipeCopy copy) async => docs[id] = copy;
  @override
  Future<void> remove(String id) async => docs.remove(id);
}

void main() {
  final seed = readSeed();
  Future<String> readSeedFile(String path) async =>
      seed[path] ?? (throw FileSystemException('not bundled', path));

  RecipeRepository phone(FakeLibrarySite site, MemoryLibraryStore store) =>
      RecipeRepository(
        read: readSeedFile,
        library: OnlineRecipeLibrary(
          store: store,
          baseUrl: Uri.parse('https://library.test/'),
          fetch: site.fetch,
        ),
      );

  SofraController controller(AccountStore account, RecipeRepository recipes) =>
      SofraController(
        store: account,
        recipes: recipes,
        readAsset: (path) => File(path).readAsString(),
        reminders: SilentReminders(),
      );

  test('a saved recipe is pinned on the phone and copied to the account; '
      'a new phone restores it even after the library dropped it', () async {
    final site = FakeLibrarySite()
      ..files = publishLibrary(
        seed,
        edit: (rows, bodies) =>
            addRecipe(rows, bodies, 'eg-koshari', 'eg-library-only'),
      );
    final account = AccountStore();
    final first = phone(site, MemoryLibraryStore());
    final c1 = controller(account, first);
    await c1.load();
    await c1.checkLibrary(force: true);
    await c1.updateProfile(
      (p) => p.copyWith(saved: {'eg-library-only', 'eg-koshari'}),
    );
    await c1.syncSavedRecipes();
    expect(await first.library!.pinnedIds(), {'eg-library-only', 'eg-koshari'});
    expect(account.archive.docs.keys, {'eg-library-only', 'eg-koshari'});
    final copy = account.archive.docs['eg-library-only']!;
    expect(copy.sha256, sha(copy.body));
    // Not inside the state document.
    expect(jsonEncode(account.data), isNot(contains('"steps"')));

    // The library drops the recipe; a new phone has no network at all.
    site.files = publishLibrary(seed, generatedAt: '2026-12-01T00:00:00Z');
    site.offline = true;
    final second = phone(site, MemoryLibraryStore());
    final c2 = controller(account, second);
    await c2.load();
    await c2.syncSavedRecipes();
    expect(await second.library!.pinnedIds(), {
      'eg-library-only',
      'eg-koshari',
    });
    expect((await second.get('eg-library-only')).id, 'eg-library-only');
    final saved = await second.search();
    expect(
      saved.where((r) => r['id'] == 'eg-library-only').single['pinnedOnly'],
      isTrue,
    );

    // Unsaving removes the pin and the account copy.
    await c2.updateProfile((p) => p.copyWith(saved: {'eg-koshari'}));
    await c2.syncSavedRecipes();
    expect(await second.library!.pinnedIds(), {'eg-koshari'});
    expect(account.archive.docs.keys, {'eg-koshari'});
  });

  testWidgets('settings show what the library keeps and update on demand', (
    tester,
  ) async {
    final site = FakeLibrarySite()..files = publishLibrary(seed);
    final store = MemoryLibraryStore();
    // Built in the real zone: its futures must not wait on the fake clock.
    late final RecipeRepository recipes;
    await tester.runAsync(() async {
      recipes = phone(site, store);
      await recipes.library!.update();
      await recipes.get('eg-koshari');
      await recipes.pin('lv-shakshuka');
    });
    var asked = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: L10n.supportedLocales,
        localizationsDelegates: L10n.delegates,
        home: Scaffold(
          body: LibrarySettings(
            recipes: recipes,
            onUpdate: () async {
              asked++;
              return false;
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    String text(String key) => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .join(' ');
    expect(text('library-on-device'), contains('2'));
    expect(text('library-saved'), contains('1'));
    expect(text('library-size'), contains('ميجابايت'));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('library-updated'))).data,
      contains('2026-11-20'),
    );
    await tester.tap(find.byKey(const ValueKey('library-update-now')));
    await tester.pumpAndSettle();
    expect(asked, 1);
    expect(find.text(L10n.of(AppLanguage.ar).libraryUpToDate), findsOneWidget);
  });
}
