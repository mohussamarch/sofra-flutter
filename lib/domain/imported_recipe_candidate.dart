import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'recipe_catalog.dart';

/// A structural source candidate, never food/nutrition or source authenticity approval.
///
/// [expectedSha256] must come from the caller's trusted artifact reference. The
/// UTF-8 digest checks local consistency of the exact Node-validated payload;
/// Dart does not reconstruct upstream source/draft/food snapshot fingerprints.
class ImportedRecipeCandidate {
  ImportedRecipeCandidate._(
    this.transportSha256,
    this.recipe,
    this._transport,
    this._provenance,
    this.remainingGates,
  );

  factory ImportedRecipeCandidate.fromTransport(
    Map<String, dynamic> transport, {
    required String expectedSha256,
  }) {
    final owned = _copy(transport);
    _keys(owned, const ['schemaVersion', 'encoding', 'payload', 'sha256']);
    _need(
      owned['schemaVersion'] == 1 && owned['encoding'] == 'utf8-json',
      'Unsupported candidate transport',
    );
    _sha(expectedSha256);
    _sha(owned['sha256']);
    final payload = owned['payload'];
    _need(payload is String, 'Candidate payload must be JSON text');
    final digest = sha256.convert(utf8.encode(payload as String)).toString();
    _need(
      digest == expectedSha256 && digest == owned['sha256'],
      'Candidate transport fingerprint mismatch',
    );
    final candidate = _map(jsonDecode(payload));
    _validate(candidate);
    return ImportedRecipeCandidate._(
      digest,
      CatalogRecipe.fromJson(_map(candidate['recipe'])),
      owned,
      _map(candidate['provenance']),
      List<String>.unmodifiable(
        (candidate['remainingGates'] as List).cast<String>(),
      ),
    );
  }

  factory ImportedRecipeCandidate.fromJson(Map<String, dynamic> json) {
    _keys(json, const ['version', 'expectedSha256', 'transport']);
    _need(
      json['version'] == 1 && json['expectedSha256'] is String,
      'Unsupported saved candidate',
    );
    return ImportedRecipeCandidate.fromTransport(
      _map(json['transport']),
      expectedSha256: json['expectedSha256'] as String,
    );
  }

  final String transportSha256;
  final CatalogRecipe recipe;
  final Map<String, dynamic> _transport, _provenance;
  final List<String> remainingGates;
  String get sourceId => (_provenance['source'] as Map)['sourceId'] as String;
  String get sourceRecipeId =>
      (_provenance['source'] as Map)['recipeId'] as String;
  Map<String, dynamic> get provenance => _copy(_provenance);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'expectedSha256': transportSha256,
    'transport': _copy(_transport),
  };
}

const _gates = [
  'runtime-persistence-and-provenance-validation',
  'per-page-license-exception-review',
  'runtime-food-form-basis-and-measurement-binding',
  'retention-and-nutrition-review',
];

void _need(bool condition, String message) {
  if (!condition) throw FormatException(message);
}

Map<String, dynamic> _map(Object? value) {
  _need(value is Map<String, dynamic>, 'Expected candidate JSON object');
  return value as Map<String, dynamic>;
}

List<dynamic> _list(Object? value) {
  _need(value is List, 'Expected candidate JSON list');
  return value as List;
}

void _keys(Map<String, dynamic> value, List<String> fields) {
  _need(
    value.length == fields.length && fields.every(value.containsKey),
    'Unexpected or missing candidate fields',
  );
}

void _text(Object? value) => _need(
  value is String && value.trim().isNotEmpty,
  'Expected explicit candidate text',
);

void _catalogText(Object? value) {
  _text(value);
  _need(
    value == (value as String).trim(),
    'Catalog text must already be normalized',
  );
}

void _sha(Object? value) => _need(
  value is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(value),
  'Invalid candidate SHA256',
);

void _number(Object? value, {bool zero = false, bool integer = false}) {
  _need(
    value is num &&
        value.isFinite &&
        (zero ? value >= 0 : value > 0) &&
        (!integer ||
            (value == value.truncateToDouble() && value <= 9007199254740991)),
    'Invalid candidate number',
  );
}

void _stamp(Object? value) {
  _need(
    value is String &&
        RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$')
            .hasMatch(value),
    'Explicit UTC review timestamp required',
  );
  final parsed = DateTime.tryParse(value as String);
  _need(
    parsed != null &&
        parsed.toUtc().toIso8601String().substring(0, 19) ==
            value.substring(0, 19),
    'Invalid calendar review timestamp',
  );
}

Map<String, dynamic> _copy(Map<String, dynamic> value) {
  try {
    return _map(jsonDecode(jsonEncode(value)));
  } on JsonUnsupportedObjectError {
    throw const FormatException(
      'Candidate must contain only finite JSON values',
    );
  }
}

void _validate(Map<String, dynamic> candidate) {
  _keys(candidate, const [
    'schemaVersion',
    'status',
    'runtimeReady',
    'recipe',
    'provenance',
    'nutrition',
    'remainingGates',
  ]);
  _need(
    candidate['schemaVersion'] == 1 &&
        candidate['status'] == 'runtime-recipe-candidate-unapproved' &&
        candidate['runtimeReady'] == false,
    'Source candidate cannot claim approval',
  );
  final nutrition = _map(candidate['nutrition']);
  _keys(nutrition, const ['status', 'runtimeBindings']);
  _need(
    nutrition['status'] == 'unreviewed' &&
        _list(nutrition['runtimeBindings']).isEmpty,
    'Source nutrition must remain unreviewed',
  );
  final gates = _list(candidate['remainingGates']);
  _need(
    gates.length == _gates.length &&
        List.generate(
          _gates.length,
          (i) => gates[i] == _gates[i],
        ).every((v) => v),
    'All remaining source candidate gates required',
  );
  final recipe = _map(candidate['recipe']);
  _validateRecipe(recipe);
  final provenance = _map(candidate['provenance']);
  _keys(provenance, const [
    'source',
    'sourceRecipeSha256',
    'draftSha256',
    'metadataSha256',
    'recipeSha256',
    'changeNotice',
    'sourceReview',
    'adapterReview',
    'lines',
  ]);
  for (final field in [
    'sourceRecipeSha256',
    'draftSha256',
    'metadataSha256',
    'recipeSha256',
  ]) {
    _sha(provenance[field]);
  }
  _text(provenance['changeNotice']);
  for (final field in ['sourceReview', 'adapterReview']) {
    final review = _map(provenance[field]);
    _keys(review, const ['note', 'reviewedAt']);
    _text(review['note']);
    _stamp(review['reviewedAt']);
  }
  final source = _map(provenance['source']);
  _keys(source, const [
    'recipeId',
    'recordId',
    'sourceId',
    'sourceRevision',
    'sourceSha256',
    'sourceUrl',
    'license',
    'sourceChangeNotice',
  ]);
  for (final field in [
    'recipeId',
    'recordId',
    'sourceId',
    'sourceRevision',
    'sourceChangeNotice',
  ]) {
    _text(source[field]);
  }
  _sha(source['sourceSha256']);
  _text(source['sourceUrl']);
  final url = Uri.tryParse(source['sourceUrl'] as String);
  _need(
    url != null &&
        (url.scheme == 'https' || url.scheme == 'http') &&
        url.host.isNotEmpty,
    'Source attribution URL required',
  );
  _need(_map(source['license']).isNotEmpty, 'Source licence evidence required');
  _validateLines(provenance, source, _list(recipe['ingredients']));
}

void _validateRecipe(Map<String, dynamic> recipe) {
  _keys(recipe, const [
    'id',
    'name',
    'cuisine',
    'category',
    'description',
    'difficulty',
    'servings',
    'prepTime',
    'cookTime',
    'totalTime',
    'ingredients',
    'steps',
    'tags',
    'notes',
  ]);
  _need(
    recipe['id'] is String &&
        RegExp(r'^import:[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(recipe['id']),
    'Import namespaced identity required',
  );
  for (final field in [
    'name',
    'cuisine',
    'category',
    'description',
    'difficulty',
  ]) {
    _catalogText(recipe[field]);
  }
  _number(recipe['servings'], integer: true);
  for (final field in ['prepTime', 'cookTime', 'totalTime']) {
    _number(recipe[field], zero: true);
  }
  _need(
    (recipe['prepTime'] as num) + (recipe['cookTime'] as num) ==
        recipe['totalTime'],
    'Candidate total time mismatch',
  );
  _need(
    recipe['notes'] == null || recipe['notes'] is String,
    'Invalid recipe notes',
  );
  if (recipe['notes'] != null) _text(recipe['notes']);
  for (final tag in _list(recipe['tags'])) {
    _text(tag);
  }
  final ingredients = _list(recipe['ingredients']);
  final steps = _list(recipe['steps']);
  _need(
    ingredients.isNotEmpty && steps.isNotEmpty,
    'Candidate recipe contents required',
  );
  for (final raw in ingredients) {
    final ingredient = _map(raw);
    _keys(ingredient, const [
      'id',
      'name',
      'amount',
      'unit',
      'scale',
      'optional',
      'label',
      'display',
      'note',
    ]);
    for (final field in ['id', 'name', 'unit', 'note']) {
      _text(ingredient[field]);
    }
    _catalogText(ingredient['id']);
    _catalogText(ingredient['name']);
    _number(ingredient['amount']);
    _need(
      ingredient['scale'] is bool &&
          ingredient['optional'] is bool &&
          ingredient['label'] == null &&
          ingredient['display'] == null,
      'Explicit ingredient decisions required',
    );
  }
  for (var i = 0; i < steps.length; i++) {
    final step = _map(steps[i]);
    _keys(step, const ['n', 'text', 'duration', 'passive', 'tip']);
    _need(
      step['n'] == i + 1 && step['passive'] is bool,
      'Explicit ordered recipe steps required',
    );
    _catalogText(step['text']);
    _number(step['duration'], zero: true);
    if (step['tip'] != null) _text(step['tip']);
  }
}

void _validateLines(
  Map<String, dynamic> provenance,
  Map<String, dynamic> source,
  List<dynamic> ingredients,
) {
  final lines = _list(provenance['lines']);
  _need(lines.isNotEmpty, 'Source provenance lines required');
  final lineIds = <String>{};
  String? parserVersion, quantityParserVersion;
  var nextRuntimeIndex = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = _map(lines[i]);
    _keys(line, const [
      'target',
      'resolution',
      'disposition',
      'note',
      'runtimeLineIndices',
      'components',
    ]);
    final target = _map(line['target']);
    _keys(target, const [
      'schemaVersion',
      'recipeId',
      'recordId',
      'sourceId',
      'sourceRevision',
      'sourceSha256',
      'parserVersion',
      'quantityParserVersion',
      'lineIndex',
      'lineId',
      'sourceText',
      'derivedRecipeSha256',
    ]);
    _need(
      target['schemaVersion'] == 1 &&
          target['lineIndex'] == i &&
          target['derivedRecipeSha256'] == provenance['sourceRecipeSha256'],
      'Stale or reordered source line',
    );
    for (final field in [
      'recipeId',
      'recordId',
      'sourceId',
      'sourceRevision',
      'sourceSha256',
    ]) {
      _need(target[field] == source[field], 'Mismatched source line guard');
    }
    for (final field in [
      'lineId',
      'sourceText',
      'parserVersion',
      'quantityParserVersion',
    ]) {
      _text(target[field]);
    }
    _need(lineIds.add(target['lineId'] as String), 'Duplicate source line');
    parserVersion ??= target['parserVersion'] as String;
    quantityParserVersion ??= target['quantityParserVersion'] as String;
    _need(
      target['parserVersion'] == parserVersion &&
          target['quantityParserVersion'] == quantityParserVersion,
      'Mismatched source parser guard',
    );
    _text(line['note']);
    _need(
      const ['single', 'choice', 'split'].contains(line['resolution']) &&
          const [
            'required',
            'included-optional',
            'excluded-optional',
          ].contains(line['disposition']),
      'Explicit source line resolution/disposition required',
    );
    final components = _list(line['components']);
    final indices = _list(line['runtimeLineIndices']);
    final excluded = line['disposition'] == 'excluded-optional';
    _need(
      indices.length == components.length &&
          (excluded
              ? components.isEmpty
              : line['resolution'] == 'split'
              ? components.length >= 2
              : components.length == 1),
      'Source component count mismatch',
    );
    for (var j = 0; j < components.length; j++) {
      _need(
        nextRuntimeIndex < ingredients.length && indices[j] == nextRuntimeIndex,
        'Source mappings must cover runtime lines once in order',
      );
      final ingredient = _map(ingredients[nextRuntimeIndex++]);
      final component = _map(components[j]);
      _keys(component, const [
        'runtimeIngredientId',
        'form',
        'rawFoodReference',
      ]);
      _text(component['runtimeIngredientId']);
      _text(component['form']);
      _need(
        component['runtimeIngredientId'] == ingredient['id'] &&
            component['form'] == ingredient['note'] &&
            ingredient['optional'] ==
                (line['disposition'] == 'included-optional'),
        'Source component identity/form/optional mismatch',
      );
      final food = _map(component['rawFoodReference']);
      _keys(food, const ['foodId', 'foodVersion', 'foodSnapshotSha256']);
      _text(food['foodId']);
      _text(food['foodVersion']);
      _sha(food['foodSnapshotSha256']);
    }
  }
  _need(nextRuntimeIndex == ingredients.length, 'Unmapped runtime ingredients');
}
