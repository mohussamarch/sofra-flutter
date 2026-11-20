import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/recipe_photo_library.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_catalog.dart';
import '../domain/servings_engine.dart';
import '../l10n/l10n.dart';
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

  /// The recipe's English name from the catalog index, when it has one.
  Future<String?>? nameEn;

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
    nameEn ??= englishRecipeName(c, widget.recipeId);
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
                      color: on ? color : Sofra.card,
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
                                n > 1
                                    ? '${L10n.term(cuisine)} $n'
                                    : L10n.term(cuisine),
                                style: TextStyle(
                                  color: on ? Sofra.onAccent : Sofra.ink,
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
          if (snap.error is RecipeNotOnDevice) {
            final l = context.l10n;
            return ScreenBody(
              children: [
                ErrorBlock(l.recipeNotOnDevice),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('recipe-retry'),
                    onPressed: () => setState(() => recipe = _load()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l.recipeRetry),
                  ),
                ),
              ],
            );
          }
          if (snap.hasError) {
            return ScreenBody(
              children: [ErrorBlock(context.l10n.detailOpenError)],
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
    final t = context.l10n;
    final listSep = t.detailListSeparator;
    // Known when the source states it, the servings engine computed it, or
    // the user set it; the yellow question only shows when none can.
    final known = planning.hasKnownYield;
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
            label: starting ? t.detailPreparing : t.detailCookNow,
            onPressed: known && !starting ? () => _cookNow(people) : null,
          ),
          const SizedBox(height: 6),
          Text(
            t.detailCookNowNote,
            textAlign: TextAlign.center,
            style: TextStyle(color: Sofra.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          DepthButton(
            key: const ValueKey('plan-meal'),
            compact: true,
            secondary: true,
            label: t.detailAddToPlan,
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
                color: Sofra.isDark ? Sofra.inverse : const Color(0xFFF0EDD8),
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
                  t.detailPhotoCredit(photo.credit, photo.licence),
                  style: TextStyle(color: Sofra.muted, fontSize: 11),
                ),
              ],
            );
          },
        ),
        if (bar != null) ...[const SizedBox(height: 14), bar],
        const SizedBox(height: 22),
        FutureBuilder<String?>(
          future: nameEn,
          builder: (context, en) => Text(
            L10n.pick(source.name, en.data),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 27,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (source.description.isNotEmpty)
          Text(source.description, style: TextStyle(color: Sofra.muted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SoftTag(
              minutesLabel(scaled?.totalMinutes ?? source.totalMinutes),
              icon: Icons.schedule_rounded,
            ),
            if (known) _servingsTag(source, planning),
            SoftTag(L10n.term(source.cuisine)),
            SoftTag(L10n.term(source.category)),
            if (source.difficulty.isNotEmpty)
              SoftTag(L10n.term(source.difficulty)),
          ],
        ),
        const SizedBox(height: 20),
        if (known)
          Surface(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.detailServingsQuestion,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        t.detailServingsHint,
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
          Text(t.detailLogAs),
          Wrap(
            spacing: 8,
            children: [
              for (final slot in mealSlots.entries)
                SofraChip(
                  key: ValueKey('cook-slot-${slot.key}'),
                  label: Text(L10n.term(slot.value)),
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
                    ? t.detailAllergyMatch(
                        allergy.entries
                            .map(
                              (e) => t.detailAllergyMatchItem(
                                e.key,
                                e.value.join(listSep),
                              ),
                            )
                            .join(t.detailGroupSeparator),
                      )
                    : t.detailAllergyCheck(c.profile.allergies.join(listSep)),
                style: TextStyle(
                  fontSize: 12,
                  color: Sofra.isDark ? Sofra.warn : const Color(0xFF79513D),
                ),
              ),
            ),
          ),
        SectionTitle(
          known ? t.detailIngredientsScaled : t.detailIngredientsSource,
        ),
        for (var i = 0; i < source.ingredients.length; i++)
          _IngredientRow(
            ingredient: (scaled?.recipe ?? source).ingredients[i],
            amount: scaled != null
                ? _scaledAmount(scaled, scaled.recipe.ingredients[i])
                : _sourceAmount(source.ingredients[i]),
            line: check?.lines[i],
          ),
        SectionTitle(t.detailSteps),
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
                      style: TextStyle(
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
        noteText(t.detailNoPricesNote),
      ],
    );
  }

  String _sourceAmount(CatalogIngredient i) =>
      i.display ??
      (i.amount == null
          ? i.label ?? i.note ?? context.l10n.detailToTaste
          : '${formatAmount(i.amount!)} ${L10n.term(i.unit ?? '')}'.trim());

  /// [ScaledCatalogRecipe.display] with the unit in the current language.
  String _scaledAmount(ScaledCatalogRecipe s, CatalogIngredient i) {
    if (!L10n.isEnglish || i.display != null) return s.display(i);
    final amount = s.quantity(i);
    if (amount == null) return i.label ?? i.note ?? context.l10n.detailToTaste;
    final kilo = i.unit == 'كيلو'; // i18n-data
    if (kilo && amount < 1) {
      final grams = roundRecipeAmount(amount * 1000, 'جرام'); // i18n-data
      return '${recipeNumber(grams)} ${L10n.term('جم')}'; // i18n-data
    }
    return '${recipeNumber(amount)} ${L10n.term(i.unit ?? '')}'.trim();
  }

  /// The whole recipe's yield. When the app worked it out (or the user set
  /// it), a muted (i) opens how, and the place to change it.
  Widget _servingsTag(CatalogRecipe source, CatalogRecipe planning) {
    final t = context.l10n;
    final count = planning.effectiveServings!;
    final userSet = planning.id != source.id;
    final tag = SoftTag(t.detailYieldServes(count), icon: Icons.groups_rounded);
    if (!userSet && !planning.servingsComputedByApp) return tag;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tag,
        IconButton(
          key: const ValueKey('servings-info'),
          tooltip: t.servingsInfoLabel,
          onPressed: () => _servingsInfo(source, count, userSet),
          icon: const Icon(Icons.info_outline_rounded),
          iconSize: 18,
          color: Sofra.muted,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _servingsInfo(
    CatalogRecipe source,
    int count,
    bool userSet,
  ) async {
    final t = context.l10n;
    final direction = Directionality.of(context);
    final estimate = source.servingsEstimate;
    final driver = userSet ? null : estimate.mainDriver;
    String? basis;
    if (driver != null) {
      final line = source.ingredients
          .where((i) => i.id == driver.ingredientId)
          .firstOrNull;
      final per = ServingsEngine.shared.perPerson(driver.category);
      if (line != null && per != null) {
        basis = t.servingsInfoBasis(
          _portion(driver.amount, driver.unit),
          L10n.term(line.name),
          _portion(per, driver.unit),
        );
      }
    }
    final low = !userSet && estimate.confidence == ServingsConfidence.low;
    var guess = count.clamp(1, 20);
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: direction,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.detailYieldServes(count),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (basis != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      basis,
                      key: const ValueKey('servings-basis'),
                      style: TextStyle(color: Sofra.muted),
                    ),
                  ],
                  if (low) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.servingsInfoLow,
                      key: const ValueKey('servings-low'),
                      style: TextStyle(color: Sofra.muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    t.servingsInfoAdjust,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Counter(
                        value: guess,
                        max: 20,
                        onChanged: (v) => setSheet(() => guess = v),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DepthButton(
                          key: const ValueKey('servings-adjust'),
                          compact: true,
                          label: t.detailYieldServes(guess),
                          onPressed: guess == count
                              ? null
                              : () => Navigator.pop(ctx, guess),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    if (await c.reviewYield(widget.recipeId, chosen)) {
      setState(() => recipe = _load());
    }
  }

  /// An engine amount in g, ml or pieces, in the recipe's own units.
  String _portion(double value, String unit) {
    String inUnit(double v, String term) =>
        '${recipeNumber(roundRecipeAmount(v, term))} ${L10n.term(term)}';
    return switch (unit) {
      'g' when value >= 1000 => inUnit(value / 1000, 'كيلو'), // i18n-data
      'g' => inUnit(value, 'جرام'), // i18n-data
      'ml' when value >= 1000 => inUnit(value / 1000, 'لتر'), // i18n-data
      'ml' => inUnit(value, 'مل'), // i18n-data
      _ => inUnit(value, 'حبة'), // i18n-data
    };
  }

  Widget _yieldReview() => Surface(
    color: Sofra.isDark ? Sofra.warnTint : const Color(0xFFFFF3D4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.detailYieldUnknown,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.detailYieldAsk,
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
                label: context.l10n.detailYieldServes(yieldGuess),
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
    final t = context.l10n;
    final direction = Directionality.of(context);
    final choice = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: direction,
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
    nav.notify(t.detailPlanned);
  }

  String _defaultSlot() {
    final meals = c.profile.meals;
    if (meals.contains('غداء')) return 'lunch'; // i18n-data
    if (meals.contains('عشاء')) return 'dinner'; // i18n-data
    return 'breakfast';
  }
}

/// The catalog index's English name for [recipeId], or null when the index
/// has none (or cannot be read; the Arabic name is shown then).
Future<String?> englishRecipeName(SofraController c, String recipeId) async {
  try {
    for (final row in await c.recipes.retainedIndex) {
      if (row['id'] == recipeId) return row['nameEn'] as String?;
    }
  } on Object {
    // The English name is an extra; the recipe opens without it.
  }
  return null;
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
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ScreenBody(
      children: [
        Surface(
          color: Sofra.isDark ? Sofra.inverse : const Color(0xFFF0EDD8),
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
          t.detailWaysToMake(widget.ways.length),
          style: TextStyle(color: Sofra.muted),
        ),
        SectionTitle(t.detailIngredients),
        FutureBuilder<List<CatalogRecipe>>(
          future: recipes,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorBlock(t.detailWaysOpenError);
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
        Surface(
          key: const ValueKey('compare-pick'),
          border: true,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.arrow_upward_rounded, color: Sofra.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.detailComparePickHint,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
          : '$name: ${[for (final i in ways) L10n.term(cuisines[i])].join(context.l10n.detailListSeparator)}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: ways.isEmpty
              ? Sofra.card
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
    final t = context.l10n;
    final direction = Directionality.of(context);
    final fromLabel = L10n.term(unitLabel(from));
    final toLabel = L10n.term(unitLabel(to));
    final factor = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: direction,
        child: AlertDialog(
          title: Text(t.detailDefineConversion),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.detailConversionQuestion(fromLabel, name, toLabel)),
                const SizedBox(height: 4),
                Text(
                  t.detailConversionHint,
                  style: TextStyle(fontSize: 12, color: Sofra.muted),
                ),
                TextFormField(
                  key: const ValueKey('unit-rule-factor'),
                  autofocus: true,
                  onChanged: (value) => input = value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(suffixText: toLabel),
                  validator: (value) {
                    final q = double.tryParse(value ?? '');
                    return q == null || !q.isFinite || q <= 0
                        ? t.detailEnterPositive
                        : null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.detailCancel),
            ),
            TextButton(
              key: const ValueKey('unit-rule-save'),
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, double.parse(input));
                }
              },
              child: Text(t.detailSave),
            ),
          ],
        ),
      ),
    );
    if (factor == null) return;
    if (await c.saveUnitRule(id, from, to, factor)) {
      nav.notify(
        t.detailConversionSaved(fromLabel, name, formatAmount(factor), toLabel),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    final (icon, color, status) = switch (line?.status) {
      LineStock.inStock => (
        Icons.check_circle_rounded,
        Sofra.green,
        t.detailInStock,
      ),
      LineStock.missing => (
        Icons.add_circle_outline_rounded,
        Sofra.orange,
        t.detailMissing(
          formatAmount(line!.missing!),
          L10n.term(ingredient.unit ?? ''),
        ),
      ),
      LineStock.unresolved => (
        Icons.help_outline_rounded,
        Sofra.muted,
        t.detailUnitMismatch,
      ),
      LineStock.unmeasured => (
        Icons.remove_rounded,
        Sofra.muted,
        t.detailUnmeasured,
      ),
      LineStock.optional => (
        Icons.remove_rounded,
        Sofra.muted,
        t.detailOptional,
      ),
      null => (Icons.circle_outlined, Sofra.muted, null),
    };
    // In English the source line (when the data has it) names the
    // ingredient; it already carries the amount.
    final name = L10n.pick(ingredient.name, ingredient.display);
    final shownAmount = name == amount ? '' : amount;
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
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        color: line?.status == LineStock.missing
                            ? (Sofra.isDark
                                  ? Sofra.accent
                                  : const Color(0xFFA05233))
                            : Sofra.muted,
                        fontSize: 12,
                      ),
                    ),
                  if (ingredient.note != null)
                    Text(
                      ingredient.note!,
                      style: TextStyle(fontSize: 11, color: Sofra.muted),
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
                        label: Text(t.detailDefineConversion),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              shownAmount,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
    final t = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.detailPlanWhen,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final (i, label) in [
                  (0, t.detailToday),
                  (1, t.detailTomorrow),
                  (2, t.detailDayAfterTomorrow),
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
                    label: Text(L10n.term(e.value)),
                    selected: slot == e.key,
                    onSelected: (_) => setState(() => slot = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DepthButton(
              key: const ValueKey('plan-confirm'),
              label: t.detailDone,
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
