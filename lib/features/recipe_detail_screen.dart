import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/recipe_catalog.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});
  final String recipeId;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Future<(CatalogRecipe, CatalogRecipe)>? recipe;
  int? servings;
  int yieldGuess = 4;

  SofraController get c => SofraScope.controllerOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    recipe ??= _load();
  }

  /// (catalog source for display, planning copy that may carry a yield).
  Future<(CatalogRecipe, CatalogRecipe)> _load() async {
    final source = await c.recipes.get(widget.recipeId);
    return (source, await c.planningRecipe(widget.recipeId));
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(CatalogRecipe, CatalogRecipe)>(
        future: recipe,
        builder: (context, snap) {
          if (snap.hasError) {
            return const ScreenBody(
              children: [ErrorBlock('تعذّر فتح الوصفة. ارجع وجرّب تاني.')],
            );
          }
          final data = snap.data;
          if (data == null) return const LoadingBlock();
          return _detail(data.$1, data.$2);
        },
      );

  Widget _detail(CatalogRecipe source, CatalogRecipe planning) {
    final c = this.c;
    final known = planning.servings != null;
    final people = servings ?? c.profile.servings;
    final scaled = known ? planning.forServings(people) : null;
    final check = scaled == null ? null : c.checkStock(scaled);
    final allergy = allergyMatches(source, c.profile.allergies);
    return ScreenBody(
      footer: DepthButton(
        key: const ValueKey('plan-meal'),
        label: 'إضافة الوجبة للسفرة',
        onPressed: known ? () => _plan(people) : null,
      ),
      children: [
        Surface(
          color: const Color(0xFFF0EDD8),
          padding: const EdgeInsets.all(12),
          child: Center(child: MealArt(kind: artKind(source.id), size: 260)),
        ),
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
                        'هنطبخ لكام حد؟',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'الكميات بتتظبط لوحدها',
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
        if (allergy.isNotEmpty || c.profile.allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Surface(
              color: Sofra.peach,
              padding: const EdgeInsets.all(16),
              child: Text(
                allergy.isNotEmpty
                    ? 'خد بالك: في مكوّن اسمه فيه «${allergy.join('، ')}» من الحساسية المسجّلة. المطابقة بالاسم بس، راجع المكونات بنفسك.'
                    : 'راجع مكونات الوصفة والعبوات مع الحساسية المسجّلة: ${c.profile.allergies.join('، ')}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF79513D)),
              ),
            ),
          ),
        SectionTitle(known ? 'المكونات على قدّكم' : 'المكونات زي المصدر'),
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
          'الأسعار والقيم الغذائية مش بتظهر هنا لحد ما تتراجع من مصادرها. الكميات من المصدر.',
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
          'المصدر مش كاتب الوصفة دي بتكفي كام فرد',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'عشان نظبط الكميات ونحطها على السفرة، قولنا الوصفة كلها تقريبًا تكفي كام فرد. الوصفة الأصلية مش هتتغير.',
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
    nav.notify('الوجبة على السفرة.. والمخزون لسه زي ما هو');
  }

  String _defaultSlot() {
    final meals = c.profile.meals;
    if (meals.contains('غدا')) return 'lunch';
    if (meals.contains('عشا')) return 'dinner';
    return 'breakfast';
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
                Text('1 ${unitLabel(from)} من $name = كام ${unitLabel(to)}؟'),
                const SizedBox(height: 4),
                const Text(
                  'اكتب القياس من مطبخك. هيتحفظ للمكوّن ده بس.',
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
                        ? 'اكتب رقم أكبر من صفر'
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
        'اتحفظ: 1 ${unitLabel(from)} $name = ${formatAmount(factor)} ${unitLabel(to)}',
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
      LineStock.unmeasured => (Icons.remove_rounded, Sofra.muted, 'مش مقاس'),
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
              'نحطها على سفرة إمتى؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final (i, label) in const [
                  (0, 'النهارده'),
                  (1, 'بكرة'),
                  (2, 'بعد بكرة'),
                ])
                  ChoiceChip(
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
                  ChoiceChip(
                    label: Text(e.value),
                    selected: slot == e.key,
                    onSelected: (_) => setState(() => slot = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DepthButton(
              key: const ValueKey('plan-confirm'),
              label: 'تمام',
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
