import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/data/community_backend.dart';
import 'package:tabkha_demo/data/recipe_photo_library.dart';
import 'package:tabkha_demo/domain/community.dart';

import 'sofra_controller_test.dart' show threeLines;
import 'recipe_variants_test.dart' as f;

PriceReport report(String uid, double amount, {String day = '2026-10-20'}) =>
    PriceReport(
      uid: uid,
      country: 'EG',
      area: ' مدينة  نصر ',
      ingredientId: 'rice',
      quantity: 1,
      unit: 'kg',
      amount: amount,
      paidOn: DateTime.parse(day),
    );

SofraController account(MemoryServer server, String uid, {f.Store? store}) =>
    SofraController(
      store: store ?? f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
      reminders: SilentReminders(),
      community: MemoryCommunity(server, uid),
    );

void main() {
  final today = DateTime(2026, 10, 26);

  test('an area price needs two households and recent reports', () {
    expect(
      areaPrice(
        [report('a', 40), report('a', 44)],
        ingredientId: 'rice',
        unit: 'kg',
        today: today,
      ),
      isNull,
    );
    final p = areaPrice(
      [
        report('a', 40),
        report('b', 50),
        report('c', 44),
        report('d', 99, day: '2026-07-01'),
      ],
      ingredientId: 'rice',
      unit: 'kg',
      today: today,
    )!;
    expect(p.medianPerUnit, 44);
    expect(p.households, 3);
    expect(report('a', 1).area, 'مدينه نصر');
  });

  test('weeks start on Saturday and challenges are measured from cooking', () {
    expect(weekStart(DateTime(2026, 10, 26)), DateTime(2026, 10, 24));
    expect(weekStart(DateTime(2026, 10, 24)), DateTime(2026, 10, 24));
    expect(weekKey(DateTime(2026, 10, 30)), '2026-10-24');
    const cooked = [
      ('2026-10-10', 'koshari'),
      ('2026-10-24', 'koshari'),
      ('2026-10-25', 'molokhia'),
      ('2026-10-26', 'molokhia'),
      ('2026-10-31', 'fatta'),
    ];
    final day = DateTime(2026, 10, 26);
    expect(challengeProgress(challenges[0], day, cooked), 3);
    expect(challengeProgress(challenges[1], day, cooked), 2);
    expect(challengeProgress(challenges[2], day, cooked), 1);
    expect(
      challengeFor(DateTime(2026, 10, 24)),
      same(challengeFor(DateTime(2026, 10, 30))),
    );
  });

  test('invite codes avoid look-alike letters', () {
    final code = newInviteCode();
    expect(validInvite(code), isTrue);
    expect(normalizeInvite('ab cd-efgh'), 'ABCDEFGH');
    expect(validInvite('ABCDEFGI'), isFalse);
  });

  test('photos are only references to files in the photos folder', () {
    expect(() => PhotoRef(path: '../secret', byUid: 'a'), throwsArgumentError);
    final p = PhotoRef(path: 'photos/a/koshari-1.webp', byUid: 'a', width: 800);
    expect(PhotoRef.fromJson(p.toJson()).width, 800);
  });

  test('two accounts share one kitchen through an invite', () async {
    final server = MemoryServer();
    var reopened = 0;
    final aliceStore = f.Store();
    final alice = SofraController(
      store: aliceStore,
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
      reminders: SilentReminders(),
      community: MemoryCommunity(server, 'alice'),
      reopen: () => reopened++,
    );
    await alice.load();
    await alice.updateProfile((p) => p.copyWith(name: 'مريم'));
    final kid = await alice.shareKitchen();
    expect(reopened, 1);
    expect(server.kitchenState[kid]!['name'], 'مريم');
    final code = await alice.community!.createInvite(kid);

    final bob = account(server, 'bob');
    await bob.load();
    await expectLater(
      bob.joinKitchen('WRONG123'),
      throwsA(isA<InviteProblem>()),
    );
    expect(await bob.joinKitchen(code.toLowerCase()), kid);
    final k = await bob.community!.kitchen(kid);
    expect(k.members, ['alice', 'bob']);
    expect(k.owner, 'alice');

    server.clock = () => DateTime.now().add(const Duration(days: 8));
    final late = account(server, 'eve');
    await late.load();
    await expectLater(late.joinKitchen(code), throwsA(isA<InviteProblem>()));

    await bob.leaveKitchen(kid);
    expect(await bob.community!.membership(), isNull);
    expect((await alice.community!.kitchen(kid)).members, ['alice']);
  });

  test('a shared recipe is read and rated by another household', () async {
    final server = MemoryServer();
    final alice = account(server, 'alice');
    await alice.load();
    await alice.createMyRecipe(
      name: 'رز بالشعرية',
      servings: 2,
      cuisine: 'مصري',
      prepMinutes: 5,
      cookMinutes: 20,
      category: 'أطباق رئيسية',
      description: 'من البيت',
      difficulty: 'سهل',
      lines: const [
        MyRecipeLine('rice', 'رز', amount: 200, unit: 'g'),
        MyRecipeLine('salt', 'ملح'),
      ],
      steps: const [('حمّر الشعرية', 5), ('سيبه يستوي', 20)],
    );
    final shared = await alice.shareMyRecipe(alice.myRecipes.single);
    expect(shared.lines.last.amount, isNull);
    expect(shared.photos, isEmpty);

    final bob = account(server, 'bob');
    await bob.load();
    final list = await bob.community!.recentRecipes();
    expect(list.single.title, 'رز بالشعرية');
    await bob.rateRecipe(shared.id, 4, 'حلوة');
    await bob.rateRecipe(shared.id, 5, '');
    final ratings = await alice.community!.ratings(shared.id);
    expect(ratings, hasLength(1));
    expect(averageStars(ratings), 5);
  });

  test('prices shared in an area show once two homes report them', () async {
    final server = MemoryServer();
    Future<SofraController> home(String uid, double paid) async {
      final c = account(server, uid);
      await c.load();
      await c.updateProfile((p) => p.copyWith(area: 'مدينة نصر'));
      await c.setUserPrice('rice', 1, 'kg', paid);
      await c.sharePrice(c.myPrices.single);
      return c;
    }

    final a = await home('a', 40);
    expect(await a.areaPrices(), isEmpty);
    await home('b', 50);
    final prices = await a.areaPrices();
    expect(prices[('rice', 'kg')]!.medianPerUnit, 45);
    expect(prices[('rice', 'kg')]!.households, 2);
  });

  test('the weekly challenge entry carries the household progress', () async {
    final server = MemoryServer();
    final c = account(server, 'a');
    await c.load();
    final entry = await c.joinChallenge(today: today);
    expect(entry.progress, 0);
    expect(
      (await c.community!.challengeEntries(weekKey(today))).single.uid,
      'a',
    );
  });

  test('stories last a day and are grouped per household', () async {
    final server = MemoryServer();
    var now = DateTime(2026, 10, 26, 9);
    server.clock = () => now;
    final a = MemoryCommunity(server, 'a'), b = MemoryCommunity(server, 'b');
    await a.postStory(name: 'بيت أ', text: 'فطار', colorIndex: 1);
    now = now.add(const Duration(hours: 2));
    await b.postStory(name: 'بيت ب', text: 'غداء', dish: 'ملوخية');
    now = now.add(const Duration(hours: 1));
    await a.postStory(name: 'بيت أ', text: 'عشاء');
    final rings = storyRings(await a.liveStories(), now);
    expect(rings.map((r) => r.first.uid), ['a', 'b']);
    expect(rings.first.map((s) => s.text), ['فطار', 'عشاء']);
    now = now.add(const Duration(hours: 22));
    expect((await a.liveStories()).map((s) => s.text), ['غداء', 'عشاء']);
    expect(
      () => Story(id: 'x', uid: 'a', name: 'n', text: ' ', createdAt: now),
      throwsArgumentError,
    );
  });

  test('suggested channels come from the verified list', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    final creators = await c.creators();
    expect(creators.map((x) => x.id), contains('manal-alalem'));
    expect(
      creators.every(
        (x) => x.channelUrl.startsWith('https://www.youtube.com/'),
      ),
      isTrue,
    );
    expect(
      () => Creator.fromJson({
        'id': 'x',
        'name': 'x',
        'short': 'x',
        'channelUrl': 'https://evil.example',
      }),
      throwsFormatException,
    );
  });

  test('without an account the community actions are refused', () async {
    final c = SofraController(
      store: f.Store(),
      recipes: f.repository(value: threeLines()),
      readAsset: (path) => File(path).readAsString(),
    );
    await c.load();
    expect(c.community, isNull);
    expect(() => c.shareKitchen(), throwsStateError);
  });

  test(
    'the bundled photo library is valid and photos need a licence',
    () async {
      final library = RecipePhotoLibrary(read: (p) => File(p).readAsString());
      expect(await library.all, isA<Map>());
      expect(
        () => RecipePhoto.fromJson({
          'file': 'eg-koshari.webp',
          'credit': 'x',
          'licence': '',
        }),
        throwsFormatException,
      );
      final c = SofraController(
        store: f.Store(),
        recipes: f.repository(value: threeLines()),
        readAsset: (path) async => throw StateError('missing'),
      );
      expect(await c.photosOf('eg-koshari'), isEmpty);
    },
  );
}
