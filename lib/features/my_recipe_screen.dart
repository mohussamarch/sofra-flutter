import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/ingredient_directory.dart';
import '../domain/recipe_variants.dart';
import '../ui/design.dart';
import 'common.dart';

const _categories = ['أطباق رئيسية', 'فطار', 'شوربة', 'سلطات', 'حلويات'];
const _levels = ['سهل', 'متوسط', 'صعب'];
const _cuisines = ['مصري', 'شامي', 'خليجي', 'مغربي', 'تركي', 'إيطالي'];
const _units = ['g', 'kg', 'ml', 'l', 'count'];

/// The user's own recipes over the book: a row to open them and to write a
/// new one.
class MyRecipesStrip extends StatelessWidget {
  const MyRecipesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final mine = SofraScope.controllerOf(context).myRecipes;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SofraChip(
            key: const ValueKey('my-recipe-new'),
            avatar: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('وصفة من عندي'),
            onPressed: () => _open(context, const MyRecipeScreen()),
          ),
          for (final r in mine)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: SofraChip(
                key: ValueKey('my-recipe-${r.variantId}'),
                avatar: const Icon(Icons.bookmark_rounded, size: 16),
                label: Text(r.recipe.name),
                onPressed: () => _planMine(context, r),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _open(BuildContext context, Widget page) {
  final scope = SofraScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: Directionality(textDirection: TextDirection.rtl, child: page),
      ),
    ),
  );
}

/// Puts one of the user's recipes on the table: which day and which meal.
Future<void> _planMine(BuildContext context, RecipeRevision r) async {
  final c = SofraScope.controllerOf(context);
  var tomorrow = false;
  var slot = 'lunch';
  final ok = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.recipe.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${r.recipe.ingredients.length} مكونات · ${r.recipe.steps.length} خطوات',
                  style: const TextStyle(color: Sofra.muted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    SofraChip(
                      label: Text(c.market.today),
                      selected: !tomorrow,
                      onSelected: (_) => set(() => tomorrow = false),
                    ),
                    SofraChip(
                      label: const Text('غدًا'),
                      selected: tomorrow,
                      onSelected: (_) => set(() => tomorrow = true),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final MapEntry(key: s, value: label)
                        in mealSlots.entries)
                      SofraChip(
                        label: Text(label),
                        selected: slot == s,
                        onSelected: (_) => set(() => slot = s),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DepthButton(
                  key: const ValueKey('my-recipe-plan'),
                  label: 'ضعها على السفرة',
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (ok != true) return;
  final now = DateTime.now();
  final planned = await c.planMeal(
    r.variantId,
    day: tomorrow ? now.add(const Duration(days: 1)) : now,
    slot: slot,
    servings: c.profile.servings,
  );
  if (planned && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('أُضيفت إلى السفرة.')));
  }
}

class _Line {
  _Line(this.entry);
  final IngredientEntry entry;
  final amount = TextEditingController();
  late String unit = _units.contains(entry.defaultUnit)
      ? entry.defaultUnit
      : 'g';
  bool measured = true;
}

class _Step {
  final text = TextEditingController();
  final minutes = TextEditingController();
}

/// Writes a recipe of the user's own: every amount, time and step is what
/// they type. Nothing is guessed; nutrition stays unknown.
class MyRecipeScreen extends StatefulWidget {
  const MyRecipeScreen({super.key});
  @override
  State<MyRecipeScreen> createState() => _MyRecipeScreenState();
}

class _MyRecipeScreenState extends State<MyRecipeScreen> {
  final name = TextEditingController();
  final cuisine = TextEditingController(text: 'مصري');
  final prep = TextEditingController();
  final cook = TextEditingController();
  final description = TextEditingController();
  int servings = 4;
  String category = _categories.first;
  String difficulty = _levels.first;
  final lines = <_Line>[];
  final steps = <_Step>[_Step()];
  bool busy = false;
  String? error;

  int? _int(TextEditingController t) => int.tryParse(t.text.trim());

  bool get _ready =>
      name.text.trim().isNotEmpty &&
      cuisine.text.trim().isNotEmpty &&
      description.text.trim().isNotEmpty &&
      (_int(prep) ?? -1) >= 0 &&
      (_int(cook) ?? -1) >= 0 &&
      lines.isNotEmpty &&
      lines.every(
        (l) => !l.measured || (double.tryParse(l.amount.text.trim()) ?? 0) > 0,
      ) &&
      steps.isNotEmpty &&
      steps.every(
        (s) =>
            s.text.text.trim().isNotEmpty &&
            (double.tryParse(s.minutes.text.trim()) ?? -1) >= 0,
      );

  Future<void> _addLine() async {
    final directory = SofraScope.controllerOf(context).directory;
    if (directory == null) return;
    final picked = await showModalBottomSheet<IngredientEntry>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _IngredientPicker(directory: directory),
      ),
    );
    if (picked != null) setState(() => lines.add(_Line(picked)));
  }

  Future<void> _save() async {
    final c = SofraScope.controllerOf(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await c.createMyRecipe(
        name: name.text,
        servings: servings,
        cuisine: cuisine.text,
        prepMinutes: _int(prep)!,
        cookMinutes: _int(cook)!,
        category: category,
        description: description.text,
        difficulty: difficulty,
        lines: [
          for (final l in lines)
            MyRecipeLine(
              l.entry.id,
              l.entry.name,
              amount: l.measured ? double.parse(l.amount.text.trim()) : null,
              unit: l.measured ? l.unit : null,
            ),
        ],
        steps: [
          for (final s in steps)
            (s.text.text, double.parse(s.minutes.text.trim())),
        ],
      );
      if (!mounted) return;
      if (id == null) {
        setState(() => error = 'لم تُحفظ الوصفة. حاول مرة أخرى.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظت الوصفة في وصفاتك.')),
        );
        Navigator.pop(context);
      }
    } on ArgumentError {
      setState(() => error = 'اكتب مطبخًا محددًا للوصفة، مثل «مصري».');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void touch(_) => setState(() {});
    const number = TextInputType.number;
    return Scaffold(
      backgroundColor: Sofra.cream,
      appBar: AppBar(
        title: const Text('وصفة من عندي'),
        backgroundColor: Sofra.cream,
      ),
      body: ScreenBody(
        footer: DepthButton(
          key: const ValueKey('my-recipe-save'),
          label: busy ? 'جارٍ الحفظ…' : 'احفظ الوصفة',
          onPressed: _ready && !busy ? _save : null,
        ),
        children: [
          TextField(
            key: const ValueKey('my-recipe-name'),
            controller: name,
            onChanged: touch,
            decoration: const InputDecoration(labelText: 'اسم الأكلة'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('my-recipe-description'),
            controller: description,
            onChanged: touch,
            decoration: const InputDecoration(labelText: 'وصف قصير'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('my-recipe-cuisine'),
            controller: cuisine,
            onChanged: touch,
            decoration: const InputDecoration(labelText: 'المطبخ'),
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final k in _cuisines)
                SofraChip(
                  label: Text(k),
                  onPressed: () => setState(() => cuisine.text = k),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('my-recipe-prep'),
                  controller: prep,
                  onChanged: touch,
                  keyboardType: number,
                  decoration: const InputDecoration(
                    labelText: 'التحضير (دقيقة)',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const ValueKey('my-recipe-cook'),
                  controller: cook,
                  onChanged: touch,
                  keyboardType: number,
                  decoration: const InputDecoration(labelText: 'الطبخ (دقيقة)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('تكفي كم فردًا؟')),
              IconButton(
                onPressed: servings > 1
                    ? () => setState(() => servings--)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Text(
                '$servings',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => servings++),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final k in _categories)
                SofraChip(
                  label: Text(k),
                  selected: category == k,
                  onSelected: (_) => setState(() => category = k),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final k in _levels)
                SofraChip(
                  label: Text(k),
                  selected: difficulty == k,
                  onSelected: (_) => setState(() => difficulty = k),
                ),
            ],
          ),
          SectionTitle('المكونات', action: '+ مكوّن', onAction: _addLine),
          for (final (i, l) in lines.indexed)
            Padding(
              key: ValueKey('my-recipe-line-${l.entry.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(l.entry.name)),
                  if (l.measured) ...[
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: const ValueKey('my-recipe-amount'),
                        controller: l.amount,
                        onChanged: touch,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: l.unit,
                      items: [
                        for (final u in _units)
                          DropdownMenuItem(value: u, child: Text(unitLabel(u))),
                      ],
                      onChanged: (u) => setState(() => l.unit = u!),
                    ),
                  ] else
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'حسب الرغبة',
                        style: TextStyle(color: Sofra.muted),
                      ),
                    ),
                  IconButton(
                    tooltip: l.measured ? 'دون كمية' : 'بكمية',
                    onPressed: () => setState(() => l.measured = !l.measured),
                    icon: Icon(
                      l.measured
                          ? Icons.straighten_rounded
                          : Icons.scale_outlined,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'احذف',
                    onPressed: () => setState(() => lines.removeAt(i)),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
          SectionTitle(
            'الخطوات',
            action: '+ خطوة',
            onAction: () => setState(() => steps.add(_Step())),
          ),
          for (final (i, s) in steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text('${i + 1}.'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      key: ValueKey('my-recipe-step-$i'),
                      controller: s.text,
                      onChanged: touch,
                      maxLines: null,
                      decoration: const InputDecoration(hintText: 'ماذا ستفعل'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: ValueKey('my-recipe-step-minutes-$i'),
                      controller: s.minutes,
                      onChanged: touch,
                      keyboardType: number,
                      decoration: const InputDecoration(hintText: 'دقيقة'),
                    ),
                  ),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ErrorBlock(error!),
            ),
          const SizedBox(height: 8),
          const Text(
            'لن تُحسب القيم الغذائية لهذه الوصفة حتى تُربط مكوناتها بمصدر.',
            style: TextStyle(color: Sofra.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IngredientPicker extends StatefulWidget {
  const _IngredientPicker({required this.directory});
  final IngredientDirectory directory;
  @override
  State<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<_IngredientPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final found = query.trim().isEmpty
        ? widget.directory.entries.take(30).toList()
        : widget.directory.search(query);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const ValueKey('my-recipe-ingredient-search'),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن مكوّن',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final e in found)
                    ListTile(
                      key: ValueKey('my-recipe-pick-${e.id}'),
                      title: Text(e.name),
                      subtitle: Text(e.category),
                      onTap: () => Navigator.pop(context, e),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
