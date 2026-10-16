import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/recipe_library_repository.dart';
import 'food_nutrition.dart';
import 'personal_recipe_draft.dart';

/// Pins the whole recipe evidence and its own attribution/policy context.
/// This is local consistency evidence, never food, licence or publication approval.
String recipeLibrarySourceFingerprint(RecipeLibraryEntry entry) =>
    _fingerprint(_source(entry));

class RecipeLibraryLineDecision {
  RecipeLibraryLineDecision({
    required RecipeFoodInput input,
    required this.scales,
    required this.overrideSourceExclusion,
    this.name,
  }) : input = PersonalRecipeLine(
         id: input.ingredientId,
         name: name ?? input.ingredientId,
         input: input,
         scales: scales,
       ).input;
  final RecipeFoodInput input;
  final bool scales, overrideSourceExclusion;
  final String? name;
}

/// Private calculation draft plus the exact library evidence explicitly reviewed.
/// Persist this whole envelope to retain source rights/gates; no publication occurs.
class RecipeLibraryDraftReview {
  RecipeLibraryDraftReview._({
    required Map<String, dynamic> source,
    required this.sourceFingerprint,
    required PersonalRecipeDraft draft,
    required List<bool> overrides,
  }) : _sourceSnapshot = _owned(source),
       draft = PersonalRecipeDraft.fromJson(draft.toJson()),
       _overrides = List.unmodifiable(overrides);

  factory RecipeLibraryDraftReview.create({
    required RecipeLibraryEntry entry,
    required String expectedSourceFingerprint,
    required String draftId,
    required String revision,
    required DateTime createdAt,
    required double servings,
    required Map<int, RecipeLibraryLineDecision> decisions,
    String? name,
    String? cuisine,
    int? prepMinutes,
    int? cookMinutes,
    String? note,
  }) {
    final source = _source(entry), pin = _fingerprint(source);
    if (pin != expectedSourceFingerprint) {
      throw StateError('Library source changed; review the full source again');
    }
    if (decisions.length != entry.ingredients.length ||
        decisions.keys.any(
          (line) => line < 0 || line >= entry.ingredients.length,
        )) {
      throw ArgumentError('Explicit decisions must cover every source line');
    }
    final lines = <PersonalRecipeLine>[], overrides = <bool>[];
    for (var i = 0; i < entry.ingredients.length; i++) {
      final decision = decisions[i]!;
      _selection(
        entry.ingredients[i].included,
        decision.input.selected,
        decision.overrideSourceExclusion,
      );
      lines.add(
        PersonalRecipeLine(
          id: decision.input.ingredientId,
          name: decision.name ?? entry.ingredients[i].labelAr,
          input: decision.input,
          scales: decision.scales,
        ),
      );
      overrides.add(decision.overrideSourceExclusion);
    }
    final draft = PersonalRecipeDraft(
      id: draftId,
      revision: revision,
      name: name ?? entry.titleAr,
      servings: servings,
      createdAt: createdAt,
      lines: lines,
      cuisine: cuisine,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      instructions: entry.stepsArabic,
      note: note,
    );
    return RecipeLibraryDraftReview._(
      source: source,
      sourceFingerprint: pin,
      draft: draft,
      overrides: overrides,
    );
  }

  factory RecipeLibraryDraftReview.fromJson(Map<String, dynamic> json) {
    try {
      final owned = _owned(json);
      _keys(owned, const [
        'schemaVersion',
        'source',
        'sourceFingerprint',
        'draft',
        'decisions',
        'fingerprint',
      ]);
      if (owned['schemaVersion'] is! int || owned['schemaVersion'] != 1) {
        throw const FormatException('Unsupported library draft review schema');
      }
      final source = _map(owned['source']);
      _validateSource(source);
      final pin = _text(owned['sourceFingerprint']);
      if (_fingerprint(source) != pin) {
        throw const FormatException('Library source fingerprint changed');
      }
      final draft = PersonalRecipeDraft.fromJson(_map(owned['draft']));
      final ingredients = source['ingredients'] as List;
      final decisions = owned['decisions'] as List;
      if (ingredients.length != draft.lines.length ||
          decisions.length != draft.lines.length ||
          _fingerprint(source['stepsArabic']) !=
              _fingerprint(draft.instructions)) {
        throw const FormatException(
          'Library draft/source line or instruction mismatch',
        );
      }
      final overrides = <bool>[];
      for (var i = 0; i < ingredients.length; i++) {
        final decision = _map(decisions[i]);
        _keys(decision, const ['line', 'overrideSourceExclusion']);
        if (decision['line'] is! int ||
            decision['line'] != i ||
            decision['overrideSourceExclusion'] is! bool) {
          throw const FormatException('Malformed library line decision');
        }
        final override = decision['overrideSourceExclusion'] as bool;
        _selection(
          _map(ingredients[i])['included'] as bool?,
          draft.lines[i].input.selected,
          override,
        );
        overrides.add(override);
      }
      final review = RecipeLibraryDraftReview._(
        source: source,
        sourceFingerprint: pin,
        draft: draft,
        overrides: overrides,
      );
      if (owned['fingerprint'] != review.fingerprint) {
        throw const FormatException('Library draft review fingerprint changed');
      }
      return review;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Malformed library draft review');
    }
  }

  final Map<String, dynamic> _sourceSnapshot;
  final List<bool> _overrides;
  final PersonalRecipeDraft draft;
  final String sourceFingerprint;
  String get libraryEntryId => _sourceSnapshot['id'] as String;
  Map<String, dynamic> get sourceSnapshot => _owned(_sourceSnapshot);
  String get fingerprint => _fingerprint(_payload());

  Map<String, dynamic> _payload() => {
    'schemaVersion': 1,
    'source': sourceSnapshot,
    'sourceFingerprint': sourceFingerprint,
    'draft': draft.toJson(),
    'decisions': [
      for (var i = 0; i < _overrides.length; i++)
        {'line': i, 'overrideSourceExclusion': _overrides[i]},
    ],
  };
  Map<String, dynamic> toJson() => {..._payload(), 'fingerprint': fingerprint};

  void assertSource(RecipeLibraryEntry entry, {String? expectedFingerprint}) {
    if (expectedFingerprint != null && expectedFingerprint != fingerprint) {
      throw StateError('Library draft review changed');
    }
    if (recipeLibrarySourceFingerprint(entry) != sourceFingerprint) {
      throw StateError('Library source changed; review the full source again');
    }
  }
}

/// An explicitly acknowledged numeric source declaration, never a measurement.
/// No volume/count conversion, food matching, recipe scaling or persistence.
class RecipeLibraryMassProposal {
  RecipeLibraryMassProposal._({
    required this.recipeId,
    required this.sourceFingerprint,
    required this.lineIndex,
    required this.ingredient,
    required this.amount,
  });

  factory RecipeLibraryMassProposal.fromSource({
    required RecipeLibraryEntry entry,
    required String expectedSourceFingerprint,
    required int lineIndex,
    required bool acknowledgeDeclaredSourceMass,
  }) {
    if (!acknowledgeDeclaredSourceMass) {
      throw ArgumentError(
        'Review the declared source mass before proposing it',
      );
    }
    final pin = recipeLibrarySourceFingerprint(entry);
    if (pin != expectedSourceFingerprint) {
      throw StateError('Library source changed; review the source again');
    }
    if (lineIndex < 0 || lineIndex >= entry.ingredients.length) {
      throw ArgumentError('Unknown library ingredient line');
    }
    final ingredient = entry.ingredients[lineIndex];
    final value = ingredient.amount;
    final unit = switch (ingredient.unit) {
      'g' => FoodQuantityUnit.g,
      'kg' => FoodQuantityUnit.kg,
      _ => null,
    };
    if (value == null || !value.isFinite || value <= 0 || unit == null) {
      throw ArgumentError(
        'Only positive declared g/kg source amounts supported',
      );
    }
    return RecipeLibraryMassProposal._(
      recipeId: entry.id,
      sourceFingerprint: pin,
      lineIndex: lineIndex,
      ingredient: ingredient,
      amount: FoodAmount(value: value, unit: unit),
    );
  }

  final String recipeId, sourceFingerprint;
  final int lineIndex;
  final RecipeLibraryIngredient ingredient;
  final FoodAmount amount;

  /// Caller still reviews identity, forms, inclusion, scaling and preparation.
  /// The resulting decision always retains quantityEstimated=true.
  RecipeLibraryLineDecision toDecision({
    required RecipeLibraryEntry currentEntry,
    required String ingredientId,
    required FoodRecord? food,
    required FoodForm amountForm,
    required FoodForm preparedForm,
    required bool optional,
    required bool selected,
    required bool asPurchased,
    required PreparationTransform? preparation,
    required bool scales,
    required bool overrideSourceExclusion,
  }) {
    if (currentEntry.id != recipeId ||
        recipeLibrarySourceFingerprint(currentEntry) != sourceFingerprint) {
      throw StateError('Library source changed; review the mass again');
    }
    _selection(ingredient.included, selected, overrideSourceExclusion);
    return RecipeLibraryLineDecision(
      input: RecipeFoodInput(
        ingredientId: ingredientId,
        food: food,
        amount: amount,
        amountForm: amountForm,
        preparedForm: preparedForm,
        quantityEstimated: true,
        optional: optional,
        selected: selected,
        asPurchased: asPurchased,
        preparation: preparation,
      ),
      scales: scales,
      overrideSourceExclusion: overrideSourceExclusion,
      name: ingredient.labelAr,
    );
  }
}

void _selection(bool? sourceIncluded, bool selected, bool override) {
  final replacingExclusion = sourceIncluded == false && selected;
  if (override != replacingExclusion) {
    throw ArgumentError(
      'Excluded source lines need an explicit, applicable override',
    );
  }
}

const _metadataFields = {
  'schemaVersion',
  'batchId',
  'retrievedAt',
  'sourcePolicy',
  'reviewer',
  'reviewedAt',
  'changeNotice',
  'sourceEvidence',
  'limitations',
};
Map<String, dynamic> _source(RecipeLibraryEntry entry) {
  final source = entry.toJson(), metadata = entry.packMetadata;
  final context = <String, dynamic>{
    for (final key in _metadataFields)
      if (metadata.containsKey(key)) key: metadata[key],
  };
  final creatorId = entry.sourceRecord['creatorId'];
  if (creatorId != null) {
    final candidates = [
      if (metadata['creators'] is List) ...metadata['creators'] as List,
      if (metadata['creator'] is Map) metadata['creator'],
    ];
    final matching = <String, Map>{};
    for (final creator in candidates) {
      if (creator is Map && creator['creatorId'] == creatorId) {
        matching[_fingerprint(creator)] = creator;
      }
    }
    if (matching.isNotEmpty) context['creators'] = matching.values.toList();
  }
  if (metadata.containsKey('sourceIndex')) {
    final rows = metadata['sourceIndex'];
    if (rows is! List) {
      throw const FormatException('Malformed source request context');
    }
    final matching = <Map<String, dynamic>>[];
    for (final row in rows) {
      final request = _map(row);
      if (entry.sourceUrls.contains(request['url'])) matching.add(request);
    }
    final evidence = entry.sourceRecord['sourceEvidence'];
    if (evidence is Map && evidence.containsKey('sourceIndex')) {
      final index = evidence['sourceIndex'];
      if (index is! int || !matching.any((row) => row['index'] == index)) {
        throw const FormatException(
          'Missing referenced source request context',
        );
      }
    }
    if (matching.isNotEmpty) context['sourceIndex'] = matching;
  }
  source['packMetadata'] = context;
  _validateSource(source);
  return _owned(source);
}

void _validateSource(Map<String, dynamic> source) {
  _keys(source, const [
    'id',
    'titleAr',
    'ingredients',
    'stepsArabic',
    'sourceUrls',
    'cuisineLabels',
    'familyId',
    'methodId',
    'runtimeReady',
    'nutrition',
    'sourceRecord',
    'sourceSnapshot',
    'packMetadata',
  ]);
  _text(source['id']);
  _text(source['titleAr']);
  if (source['runtimeReady'] != false ||
      source['nutrition'] != null ||
      (source['ingredients'] as List).isEmpty ||
      (source['stepsArabic'] as List).isEmpty) {
    throw const FormatException('Invalid library source snapshot');
  }
  for (final raw in source['ingredients'] as List) {
    final ingredient = _map(raw);
    _keys(ingredient, const [
      'labelAr',
      'amount',
      'unit',
      'sourceQuantityText',
      'optional',
      'included',
      'supplemental',
    ]);
    _text(ingredient['labelAr']);
    final amount = ingredient['amount'];
    if (amount != null && (amount is! num || !amount.isFinite || amount < 0) ||
        (ingredient['optional'] != null && ingredient['optional'] is! bool) ||
        ingredient['supplemental'] is! bool ||
        ingredient['included'] != null && ingredient['included'] is! bool) {
      throw const FormatException('Malformed library source ingredient');
    }
  }
  for (final raw in source['stepsArabic'] as List) {
    _text(raw);
  }
  _map(source['sourceRecord']);
  if (source['sourceSnapshot'] != null) {
    _map(source['sourceSnapshot']);
  }
  final metadata = _map(source['packMetadata']);
  if (metadata.containsKey('sourceIndex')) {
    final rows = metadata['sourceIndex'];
    if (rows is! List || rows.isEmpty) {
      throw const FormatException('Malformed source request context');
    }
    final indexes = <int>{};
    for (final row in rows) {
      final request = _map(row);
      final index = request['index'], ordinal = request['request'];
      if (index is! int ||
          index < 0 ||
          !indexes.add(index) ||
          ordinal is! int ||
          ordinal <= 0 ||
          !(source['sourceUrls'] as List).contains(request['url'])) {
        throw const FormatException(
          'Unrelated or malformed source request context',
        );
      }
      _text(request['url']);
      _text(request['outcome']);
    }
    final evidence = _map(source['sourceRecord'])['sourceEvidence'];
    if (evidence is Map && evidence.containsKey('sourceIndex')) {
      final index = evidence['sourceIndex'];
      if (index is! int || !indexes.contains(index)) {
        throw const FormatException(
          'Missing referenced source request context',
        );
      }
    }
  }

  if (metadata.keys.any(
    (key) =>
        !_metadataFields.contains(key) &&
        key != 'creators' &&
        key != 'sourceIndex',
  )) {
    throw const FormatException(
      'Unrelated library pack metadata in draft review',
    );
  }
}

Map<String, dynamic> _owned(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
Map<String, dynamic> _map(Object? value) =>
    Map<String, dynamic>.from(value as Map);
String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing library draft review text');
  }
  return value;
}

void _keys(Map<String, dynamic> value, List<String> keys) {
  if (value.length != keys.length ||
      keys.any((key) => !value.containsKey(key))) {
    throw const FormatException(
      'Unexpected or missing library draft review fields',
    );
  }
}

String _fingerprint(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_sorted(value)))).toString();
Object? _sorted(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _sorted(value[key])};
  }
  if (value is List) {
    return value.map(_sorted).toList();
  }
  return value;
}
