part of 'kitchen_service.dart';

extension MonthlyPlanAcceptance on KitchenService {
  /// Persists only the exact affordable option explicitly selected from a
  /// current search preview. The selection never changes budget or purchase data.
  Future<List<PlannedMeal>> acceptMonthlyBudgetSearchOption(
    MonthlyBudgetSearchPreview preview, {
    required String optionId,
    required Map<String, String> planIdsByPool,
    bool allowReplaceUncooked = false,
  }) async {
    final planIds = Map<String, String>.of(planIdsByPool);
    if (optionId.trim().isEmpty ||
        planIds.isEmpty ||
        planIds.keys.any((key) => key.trim().isEmpty) ||
        planIds.values.any((id) => id.trim().isEmpty) ||
        planIds.values.toSet().length != planIds.length) {
      throw ArgumentError('Option and unique nonblank plan IDs required');
    }
    void requireFreshPreview() {
      if (!identical(preview._owner, this)) {
        throw StateError('Monthly search preview belongs to another kitchen');
      }
      if (!identical(_tail, preview._writeTail) ||
          jsonEncode(snapshot) != preview._snapshot) {
        throw StateError('Kitchen changed; search again before accepting');
      }
    }

    requireFreshPreview();
    final matching = preview.search.comparison.assessments
        .where((row) => row.option.id == optionId)
        .toList();
    if (matching.length != 1) {
      throw ArgumentError('Option was not evaluated in this search');
    }
    final assessment = matching.single;
    if (!preview.search.eligibleRanked.any(
          (row) => row.option.id == optionId,
        ) ||
        assessment.withinBudget != true) {
      throw StateError(
        'Only a known affordable eligible option can be accepted',
      );
    }
    final coverage = preview.search.requiredCoverage;
    if (coverage == null || !coverage.coversRequired) {
      throw StateError('Explicit complete monthly slot coverage is required');
    }

    final mealsByPool = <String, PlannedMeal>{};
    final seenPools = <String>{};
    for (final selected in assessment.option.meals) {
      final matches = <({String poolId, PlannedMeal meal})>[];
      for (final pool in preview.candidatesByPool.entries) {
        final candidate = pool.value[selected.candidateId];
        if (candidate != null &&
            candidate.date == selected.date &&
            candidate.slot == selected.slot) {
          matches.add((poolId: pool.key, meal: candidate));
        }
      }
      if (matches.length != 1) {
        throw StateError('Selected candidate evidence is missing or ambiguous');
      }
      final evidence = matches.single;
      if (!seenPools.add(evidence.poolId)) {
        throw StateError('An option selected more than one candidate per pool');
      }
      mealsByPool[evidence.poolId] = evidence.meal;
    }
    if (mealsByPool.isEmpty ||
        planIds.length != mealsByPool.length ||
        !planIds.keys.toSet().containsAll(mealsByPool.keys) ||
        !mealsByPool.keys.toSet().containsAll(planIds.keys)) {
      throw ArgumentError(
        'Plan ID mapping must cover exactly the selected pools',
      );
    }

    final prepared = <({PlannedMeal meal, RecipeRevision revision})>[];
    for (final poolId in mealsByPool.keys) {
      final candidate = mealsByPool[poolId]!;
      if (candidate.completed) {
        throw StateError('Completed candidate meals cannot be accepted');
      }
      final expectedKey = candidate.recipeRevisionKey;
      if (expectedKey == null) {
        throw StateError(
          'Search candidate is missing its exact recipe revision',
        );
      }
      // Catalog drafts can be previewed before they have been registered in
      // the recipe book. Rebuild only from the same source ID and verify its
      // deterministic revision key before the one atomic registration/write.
      final revision =
          recipeBook.revisions[expectedKey] ??
          _catalogDraft(await recipes.get(candidate.recipeId));
      if (revision.key != expectedKey ||
          revision.variantId != candidate.recipeId) {
        throw StateError('Selected recipe revision changed; search again');
      }
      prepared.add((
        meal: PlannedMeal(
          id: planIds[poolId]!,
          date: candidate.date,
          slot: candidate.slot,
          recipeId: candidate.recipeId,
          servings: candidate.servings,
          recipeRevisionKey: revision.key,
        ),
        revision: revision,
      ));
    }

    requireFreshPreview();
    await _write((k) {
      if (jsonEncode(k) != preview._snapshot) {
        throw StateError('Kitchen changed; search again before accepting');
      }
      final plans = k['plans'] as List;
      final indices = <int>[];
      for (final entry in prepared) {
        final matches = <int>[];
        for (var i = 0; i < plans.length; i++) {
          if ((plans[i] as Map)['id'] == entry.meal.id) matches.add(i);
        }
        if (matches.length > 1) {
          throw StateError('Duplicate plan ID prevents safe replacement');
        }
        if (matches.isNotEmpty) {
          final existing = PlannedMeal.fromJson(
            Map<String, dynamic>.from(plans[matches.single] as Map),
          );
          if (existing.completed) {
            throw StateError('Cooked plans cannot be replaced');
          }
          if (!allowReplaceUncooked) {
            throw StateError(
              'Plan ID already exists; explicit replacement required',
            );
          }
        }
        indices.add(matches.isEmpty ? -1 : matches.single);
      }
      for (final entry in prepared) {
        if (entry.revision.kind == RecipeRevisionKind.catalog) {
          k['recipeBook'] = _registerCatalog(
            _recipeBook(k),
            entry.revision,
          ).toJson();
        }
      }
      for (var i = 0; i < prepared.length; i++) {
        final index = indices[i];
        if (index < 0) {
          plans.add(prepared[i].meal.toJson());
        } else {
          plans[index] = prepared[i].meal.toJson();
        }
      }
    });
    return List<PlannedMeal>.unmodifiable(prepared.map((entry) => entry.meal));
  }
}
