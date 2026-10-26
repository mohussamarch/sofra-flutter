import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';

void main() {
  RecipeRepository repository() =>
      RecipeRepository(read: (p) => File(p).readAsString());
  test(
    'active catalog has a concrete cuisine and held recipes remain recoverable',
    () async {
      final repo = repository();
      final active = await repo.index;
      final retained = await repo.retainedIndex;
      expect(retained, hasLength(687));
      expect(active.length, lessThan(retained.length));
      for (final row in active) {
        expect(row['catalogStatus'], 'active');
        expect(
          row['cuisine'],
          isNot(anyOf('غير محدد', 'عالمي متنوع', 'آسيوي', 'أمريكي جنوبي')),
        );
        expect(row['cuisineGroup'], isNotNull);
      }
      final held = retained.firstWhere(
        (r) => r['catalogStatus'] == 'held-cuisine',
      );
      await expectLater(repo.get(held['id'] as String), throwsStateError);
      expect(
        (await repo.get(held['id'] as String, includeHeld: true)).id,
        held['id'],
      );
      expect((await repo.loadAll()).length, active.length);
      expect((await repo.loadAll(includeHeld: true)).length, retained.length);
    },
  );
  test(
    'other is a display group and never overwrites the actual cuisine',
    () async {
      final repo = repository();
      final groups = await repo.cuisineGroups;
      expect(groups, hasLength(16));
      expect(() => groups.clear(), throwsUnsupportedError);
      expect(() => groups.first['count'] = 999, throwsUnsupportedError);
      expect(
        () => (groups.first['members'] as List).clear(),
        throwsUnsupportedError,
      );
      final other = await repo.search(cuisineGroup: 'other');
      expect(other, isNotEmpty);
      expect(other.any((r) => r['cuisine'] == 'عُماني'), isTrue);
      expect(
        (await repo.search(cuisineGroup: 'levantine'))
            .any((r) => r['cuisine'] == 'لبناني'),
        isTrue,
      );
      expect(other.any((r) => r['cuisine'] == 'مصري'), isFalse);
      expect(other.any((r) => r['cuisine'] == 'سعودي'), isFalse);
      expect(other.any((r) => r['cuisine'] == 'غير محدد'), isFalse);
      expect(
        (await repo.search(cuisineGroup: 'italian'))
            .every((r) => r['cuisine'] == 'إيطالي'),
        isTrue,
      );
    },
  );
  test('group counts cannot conceal mismatched active membership', () async {
    final repo = RecipeRepository(
      read: (path) async {
        final data =
            jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
        (data['cuisineGroups'] as List).first['count'] = 999;
        return jsonEncode(data);
      },
    );
    await expectLater(repo.index, throwsFormatException);
  });
  test('shipping policy pins exactly15 selected main groups plus other and reconciles every retained ID', () async {
    final data =
        jsonDecode(await File('recipes/data/index.json').readAsString()) as Map;
    final groups = data['cuisineGroups'] as List;
    expect(groups, hasLength(16));
    expect(
      groups.where((g) => g['kind'] == 'primary').map((g) => g['order']),
      List.generate(15, (i) => i + 1),
    );
    expect(groups.last['id'], 'other');
    final retained = await repository().retainedIndex;
    expect(retained.map((r) => r['id']).toSet(), hasLength(retained.length));
    expect(
      groups.fold<int>(0, (n, g) => n + g['count'] as int),
      (await repository().index).length,
    );
    final review = jsonDecode(
      await File('data/recipes/cuisine-policy-20261022/review.json')
          .readAsString(),
    ) as Map;
    expect(
      (review['heldRecipeIds'] as List).toSet(),
      retained
          .where((r) => r['catalogStatus'] == 'held-cuisine')
          .map((r) => r['id'])
          .toSet(),
    );
  });
}
