part of 'kitchen_service.dart';

/// Caller-reviewed identity and serving choice, not an inferred dietary fit.
class RecipePoolChoice {
  const RecipePoolChoice({
    required this.id,
    required this.recipeId,
    required this.servings,
    this.recipeRevisionKey,
  });
  final String id, recipeId;
  final int servings;
  final String? recipeRevisionKey;
}

class WeeklyRecipeSlot {
  WeeklyRecipeSlot({
    required this.weekday,
    required this.slot,
    required List<RecipePoolChoice> choices,
  }) : choices = List.unmodifiable(choices);
  final int weekday;
  final String slot;
  final List<RecipePoolChoice> choices;
}

/// A proposal only. Feed both fields into search, then explicitly choose/save.
class MonthlyCandidatePools {
  MonthlyCandidatePools._(
    Map<String, List<PlannedMeal>> pools,
    List<MonthlyBudgetCoverage> requiredSlots,
  ) : pools = Map.unmodifiable({
        for (final e in pools.entries)
          e.key: List<PlannedMeal>.unmodifiable(e.value),
      }),
      requiredSlots = List.unmodifiable(requiredSlots);
  final Map<String, List<PlannedMeal>> pools;
  final List<MonthlyBudgetCoverage> requiredSlots;
}

extension MonthlyPoolGeneration on KitchenService {
  Future<RecipeRevision> _resolveMonthlyCandidate(PlannedMeal meal) async {
    final key = meal.recipeRevisionKey;
    final RecipeRevision revision;
    if (key != null && !recipeBook.revisions.containsKey(key)) {
      // Proposals may pin an unsaved catalog snapshot; never replace drift.
      revision = _catalogDraft(await recipes.get(meal.recipeId));
      if (revision.key != key) {
        throw StateError('Generated catalog revision changed; regenerate');
      }
    } else {
      revision = await _resolveMeal(meal);
    }
    if (!RecipeRepository.hasConcreteCuisine(revision.recipe.cuisine)) {
      throw StateError('Candidate cuisine requires review');
    }
    return revision;
  }

  /// Expands a complete explicit weekly pattern over the saved calendar month.
  /// No recipes are picked from the whole catalog and no plans are written.
  Future<MonthlyCandidatePools> generateMonthlyCandidatePools(
    String budgetId, {
    required List<WeeklyRecipeSlot> weeklyTemplate,
    required List<String> requiredDailySlots,
    required int maxPools,
    required int maxCandidatesPerSlot,
    required bool acknowledgeRecipeEligibility,
  }) async {
    final template = List<WeeklyRecipeSlot>.of(weeklyTemplate);
    final daily = List<String>.of(requiredDailySlots);
    if (!acknowledgeRecipeEligibility ||
        maxPools < 1 ||
        maxCandidatesPerSlot < 1 ||
        daily.isEmpty ||
        daily.toSet().length != daily.length ||
        daily.any((s) => s.trim().isEmpty || s.trim() != s)) {
      throw ArgumentError(
        'Explicit reviewed template, daily slots and positive caps required',
      );
    }
    final bySlot = <(int, String), WeeklyRecipeSlot>{};
    for (final t in template) {
      if (t.weekday < 1 ||
          t.weekday > 7 ||
          !daily.contains(t.slot) ||
          bySlot.containsKey((t.weekday, t.slot)) ||
          t.choices.isEmpty ||
          t.choices.length > maxCandidatesPerSlot ||
          t.choices.map((c) => c.id).toSet().length != t.choices.length) {
        throw ArgumentError(
          'Unique complete weekday/slot template and bounded choices required',
        );
      }
      for (final c in t.choices) {
        if (c.id.trim().isEmpty ||
            c.recipeId.trim().isEmpty ||
            (c.recipeRevisionKey != null &&
                c.recipeRevisionKey!.trim().isEmpty) ||
            c.servings < 1 ||
            c.servings > 1000) {
          throw ArgumentError(
            'Explicit candidate identity and servings1..1000 required',
          );
        }
      }
      bySlot[(t.weekday, t.slot)] = t;
    }
    if (bySlot.length != 7 * daily.length) {
      throw ArgumentError('Every required daily slot needs all seven weekdays');
    }
    final k = snapshot, guard = jsonEncode(snapshot), tail = _tail;
    final budgets = (k['budgets'] as List)
        .where((b) => b['id'] == budgetId)
        .toList();
    if (budgets.length != 1) throw ArgumentError('Unknown or ambiguous budget');
    final period = BudgetPeriod.fromJson(
      Map<String, dynamic>.from(budgets.single as Map),
    );
    final start = parseDay(period.start), end = parseDay(period.end);
    if (start.day != 1 || end != DateTime(start.year, start.month + 1)) {
      throw ArgumentError('Exactly one saved calendar month required');
    }
    if (period.country !=
        MarketProfile.fromCode(k['country'] as String).country) {
      throw StateError('Select the budget country first');
    }
    final days = DateTime.utc(
      start.year,
      start.month + 1,
    ).difference(DateTime.utc(start.year, start.month)).inDays;
    if (days * daily.length > maxPools) {
      throw ArgumentError('Month exceeds explicit pool cap');
    }
    // Resolve each exact recipe once; every serving choice still validates.
    final resolved = <(String, String?), RecipeRevision>{};
    for (final t in template) {
      for (final c in t.choices) {
        final key = (c.recipeId, c.recipeRevisionKey);
        final revision =
            resolved[key] ??
            await _resolveMonthlyCandidate(
              PlannedMeal(
                id: c.id,
                date: period.start,
                slot: t.slot,
                recipeId: c.recipeId,
                servings: c.servings,
                recipeRevisionKey: c.recipeRevisionKey,
              ),
            );
        if (!RecipeRepository.hasConcreteCuisine(revision.recipe.cuisine)) {
          throw StateError('Candidate cuisine requires review');
        }
        revision.recipe.forServings(c.servings); // Unknown yield rejects.
        resolved[key] = revision;
      }
    }
    if (!identical(tail, _tail) || guard != jsonEncode(snapshot)) {
      throw StateError('Kitchen changed; regenerate monthly candidate pools');
    }
    final pools = <String, List<PlannedMeal>>{},
        coverage = <MonthlyBudgetCoverage>[];
    for (var day = 1; day <= days; day++) {
      final date = DateTime.utc(start.year, start.month, day);
      final text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      for (final slot in daily) {
        final t = bySlot[(date.weekday, slot)]!;
        pools['pool:$text:$slot'] = [
          for (final c in t.choices)
            PlannedMeal(
              id: c.id,
              date: text,
              slot: slot,
              recipeId: c.recipeId,
              servings: c.servings,
              recipeRevisionKey:
                  resolved[(c.recipeId, c.recipeRevisionKey)]!.key,
            ),
        ];
        coverage.add(MonthlyBudgetCoverage(text, slot));
      }
    }
    return MonthlyCandidatePools._(pools, coverage);
  }
}
