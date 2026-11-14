import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/ingredient_directory.dart';
import '../domain/quick_add.dart';

/// Reads what was bought from a receipt photo, an order screenshot or a
/// messy pasted text. The result is only a draft the user reviews.
abstract class PurchaseReader {
  Future<List<QuickLine>> readImage(
    Uint8List bytes,
    String mimeType,
    IngredientDirectory directory,
  );
  Future<List<QuickLine>> readText(String text, IngredientDirectory directory);
}

/// The reader this build can use, or null when there is none (no Firebase
/// app): photo reading is then switched off and typing still works. Tests
/// replace it.
PurchaseReader? Function() purchaseReader = () =>
    Firebase.apps.isEmpty ? null : GeminiPurchaseReader();

/// Gemini through Firebase AI Logic on the app's own Firebase project. The
/// image goes to Google for this one request and is not stored by the app.
class GeminiPurchaseReader implements PurchaseReader {
  static const model = String.fromEnvironment(
    'SOFRA_READER_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );

  static const _rules = '''
You read grocery receipts, online grocery order screenshots and shopping lists from Egypt and Saudi Arabia, written in Arabic or English.
Return every food or cooking ingredient that was bought as one item. Skip totals, tax, discounts, delivery fees, bags, cleaning products and anything that is not food.
For each item:
- raw: the product text as written, kept short.
- id: the id from the INGREDIENTS list that this product is. Ignore the brand and choose the plain ingredient. Use an empty string when nothing in the list fits; never force a fit.
- name: the plain Arabic name of the ingredient.
- quantity and unit: the total amount bought, only when it is written or follows directly from a written pack size and count (2 x 1 L is 2 l). The unit must be one of the units listed for that ingredient, or g, kg, ml or l. When the amount is not written, give quantity 0 and an empty unit.
- paid: the line total as written, or 0 when no price is written.
Never invent a value that is not written.
INGREDIENTS (id | name | units):
''';

  String _prompt(IngredientDirectory d) =>
      _rules +
      [for (final e in d.entries) '${e.id} | ${e.name} | ${e.units.join(', ')}']
          .join('\n');

  GenerativeModel _model() => FirebaseAI.googleAI().generativeModel(
    model: model,
    generationConfig: GenerationConfig(
      temperature: 0,
      responseMimeType: 'application/json',
      responseSchema: Schema.object(
        properties: {
          'items': Schema.array(
            items: Schema.object(
              properties: {
                'raw': Schema.string(),
                'id': Schema.string(),
                'name': Schema.string(),
                'quantity': Schema.number(),
                'unit': Schema.string(),
                'paid': Schema.number(),
              },
            ),
          ),
        },
      ),
    ),
  );

  @override
  Future<List<QuickLine>> readImage(
    Uint8List bytes,
    String mimeType,
    IngredientDirectory directory,
  ) async {
    final response = await _model().generateContent([
      Content.multi([
        TextPart(_prompt(directory)),
        InlineDataPart(mimeType, bytes),
      ]),
    ]);
    return linesFromReply(response.text, directory);
  }

  @override
  Future<List<QuickLine>> readText(
    String text,
    IngredientDirectory directory,
  ) async {
    final response = await _model().generateContent([
      Content.text('${_prompt(directory)}\n\nTEXT TO READ:\n$text'),
    ]);
    return linesFromReply(response.text, directory);
  }
}

/// Turns the reader's JSON reply into draft lines, trusting nothing in it: an
/// unknown id falls back to matching the name, and an amount that does not
/// suit the ingredient is dropped.
List<QuickLine> linesFromReply(String? reply, IngredientDirectory directory) {
  if (reply == null || reply.trim().isEmpty) return const [];
  final decoded = jsonDecode(reply);
  final items = decoded is Map ? decoded['items'] : decoded;
  if (items is! List) return const [];
  final lines = <QuickLine>[];
  for (final item in items) {
    if (item is! Map) continue;
    String text(String key) =>
        (item[key] is String ? item[key] as String : '').trim();
    double? number(String key) {
      final v = item[key];
      return v is num && v.isFinite && v > 0 ? v.toDouble() : null;
    }

    final name = text('name');
    final raw = text('raw').isEmpty ? name : text('raw');
    if (raw.isEmpty) continue;
    final byId = directory.entry(text('id'));
    final byName = byId == null
        ? matchIngredient(directory, name.isEmpty ? raw : name)
        : null;
    final line = QuickLine(
      raw: raw,
      entry: byId ?? byName?.entry,
      sure: byId != null || (byName?.sure ?? false),
      paid: number('paid'),
    );
    final unit = text('unit');
    setAmount(line, number('quantity'), unit.isEmpty ? null : unit);
    lines.add(line);
  }
  return lines;
}
