import 'package:flutter/material.dart';

import '../domain/ingredient_directory.dart';
import '../domain/kitchen_core.dart';
import '../domain/models.dart';
import '../domain/recipe_catalog.dart';
import '../ui/design.dart';

/// Scrollable screen body with an optional pinned footer action.
class ScreenBody extends StatelessWidget {
  const ScreenBody({
    super.key,
    required this.children,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 120),
  });
  final List<Widget> children;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
      if (footer != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Sofra.cream,
            border: Border(top: BorderSide(color: Sofra.line)),
          ),
          child: footer,
        ),
    ],
  );
}

Widget introBlock(String title, String subtitle, {required IconData icon}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Sofra.mint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Sofra.green, size: 30),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(color: Sofra.muted, fontSize: 16),
        ),
      ],
    );

Widget summaryLine(IconData icon, String title, String subtitle) => Row(
  children: [
    Icon(icon, color: Sofra.green, size: 24),
    const SizedBox(width: 12),
    Expanded(
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    const SizedBox(width: 12),
    Flexible(
      child: Text(
        subtitle,
        textAlign: TextAlign.end,
        style: const TextStyle(color: Sofra.muted, fontSize: 12),
      ),
    ),
  ],
);

Widget noteText(String text, {TextAlign align = TextAlign.start}) => Text(
  text,
  textAlign: align,
  style: const TextStyle(color: Sofra.muted, fontSize: 11),
);

String zoneName(StorageZone value) => switch (value) {
  StorageZone.fridge => 'التلاجة',
  StorageZone.freezer => 'الفريزر',
  StorageZone.pantry => 'الدولاب',
};

IconData categoryIcon(String? category) => switch (category) {
  'خضار' || 'فاكهة' => Icons.eco_outlined,
  'توابل' => Icons.spa_outlined,
  'زيوت' || 'صوصات' => Icons.water_drop_outlined,
  'مخبوزات' => Icons.bakery_dining_outlined,
  'بقوليات' || 'مكسرات' => Icons.grain_rounded,
  'مشروبات' => Icons.local_cafe_outlined,
  'بروتين' => Icons.egg_alt_outlined,
  'حبوب' => Icons.grain_rounded,
  'ألبان' => Icons.local_drink_outlined,
  _ => Icons.kitchen_outlined,
};

String formatAmount(double value) => recipeNumber(value);

/// Arabic count phrase: "حاجة واحدة", "حاجتين", "3 حاجات", "11 حاجة".
String countText(
  int n,
  String one,
  String two,
  String few, {
  String empty = '',
}) => switch (n) {
  0 => empty,
  1 => '$one واحدة',
  2 => two,
  >= 3 && <= 10 => '$n $few',
  _ => '$n $one',
};

/// Arabic label for a canonical unit; counted units are already Arabic.
String unitLabel(String? unit) => unit == null ? '' : Units.label(unit);

/// "عندك 3 حبة" style amount with an Arabic unit.
String amountLabel(double value, String? unit) =>
    '${formatAmount(value)} ${unitLabel(unit)}'.trim();

/// Minutes from the catalog may be unknown; never shown as zero.
String minutesLabel(Object? minutes) =>
    minutes is num ? '${minutes.round()} دقيقة' : 'الوقت غير محدد';

/// Stable illustration choice for a recipe without real photos yet.
int artKind(String id) => id.codeUnits.fold(0, (a, b) => a + b) % 4;

/// Name-only match against the user's allergy notes: each note with the
/// recipe lines whose name, or a name of the kitchen ingredient the line maps
/// to ([names]), contains it (alef/ta marbuta/ya forms alike). It is a
/// reminder to read the ingredients, never a safety guarantee: a group word
/// like "ألبان" does not find cheese unless a name says so.
Map<String, List<String>> allergyMatches(
  CatalogRecipe recipe,
  Set<String> allergies, {
  Iterable<String> Function(CatalogIngredient line)? names,
}) {
  final found = <String, List<String>>{};
  for (final a in allergies) {
    final key = IngredientDirectory.normalizeArabic(a);
    if (key.isEmpty) continue;
    for (final line in recipe.ingredients) {
      final hit = [
        line.name,
        ...?names?.call(line),
      ].any((n) => IngredientDirectory.normalizeArabic(n).contains(key));
      if (hit) (found[a] ??= []).add(line.name);
    }
  }
  return found;
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Center(child: CircularProgressIndicator()),
  );
}

class ErrorBlock extends StatelessWidget {
  const ErrorBlock(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Surface(
    color: Sofra.peach,
    child: Text(message, style: const TextStyle(color: Color(0xFF79513D))),
  );
}
