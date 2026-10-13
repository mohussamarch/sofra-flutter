import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_nutrition.dart';
import '../domain/recipe_nutrition.dart';
import '../domain/recipe_variants.dart';
import 'food_repository.dart';

String _text(dynamic v) {
  if (v is! String || v.trim().isEmpty) {
    throw const FormatException('Missing reference identity');
  }
  return v;
}

class RecipeReferenceCandidate {
  RecipeReferenceCandidate._(Map<String, dynamic> j)
    : foodId = _text(j['foodId']),
      form = FoodForm.values.byName(_text(j['form'])),
      sourceDescription = _text(j['sourceDescription']),
      sourceVersion = _text(j['sourceVersion']),
      rationale = _text(j['rationale']) {
    if (!RegExp(r'^usda:[0-9]+$').hasMatch(foodId) ||
        !{'raw', 'cooked', 'asSold', 'prepared'}.contains(form.name)) {
      throw const FormatException('Invalid reference candidate');
    }
  }
  final String foodId, sourceDescription, sourceVersion, rationale;
  final FoodForm form;
}

/// A reviewed identity proposal, not a verified product/quantity/preparation.
class RecipeReferenceEntry {
  RecipeReferenceEntry._(Map<String, dynamic> j)
    : recipeId = _text(j['recipeId']),
      line = j['line'] as int,
      ingredientId = _text(j['ingredientId']),
      expectedName = _text(j['expectedName']),
      snapshotVersion = _text(j['recipeSnapshotVersion']),
      sourceFile = _text(j['recipeSourceFile']),
      sourceSha256 = _text(j['recipeSourceSha256']),
      requiresUserChoice = j['requiresUserChoice'] as bool,
      blocked = j['blocked'] as bool,
      issues = List.unmodifiable((j['issues'] as List).cast<String>()),
      candidates = List.unmodifiable(
        (j['candidates'] as List).map(
          (v) =>
              RecipeReferenceCandidate._(Map<String, dynamic>.from(v as Map)),
        ),
      ) {
    if (line < 0 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceSha256) ||
        candidates.isEmpty ||
        candidates.map((v) => v.foodId).toSet().length != candidates.length ||
        (!requiresUserChoice && candidates.length != 1) ||
        (blocked && !requiresUserChoice)) {
      throw const FormatException('Invalid reference entry');
    }
  }
  final String recipeId,
      ingredientId,
      expectedName,
      snapshotVersion,
      sourceFile,
      sourceSha256;
  final int line;
  final bool requiresUserChoice, blocked;
  final List<String> issues;
  final List<RecipeReferenceCandidate> candidates;
}

class RecipeReferenceResolution {
  RecipeReferenceResolution(
    List<RecipeFoodSelection> selections,
    Map<int, List<String>> issues,
  ) : selections = List.unmodifiable(selections),
      issues = Map.unmodifiable(
        issues.map((k, v) => MapEntry(k, List<String>.unmodifiable(v))),
      );
  final List<RecipeFoodSelection> selections;
  final Map<int, List<String>> issues;
}

class RecipeReferenceApplication {
  RecipeReferenceApplication({
    required this.resolution,
    required List<int> appliedLines,
    required List<int> preservedLines,
  }) : appliedLines = List.unmodifiable(appliedLines),
       preservedLines = List.unmodifiable(preservedLines);
  final RecipeReferenceResolution resolution;
  final List<int> appliedLines, preservedLines;
}

/// Explicit proposal resolution against a full immutable recipe snapshot.
/// Does not infer local brand, portion conversion, allergen absence or retention.
class RecipeReferenceRepository {
  RecipeReferenceRepository({FoodAssetReader? read, FoodRepository? foods})
    : _read = read ?? rootBundle.loadString,
      _foods = foods ?? FoodRepository(read: read);
  final FoodAssetReader _read;
  final FoodRepository _foods;
  Future<List<RecipeReferenceEntry>>? _entries;
  String? _reviewedDate;
  Future<List<RecipeReferenceEntry>> _load() => _entries ??= _loadEntries();
  Future<List<RecipeReferenceEntry>> _loadEntries() async {
    try {
      final j = jsonDecode(
        await _read('data/nutrition/recipe-reference-review.json'),
      ) as Map;
      if (j['schemaVersion'] != 1) {
        throw const FormatException('Reference review schema');
      }
      _reviewedDate = _text(j['reviewedDate']);
      final entries = (j['entries'] as List)
          .map(
            (v) => RecipeReferenceEntry._(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
      final keys = entries.map((v) => jsonEncode([v.recipeId, v.line])).toSet();
      if (keys.length != entries.length) {
        throw const FormatException('Duplicate recipe reference line');
      }
      return List.unmodifiable(entries);
    } catch (_) {
      _entries = null;
      rethrow;
    }
  }

  Future<List<RecipeReferenceEntry>> reviewFor(RecipeRevision revision) async {
    final entries = (await _load())
        .where((v) => v.recipeId == revision.variantId)
        .toList();
    final recipe = revision.recipe,
        version = recipeSnapshotVersion(revision.recipe);
    for (final e in entries) {
      if (e.snapshotVersion != version ||
          e.line >= recipe.ingredients.length ||
          recipe.ingredients[e.line].id != e.ingredientId ||
          recipe.ingredients[e.line].name != e.expectedName) {
        throw StateError('Reference review is stale for this recipe snapshot');
      }
    }
    return List.unmodifiable(entries);
  }

  Future<RecipeReferenceResolution> resolve(
    RecipeRevision revision, {
    required bool acknowledgeGenericReferences,
    Map<int, String> choices = const {},
  }) async {
    if (!acknowledgeGenericReferences) {
      throw ArgumentError(
        'Explicit acceptance of generic reference estimates required',
      );
    }
    // Capture caller-owned choices before metadata or food source reads.
    final selected = Map<int, String>.from(choices);
    final entries = await reviewFor(revision),
        byLine = {for (final e in entries) e.line: e};
    for (final choice in selected.entries) {
      final e = byLine[choice.key];
      if (e == null ||
          e.blocked ||
          !e.candidates.any((v) => v.foodId == choice.value)) {
        throw ArgumentError(
          'Invalid or blocked reference choice at line ${choice.key}',
        );
      }
    }
    final selections = <RecipeFoodSelection>[], issues = <int, List<String>>{};
    for (var line = 0; line < revision.recipe.ingredients.length; line++) {
      final e = byLine[line];
      if (e == null) {
        issues[line] = ['No reviewed reference for this recipe line'];
        continue;
      }
      issues[line] = [...e.issues];
      if (e.blocked) {
        issues[line]!.add(
          'Compound line requires separate measured components',
        );
        continue;
      }
      if (e.requiresUserChoice && !selected.containsKey(line)) {
        issues[line]!.add('Explicit food identity choice required');
        continue;
      }
      final candidate = selected.containsKey(line)
          ? e.candidates.singleWhere((v) => v.foodId == selected[line])
          : e.candidates.single;
      final food = await _foods.usdaFood(
        candidate.foodId,
        form: candidate.form.name,
        nameAr: e.expectedName,
      );
      if (food.nameEn != candidate.sourceDescription ||
          food.version != candidate.sourceVersion) {
        throw StateError('Reference food source changed; re-review required');
      }
      selections.add(
        RecipeFoodSelection(
          recipeId: revision.variantId,
          recipeRevisionKey: revision.key,
          line: line,
          food: food,
          amountForm: candidate.form,
          preparedForm: FoodForm.cooked,
          referenceReviewId: jsonEncode([
            e.recipeId,
            e.snapshotVersion,
            line,
            candidate.foodId,
            candidate.sourceVersion,
          ]),
          referenceEvidence: jsonEncode({
            'reviewedDate': _reviewedDate,
            'recipeSourceFile': e.sourceFile,
            'recipeSourceSha256': e.sourceSha256,
            'sourceDescription': candidate.sourceDescription,
            'rationale': candidate.rationale,
            'genericReferenceAccepted': true,
            'issues': e.issues,
          }),
        ),
      );
    }
    return RecipeReferenceResolution(selections, issues);
  }
}
