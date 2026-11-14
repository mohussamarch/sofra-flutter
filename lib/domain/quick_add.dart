import 'ingredient_directory.dart';
import 'kitchen_core.dart';

/// One line of a typed list, a receipt or an online order, before the user
/// confirms it into stock. Nothing here is a guess the user cannot see: a line
/// without a known ingredient or amount stays without one.
class QuickLine {
  QuickLine({
    required this.raw,
    this.entry,
    this.sure = false,
    this.quantity,
    this.unit,
    this.paid,
  });

  /// What was typed or read, shown under the matched name.
  final String raw;

  /// The kitchen ingredient; null until the user picks one.
  IngredientEntry? entry;

  /// False when [entry] was found inside a longer text rather than named
  /// exactly: the review screen asks the user to look at it.
  bool sure;

  /// Both null when the amount is not known.
  double? quantity;
  String? unit;

  /// What the receipt says was paid for this line, if it says so.
  double? paid;

  bool include = true;

  bool get ready => include && entry != null;
}

/// Arabic-Indic and Persian digits and decimal marks to Latin.
String latinDigits(String value) {
  final out = StringBuffer();
  for (final r in value.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(r - 0x0660 + 0x30);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(r - 0x06F0 + 0x30);
    } else if (r == 0x066B) {
      out.write('.');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Unit words people type, to the unit the kitchen stores. Keys are already
/// normalized with [IngredientDirectory.normalizeArabic].
const _unitWords = <String, String>{
  'جم': 'g',
  'جرام': 'g',
  'غرام': 'g',
  'g': 'g',
  'gm': 'g',
  'gr': 'g',
  'gram': 'g',
  'grams': 'g',
  'كيلو': 'kg',
  'كجم': 'kg',
  'كغم': 'kg',
  'كغ': 'kg',
  'كيلوجرام': 'kg',
  'كيلوغرام': 'kg',
  'kg': 'kg',
  'kilo': 'kg',
  'kilos': 'kg',
  'مل': 'ml',
  'ملي': 'ml',
  'مللي': 'ml',
  'ml': 'ml',
  'لتر': 'l',
  'ليتر': 'l',
  'l': 'l',
  'lt': 'l',
  'ltr': 'l',
  'liter': 'l',
  'litre': 'l',
  'حبه': 'count',
  'حبات': 'count',
  'حبايه': 'count',
  'قطعه': 'count',
  'قطع': 'count',
  'pc': 'count',
  'pcs': 'count',
  'piece': 'count',
  'pieces': 'count',
  'كيس': 'كيس',
  'اكياس': 'كيس',
  'علبه': 'علبة',
  'علب': 'علبة',
  'زجاجه': 'زجاجة',
  'زجاجات': 'زجاجة',
  'ازازه': 'زجاجة',
  'قزازه': 'زجاجة',
  'برطمان': 'برطمان',
  'باكو': 'باكو',
  'ربطه': 'ربطة',
  'حزمه': 'ربطة',
  'كرتونه': 'كرتونة',
  'رغيف': 'رغيف',
  'ارغفه': 'رغيف',
  'راس': 'رأس',
  'عود': 'عود',
  'فص': 'فص',
  'عبوه': 'عبوة',
};

/// Dual forms: the word itself means two of the unit.
const _dualWords = <String, String>{
  'كيلوين': 'kg',
  'لترين': 'l',
  'حبتين': 'count',
  'قطعتين': 'count',
  'كيسين': 'كيس',
  'علبتين': 'علبة',
  'زجاجتين': 'زجاجة',
  'ازازتين': 'زجاجة',
  'برطمانين': 'برطمان',
  'باكوين': 'باكو',
  'ربطتين': 'ربطة',
  'كرتونتين': 'كرتونة',
  'رغيفين': 'رغيف',
};

const _numberWords = <String, double>{
  'نص': .5,
  'نصف': .5,
  'ربع': .25,
  'واحد': 1,
  'واحده': 1,
  'اتنين': 2,
  'اثنين': 2,
  'تلاته': 3,
  'ثلاثه': 3,
  'اربعه': 4,
  'خمسه': 5,
  'سته': 6,
  'سبعه': 7,
  'تمانيه': 8,
  'ثمانيه': 8,
  'تسعه': 9,
  'عشره': 10,
};

const _andFractions = <String, double>{'ونص': .5, 'ونصف': .5, 'وربع': .25};

String _norm(String v) => IngredientDirectory.normalizeArabic(v);

/// Units a line may keep for this ingredient: the ones it is stocked in, plus
/// the other size of the same measure (g with kg, ml with l).
bool unitFits(IngredientEntry entry, String unit) {
  final u = Units.canonical(unit);
  final own = entry.units.map(Units.canonical).toSet();
  if (own.contains(u)) return true;
  const families = [
    {'g', 'kg'},
    {'ml', 'l'},
  ];
  return families.any((f) => f.contains(u) && f.any(own.contains));
}

final _terms = Expando<List<(String, IngredientEntry, bool)>>();

List<(String, IngredientEntry, bool)> _termsOf(IngredientDirectory d) =>
    _terms[d] ??= [
      for (final e in d.entries) ...[
        (_norm(e.name), e, true),
        for (final a in e.aliases) (_norm(a), e, false),
      ],
    ];

String _dropArticle(String normalized) => normalized
    .split(' ')
    .map((w) => w.length > 4 && w.startsWith('ال') ? w.substring(2) : w)
    .join(' ');

/// The kitchen ingredient a free text names, with whether it names it exactly.
/// A longer text ("لبن جهينة كامل الدسم") takes the longest ingredient name
/// found in it as whole words, and is then not [sure].
({IngredientEntry entry, bool sure})? matchIngredient(
  IngredientDirectory directory,
  String text,
) {
  final plain = _norm(
    latinDigits(text)
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' '),
  );
  if (plain.isEmpty) return null;
  final terms = _termsOf(directory);
  for (final q in {plain, _dropArticle(plain)}) {
    for (final name in [true, false]) {
      for (final t in terms) {
        if (t.$3 == name && t.$1 == q) return (entry: t.$2, sure: true);
      }
    }
  }
  (String, IngredientEntry, bool)? best;
  for (final q in {plain, _dropArticle(plain)}) {
    final padded = ' $q ';
    for (final t in terms) {
      if (t.$1.length < 2 || !padded.contains(' ${t.$1} ')) continue;
      if (best == null ||
          t.$1.length > best.$1.length ||
          (t.$1.length == best.$1.length && t.$3 && !best.$3)) {
        best = t;
      }
    }
  }
  return best == null ? null : (entry: best.$2, sure: false);
}

/// Reads a typed or pasted list ("2 كيلو طماطم، لبن، 6 بيض") into lines.
/// Runs on the device, with no network.
List<QuickLine> parseQuickText(String text, IngredientDirectory directory) {
  final lines = <QuickLine>[];
  for (final part in latinDigits(text).split(RegExp(r'[\n\r,،;؛+]+'))) {
    final raw = part
        .replaceFirst(RegExp(r'^\s*(?:[-•*·]+|\d+[.)])\s*'), '')
        .trim();
    if (raw.isEmpty) continue;
    double? quantity;
    String? unit;
    final name = <String>[];
    final tokens = raw.split(RegExp(r'\s+'));
    var afterNumber = false;
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final n = _norm(token);
      final wasNumber = afterNumber;
      afterNumber = false;
      final nextIsUnit =
          i + 1 < tokens.length &&
          (_unitWords[_norm(tokens[i + 1])] ??
                  _dualWords[_norm(tokens[i + 1])]) !=
              null;
      final number = RegExp(r'^(\d+(?:\.\d+)?)(?:/(\d+))?(.*)$').firstMatch(n);
      if (number != null && quantity == null) {
        final tail = number[3]!;
        final tailUnit = tail.isEmpty ? null : _unitWords[tail];
        final top = double.parse(number[1]!);
        final bottom = number[2] == null ? 1.0 : double.parse(number[2]!);
        if ((tail.isEmpty || tailUnit != null) && bottom > 0 && top > 0) {
          quantity = top / bottom;
          unit ??= tailUnit;
          afterNumber = tailUnit == null;
          continue;
        }
      }
      if (_numberWords[n] != null &&
          quantity == null &&
          (name.isEmpty || nextIsUnit)) {
        quantity = _numberWords[n];
        afterNumber = true;
        continue;
      }
      if (_andFractions[n] != null && unit != null && quantity != null) {
        quantity += _andFractions[n]!;
        continue;
      }
      // A unit word counts at the start ("كيلو طماطم") or right after the
      // number ("طماطم 2 كيلو"), never in the middle of a name.
      if (unit == null && (name.isEmpty || wasNumber)) {
        if (_dualWords[n] != null && quantity == null) {
          unit = _dualWords[n];
          quantity = 2;
          continue;
        }
        if (_unitWords[n] != null) {
          unit = _unitWords[n];
          quantity ??= 1;
          continue;
        }
      }
      name.add(token);
    }
    if (unit != null) quantity ??= 1;
    final label = name.join(' ');
    final found = matchIngredient(directory, label);
    if (!(found?.sure ?? false) && quantity == null) {
      // "طماطم وخيار": two things joined by "و".
      final pieces = label.split(RegExp(r'\s+و(?=\S)'));
      final each = [for (final p in pieces) matchIngredient(directory, p)];
      if (pieces.length > 1 && each.every((m) => m != null)) {
        for (var i = 0; i < pieces.length; i++) {
          lines.add(
            QuickLine(
              raw: pieces[i].trim(),
              entry: each[i]!.entry,
              sure: each[i]!.sure,
            ),
          );
        }
        continue;
      }
    }
    final line = QuickLine(
      raw: raw,
      entry: found?.entry,
      sure: found?.sure ?? false,
    );
    setAmount(line, quantity, unit);
    lines.add(line);
  }
  return lines;
}

/// Keeps an amount on a line only when it makes sense for its ingredient: a
/// bare number counts pieces only for things kept by the piece, and a unit the
/// ingredient is not kept in is dropped rather than converted by guess.
void setAmount(QuickLine line, double? quantity, String? unit) {
  final entry = line.entry;
  line
    ..quantity = null
    ..unit = null;
  if (quantity == null || quantity <= 0 || !quantity.isFinite) return;
  if (entry == null) {
    line
      ..quantity = quantity
      ..unit = unit;
    return;
  }
  final u =
      unit ??
      (entry.units.map(Units.canonical).contains('count') ? 'count' : null);
  if (u == null || !unitFits(entry, u)) return;
  line
    ..quantity = quantity
    ..unit = Units.canonical(u);
}
