import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/food_nutrition.dart';
import '../domain/kitchen_core.dart';
import '../domain/recipe_catalog.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'month_plan_screen.dart';
import 'shopping_sheet.dart';

/// A planned meal's recipe name, in English when the catalog carries one.
Future<String> plannedMealTitle(SofraController c, PlannedMeal meal) async =>
    _recipeName(c, await c.recipeForPlan(meal.id));

Future<String> _recipeName(SofraController c, CatalogRecipe recipe) async {
  if (!L10n.isEnglish) return recipe.name;
  try {
    final rows = await c.recipes.retainedIndex;
    final row = rows.where((r) => r['id'] == recipe.id).firstOrNull;
    return L10n.pick(recipe.name, row?['nameEn'] as String?);
  } catch (_) {
    return recipe.name;
  }
}

/// Planned meals for the coming week, each with its live stock check.
class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final t = context.l10n;
    final meals = c.upcoming(DateTime.now());
    final today = L10n.term(c.market.today);
    final tools = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton.icon(
          key: const ValueKey('open-month-plan'),
          onPressed: () => openMonthPlan(context),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(t.planMonthAndBudget),
        ),
        TextButton.icon(
          key: const ValueKey('open-shopping'),
          onPressed: () => openShopping(context),
          icon: const Icon(Icons.shopping_basket_outlined),
          label: Text(t.planShoppingItems),
        ),
      ],
    );
    if (meals.isEmpty) {
      return ScreenBody(
        children: [
          Text(
            t.planOnTable(today),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          tools,
          const SizedBox(height: 24),
          const Center(child: ChefArt(size: 250)),
          Center(
            child: Text(
              t.planTableWorthIt,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              t.planPickMealHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted, fontSize: 16),
            ),
          ),
          const SizedBox(height: 28),
          DepthButton(
            label: t.planPickDishForTable,
            onPressed: () => nav.goTab(AppTab.recipes),
          ),
        ],
      );
    }
    final byDay = <String, List<PlannedMeal>>{};
    for (final m in meals) {
      byDay.putIfAbsent(m.date, () => []).add(m);
    }
    final todayKey = localDay(DateTime.now());
    final tomorrow = localDay(DateTime.now().add(const Duration(days: 1)));
    return ScreenBody(
      children: [
        Text(
          t.planOnTable(today),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        tools,
        const SizedBox(height: 8),
        Text(
          t.planComingDays,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 27),
        ),
        for (final e in byDay.entries) ...[
          SectionTitle(
            e.key == todayKey
                ? today
                : e.key == tomorrow
                ? t.planTomorrow
                : e.key,
          ),
          for (final m in e.value) PlannedMealCard(m, key: ValueKey(m.id)),
        ],
        const SizedBox(height: 16),
        noteText(t.planNoDeductNote, align: TextAlign.center),
      ],
    );
  }
}

class PlannedMealCard extends StatefulWidget {
  const PlannedMealCard(
    this.meal, {
    super.key,
    this.compact = false,
    this.glass = false,
  });
  final PlannedMeal meal;
  final bool compact;

  /// Frosted glass over the 3D table instead of a white card.
  final bool glass;
  @override
  State<PlannedMealCard> createState() => _PlannedMealCardState();
}

class _PlannedMealCardState extends State<PlannedMealCard> {
  Future<(String, CookingCheck)>? data;
  int? _stockVersion;

  /// Re-check when inventory changes (identity of the lots list content).
  Future<(String, CookingCheck)> _data(SofraController c) {
    // The language too: the title follows it.
    final version = Object.hash(
      L10n.language,
      Object.hashAll(c.kitchen.inventory.map((l) => '${l.id}:${l.quantity}')),
    );
    if (data == null || version != _stockVersion) {
      _stockVersion = version;
      data = () async {
        final recipe = await c.recipeForPlan(widget.meal.id);
        return (
          await _recipeName(c, recipe),
          c.checkStock(recipe.forServings(widget.meal.servings)),
        );
      }();
    }
    return data!;
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final m = widget.meal;
    final t = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: widget.glass ? 0 : 14),
      child: FutureBuilder<(String, CookingCheck)>(
        future: _data(c),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorBlock(t.planMealLoadError);
          }
          final d = snap.data;
          if (d == null) return const LoadingBlock();
          final (title, check) = d;
          final missing = check.where(LineStock.missing).toList();
          final unresolved = check.where(LineStock.unresolved).length;
          final unmeasured = check.where(LineStock.unmeasured).length;
          final inStock = check.where(LineStock.inStock).length;
          Widget card(Widget child) => widget.glass
              ? LiquidGlass(
                  strong: true,
                  padding: const EdgeInsets.all(18),
                  child: child,
                )
              : Surface(
                  color: m.completed ? Sofra.mint : Sofra.card,
                  child: child,
                );
          return card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wraps: on a narrow glass card the tag drops under the name.
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SoftTag(
                      t.planSlotServings(
                        L10n.term(slotLabel(m.slot)),
                        m.servings,
                      ),
                    ),
                  ],
                ),
                if (m.completed) ...[
                  const SizedBox(height: 10),
                  SoftTag(t.planCooked, icon: Icons.check_circle_rounded),
                ] else if (!widget.compact) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SoftTag(
                        t.planInStock('$inStock'),
                        icon: Icons.check_rounded,
                      ),
                      if (missing.isNotEmpty)
                        SoftTag(
                          t.planMissingCount('${missing.length}'),
                          color: Sofra.peach,
                          ink: Sofra.warn,
                        ),
                      if (unresolved > 0)
                        SoftTag(
                          t.planOtherUnit('$unresolved'),
                          color: Sofra.cream,
                          ink: Sofra.muted,
                        ),
                      if (unmeasured > 0)
                        SoftTag(
                          t.planNoAmount('$unmeasured'),
                          color: Sofra.cream,
                          ink: Sofra.muted,
                        ),
                    ],
                  ),
                  _Nutrition(meal: m),
                  if (missing.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final l
                        in widget.glass ? const <CookingLine>[] : missing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: Sofra.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l.ingredient.name)),
                            Flexible(
                              child: Text(
                                '${formatAmount(l.missing!)} '
                                '${L10n.term(l.ingredient.unit ?? '')}',
                                textAlign: TextAlign.end,
                                style: TextStyle(color: Sofra.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    DepthButton(
                      key: ValueKey('add-missing-${m.id}'),
                      compact: true,
                      secondary: true,
                      label: t.planBoughtMissing,
                      onPressed: () async {
                        if (await c.addMissing(check)) {
                          nav.notify(L10n.current.planMissingAdded);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  DepthButton(
                    key: ValueKey('start-cooking-${m.id}'),
                    label: t.planStartCooking,
                    icon: Icons.soup_kitchen_rounded,
                    onPressed: () => nav.startCooking(m),
                  ),
                  TextButton(
                    onPressed: () => c.removePlan(m.id),
                    child: Text(t.planRemoveMeal),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Per-portion energy and macros, shown only when every ingredient has a
/// sourced value; otherwise nothing, never a partial guess.
class _Nutrition extends StatefulWidget {
  const _Nutrition({required this.meal});
  final PlannedMeal meal;
  @override
  State<_Nutrition> createState() => _NutritionState();
}

class _NutritionState extends State<_Nutrition> {
  Future<Map<NutrientId, double>?>? values;
  Future<int>? missing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    values ??= SofraScope.controllerOf(context).portionNutrition(widget.meal);
    missing ??= SofraScope.controllerOf(context)
        .nutritionMissingCount(widget.meal);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<NutrientId, double>?>(
    future: values,
    builder: (context, snap) {
      final v = snap.data;
      if (v == null) {
        return FutureBuilder<int>(
          future: missing,
          builder: (context, gap) {
            final n = gap.data ?? 0;
            if (n == 0) return const SizedBox.shrink();
            return Padding(
              key: ValueKey('nutrition-incomplete-${widget.meal.id}'),
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                context.l10n.planNutritionIncomplete(n),
                style: TextStyle(color: Sofra.muted, fontSize: 13),
              ),
            );
          },
        );
      }
      final t = context.l10n;
      String g(NutrientId id, String label) => v[id] == null
          ? ''
          : t.planNutrient(label, formatAmount(v[id]!.roundToDouble()));
      return Padding(
        key: ValueKey('nutrition-${widget.meal.id}'),
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          t.planPerPortion(
                formatAmount(v[NutrientId.energyKcal]!.roundToDouble()),
              ) +
              g(NutrientId.protein, t.planProtein) +
              g(NutrientId.carbohydrate, t.planCarbs) +
              g(NutrientId.fat, t.planFat),
          style: TextStyle(color: Sofra.muted, fontSize: 13),
        ),
      );
    },
  );
}
