import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/community_backend.dart';
import 'package:tabkha_demo/domain/community.dart';

import 'community_test.dart' show account, report;

void main() {
  test('an account deletes only its own story', () async {
    final server = MemoryServer();
    final a = MemoryCommunity(server, 'a'), b = MemoryCommunity(server, 'b');
    final mine = await a.postStory(name: 'بيت أ', text: 'فطار');
    final theirs = await b.postStory(name: 'بيت ب', text: 'غداء');
    await a.deleteStory(theirs.id);
    expect(await a.liveStories(), hasLength(2));
    await a.deleteStory(mine.id);
    expect((await a.liveStories()).single.uid, 'b');
  });

  test('a rating is removed by its author and a shared recipe too', () async {
    final server = MemoryServer();
    final a = account(server, 'a'), b = account(server, 'b');
    await a.load();
    await b.load();
    final recipe = SharedRecipe(
      id: 'a-r1',
      authorUid: 'a',
      authorName: 'أ',
      title: 'رز',
      servings: 2,
      lines: [SharedLine('رز', amount: 1, unit: 'cup')],
      steps: const ['اطبخ'],
    );
    await a.community!.shareRecipe(recipe);
    await a.rateRecipe(recipe.id, 5, 'حلوة');
    await b.rateRecipe(recipe.id, 3, '');
    await b.community!.deleteRating(recipe.id);
    final left = await a.community!.ratings(recipe.id);
    expect(left.map((r) => r.uid), ['a']);

    await b.community!.deleteSharedRecipe(recipe.id);
    expect(await a.community!.recentRecipes(), hasLength(1));
    await a.community!.deleteSharedRecipe(recipe.id);
    expect(await a.community!.recentRecipes(), isEmpty);
  });

  test('a shared price is taken back without touching other homes', () async {
    final server = MemoryServer();
    final a = MemoryCommunity(server, 'a'), b = MemoryCommunity(server, 'b');
    await a.reportPrice(report('a', 40));
    await b.reportPrice(report('b', 50));
    await a.deletePriceReports(
      country: 'EG',
      area: 'مدينة نصر',
      ingredientId: 'rice',
      unit: 'kg',
    );
    final left = await a.areaReports('EG', 'مدينة نصر');
    expect(left.map((r) => r.uid), ['b']);
  });

  test('the controller un-shares the price it shared', () async {
    final server = MemoryServer();
    final c = account(server, 'a');
    await c.load();
    await c.updateProfile((p) => p.copyWith(area: 'مدينة نصر'));
    await c.setUserPrice('rice', 1, 'kg', 40);
    await c.sharePrice(c.myPrices.single);
    expect(server.prices, hasLength(1));
    await c.unsharePrice(c.myPrices.single);
    expect(server.prices, isEmpty);
  });
}
