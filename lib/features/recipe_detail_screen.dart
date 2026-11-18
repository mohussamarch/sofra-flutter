import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/recipe_photo_library.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_catalog.dart';
import '../ui/design.dart';
import '../ui/flags.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'dish_sheet.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.compare = false,
  });
  final String recipeId;

  /// Opened from a dish's card: no country chosen yet, the ways' ingredients
  /// compared.
  final bool compare;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Future<(CatalogRecipe, CatalogRecipe)>? recipe;

  /// The dish this recipe is one way of, with its ways' index rows.
  Future<(Dish, List<Map<String, dynamic>>)?>? dish;
  int? servings;
  int yieldGuess = 4;
  bool starting = false;
  String cookingSlot = 'lunch';

  SofraController get c => SofraScope.controllerOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    recipe ??= _load();
    dish ??= _dish();
  }

  Future<(Dish, List<Map<String, dynamic>>)?> _dish() async {
    try {
      final found = (await c.recipes.dishes).where(
        (d) => d.recipes.contains(widget.recipeId),
      );
      if (found.isEmpty) return null;
      final rows = {
        for (final r in await c.recipes.index) r['id'] as String: r,
      };
      final d = found.first;
      return (d, [for (final id in d.recipes) rows[id]!]);
    } on Object {
      // The dish grouping is an extra: the recipe opens on its own.
      return null;
    }
  }

  /// The dish's countries as one bar; the chosen way is filled with its
  /// colour. Choosing it again goes back to comparing.
  Widget _bar(List<Map<String, dynamic>> ways) {
    final nav = SofraScope.navOf(context);
    final seen = <String, int>{};
    return SingleChildScrollView(
      key: const ValueKey('country-bar'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, w) in ways.indexed)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Builder(
                builder: (context) {
                  final id = w['id'] as String;
                  final cuisine = '${w['cuisine']}';
                  final n = seen[cuisine] = (seen[cuisine] ?? 0) + 1;
                  final on = !widget.compare && id == widget.recipeId;
                  final color = wayColors[i % wayColors.length];
                  return Semantics(
                    button: true,
                    selected: on,
                    child: Material(
                      color: on ? color : Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(color: color, width: 2),
                      ),
                      child: InkWell(
                        key: ValueKey('way-$id'),
                        customBorder: const StadiumBorder(),
                        onTap: () => on
                            ? nav.openRecipe(widget.recipeId, compare: true)
                            : nav.openRecipe(id),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            6,
                            6,
                            14,
                            6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CuisineFlag(cuisine, size: 26),
                              const SizedBox(width: 8),
                              Text(
                                n > 1 ? '$cuisine $n' : cuisine,
                                style: TextStyle(
                                  color: on ? Colors.white : Sofra.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// (catalog source for display, planning copy that may carry a yield).
  Future<(CatalogRecipe, CatalogRecipe)> _load() async {
    final source = await c.recipes.get(widget.recipeId);
    return (source, await c.planningRecipe(widget.recipeId));
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(Dish, List<Map<String, dynamic>>)?>(
    future: dish,
    builder: (context, found) {
      if (found.connectionState != ConnectionState.done) {
        return const LoadingBlock();
      }
      final ways = found.data;
      if (widget.compare && ways != null) {
        return _CompareView(dish: ways.$1, ways: ways.$2, bar: _bar(ways.$2));
      }
      return FutureBuilder<(CatalogRecipe, CatalogRecipe)>(
        future: recipe,
        builder: (context, snap) {
          if (snap.hasError) {
            return const ScreenBody(
              children: [ErrorBlock('تعذّر فتح الوصفة. ارجع وحاول مرة أخرى.')],
            );
          }
          final data = snap.data;
          if (data == null) return const LoadingBlock();
          return _detail(data.$1, data.$2, ways == null ? null : _bar(ways.$2));
        },
      );
    },
  );

  Widget _detail(CatalogRecipe source, CatalogRecipe planning, Widget? bar) {
    final c = this.c;
    final known = planning.servings != null;
    final people = servings ?? c.profile.servings;
    final scaled = known ? planning.forServings(people) : null;
    final check = scaled == null ? null : c.checkStock(scaled);
    final allergy = allergyMatches(
      source,
      c.profile.allergies,
      names: c.stockNames,
    );
    return ScreenBody(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DepthButton(
            key: const ValueKey('cook-now'),
            label: starting ? 'بنجهّز الطبخة…' : 'أطبخ الآن',
            onPressed: known && !starting ? () => _cookNow(people) : null,
          ),
          const SizedBox(height: 6),
          const Text(
            'تُحفظ كوجبة لليوم لاستكمالها. لا خصم قبل التأكيد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Sofra.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          DepthButton(
            key: const ValueKey('plan-meal'),
            compact: true,
            secondary: true,
            label: 'أضيف للخطة',
            onPressed: known && !starting ? () => _plan(people) : null,
          ),
        ],
      ),
      children: [
        FutureBuilder<List<RecipePhoto>>(
          future: c.photosOf(source.id),
          builder: (context, snap) {
            final photo = snap.data?.firstOrNull;
            if (photo == null) {
              return Surface(
                color: const Color(0xFFF0EDD8),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: MealArt(kind: artKind(source.id), size: 260),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      photo.asset,
                      key: const ValueKey('recipe-photo'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  'الصورة: ${photo.credit} · ${photo.licence}',
                  style: const TextStyle(color: Sofra.muted, fontSize: 11),
                ),
              ],
            );
          },
        ),
        if (bar != null) ...[const SizedBox(height: 14), bar],
        const SizedBox(height: 22),
        Text(
          source.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 27,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        if (source.description.isNotEmpty)
          Text(source.description, style: const TextStyle(color: Sofra.muted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SoftTag(
              minutesLabel(scaled?.totalMinutes ?? source.totalMinutes),
              icon: Icons.schedule_rounded,
            ),
            SoftTag(source.cuisine),
            SoftTag(source.category),
            if (source.difficulty.isNotEmpty) SoftTag(source.difficulty),
          ],
        ),
        const SizedBox(height: 20),
        if (known)
          Surface(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نطبخ لكم شخصًا؟',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'تُضبط الكميات تلقائيًا',
                        style: TextStyle(fontSize: 11, color: Sofra.muted),
                      ),
                    ],
                  ),
                ),
                Counter(
                  value: people,
                  onChanged: (v) => setState(() => servings = v),
                ),
              ],
            ),
          )
        else
          _yieldReview(),
        if (known) ...[
          const SizedBox(height: 12),
          const Text('أسجّل الطبخة كـ'),
          Wrap(
            spacing: 8,
            children: [
              for (final slot in mealSlots.entries)
                SofraChip(
                  key: ValueKey('cook-slot-${slot.key}'),
                  label: Text(slot.value),
                  selected: cookingSlot == slot.key,
                  onSelected: starting
                      ? null
                      : (_) => setState(() => cookingSlot = slot.key),
                ),
            ],
          ),
        ],
        if (allergy.isNotEmpty || c.profile.allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Surface(
              color: Sofra.peach,
              padding: const EdgeInsets.all(16),
              child: Text(
                allergy.isNotEmpty
                    ? 'انتبه: ${allergy.entries.map((e) => '«${e.key}» في ${e.value.join('، ')}').join('؛ ')}. المطابقة بالاسم بس، راجع المكونات والعبوات بنفسك.'
                    : 'راجع مكونات الوصفة والعبوات مع الحساسية المسجّلة: ${c.profile.allergies.join('، ')}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF79513D)),
              ),
            ),
          ),
        SectionTitle(known ? 'المكونات على قدركم' : 'المكونات كما في المصدر'),
        for (var i = 0; i < source.ingredients.length; i++)
          _IngredientRow(
            ingredient: (scaled?.recipe ?? source).ingredients[i],
            amount: scaled != null
                ? scaled.display(scaled.recipe.ingredients[i])
                : _sourceAmount(source.ingredients[i]),
            line: check?.lines[i],
          ),
        const SectionTitle('الخطوات'),
        for (final step in source.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Sofra.mint,
                    child: Text(
                      '${step.number}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Sofra.greenDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(step.text)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        noteText(
          'لا تظهر الأسعار والقيم الغذائية هنا حتى تُراجع من مصادرها. الكميات من المصدر.',
        ),
      ],
    );
  }

  String _sourceAmount(CatalogIngredient i) =>
      i.display ??
      (i.amount == null
          ? i.label ?? i.note ?? 'حسب الرغبة'
          : '${formatAmount(i.amount!)} ${i.unit ?? ''}'.trim());

  Widget _yieldReview() => Surface(
    color: const Color(0xFFFFF3D4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'لم يذكر المصدر عدد من تكفيهم هذه الوصفة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'لنضبط الكميات ونضعها على السفرة، أخبرنا كم فردًا تكفي الوصفة كلها تقريبًا. الوصفة الأصلية لن تتغير.',
          style: TextStyle(fontSize: 12, color: Sofra.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Counter(
              value: yieldGuess,
              onChanged: (v) => setState(() => yieldGuess = v),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DepthButton(
                key: const ValueKey('review-yield'),
                compact: true,
                label: 'تكفي $yieldGuess أفراد',
                onPressed: () async {
                  if (await c.reviewYield(widget.recipeId, yieldGuess)) {
                    setState(() => recipe = _load());
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _cookNow(int people) async {
    if (starting) return;
    final nav = SofraScope.navOf(context);
    setState(() => starting = true);
    try {
      final meal = await c.prepareCooking(
        widget.recipeId,
        servings: people,
        slot: cookingSlot,
      );
      if (mounted && meal != null) nav.startCooking(meal);
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> _plan(int people) async {
    final nav = SofraScope.navOf(context);
    final choice = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PlanSheet(defaultSlot: _defaultSlot()),
      ),
    );
    if (choice == null || !mounted) return;
    final ok = await c.planMeal(
      widget.recipeId,
      day: choice.$1,
      slot: choice.$2,
      servings: people,
    );
    if (!ok) return;
    nav.goTab(AppTab.table);
    nav.notify('الوجبة على السفرة، والمخزون لم يتغير');
  }

  String _defaultSlot() {
    final meals = c.profile.meals;
    if (meals.contains('غداء')) return 'lunch';
    if (meals.contains('عشاء')) return 'dinner';
    return 'breakfast';
  }
}

/// A dish with no country chosen: its ways' ingredients in one list. What
/// every way uses is plain; what only some use is tinted with that way's
/// colour and carries its flag, so the difference shows at a glance.
class _CompareView extends StatefulWidget {
  const _CompareView({
    required this.dish,
    required this.ways,
    required this.bar,
  });
  final Dish dish;
  final List<Map<String, dynamic>> ways;
  final Widget bar;

  @override
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  Future<List<CatalogRecipe>>? recipes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = SofraScope.controllerOf(context);
    recipes ??= Future.wait([
      for (final w in widget.ways) c.recipes.get(w['id'] as String),
    ]);
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      Surface(
        color: const Color(0xFFF0EDD8),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: MealArt(
            kind: artKind(widget.ways.first['id'] as String),
            size: 220,
          ),
        ),
      ),
      const SizedBox(height: 14),
      widget.bar,
      const SizedBox(height: 22),
      Text(
        widget.dish.name,
        key: const ValueKey('compare-title'),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 27,
          height: 1.3,
        ),
      ),
      Text(
        '${waysLabel(widget.ways.length)} لعملها',
        style: const TextStyle(color: Sofra.muted),
      ),
      const SectionTitle('المكونات'),
      FutureBuilder<List<CatalogRecipe>>(
        future: recipes,
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorBlock('تعذّر فتح الطرق. ارجع وحاول مرة أخرى.');
          }
          final all = snap.data;
          if (all == null) return const LoadingBlock();
          final cuisines = [for (final w in widget.ways) '${w['cuisine']}'];
          return Column(
            children: [
              for (final l in compareIngredients(all))
                _CompareRow(
                  key: ValueKey('compare-${l.id}'),
                  name: l.name,
                  ways: l.ways.length == all.length ? const [] : l.ways,
                  cuisines: cuisines,
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      const Surface(
        key: ValueKey('compare-pick'),
        border: true,
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.arrow_upward_rounded, color: Sofra.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'اختر بلدًا من الشريط لترى الكميات والخطوات.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One ingredient of a compared dish: its name and the ways (indices) that
/// use it.
class ComparedLine {
  const ComparedLine(this.id, this.name, this.ways);
  final String id, name;
  final List<int> ways;
}

/// Every ingredient of [recipes] once, by ingredient id, in the first way's
/// order and then each next way's additions; each with the ways that use it.
List<ComparedLine> compareIngredients(List<CatalogRecipe> recipes) {
  final names = <String, String>{};
  final ways = <String, List<int>>{};
  for (final (i, r) in recipes.indexed) {
    for (final line in r.ingredients) {
      names.putIfAbsent(line.id, () => line.name);
      final used = ways.putIfAbsent(line.id, () => []);
      if (!used.contains(i)) used.add(i);
    }
  }
  return [for (final id in names.keys) ComparedLine(id, names[id]!, ways[id]!)];
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    super.key,
    required this.name,
    required this.ways,
    required this.cuisines,
  });
  final String name;

  /// The ways using it; empty when every way does.
  final List<int> ways;
  final List<String> cuisines;

  @override
  Widget build(BuildContext context) {
    final own = ways.length == 1
        ? wayColors[ways.single % wayColors.length]
        : null;
    return Semantics(
      label: ways.isEmpty
          ? name
          : '$name: ${[for (final i in ways) cuisines[i]].join('، ')}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: ways.isEmpty
              ? Colors.white
              : own?.withValues(alpha: .13) ?? Sofra.sand,
          borderRadius: BorderRadius.circular(Sofra.r16),
          border: own == null
              ? null
              : BorderDirectional(start: BorderSide(color: own, width: 4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: own ?? Sofra.ink,
                ),
              ),
            ),
            for (final i in ways)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: CuisineFlag(cuisines[i], size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.amount,
    required this.line,
  });
  final CatalogIngredient ingredient;
  final String amount;
  final CookingLine? line;

  /// Asks "1 cup of rice = ? g" and saves it as this ingredient's own rule.
  Future<void> _defineRule(BuildContext context) async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final id = c.stockId(ingredient.id);
    final from = ingredient.unit!;
    final to = c.stockUnit(id)!;
    final name = c.ingredientName(id);
    var input = '';
    final form = GlobalKey<FormState>();
    final factor = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حدد التحويل'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 ${unitLabel(from)} من $name = كم ${unitLabel(to)}؟'),
                const SizedBox(height: 4),
                const Text(
                  'اكتب القياس من مطبخك. سيُحفظ لهذا المكوّن فقط.',
                  style: TextStyle(fontSize: 12, color: Sofra.muted),
                ),
                TextFormField(
                  key: const ValueKey('unit-rule-factor'),
                  autofocus: true,
                  onChanged: (value) => input = value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(suffixText: unitLabel(to)),
                  validator: (value) {
                    final q = double.tryParse(value ?? '');
                    return q == null || !q.isFinite || q <= 0
                        ? 'اكتب رقمًا أكبر من صفر'
                        : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              key: const ValueKey('unit-rule-save'),
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, double.parse(input));
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (factor == null) return;
    if (await c.saveUnitRule(id, from, to, factor)) {
      nav.notify(
        'حُفظ: 1 ${unitLabel(from)} $name = ${formatAmount(factor)} ${unitLabel(to)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final (icon, color, status) = switch (line?.status) {
      LineStock.inStock => (
        Icons.check_circle_rounded,
        Sofra.green,
        'موجود عندك',
      ),
      LineStock.missing => (
        Icons.add_circle_outline_rounded,
        Sofra.orange,
        'ناقص ${formatAmount(line!.missing!)} ${ingredient.unit}',
      ),
      LineStock.unresolved => (
        Icons.help_outline_rounded,
        Sofra.muted,
        'الوحدة مختلفة عن المخزون',
      ),
      LineStock.unmeasured => (Icons.remove_rounded, Sofra.muted, 'دون مقدار'),
      LineStock.optional => (Icons.remove_rounded, Sofra.muted, 'اختياري'),
      null => (Icons.circle_outlined, Sofra.muted, null),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        color: line?.status == LineStock.missing
                            ? const Color(0xFFA05233)
                            : Sofra.muted,
                        fontSize: 12,
                      ),
                    ),
                  if (ingredient.note != null)
                    Text(
                      ingredient.note!,
                      style: const TextStyle(fontSize: 11, color: Sofra.muted),
                    ),
                  if (line?.status == LineStock.unresolved &&
                      ingredient.unit != null &&
                      c.stockUnit(c.stockId(ingredient.id)) != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: ValueKey('unit-rule-${line!.index}'),
                        onPressed: () => _defineRule(context),
                        icon: const Icon(Icons.straighten_rounded, size: 16),
                        label: const Text('حدد التحويل'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PlanSheet extends StatefulWidget {
  const _PlanSheet({required this.defaultSlot});
  final String defaultSlot;
  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  int day = 0;
  late String slot = widget.defaultSlot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'متى نضعها على السفرة؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final (i, label) in const [
                  (0, 'اليوم'),
                  (1, 'غدًا'),
                  (2, 'بعد غد'),
                ])
                  SofraChip(
                    label: Text(label),
                    selected: day == i,
                    onSelected: (_) => setState(() => day = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final e in mealSlots.entries)
                  SofraChip(
                    label: Text(e.value),
                    selected: slot == e.key,
                    onSelected: (_) => setState(() => slot = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DepthButton(
              key: const ValueKey('plan-confirm'),
              label: 'تم',
              onPressed: () => Navigator.pop(context, (
                DateTime(today.year, today.month, today.day + day),
                slot,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
