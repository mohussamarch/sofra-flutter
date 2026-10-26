import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/domain/recipe_catalog.dart';
import 'package:tabkha_demo/features/common.dart';

import 'recipe_variants_test.dart' as f;

CatalogRecipe lines() => CatalogRecipe.fromJson({
  ...f.recipe().toJson(),
  'ingredients': [
    {'id': 'mozz', 'name': 'موتزاريلا مبشورة', 'amount': 100, 'unit': 'جرام'},
    {'id': 'flour', 'name': 'دقيق', 'amount': 2, 'unit': 'كوب'},
    {'id': 'tahini', 'name': 'طحينة', 'amount': 1, 'unit': 'كوب'},
  ],
});

void main() {
  test('allergy notes match line names with Arabic letter forms alike', () {
    expect(allergyMatches(lines(), {'طحينه'}), {
      'طحينه': ['طحينة'],
    });
    expect(allergyMatches(lines(), {'سمك'}), isEmpty);
  });

  test('allergy notes also match the kitchen ingredient names', () {
    Iterable<String> names(CatalogIngredient line) =>
        line.id == 'mozz' ? ['جبنة موتزاريلا', 'جبن موزاريلا'] : const [];
    expect(allergyMatches(lines(), {'جبنة'}), isEmpty);
    expect(allergyMatches(lines(), {'جبنة'}, names: names), {
      'جبنة': ['موتزاريلا مبشورة'],
    });
    // A group word is not a composition rule: "ألبان" finds nothing here.
    expect(allergyMatches(lines(), {'ألبان'}, names: names), isEmpty);
  });
}
