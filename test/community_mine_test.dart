import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/community_backend.dart';
import 'package:tabkha_demo/domain/community.dart';

SharedRecipe _recipe(String id, String uid) => SharedRecipe(
  id: id,
  authorUid: uid,
  authorName: 'بيت $uid',
  title: 'وصفة $id',
  servings: 2,
  lines: [SharedLine('أرز', amount: 1, unit: 'كوب')],
  steps: const ['اطبخ.'],
);

void main() {
  test('recipesBy finds an older recipe beyond the newest 30', () async {
    final server = MemoryServer();
    final me = MemoryCommunity(server, 'me');
    final other = MemoryCommunity(server, 'other');

    await me.shareRecipe(_recipe('me-old', 'me'));
    for (var i = 0; i < 35; i++) {
      await other.shareRecipe(_recipe('other-$i', 'other'));
    }
    await me.shareRecipe(_recipe('me-new', 'me'));

    final recent = await me.recentRecipes();
    expect(recent.map((r) => r.id), isNot(contains('me-old')));

    final mine = await me.recipesBy('me');
    expect(mine.map((r) => r.id).toList(), ['me-new', 'me-old']);
    expect((await me.recipesBy('nobody')), isEmpty);
  });

  test('recipesBy returns at most 50, newest first', () async {
    final server = MemoryServer();
    final me = MemoryCommunity(server, 'me');
    for (var i = 0; i < 60; i++) {
      await me.shareRecipe(_recipe('me-$i', 'me'));
    }
    final mine = await me.recipesBy('me');
    expect(mine, hasLength(50));
    expect(mine.first.id, 'me-59');
    expect(mine.last.id, 'me-10');
  });
}
