import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';
import 'package:tabkha_demo/domain/food_nutrition.dart';
import 'package:tabkha_demo/domain/recipe_library_draft.dart';

import 'recipe_library_repository_test.dart' as fixtures;
import 'recipe_library_draft_test.dart' as reviews;

Future<RecipeLibraryEntry> source({
  double? amount = 0.5,
  String? unit = 'kg',
  bool included = true,
}) async {
  final f = fixtures.LibraryFixture();
  f.local = fixtures.owned(f.local);
  f.local['recipes'][0]['ingredients'][0].addAll({
    'amount': amount,
    'unit': unit,
    'sourceText': 'declared source mass',
    'included': included,
  });
  f.rebuild();
  return (await f.repository().all()).first;
}

RecipeLibraryMassProposal propose(
  RecipeLibraryEntry e, {
  String? pin,
  int line = 0,
  bool ack = true,
}) => RecipeLibraryMassProposal.fromSource(
  entry: e,
  expectedSourceFingerprint: pin ?? recipeLibrarySourceFingerprint(e),
  lineIndex: line,
  acknowledgeDeclaredSourceMass: ack,
);

RecipeLibraryLineDecision decide(
  RecipeLibraryMassProposal p,
  RecipeLibraryEntry e, {
  bool selected = true,
  bool override = false,
}) => p.toDecision(
  currentEntry: e,
  ingredientId: 'private-mass',
  food: null,
  amountForm: FoodForm.raw,
  preparedForm: FoodForm.cooked,
  optional: true,
  selected: selected,
  asPurchased: false,
  preparation: null,
  scales: true,
  overrideSourceExclusion: override,
);

void main() {
  test(
    'source kg remains kg and estimated through saved review roundtrip',
    () async {
      final e = await source(), p = propose(e);
      expect(p.recipeId, e.id);
      expect(p.lineIndex, 0);
      expect(p.ingredient.sourceQuantityText, 'declared source mass');
      expect(p.amount.value, 0.5);
      expect(p.amount.unit, FoodQuantityUnit.kg);
      final d = decide(p, e);
      expect(d.input.quantityEstimated, isTrue);
      expect(d.input.food, isNull);
      expect(d.input.amountForm, FoodForm.raw);
      expect(d.input.preparedForm, FoodForm.cooked);
      final review = reviews.makeReview(
        e,
        choices: {0: d, 1: reviews.decision(1)},
      );
      final loaded = RecipeLibraryDraftReview.fromJson(review.toJson());
      expect(loaded.draft.lines.first.input.quantityEstimated, isTrue);
      expect(loaded.draft.lines.first.input.amount!.unit, FoodQuantityUnit.kg);
      expect(loaded.sourceFingerprint, p.sourceFingerprint);
      expect(e.runtimeReady, isFalse);
      final grams = propose(await source(amount: 125, unit: 'g'));
      expect(grams.amount.value, 125);
      expect(grams.amount.unit, FoodQuantityUnit.g);
    },
  );
  test(
    'unknown non-mass and nonpositive declarations are never converted',
    () async {
      for (final unit in [null, 'cup', 'ml', 'oz', 'count', 'G', ' kg ']) {
        final e = await source(unit: unit);
        expect(() => propose(e), throwsArgumentError, reason: '$unit');
      }
      await expectLater(source(amount: -1), throwsFormatException);
      for (final amount in [null, 0.0]) {
        final e = await source(amount: amount);
        expect(() => propose(e), throwsArgumentError, reason: '$amount');
      }
    },
  );
  test(
    'proposal and decision reject absent acknowledgement or changed source',
    () async {
      final e = await source(),
          p = propose(e),
          changed = await source(amount: 0.6);
      expect(() => propose(e, ack: false), throwsArgumentError);
      expect(() => propose(e, pin: 'stale'), throwsStateError);
      for (final line in [-1, 2]) {
        expect(() => propose(e, line: line), throwsArgumentError);
      }
      expect(() => decide(p, changed), throwsStateError);
    },
  );
  test(
    'excluded line stays excluded unless applicable override is explicit',
    () async {
      final excluded = await source(included: false), p = propose(excluded);
      expect(() => decide(p, excluded), throwsArgumentError);
      expect(decide(p, excluded, selected: false).input.selected, isFalse);
      expect(
        decide(p, excluded, override: true).input.quantityEstimated,
        isTrue,
      );
      final included = await source();
      expect(
        () => decide(propose(included), included, override: true),
        throwsArgumentError,
      );
    },
  );
}
