import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_repository.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';

void main() {
  test('retained extracted recipes keep source content independently of cuisine admission', () async {
    final repo = RecipeRepository(read: (p) => File(p).readAsString());
    final all = await repo.loadAll(includeHeld: true);
    expect(all.length, 687);
    for (final id in [
      'ma650-manal-muhammara-20261021b',
      'ma650-dina-macki-paplo-omani-balochi-lemon-fish-curry',
      'ma650-amjaad-al-hussain-yemeni-chicken-in-marag',
      'bc650-miso-soup',
    ]) {
      final r = await repo.get(id, includeHeld: true);
      expect(r.ingredients, isNotEmpty);
      expect(r.steps, isNotEmpty);
      expect(r.notes, contains('https://'));
      expect(
        CatalogRecipe.fromJson(jsonDecode(jsonEncode(r.toJson()))).toJson(),
        r.toJson(),
      );
      if (!r.hasKnownYield) {
        expect(() => r.forServings(4), throwsArgumentError);
      }
      if (r.prepMinutes == null || r.cookMinutes == null) {
        expect(r.totalMinutes, isNull);
      }
      if (r.hasKnownYield && !r.hasCompleteSchedule) {
        expect(() => r.forServings(r.servings!).schedule, throwsStateError);
      }
    }
    for (final r in all.where((r) => r.metadataPolicy != null)) {
      expect(r.notes, contains('https://'));
      for (final i in r.ingredients) {
        if (i.amount == null) expect(i.scales, isFalse);
        if (i.scales && i.amount != null) {
          expect(
            i.display,
            isNull,
            reason: 'Measured amounts must use scaled display: ${r.id}/${i.id}',
          );
        }
      }
    }
  });
}
