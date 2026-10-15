import 'dart:convert';

import '../domain/kitchen_core.dart';
import '../domain/purchase_forecast.dart';
import '../domain/monthly_budget_choices.dart';
import '../domain/food_nutrition.dart';
import '../domain/person_nutrition.dart';
import '../domain/recipe_nutrition.dart';
import '../domain/recipe_catalog.dart';
import '../domain/recipe_variants.dart';
import '../domain/imported_recipe_candidate.dart';
import '../domain/personal_recipe_draft.dart';
import '../domain/recipe_library_draft.dart';
import 'recipe_library_repository.dart';
import '../domain/personal_recipe_finalization.dart';
import '../domain/cooking_timer.dart';
import '../domain/market_profile.dart';
import '../domain/models.dart';
import 'recipe_repository.dart';
import 'recipe_reference_repository.dart';
import 'household_measure_repository.dart';
import 'preparation_category_repository.dart';
import 'state_store.dart';

Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
Map<String, dynamic> _fresh() => {
  'version': 1,
  'country': 'EG',
  'members': [],
  'seats': [],
  'inventory': [],
  'leftovers': [],
  'plans': [],
  'history': [],
  'prices': [],
  'purchases': [],
  'budgets': [],
};

/// One state owner for the future UI. Writes are atomic and published only after
/// the existing local/Firestore store succeeds; stale cloud writes still fail.
class KitchenService {
  KitchenService(this.store, this.recipes, {this.legacyUnits = const {}});
  final StateStore store;
  final RecipeRepository recipes;
  final Map<String, String> legacyUnits;
  Map<String, dynamic>? _root;
  Future<void> _tail = Future.value();
  Map<String, dynamic> get snapshot {
    if (_root == null) throw StateError('Load before use');
    return _clone(_root!['kitchen'] as Map<String, dynamic>);
  }

  MarketProfile get market =>
      MarketProfile.fromCode(snapshot['country'] as String?);
  List<InventoryLot> get inventory => List.unmodifiable(
    (snapshot['inventory'] as List).map(
      (v) => InventoryLot.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );
  List<PlannedMeal> get plans => List.unmodifiable(
    (snapshot['plans'] as List).map(
      (v) => PlannedMeal.fromJson(Map<String, dynamic>.from(v as Map)),
    ),
  );

  Future<void> load() async {
    await _tail;
    final root =
        await store.load() ?? {'schema': 1, 'name': '', 'stock': <dynamic>[]};
    if (root['schema'] != 1) {
      throw const FormatException('Unsupported state schema');
    }
    final raw = root['kitchen'];
    final kitchen = raw == null
        ? _fresh()
        : Map<String, dynamic>.from(raw as Map);
    if (root['country'] == 'EG' || root['country'] == 'SA') {
      kitchen['country'] = root['country'];
    }
    if (kitchen['version'] != 1) {
      throw const FormatException('Unsupported kitchen schema');
    }
    if (raw == null) {
      final rows = root['stock'] as List? ?? [];
      final migrated = <Map<String, dynamic>>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i] as Map, id = row['id'] as String;
        final unit = legacyUnits[id];
        if (unit == null) throw StateError('Missing legacy unit for $id');
        migrated.add(
          InventoryLot(
            id: 'legacy-$i',
            ingredientId: id,
            quantity: (row['quantity'] as num).toDouble(),
            unit: unit,
            zone: StorageZone.values.byName(row['zone'] as String),
          ).toJson(),
        );
      }
      kitchen['inventory'] = migrated;
    }
    for (final row in kitchen['inventory'] as List) {
      InventoryLot.fromJson(Map<String, dynamic>.from(row as Map));
    }
    for (final row in kitchen['members'] as List) {
      HouseholdMember.fromJson(Map<String, dynamic>.from(row as Map));
    }
    for (final row in kitchen['plans'] as List) {
      PlannedMeal.fromJson(Map<String, dynamic>.from(row as Map));
    }
    final nutrition = kitchen['nutrition'];
    if (nutrition != null) {
      final n = Map<String, dynamic>.from(nutrition as Map);
      if (n['version'] != 1) {
        throw const FormatException('Unsupported nutrition schema');
      }
      for (final v in (n['profiles'] as Map).values) {
        NutritionPersonProfile.fromJson(Map<String, dynamic>.from(v as Map));
      }
      for (final v in (n['selections'] as Map).values) {
        RecipeFoodSelection.fromJson(Map<String, dynamic>.from(v as Map));
      }
      NutritionLedger.fromJson(Map<String, dynamic>.from(n['ledger'] as Map));
    }
    _personalDraftBook(kitchen);
    final book = _recipeBook(kitchen);
    for (final raw in kitchen['plans'] as List) {
      final meal = PlannedMeal.fromJson(Map<String, dynamic>.from(raw as Map));
      if (meal.recipeRevisionKey != null &&
          book.revisions[meal.recipeRevisionKey]?.variantId != meal.recipeId) {
        throw const FormatException(
          'Planned recipe revision is missing or mismatched',
        );
      }
    }
    root['kitchen'] = kitchen;
    _root = _clone(root);
  }

  Future<void> _write(void Function(Map<String, dynamic>) change) {
    final result = _tail.then((_) async {
      if (_root == null) throw StateError('Load before saving');
      final next = _clone(_root!);
      change(next['kitchen'] as Map<String, dynamic>);
      if (jsonEncode(next) == jsonEncode(_root)) return;
      next['country'] = (next['kitchen'] as Map)['country'];
      // Firestore's current state document has a hard size limit. Keep margin
      // for field overhead and fail without deleting historical records.
      if (utf8.encode(jsonEncode(next)).length > 850000) {
        throw StateError(
          'State archive required before further saves (850KB guard)',
        );
      }
      await store.save(next);
      _root = next;
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Map<String, dynamic> _nutrition(Map<String, dynamic> k) => k.putIfAbsent(
    'nutrition',
    () => <String, dynamic>{
      'version': 1,
      'profiles': <String, dynamic>{},
      'selections': <String, dynamic>{},
      'ledger': NutritionLedger.empty().toJson(),
    },
  ) as Map<String, dynamic>;

  NutritionLedger get nutritionLedger {
    final n = snapshot['nutrition'] as Map?;
    return n == null
        ? NutritionLedger.empty()
        : NutritionLedger.fromJson(
            Map<String, dynamic>.from(n['ledger'] as Map),
          );
  }

  NutritionPersonProfile? nutritionProfile(String memberId) {
    final n = snapshot['nutrition'] as Map?;
    final raw = (n?['profiles'] as Map?)?[memberId];
    return raw == null
        ? null
        : NutritionPersonProfile.fromJson(
            Map<String, dynamic>.from(raw as Map),
          );
  }

  Future<void> saveNutritionProfile(NutritionPersonProfile profile) => _write((
    k,
  ) {
    if (!(k['members'] as List).any((v) => v['id'] == profile.memberId)) {
      throw StateError('Nutrition profile must reference a household member');
    }
    (_nutrition(k)['profiles'] as Map)[profile.memberId] = profile.toJson();
  });

  static void _validatePersonalDraft(PersonalRecipeDraft draft) {
    for (final line in draft.lines) {
      final preparation = line.input.preparation;
      if (preparation != null &&
          PreparationCategoryRepository.isCategoryEstimate(preparation)) {
        throw StateError(
          'Review preparation for this new draft separately; '
          'a category acceptance scoped to a recipe cannot be copied',
        );
      }
    }
  }

  Map<String, dynamic> _personalDraftBook(Map<String, dynamic> k) {
    if (k['personalRecipeDrafts'] == null) {
      return {
        'version': 1,
        'revisions': <String, dynamic>{},
        'active': <String, dynamic>{},
      };
    }
    final book = Map<String, dynamic>.from(k['personalRecipeDrafts'] as Map);
    if (book['version'] != 1 ||
        book['revisions'] is! Map ||
        book['active'] is! Map) {
      throw const FormatException('Personal recipe draft book version');
    }
    final drafts = <String, PersonalRecipeDraft>{};
    for (final entry in (book['revisions'] as Map).entries) {
      final record = entry.value as Map;
      final draft = PersonalRecipeDraft.fromJson(
        Map<String, dynamic>.from(record['draft'] as Map),
      );
      _validatePersonalDraft(draft);
      final at = DateTime.tryParse(record['reviewedAt'] as String? ?? '');
      if (entry.key != draft.key ||
          record['acknowledgeInputsReviewed'] != true ||
          record['reviewNote'] is! String ||
          (record['reviewNote'] as String).trim().isEmpty ||
          at == null ||
          !at.isUtc ||
          at.toIso8601String() != record['reviewedAt']) {
        throw const FormatException('Invalid personal draft review');
      }
      if (record['librarySource'] != null) {
        final origin = RecipeLibraryDraftReview.fromJson(
          Map<String, dynamic>.from(record['librarySource'] as Map),
        );
        if (origin.draft.fingerprint != draft.fingerprint) {
          throw const FormatException('Library source and draft differ');
        }
      }
      drafts[entry.key as String] = draft;
    }
    final active = book['active'] as Map;
    for (final entry in active.entries) {
      if (drafts[entry.value]?.id != entry.key) {
        throw const FormatException(
          'Missing or mismatched active personal draft',
        );
      }
    }
    if (drafts.values.any((v) => !active.containsKey(v.id))) {
      throw const FormatException('Personal draft active version missing');
    }
    return book;
  }

  List<PersonalRecipeDraft> get personalRecipeDrafts => List.unmodifiable(
    (_personalDraftBook(snapshot)['revisions'] as Map).values.map(
      (v) => PersonalRecipeDraft.fromJson(
        Map<String, dynamic>.from(v['draft'] as Map),
      ),
    ),
  );

  PersonalRecipeDraft? personalRecipeDraft(String id, {String? revisionKey}) {
    final book = _personalDraftBook(snapshot);
    final key = revisionKey ?? (book['active'] as Map)[id];
    final raw = (book['revisions'] as Map)[key];
    if (raw == null) return null;
    final result = PersonalRecipeDraft.fromJson(
      Map<String, dynamic>.from(raw['draft'] as Map),
    );
    if (result.id != id) throw StateError('Personal draft identity mismatch');
    return result;
  }

  /// User-owned drafts created from scratch. No catalog parent, guessed timing,
  /// scientific approval, planning, stock write or person consumption implied.
  Future<void> savePersonalRecipeDraft(
    PersonalRecipeDraft submitted, {
    required bool acknowledgeInputsReviewed,
    required String reviewNote,
    required DateTime reviewedAt,
    String? expectedActiveKey,
  }) => _saveReviewedPersonalDraft(
    submitted,
    acknowledgeInputsReviewed: acknowledgeInputsReviewed,
    reviewNote: reviewNote,
    reviewedAt: reviewedAt,
    expectedActiveKey: expectedActiveKey,
  );

  /// Private calculator only. Source rights and planning approval stay pending.
  Future<void> saveLibraryRecipeDraft(
    RecipeLibraryDraftReview submitted, {
    required RecipeLibraryRepository library,
    required bool acknowledgeInputsReviewed,
    required String reviewNote,
    required DateTime reviewedAt,
    String? expectedActiveKey,
  }) async {
    final review = RecipeLibraryDraftReview.fromJson(submitted.toJson());
    final entries = (await library.all())
        .where((e) => e.id == review.libraryEntryId)
        .toList();
    if (entries.length != 1) throw StateError('Current library source missing');
    review.assertSource(entries.single);
    await _saveReviewedPersonalDraft(
      review.draft,
      acknowledgeInputsReviewed: acknowledgeInputsReviewed,
      reviewNote: reviewNote,
      reviewedAt: reviewedAt,
      expectedActiveKey: expectedActiveKey,
      sourceReview: review,
    );
  }

  RecipeLibraryDraftReview? libraryRecipeDraftReview(
    String id, {
    String? revisionKey,
  }) {
    final draft = personalRecipeDraft(id, revisionKey: revisionKey);
    if (draft == null) return null;
    final record =
        (_personalDraftBook(snapshot)['revisions'] as Map)[draft.key];
    if (record['librarySource'] == null) return null;
    return RecipeLibraryDraftReview.fromJson(
      Map<String, dynamic>.from(record['librarySource'] as Map),
    );
  }

  Future<void> _saveReviewedPersonalDraft(
    PersonalRecipeDraft submitted, {
    required bool acknowledgeInputsReviewed,
    required String reviewNote,
    required DateTime reviewedAt,
    String? expectedActiveKey,
    RecipeLibraryDraftReview? sourceReview,
  }) async {
    if (!acknowledgeInputsReviewed ||
        reviewNote.trim().isEmpty ||
        (expectedActiveKey != null && expectedActiveKey.trim().isEmpty)) {
      throw ArgumentError('Explicit personal ingredient review required');
    }
    final draft = PersonalRecipeDraft.fromJson(submitted.toJson());
    _validatePersonalDraft(draft);
    final record = {
      'draft': draft.toJson(),
      if (sourceReview != null) 'librarySource': sourceReview.toJson(),
      'acknowledgeInputsReviewed': true,
      'reviewNote': reviewNote.trim(),
      'reviewedAt': reviewedAt.toUtc().toIso8601String(),
    };
    await _write((k) {
      final book = _personalDraftBook(k);
      final revisions = book['revisions'] as Map,
          active = book['active'] as Map;
      final existing = revisions[draft.key];
      if (existing != null) {
        final prior = PersonalRecipeDraft.fromJson(
          Map<String, dynamic>.from(existing['draft'] as Map),
        );
        if (prior.fingerprint != draft.fingerprint ||
            existing['acknowledgeInputsReviewed'] != true ||
            existing['reviewNote'] != record['reviewNote'] ||
            existing['reviewedAt'] != record['reviewedAt'] ||
            (existing['librarySource'] == null
                    ? null
                    : RecipeLibraryDraftReview.fromJson(
                        Map<String, dynamic>.from(
                          existing['librarySource'] as Map,
                        ),
                      ).fingerprint) !=
                sourceReview?.fingerprint) {
          throw StateError('Personal draft revision is immutable');
        }
        // An old identical retry must never reactivate an earlier version.
        return;
      }
      if (active[draft.id] != expectedActiveKey) {
        throw StateError('Personal draft active revision changed;review again');
      }
      if (sourceReview == null &&
          active[draft.id] != null &&
          revisions[active[draft.id]]['librarySource'] != null) {
        throw StateError('Retain library provenance when revising this draft');
      }
      revisions[draft.key] = record;
      active[draft.id] = draft.key;
      k['personalRecipeDrafts'] = book;
    });
  }

  RecipeNutritionResult previewPersonalRecipeIngredients(
    String id, {
    String? revisionKey,
    double? servings,
  }) {
    final draft = personalRecipeDraft(id, revisionKey: revisionKey);
    if (draft == null) throw StateError('Personal recipe draft missing');
    return draft.previewIngredients(servings: servings);
  }

  RecipeNutritionResult previewPersonalRecipeCooked(
    String id, {
    String? revisionKey,
    double? servings,
    double? cookedYieldGrams,
  }) {
    final draft = personalRecipeDraft(id, revisionKey: revisionKey);
    if (draft == null) throw StateError('Personal recipe draft missing');
    return draft.previewCooked(
      servings: servings,
      cookedYieldGrams: cookedYieldGrams,
    );
  }

  RecipeBook _recipeBook(Map<String, dynamic> k) => k['recipeBook'] == null
      ? RecipeBook.empty()
      : RecipeBook.fromJson(Map<String, dynamic>.from(k['recipeBook'] as Map));

  RecipeBook get recipeBook => _recipeBook(snapshot);

  RecipeRevision _catalogDraft(CatalogRecipe recipe) => RecipeRevision(
    familyId: 'dish:${recipe.id}',
    revision: recipeSnapshotVersion(recipe),
    kind: RecipeRevisionKind.catalog,
    recipe: recipe,
  );

  RecipeBook _registerCatalog(RecipeBook book, RecipeRevision revision) {
    if (!book.families.containsKey(revision.familyId)) {
      book = book.addFamily(
        RecipeFamily(id: revision.familyId, name: revision.recipe.name),
      );
    }
    return book.addRevision(revision);
  }

  Future<RecipeRevision> catalogRevision(String recipeId) async {
    final revision = _catalogDraft(await recipes.get(recipeId));
    await _write((k) {
      k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
    });
    return revision;
  }

  Future<void> saveRecipeFamily(RecipeFamily family) => _write((k) {
    k['recipeBook'] = _recipeBook(k).addFamily(family).toJson();
  });

  /// Explicit selected import only: source envelope retained, no inherited food bindings.
  Future<RecipeRevision> importSourceRecipe({
    required ImportedRecipeCandidate candidate,
    required String reviewNote,
    required DateTime reviewedAt,
    required bool acknowledgeSourceLicenseAndInstructions,
    required bool acknowledgeNutritionUnreviewed,
  }) async {
    final review = SourceRecipeImportReview(
      candidate: candidate,
      note: reviewNote,
      reviewedAt: reviewedAt,
      acknowledgeSourceLicenseAndInstructions:
          acknowledgeSourceLicenseAndInstructions,
      acknowledgeNutritionUnreviewed: acknowledgeNutritionUnreviewed,
    );
    final draft = RecipeRevision(
      familyId: sourceImportFamilyId(review.candidate),
      revision: sourceImportRevisionId(review.candidate),
      kind: RecipeRevisionKind.imported,
      recipe: review.candidate.recipe,
      sourceImportReview: review,
    );
    if ((await recipes.index).any((v) => v['id'] == draft.variantId)) {
      throw StateError(
        'Source import cannot overwrite a shipping catalog identity',
      );
    }
    await _write((k) {
      var book = _recipeBook(k);
      if (!book.families.containsKey(draft.familyId)) {
        book = book.addFamily(
          RecipeFamily(id: draft.familyId, name: draft.recipe.name),
        );
      }
      k['recipeBook'] = book.addRevision(draft).toJson();
    });
    return draft;
  }

  /// Publish a persisted active draft and its explicit food snapshots atomically.
  /// No parent, stock deduction, person intake or automatic health approval.
  Future<RecipeRevision> finalizePersonalRecipe(
    PersonalRecipeFinalization submitted, {
    String? expectedActiveRecipeKey,
  }) async {
    final review = PersonalRecipeFinalization.fromJson(submitted.toJson());
    final revision = RecipeRevision(
      familyId: review.familyId,
      revision: review.revisionId,
      kind: RecipeRevisionKind.authored,
      recipe: review.recipe,
      authoredReview: review,
    );
    if ((await recipes.index).any((v) => v['id'] == revision.variantId)) {
      throw StateError('Personal recipe cannot overwrite catalog identity');
    }
    await _write((k) {
      var book = _recipeBook(k);
      if (book.revisions.containsKey(revision.key)) {
        book.addRevision(
          revision,
        ); // Validate exact retry, never reactivate/rebind.
        return;
      }
      final drafts = _personalDraftBook(k);
      final stored = (drafts['revisions'] as Map)[review.draft.key];
      if (stored == null ||
          PersonalRecipeDraft.fromJson(
                Map<String, dynamic>.from(stored['draft'] as Map),
              ).fingerprint !=
              review.draft.fingerprint ||
          (drafts['active'] as Map)[review.draft.id] != review.draft.key ||
          book.active[revision.variantId] != expectedActiveRecipeKey) {
        throw StateError(
          'Draft or active recipe changed;review finalization again',
        );
      }
      if (stored['librarySource'] != null) {
        throw StateError(
          'Review source import and rights before planning this library recipe',
        );
      }
      if (!book.families.containsKey(revision.familyId)) {
        book = book.addFamily(
          RecipeFamily(id: revision.familyId, name: review.recipe.name),
        );
      }
      book = book.addRevision(revision);
      final selections = _nutrition(k)['selections'] as Map;
      for (final selection in review.selectionsFor(revision.key)) {
        _validatePreparationSelection(selection);
        selections[selection.key] = selection.toJson();
      }
      k['recipeBook'] = book.toJson();
    });
    return revision;
  }

  Future<void> saveRecipeRevision(RecipeRevision revision) async {
    if (revision.kind == RecipeRevisionKind.authored) {
      throw StateError(
        'Use explicit finalizePersonalRecipe for draft publication',
      );
    }
    if (revision.kind == RecipeRevisionKind.imported) {
      throw StateError(
        'Use explicit importSourceRecipe for source import review',
      );
    }
    if (revision.kind == RecipeRevisionKind.catalog ||
        (await recipes.index).any((v) => v['id'] == revision.variantId)) {
      throw StateError('Custom recipes cannot overwrite catalog identities');
    }
    await _write((k) {
      k['recipeBook'] = _recipeBook(k).addRevision(revision).toJson();
    });
  }

  /// New personal revision only: no implicit food bindings, replanning or ratios.
  Future<RecipeRevision> splitRecipeIngredient({
    required String sourceRevisionKey,
    required int line,
    required List<CatalogIngredient> components,
    required String variantId,
    required String revision,
    required String reviewNote,
    required DateTime reviewedAt,
    required bool acknowledgeCompleteReplacement,
  }) async {
    final source = recipeBook.revisions[sourceRevisionKey];
    if (source == null) {
      throw StateError('Register and review exact source revision first');
    }
    final draft = buildIngredientSplitRevision(
      source: source,
      line: line,
      components: components,
      variantId: variantId,
      revision: revision,
      reviewNote: reviewNote,
      reviewedAt: reviewedAt,
      acknowledgeCompleteReplacement: acknowledgeCompleteReplacement,
    );
    await saveRecipeRevision(draft);
    return draft;
  }

  /// Explicit new personal revision: one quantified replacement, no inherited bindings.
  Future<RecipeRevision> chooseRecipeIngredient({
    required String sourceRevisionKey,
    required int line,
    required CatalogIngredient selected,
    required String variantId,
    required String revision,
    required String reviewNote,
    required DateTime reviewedAt,
    required bool acknowledgeCompleteReplacement,
  }) async {
    final source = recipeBook.revisions[sourceRevisionKey];
    if (source == null) {
      throw StateError('Register and review exact source revision first');
    }
    final draft = buildIngredientChoiceRevision(
      source: source,
      line: line,
      selected: selected,
      variantId: variantId,
      revision: revision,
      reviewNote: reviewNote,
      reviewedAt: reviewedAt,
      acknowledgeCompleteReplacement: acknowledgeCompleteReplacement,
    );
    await saveRecipeRevision(draft);
    return draft;
  }

  Future<RecipeRevision> _resolveMeal(PlannedMeal meal) async {
    final book = recipeBook;
    if (meal.recipeRevisionKey != null) {
      final revision = book.revisions[meal.recipeRevisionKey];
      if (revision == null || revision.variantId != meal.recipeId) {
        throw StateError('Unknown or mismatched recipe revision');
      }
      return revision;
    }
    final active = book.revisions[book.active[meal.recipeId]];
    if (active != null && active.kind != RecipeRevisionKind.catalog) {
      return active;
    }
    return _catalogDraft(await recipes.get(meal.recipeId));
  }

  Future<RecipeRevision> recipeForMeal(String planId) =>
      _resolveMeal(plans.where((v) => v.id == planId).single);

  static void _validatePreparationSelection(RecipeFoodSelection selection) {
    final preparation = selection.preparation;
    if (preparation == null ||
        !PreparationCategoryRepository.isCategoryEstimate(preparation)) {
      return;
    }
    PreparationCategoryRepository.validateAccepted(selection.food, preparation);
    final evidence = jsonDecode(preparation.evidence!) as Map;
    if (selection.recipeRevisionKey == null ||
        evidence['recipeRevisionKey'] != selection.recipeRevisionKey ||
        evidence['recipeId'] != selection.recipeId ||
        evidence['line'] != selection.line ||
        selection.amountForm != selection.food.form ||
        selection.preparedForm != FoodForm.cooked ||
        selection.asPurchased ||
        selection.notConsumed) {
      throw const FormatException('Invalid recipe-scoped preparation estimate');
    }
  }

  /// Frozen category inference, never an exact-food or finished-dish approval.
  /// Changing method replaces the single transform; factors are never layered.
  Future<void> acceptRecipePreparationEstimate(
    String planId,
    PreparationCategoryRepository preparations, {
    required int line,
    required String retentionCode,
    required String reviewNote,
    required DateTime acceptedAt,
    required bool acknowledgeCategoryEstimate,
    required bool acknowledgeUnknownLicense,
    bool replaceExisting = false,
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    if (meal.completed) throw StateError('Cannot change cooked preparation');
    final revision = await _resolveMeal(meal);
    if (line < 0 || line >= revision.recipe.ingredients.length) {
      throw RangeError('Recipe line');
    }
    final selected = _foodSelections(
      snapshot,
      revision,
    ).where((v) => v.line == line).single;
    if (selected.asPurchased ||
        selected.notConsumed ||
        selected.amountForm != selected.food.form) {
      throw StateError('Review edible input food form before preparation');
    }
    if (!replaceExisting && selected.preparation != null) {
      throw StateError('Explicit replacement of preparation required');
    }
    final before = jsonEncode(selected.toJson());
    final transform = await preparations.accept(
      selected.food,
      retentionCode: retentionCode,
      reviewNote: reviewNote,
      acceptedAt: acceptedAt,
      acknowledgeCategoryEstimate: acknowledgeCategoryEstimate,
      acknowledgeUnknownLicense: acknowledgeUnknownLicense,
    );
    final scoped = PreparationTransform.fromJson({
      ...transform.toJson(),
      'evidence': jsonEncode({
        ...jsonDecode(transform.evidence!) as Map<String, dynamic>,
        'recipeId': revision.variantId,
        'recipeRevisionKey': revision.key,
        'line': line,
      }),
    });
    final accepted = RecipeFoodSelection.fromJson({
      ...selected.toJson(),
      'preparation': scoped.toJson(),
      'preparedForm': FoodForm.cooked.name,
    });
    _validatePreparationSelection(accepted);
    await _write((k) {
      final current = (k['plans'] as List)
          .where((v) => v['id'] == planId)
          .single;
      final choices = _nutrition(k)['selections'] as Map;
      if (current['completed'] == true ||
          current['recipeRevisionKey'] != revision.key ||
          current['recipeId'] != meal.recipeId ||
          current['servings'] != meal.servings ||
          jsonEncode(
                choices[selected.key] == null
                    ? null
                    : RecipeFoodSelection.fromJson(
                        Map<String, dynamic>.from(choices[selected.key] as Map),
                      ).toJson(),
              ) !=
              before) {
        throw StateError(
          'Plan or food binding changed during preparation review',
        );
      }
      choices[accepted.key] = accepted.toJson();
    });
  }

  Future<void> saveRecipeFoodSelection(RecipeFoodSelection selection) async {
    _validatePreparationSelection(selection);
    final revision = selection.recipeRevisionKey == null
        ? _catalogDraft(await recipes.get(selection.recipeId))
        : recipeBook.revisions[selection.recipeRevisionKey];
    if (revision == null || revision.variantId != selection.recipeId) {
      throw StateError('Selection must reference the exact recipe revision');
    }
    if (selection.line >= revision.recipe.ingredients.length) {
      throw RangeError('Recipe line');
    }
    final scoped = RecipeFoodSelection.fromJson({
      ...selection.toJson(),
      'recipeRevisionKey': revision.key,
    });
    await _write((k) {
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      (_nutrition(k)['selections'] as Map)[scoped.key] = scoped.toJson();
    });
  }

  /// Accepts an equivalent BASE recipe portion, never a weighed actual use.
  /// Source estimates need a separate acknowledgement at cooking confirmation.
  Future<void> acceptRecipeHouseholdMeasure(
    String planId,
    HouseholdMeasureRepository measures, {
    required int line,
    required String optionId,
    required double measureQuantity,
    required bool acknowledgeExactSourcePortion,
    bool replaceExisting = false,
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    if (meal.completed) throw StateError('Cannot change a cooked meal measure');
    final revision = await _resolveMeal(meal);
    if (line < 0 || line >= revision.recipe.ingredients.length) {
      throw RangeError('Recipe line');
    }
    final selected = _foodSelections(
      snapshot,
      revision,
    ).where((v) => v.line == line).single;
    if (selected.asPurchased ||
        selected.notConsumed ||
        selected.amountForm != selected.food.form) {
      throw StateError(
        'Review exact edible food form before source measure acceptance',
      );
    }
    final unit = nutritionUnit(revision.recipe.ingredients[line].unit);
    if ([
      FoodQuantityUnit.g,
      FoodQuantityUnit.kg,
      FoodQuantityUnit.ml,
      FoodQuantityUnit.l,
    ].contains(unit)) {
      throw StateError(
        'Mass/volume line already quantified; review a new recipe revision',
      );
    }
    if (!replaceExisting &&
        (selected.householdMeasureEvidence != null ||
            selected.measuredAmount != null)) {
      throw StateError('Explicit replacement of an accepted quantity required');
    }
    final before = jsonEncode(selected.toJson());
    final proposal = await measures.resolve(
      selected.food,
      optionId: optionId,
      measureQuantity: measureQuantity,
      acknowledgeExactSourcePortion: acknowledgeExactSourcePortion,
    );
    final accepted = RecipeFoodSelection.fromJson({
      ...selected.toJson(),
      'measuredAmount': null,
      'householdMeasureEvidence': jsonEncode({
        ...proposal.toJson(),
        'recipeRevisionKey': revision.key,
        'line': line,
        'acceptedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    });
    await _write((k) {
      final current = (k['plans'] as List)
          .where((v) => v['id'] == planId)
          .single;
      final choices = _nutrition(k)['selections'] as Map;
      if (current['completed'] == true ||
          current['recipeRevisionKey'] != revision.key ||
          current['servings'] != meal.servings ||
          jsonEncode(
                choices[selected.key] == null
                    ? null
                    : RecipeFoodSelection.fromJson(
                        Map<String, dynamic>.from(choices[selected.key] as Map),
                      ).toJson(),
              ) !=
              before) {
        throw StateError(
          'Plan or food binding changed during source measure review',
        );
      }
      choices[accepted.key] = accepted.toJson();
    });
  }

  /// Resolve outside the transaction, then atomically save exact revision bindings.
  /// Existing user-reviewed selections are preserved unless replacement is explicit.
  Future<RecipeReferenceApplication> applyRecipeReferences(
    String planId,
    RecipeReferenceRepository references, {
    required bool acknowledgeGenericReferences,
    Map<int, String> choices = const {},
    bool replaceExisting = false,
  }) async {
    final submittedChoices = Map<int, String>.from(choices);
    final meal = plans.where((v) => v.id == planId).single;
    if (meal.completed) {
      throw StateError('Cannot change a cooked meal reference review');
    }
    final revision = await _resolveMeal(meal);
    final resolution = await references.resolve(
      revision,
      acknowledgeGenericReferences: acknowledgeGenericReferences,
      choices: submittedChoices,
    );
    final applied = <int>[], preserved = <int>[];
    if (resolution.selections.isNotEmpty) {
      await _write((k) {
        final current = (k['plans'] as List)
            .where((v) => v['id'] == planId)
            .single;
        if (current['completed'] == true ||
            current['recipeRevisionKey'] != revision.key) {
          throw StateError('Plan changed during reference review');
        }
        final selections = _nutrition(k)['selections'] as Map;
        for (final selection in resolution.selections) {
          if (selections.containsKey(selection.key) && !replaceExisting) {
            preserved.add(selection.line);
          } else {
            selections[selection.key] = selection.toJson();
            applied.add(selection.line);
          }
        }
      });
    }
    return RecipeReferenceApplication(
      resolution: resolution,
      appliedLines: applied,
      preservedLines: preserved,
    );
  }

  List<RecipeFoodSelection> _foodSelections(
    Map<String, dynamic> k,
    RecipeRevision revision,
  ) {
    final n = k['nutrition'] as Map?;
    return ((n?['selections'] as Map?)?.values ?? const [])
        .map(
          (v) =>
              RecipeFoodSelection.fromJson(Map<String, dynamic>.from(v as Map)),
        )
        .where(
          (v) =>
              v.recipeId == revision.variantId &&
              v.recipeRevisionKey == revision.key,
        )
        .map((v) {
          _validatePreparationSelection(v);
          return v;
        })
        .toList();
  }

  Future<RecipeNutritionResult> previewNutrition(
    String planId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Set<int> excludedLines = const {},
    Map<int, FoodAmount> measuredLines = const {},
    double? cookedYieldGrams,
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    final revision = await _resolveMeal(meal);
    return assessRecipeNutrition(
      scaled: revision.recipe.forServings(meal.servings),
      selections: _foodSelections(snapshot, revision),
      recipeRevisionKey: revision.key,
      optionalIds: optionalIds,
      optionalLines: optionalLines,
      excludedLines: excludedLines,
      measuredLines: measuredLines,
      cookedYieldGrams: cookedYieldGrams,
    );
  }

  /// A separate input-only estimate; never used for cooked history or intake.
  /// Quantity form is preserved: cooked weights cannot be reinterpreted as raw.
  Future<IngredientNutritionEstimate> previewIngredientNutrition(
    String planId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Set<int> excludedLines = const {},
    Map<int, FoodAmount> measuredLines = const {},
  }) async {
    final meal = plans.where((v) => v.id == planId).single;
    final revision = await _resolveMeal(meal);
    final inputs = _foodSelections(snapshot, revision)
        .map(
          (v) => RecipeFoodSelection.fromJson({
            ...v.toJson(),
            'preparedForm': v.food.form.name,
            'preparation': null,
          }),
        )
        .toList();
    return IngredientNutritionEstimate(
      assessRecipeNutrition(
        scaled: revision.recipe.forServings(meal.servings),
        selections: inputs,
        recipeRevisionKey: revision.key,
        optionalIds: optionalIds,
        optionalLines: optionalLines,
        excludedLines: excludedLines,
        measuredLines: measuredLines,
      ),
    );
  }

  /// Product snacks and planned meal batches may be explicitly registered.
  /// Cooked recipe batches are created atomically by confirmCooking instead.
  Future<void> recordNutritionEvents({
    MealBatch? batch,
    required List<NutritionEvent> events,
  }) => _write((k) {
    final n = _nutrition(k);
    var ledger = NutritionLedger.fromJson(
      Map<String, dynamic>.from(n['ledger'] as Map),
    );
    if (batch != null) ledger = ledger.addBatch(batch);
    for (final event in events) {
      if (event.personId != null &&
          !(k['members'] as List).any((v) => v['id'] == event.personId) &&
          !ledger.events.any((v) => v.personId == event.personId)) {
        throw StateError('Unknown nutrition person');
      }
      ledger = ledger.append(event);
    }
    n['ledger'] = ledger.toJson();
  });

  Future<void> saveTimer(String id, CookingTimer timer) => _write((k) {
    if (id.isEmpty) throw ArgumentError('Missing timer ID');
    final timers = k.putIfAbsent('timers', () => <String, dynamic>{}) as Map;
    timers[id] = timer.toJson();
  });

  CookingTimer? timer(String id, DateTime now) {
    final timers = snapshot['timers'] as Map?;
    final value = timers?[id];
    return value == null
        ? null
        : CookingTimer.fromJson(Map<String, dynamic>.from(value as Map))
              .at(now);
  }

  Future<void> setCountry(MarketCountry country) =>
      _write((k) => k['country'] = MarketProfile(country).code);

  Future<void> saveMember(HouseholdMember member) => _write((k) {
    final members = k['members'] as List,
        index = members.indexWhere((v) => v['id'] == member.id);
    final seats = k['seats'] as List;
    while (seats.length < 3) {
      seats.add(null);
    }
    if (index < 0) {
      members.add(member.toJson());
      final empty = seats.indexOf(null);
      if (empty < 0) {
        seats.add(member.id);
      } else {
        seats[empty] = member.id;
      }
    } else {
      members[index] = member.toJson();
    }
  });

  Future<void> swapSeats(int a, int b) => _write((k) {
    final seats = k['seats'] as List;
    if (a < 0 || b < 0 || a >= seats.length || b >= seats.length) {
      throw RangeError('Seat index');
    }
    final old = seats[a];
    seats[a] = seats[b];
    seats[b] = old;
  });

  Future<void> removeMember(String id) => _write((k) {
    (k['members'] as List).removeWhere((v) => v['id'] == id);
    final seats = k['seats'] as List;
    for (var i = 0; i < seats.length; i++) {
      if (seats[i] == id) seats[i] = null;
    }
  });

  Future<void> addStock(
    InventoryLot lot, {
    required bool newPurchase,
    double? paid,
    DateTime? purchasedAt,
  }) => _write((k) {
    final items = k['inventory'] as List;
    if (items.any((v) => v['id'] == lot.id)) {
      throw StateError('Stock lot already exists');
    }
    if (items.length >= 1000) throw StateError('Inventory limit reached');
    if (newPurchase) {
      if (paid == null || purchasedAt == null) {
        throw ArgumentError('Confirm purchase amount and date');
      }
      final entry = MoneyEntry(
        id: 'purchase-${lot.id}',
        amount: paid,
        country: MarketProfile.fromCode(k['country'] as String).country,
        date: purchasedAt,
        note: lot.ingredientId,
      );
      (k['purchases'] as List).add(entry.toJson());
    }
    items.add(lot.toJson());
  });

  Future<void> setStockQuantity(String lotId, double? quantity) => _write((k) {
    if (quantity != null) requireAmount(quantity, zero: true);
    final row =
        (k['inventory'] as List).where((v) => v['id'] == lotId).single as Map;
    row['quantity'] = quantity;
  });

  Future<void> saveLeftover(LeftoverDish dish) => _write((k) {
    final list = k['leftovers'] as List,
        index = list.indexWhere((v) => v['id'] == dish.id);
    if (index < 0) {
      list.add(dish.toJson());
    } else {
      list[index] = dish.toJson();
    }
  });
  Future<void> consumeLeftover(String id, double servings) => _write((k) {
    requireAmount(servings);
    final row =
        (k['leftovers'] as List).where((v) => v['id'] == id).single as Map;
    final available = (row['servings'] as num).toDouble();
    if (available < servings) throw StateError('Insufficient leftovers');
    row['servings'] = available - servings;
  });

  Future<void> plan(PlannedMeal meal) async {
    final revision = await _resolveMeal(meal);
    final pinned = meal.withRecipeRevision(revision.key);
    await _write((k) {
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      final plans = k['plans'] as List,
          index = plans.indexWhere((v) => v['id'] == meal.id);
      if (meal.completed || (index >= 0 && plans[index]['completed'] == true)) {
        throw StateError('Cannot replace a cooked meal');
      }
      if (index < 0) {
        plans.add(pinned.toJson());
      } else {
        plans[index] = pinned.toJson();
      }
    });
  }

  Future<void> removePlan(String id) => _write((k) {
    final list = k['plans'] as List;
    if (list.any((v) => v['id'] == id && v['completed'] == true)) {
      throw StateError('Cannot remove cooking history');
    }
    list.removeWhere((v) => v['id'] == id);
  });
  List<PlannedMeal> calendar(DateTime date, CalendarMode mode) =>
      plans.where((p) => CalendarRange(date, mode).includes(p.date)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> savePrice(MarketPrice price, {required bool userOverride}) =>
      _write((k) {
        final list = k['prices'] as List;
        list.removeWhere(
          (v) =>
              v['country'] == price.country.name &&
              v['ingredientId'] == price.ingredientId &&
              v['unit'] == Units.canonical(price.unit) &&
              v['override'] == userOverride,
        );
        list.add({
          'country': price.country.name,
          'ingredientId': price.ingredientId,
          'unit': Units.canonical(price.unit),
          'quantity': price.quantity,
          'amount': price.amount,
          'date': price.recordedAt.toIso8601String(),
          'source': price.source,
          'override': userOverride,
        });
      });
  static double? _cost(
    Map<String, dynamic> k,
    IngredientUse use,
    List<UnitRule> rules,
  ) {
    final market = MarketProfile.fromCode(k['country'] as String).country.name;
    final prices =
        (k['prices'] as List)
            .where(
              (v) =>
                  v['country'] == market &&
                  v['ingredientId'] == use.ingredientId,
            )
            .toList()
          ..sort(
            (a, b) => (b['override'] == true ? 1 : 0).compareTo(
              a['override'] == true ? 1 : 0,
            ),
          );
    for (final p in prices) {
      final amount = Units.convert(
        use.quantity,
        use.unit,
        p['unit'] as String,
        ingredientId: use.ingredientId,
        rules: rules,
      );
      if (amount != null) {
        return amount / (p['quantity'] as num) * (p['amount'] as num);
      }
    }
    return null;
  }

  double? estimatedCost(IngredientUse use, {List<UnitRule> rules = const []}) =>
      _cost(snapshot, use, rules);

  // Shared by plan and advisory previews so explicit line decisions, scaling
  // and unknown requirements retain identical semantics.
  MonthlyBudgetMeal _purchasePreviewMeal(
    PlannedMeal meal,
    RecipeRevision revision, {
    Set<int> optionalLines = const {},
    Map<int, IngredientUse> measuredLines = const {},
  }) {
    final scaled = revision.recipe.forServings(meal.servings);
    final rows = scaled.recipe.ingredients;
    bool validLine(int line) => line >= 0 && line < rows.length;
    if (optionalLines.any((line) => !validLine(line) || !rows[line].optional) ||
        measuredLines.entries.any(
          (entry) =>
              !validLine(entry.key) ||
              scaled.quantity(rows[entry.key]) != null ||
              entry.value.ingredientId != rows[entry.key].id ||
              (rows[entry.key].optional && !optionalLines.contains(entry.key)),
        )) {
      throw ArgumentError('Invalid or ignored forecast line decision');
    }
    final uses = <IngredientUse>[], unresolved = <String>{};
    for (var line = 0; line < rows.length; line++) {
      final ingredient = rows[line];
      if (ingredient.optional && !optionalLines.contains(line)) continue;
      final quantity = scaled.quantity(ingredient);
      final explicit = measuredLines[line];
      if (explicit != null) {
        uses.add(explicit);
      } else if (quantity == null) {
        unresolved.add('${meal.id}:$line:${ingredient.id}');
      } else {
        uses.add(IngredientUse(ingredient.id, quantity, ingredient.unit!));
      }
    }
    return MonthlyBudgetMeal(
      date: meal.date,
      slot: meal.slot,
      candidateId: revision.key,
      requirements: uses,
      unresolvedRequirements: unresolved,
    );
  }

  Future<PurchaseForecast> previewPurchases(
    Iterable<String> planIds, {
    List<UnitRule> rules = const [],
    Map<String, Set<int>> optionalLinesByPlan = const {},
    Map<String, Map<int, IngredientUse>> measuredByPlan = const {},
  }) async {
    final ids = List<String>.of(planIds);
    final ownedRules = List<UnitRule>.of(rules);
    final optionals = {
      for (final entry in optionalLinesByPlan.entries)
        entry.key: Set<int>.of(entry.value),
    };
    final measured = {
      for (final entry in measuredByPlan.entries)
        entry.key: Map<int, IngredientUse>.of(entry.value),
    };
    if (ids.toSet().length != ids.length ||
        optionals.keys.any((id) => !ids.contains(id)) ||
        measured.keys.any((id) => !ids.contains(id))) {
      throw ArgumentError('Duplicate plans or decisions for unselected plans');
    }
    await _tail;
    final k = snapshot;
    final guard = jsonEncode(k);
    final allPlans = (k['plans'] as List)
        .map(
          (row) => PlannedMeal.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    final selected = <PlannedMeal>[];
    for (final id in ids) {
      final matches = allPlans.where((meal) => meal.id == id).toList();
      if (matches.length != 1) {
        throw ArgumentError('Unknown or ambiguous plan: $id');
      }
      if (matches.single.completed) {
        throw StateError('Cannot forecast a completed plan');
      }
      selected.add(matches.single);
    }
    final uses = <IngredientUse>[], unresolved = <String>{};
    for (final meal in selected) {
      final revision = await _resolveMeal(meal);
      final preview = _purchasePreviewMeal(
        meal,
        revision,
        optionalLines: optionals[meal.id] ?? const {},
        measuredLines: measured[meal.id] ?? const {},
      );
      uses.addAll(preview.requirements);
      unresolved.addAll(preview.unresolvedRequirements);
    }
    await _tail;
    if (jsonEncode(snapshot) != guard) {
      throw StateError('Kitchen changed; review purchase forecast again');
    }
    return forecastPurchases(
      uses,
      (k['inventory'] as List)
          .map(
            (row) =>
                InventoryLot.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      rules: ownedRules,
      estimateCost: (use) => _cost(k, use, ownedRules),
      unresolvedRequirements: unresolved,
    );
  }

  /// Read-only advice for explicit unsaved recipe candidates and a saved month.
  /// Uses current kitchen prices/ledger/stock and the existing effective-revision
  /// resolver; a null requested revision is resolved now, not initially pinned.
  /// The returned candidateId is each exact resolved revision key. Coverage can
  /// be partial; no clinical/food/quantity approval or automatic plan is implied.
  Future<MonthlyBudgetComparison> previewMonthlyBudgetChoices(
    String budgetId, {
    required Map<String, List<PlannedMeal>> options,
    List<UnitRule> rules = const [],
    Map<String, Map<String, Set<int>>> optionalLinesByOption = const {},
    Map<String, Map<String, Map<int, IngredientUse>>> measuredByOption =
        const {},
  }) async {
    // All leaves (PlannedMeal, IngredientUse and UnitRule) have final scalar
    // fields. Own every mutable collection before yielding to queued work.
    final candidates = {
      for (final entry in options.entries)
        entry.key: List<PlannedMeal>.of(entry.value),
    };
    final ownedRules = List<UnitRule>.of(rules);
    final optionals = {
      for (final option in optionalLinesByOption.entries)
        option.key: {
          for (final meal in option.value.entries)
            meal.key: Set<int>.of(meal.value),
        },
    };
    final measurements = {
      for (final option in measuredByOption.entries)
        option.key: {
          for (final meal in option.value.entries)
            meal.key: Map<int, IngredientUse>.of(meal.value),
        },
    };
    if (budgetId.trim().isEmpty ||
        candidates.isEmpty ||
        candidates.keys.any((id) => id.trim().isEmpty) ||
        optionals.keys.any((id) => !candidates.containsKey(id)) ||
        measurements.keys.any((id) => !candidates.containsKey(id))) {
      throw ArgumentError(
        'Explicit budget/options and selected decisions required',
      );
    }
    for (final option in candidates.entries) {
      final ids = option.value.map((meal) => meal.id).toSet();
      if (ids.length != option.value.length ||
          (optionals[option.key]?.keys.any((id) => !ids.contains(id)) ??
              false) ||
          (measurements[option.key]?.keys.any((id) => !ids.contains(id)) ??
              false)) {
        throw ArgumentError('Duplicate candidate IDs or unselected decisions');
      }
      if (option.value.any((meal) => meal.completed)) {
        throw StateError('Cannot forecast completed candidate meals');
      }
    }
    await _tail;
    final k = snapshot;
    final guard = jsonEncode(k);
    final budgets = (k['budgets'] as List)
        .where((row) => row['id'] == budgetId)
        .toList();
    if (budgets.length != 1) throw ArgumentError('Unknown or ambiguous budget');
    final period = BudgetPeriod.fromJson(
      Map<String, dynamic>.from(budgets.single as Map),
    );
    if (period.country !=
        MarketProfile.fromCode(k['country'] as String).country) {
      throw StateError(
        'Select the budget country before previewing alternatives',
      );
    }
    final resolved = <MonthlyBudgetOption>[];
    for (final option in candidates.entries) {
      final meals = <MonthlyBudgetMeal>[];
      for (final meal in option.value) {
        final revision = await _resolveMeal(meal);
        meals.add(
          _purchasePreviewMeal(
            meal,
            revision,
            optionalLines: optionals[option.key]?[meal.id] ?? const {},
            measuredLines: measurements[option.key]?[meal.id] ?? const {},
          ),
        );
      }
      resolved.add(MonthlyBudgetOption(id: option.key, meals: meals));
    }
    await _tail;
    if (jsonEncode(snapshot) != guard) {
      throw StateError('Kitchen changed; review monthly budget choices again');
    }
    return compareMonthlyBudgetChoices(
      period: period,
      options: resolved,
      rules: ownedRules,
      stock: (k['inventory'] as List)
          .map(
            (row) =>
                InventoryLot.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      confirmedPurchases: (k['purchases'] as List)
          .map(
            (row) => MoneyEntry.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      estimateCost: (_, use) => _cost(k, use, ownedRules),
    );
  }

  Future<void> saveBudget(BudgetPeriod budget) => _write((k) {
    final list = k['budgets'] as List,
        index = list.indexWhere((v) => v['id'] == budget.id);
    if (index < 0) {
      list.add(budget.toJson());
    } else {
      list[index] = budget.toJson();
    }
  });
  BudgetSummary budgetSummary(String id, {double plannedPurchases = 0}) {
    final k = snapshot;
    final budget = BudgetPeriod.fromJson(
      Map<String, dynamic>.from(
        (k['budgets'] as List).where((v) => v['id'] == id).single as Map,
      ),
    );
    final purchases = (k['purchases'] as List)
        .map((v) => MoneyEntry.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    return BudgetSummary(budget, purchases, plannedPurchases: plannedPurchases);
  }

  /// Caller must explicitly resolve/acknowledge unmeasured ingredients. Optional
  /// ingredients support line-specific selection and measurement. Legacy ID
  /// inputs are only safe for unique lines; no quantity is guessed from a label.
  Future<Map<String, dynamic>> confirmCooking(
    String planId,
    String operationId, {
    Set<String> optionalIds = const {},
    Set<int>? optionalLines,
    Map<int, IngredientUse> measuredUsesByLine = const {},
    Map<int, IngredientUse> actualUsesByLine = const {},
    bool acknowledgeSourceMeasureEstimates = false,
    bool acknowledgePreparationEstimates = false,
    Set<int> omitUnmeasuredLines = const {},
    Map<String, IngredientUse> measuredUses = const {},
    Set<String> omitUnmeasured = const {},
    List<UnitRule> rules = const [],
    DateTime? cookedAt,
    double? cookedYieldGrams,
  }) async {
    final submittedActual = Map<int, IngredientUse>.from(actualUsesByLine);
    if (operationId.trim().isEmpty) throw ArgumentError('Missing operation ID');
    final old = (snapshot['history'] as List).where(
      (v) => v['operationId'] == operationId,
    );
    if (old.isNotEmpty) {
      if (old.single['planId'] != planId) {
        throw StateError('Operation ID reused for another meal');
      }
      return Map<String, dynamic>.from(old.single as Map);
    }
    final meal = plans.where((p) => p.id == planId).single;
    final revision = await _resolveMeal(meal);
    final scaled = revision.recipe.forServings(meal.servings);
    final rows = scaled.recipe.ingredients;
    final bindings = _foodSelections(snapshot, revision);
    final bindingSnapshot = jsonEncode(
      bindings.map((v) => v.toJson()).toList(),
    );
    final bindingByLine = {for (final v in bindings) v.line: v};
    bool validLine(int i) => i >= 0 && i < rows.length;
    if (optionalLines != null && optionalIds.isNotEmpty) {
      throw ArgumentError(
        'Choose optional ingredients by IDs or lines, not both',
      );
    }
    if ((optionalLines ?? {}).any((i) => !validLine(i) || !rows[i].optional) ||
        omitUnmeasuredLines.any(
          (i) => !validLine(i) || scaled.quantity(rows[i]) != null,
        ) ||
        measuredUsesByLine.entries.any(
          (e) =>
              !validLine(e.key) ||
              scaled.quantity(rows[e.key]) != null ||
              e.value.ingredientId != rows[e.key].id,
        )) {
      throw ArgumentError('Invalid optional/measured/omitted recipe line');
    }
    if (submittedActual.entries.any(
      (e) =>
          !validLine(e.key) ||
          e.value.ingredientId != rows[e.key].id ||
          measuredUsesByLine.containsKey(e.key) ||
          measuredUses.containsKey(e.value.ingredientId) ||
          omitUnmeasuredLines.contains(e.key) ||
          omitUnmeasured.contains(e.value.ingredientId),
    )) {
      throw ArgumentError('Invalid or conflicting actual cooking line');
    }
    final uses = <IngredientUse>[];
    final sourceEstimates = <int, RecipeFoodSelection>{};
    final preparationEstimates = <int, RecipeFoodSelection>{};
    final actualMeasured = <int, IngredientUse>{};
    final omittedLines = <int>{};
    final selectedOptionalLines = <int>{};
    for (var i = 0; i < rows.length; i++) {
      final ingredient = rows[i];
      if (ingredient.optional) {
        if (!(optionalLines?.contains(i) ??
            optionalIds.contains(ingredient.id))) {
          continue;
        }
        selectedOptionalLines.add(i);
      }
      final quantity = scaled.quantity(ingredient);
      if (quantity == null &&
          (omitUnmeasuredLines.contains(i) ||
              omitUnmeasured.contains(ingredient.id))) {
        if (measuredUsesByLine.containsKey(i) ||
            measuredUses.containsKey(ingredient.id)) {
          throw ArgumentError('Cannot both measure and omit a recipe line');
        }
        omittedLines.add(i);
        continue;
      }
      final preparationBinding = bindingByLine[i];
      final preparation = preparationBinding?.preparation;
      if (preparation != null &&
          PreparationCategoryRepository.isCategoryEstimate(preparation)) {
        if (!acknowledgePreparationEstimates) {
          throw StateError(
            'Acknowledge category preparation estimates before cooking',
          );
        }
        preparationEstimates[i] = preparationBinding!;
      }
      final explicit =
          submittedActual[i] ??
          (quantity == null
              ? measuredUsesByLine[i] ?? measuredUses[ingredient.id]
              : null);
      if (explicit != null) {
        if (!submittedActual.containsKey(i) &&
            !measuredUsesByLine.containsKey(i) &&
            measuredUses.containsKey(ingredient.id) &&
            rows
                    .where(
                      (r) =>
                          r.id == ingredient.id && scaled.quantity(r) == null,
                    )
                    .length >
                1) {
          throw StateError(
            'Repeated unmeasured ingredient requires line-specific measurements',
          );
        }
        if (explicit.ingredientId != ingredient.id) {
          throw ArgumentError('Actual ingredient mismatch');
        }
        uses.add(explicit);
        actualMeasured[i] = explicit;
      } else {
        final binding = bindingByLine[i],
            estimate = bindingByLine[i]?.householdMeasureAmount;
        if (estimate != null) {
          if (!acknowledgeSourceMeasureEstimates) {
            throw StateError(
              'Acknowledge source estimates or enter actual cooking quantities',
            );
          }
          final use = IngredientUse(
            ingredient.id,
            estimate.value * (ingredient.scales ? scaled.factor : 1),
            'g',
          );
          uses.add(use);
          sourceEstimates[i] = binding!;
        } else if (quantity == null) {
          throw StateError(
            'Review unmeasured recipe line $i: ${ingredient.id}',
          );
        } else {
          uses.add(IngredientUse(ingredient.id, quantity, ingredient.unit!));
        }
      }
    }
    await _write((k) {
      final history = k['history'] as List;
      final previous = history.where((v) => v['operationId'] == operationId);
      if (previous.isNotEmpty) {
        if (previous.single['planId'] != planId) {
          throw StateError('Operation ID reused');
        }
        return;
      }
      final list = k['plans'] as List,
          index = list.indexWhere((v) => v['id'] == planId);
      if (index < 0 || list[index]['completed'] == true) {
        throw StateError('Meal missing or already cooked');
      }
      final current = PlannedMeal.fromJson(
        Map<String, dynamic>.from(list[index] as Map),
      );
      if (current.recipeRevisionKey != meal.recipeRevisionKey ||
          current.recipeId != meal.recipeId ||
          current.servings != meal.servings) {
        throw StateError('Meal changed; review again');
      }
      if (jsonEncode(
            _foodSelections(k, revision).map((v) => v.toJson()).toList(),
          ) !=
          bindingSnapshot) {
        throw StateError(
          'Food quantity bindings changed; review cooking again',
        );
      }
      final stock = (k['inventory'] as List)
          .map(
            (v) => InventoryLot.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      final assessment = assessStock(uses, stock, rules: rules);
      if (!assessment.canCook) {
        throw StateError('Insufficient stock or unresolved units');
      }
      var total = 0.0;
      final unknown = <String>[];
      for (final use in uses) {
        final value = _cost(k, use, rules);
        if (value == null) {
          unknown.add(use.ingredientId);
        } else {
          total += value;
        }
      }
      k['inventory'] = assessment.after.map((v) => v.toJson()).toList();
      if (revision.kind == RecipeRevisionKind.catalog) {
        k['recipeBook'] = _registerCatalog(_recipeBook(k), revision).toJson();
      }
      list[index] = current.withRecipeRevision(revision.key).done().toJson();
      final measuredLines = <int, FoodAmount>{};
      for (var i = 0; i < scaled.recipe.ingredients.length; i++) {
        final explicit = actualMeasured[i];
        if (explicit != null) {
          final unit = nutritionUnit(explicit.unit);
          if (unit == null) {
            throw StateError(
              'Review actual measurement unit for recipe line $i',
            );
          }
          measuredLines[i] = FoodAmount(value: explicit.quantity, unit: unit);
        }
      }
      final nutrition = assessRecipeNutrition(
        scaled: scaled,
        selections: _foodSelections(k, revision),
        recipeRevisionKey: revision.key,
        optionalLines: selectedOptionalLines,
        excludedLines: omittedLines,
        measuredLines: measuredLines,
        cookedYieldGrams: cookedYieldGrams,
      );
      final n = _nutrition(k), allergenIds = <String>{};
      for (final raw in (n['profiles'] as Map).values) {
        final profile = NutritionPersonProfile.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        allergenIds.addAll(profile.allergies.map((v) => v.allergenId));
      }
      final batch = nutritionMealBatch(
        nutrition,
        batchId: 'cooked:$operationId',
        sourceSnapshotId: operationId,
        allergenIds: allergenIds,
      );
      final ledger = NutritionLedger.fromJson(
        Map<String, dynamic>.from(n['ledger'] as Map),
      );
      n['ledger'] = ledger.addBatch(batch).toJson();
      history.add({
        'operationId': operationId,
        'planId': planId,
        'recipeId': meal.recipeId,
        'recipeRevision': revision.toJson(),
        'recipeFamily': _recipeBook(k).families[revision.familyId]!.toJson(),
        'servings': meal.servings,
        'cookedAt': (cookedAt ?? DateTime.now()).toIso8601String(),
        'country': k['country'],
        'currency': MarketProfile.fromCode(k['country'] as String).currency,
        'consumed': uses.map((v) => v.toJson()).toList(),
        'omittedUnmeasured': omitUnmeasured.toList(),
        'selectedOptional': optionalIds.toList(),
        'selectedOptionalLines': selectedOptionalLines.toList(),
        'omittedUnmeasuredLines': omittedLines.toList(),
        'estimatedSourceMeasureLines': sourceEstimates.keys.toList(),
        'actualMeasuredLines': actualMeasured.keys.toList(),
        'estimatedPreparationLines': preparationEstimates.keys.toList(),
        'preparationEstimateEvidence': {
          for (final e in preparationEstimates.entries)
            e.key.toString(): jsonDecode(e.value.preparation!.evidence!),
        },
        'sourceMeasureEvidence': {
          for (final e in sourceEstimates.entries)
            e.key.toString(): jsonDecode(e.value.householdMeasureEvidence!),
        },
        'nutrition': nutrition.toJson(),
        'nutritionBatchId': batch.id,
        'cost': unknown.isEmpty ? total : null,
        'knownCost': total,
        'unpricedIngredients': unknown,
      });
    });
    return Map<String, dynamic>.from(
      (snapshot['history'] as List)
              .where((v) => v['operationId'] == operationId)
              .single
          as Map,
    );
  }
}
