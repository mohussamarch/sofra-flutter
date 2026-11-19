import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/kitchen_core.dart';
import '../domain/recipe_catalog.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'recipe_detail_screen.dart' show englishRecipeName;

/// Step-by-step cooking for one planned meal, ending in an explicit stock
/// confirmation (what is deducted, what is kept out and why).
class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.meal, required this.onDone});
  final PlannedMeal meal;
  final VoidCallback onDone;
  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  Future<CatalogRecipe>? recipe;

  /// The recipe's English name from the catalog index, when it has one.
  Future<String?>? nameEn;
  int step = 0;
  bool cooked = false;
  bool busy = false;
  // One operation ID per confirmation so a retry never cooks twice.
  late final operationId = SofraScope.controllerOf(context)
      .newId('cook-${widget.meal.id}');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = SofraScope.controllerOf(context);
    recipe ??= c.recipeForPlan(widget.meal.id);
    nameEn ??= englishRecipeName(c, widget.meal.recipeId);
  }

  /// [r]'s name in the current language.
  Widget _name(CatalogRecipe r, Widget Function(String name) build) =>
      FutureBuilder<String?>(
        future: nameEn,
        builder: (context, en) => build(L10n.pick(r.name, en.data)),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<CatalogRecipe>(
    future: recipe,
    builder: (context, snap) {
      if (snap.hasError) {
        return ScreenBody(
          children: [ErrorBlock(context.l10n.detailCookOpenError)],
        );
      }
      final r = snap.data;
      if (r == null) return const LoadingBlock();
      if (cooked) return _success(r);
      if (r.steps.isEmpty) {
        return ScreenBody(
          footer: DepthButton(
            key: const ValueKey('finish-cooking'),
            label: context.l10n.detailFinishCooking,
            onPressed: busy ? null : () => _confirm(r),
          ),
          children: [Text(context.l10n.detailNoSteps)],
        );
      }
      return _step(r);
    },
  );

  Widget _step(CatalogRecipe r) {
    final steps = r.steps;
    final last = step >= steps.length - 1;
    final s = steps[step];
    final t = context.l10n;
    return ScreenBody(
      footer: DepthButton(
        key: ValueKey(last ? 'finish-cooking' : 'next-cooking-step'),
        label: last ? t.detailFinishCooking : t.detailNextStep,
        onPressed: busy
            ? null
            : last
            ? () => _confirm(r)
            : () => setState(() => step++),
      ),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _name(
                r,
                (name) => Text(
                  name,
                  style: TextStyle(color: Sofra.muted, fontSize: 14),
                ),
              ),
            ),
            SoftTag(t.detailStepOf('${step + 1}', '${steps.length}')),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (step + 1) / steps.length,
            minHeight: 8,
            backgroundColor: Sofra.line,
            color: Sofra.green,
          ),
        ),
        const SizedBox(height: 28),
        Surface(
          color: Sofra.mint,
          child: Center(child: ChefArt(size: 200, celebrate: last)),
        ),
        const SizedBox(height: 28),
        Text(s.text, style: const TextStyle(fontSize: 19, height: 1.7)),
        const SizedBox(height: 20),
        if (s.minutes != null)
          SoftTag(
            t.detailAboutMinutes(formatAmount(s.minutes!)),
            icon: Icons.schedule_rounded,
            color: Sofra.peach,
            ink: Sofra.warn,
          ),
        if (s.tip != null) ...[
          const SizedBox(height: 12),
          Text(s.tip!, style: TextStyle(color: Sofra.muted)),
        ],
        const SizedBox(height: 20),
        if (step > 0)
          TextButton.icon(
            onPressed: () => setState(() => step--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(t.detailPreviousStep),
          ),
      ],
    );
  }

  Future<void> _confirm(CatalogRecipe r) async {
    final c = SofraScope.controllerOf(context);
    final check = c.checkStock(r.forServings(widget.meal.servings));
    final direction = Directionality.of(context);
    final cookedLess = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: direction,
        child: _ConfirmSheet(check: check),
      ),
    );
    if (cookedLess == null || !mounted) return;
    setState(() => busy = true);
    final record = await c.cook(
      widget.meal,
      check,
      operationId,
      cookedLess: cookedLess,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      cooked = record != null;
    });
  }

  Widget _success(CatalogRecipe r) => ScreenBody(
    children: [
      const SizedBox(height: 24),
      const Center(child: ChefArt(size: 260, celebrate: true)),
      const SizedBox(height: 18),
      Center(
        child: Text(
          context.l10n.detailEnjoy,
          key: const ValueKey('cooking-success'),
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: _name(
          r,
          (name) => Text(
            context.l10n.detailCookedNote(name),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Sofra.muted),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _LeftoversCard(name: r.name, maxServings: widget.meal.servings),
      const SizedBox(height: 16),
      DepthButton(
        key: const ValueKey('after-cooking-kitchen'),
        label: context.l10n.detailShowKitchen,
        onPressed: () {
          widget.onDone();
          SofraScope.navOf(context).goTab(AppTab.kitchen);
        },
      ),
    ],
  );
}

/// "Anything left?" after cooking: the servings go to the fridge as a covered
/// dish, and the microwave offers them later.
class _LeftoversCard extends StatefulWidget {
  const _LeftoversCard({required this.name, required this.maxServings});
  final String name;
  final int maxServings;
  @override
  State<_LeftoversCard> createState() => _LeftoversCardState();
}

class _LeftoversCardState extends State<_LeftoversCard> {
  double servings = 0;
  bool saved = false;

  /// Days until the reminder; null: no reminder.
  int? remind = 2;

  /// "2 حصة" / "2 servings" for the current count.
  String _servings(AppLocalizations t) => servings == 1
      ? t.detailOneServing
      : t.detailServings(formatAmount(servings));

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (saved) {
      return Surface(
        color: Sofra.mint,
        child: Text(
          t.detailLeftoversSaved(_servings(t)),
          key: const ValueKey('leftovers-saved'),
          textAlign: TextAlign.center,
        ),
      );
    }
    Widget step(String key, IconData icon, double by) => IconButton.filledTonal(
      key: ValueKey(key),
      icon: Icon(icon),
      onPressed: () => setState(
        () =>
            servings = (servings + by).clamp(0, widget.maxServings.toDouble()),
      ),
    );
    return Surface(
      child: Column(
        children: [
          Text(
            t.detailAnyLeftovers,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            t.detailLeftoversHint,
            style: TextStyle(color: Sofra.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step('leftover-less', Icons.remove_rounded, -.5),
              SizedBox(
                width: 96,
                child: Text(
                  _servings(t),
                  key: const ValueKey('leftover-servings'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              step('leftover-more', Icons.add_rounded, .5),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.detailRemindAfter,
            style: TextStyle(color: Sofra.muted, fontSize: 13),
          ),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final d in const [null, 1, 2, 3, 4, 5])
                SofraChip(
                  key: ValueKey('leftover-remind-${d ?? 0}'),
                  label: Text(
                    d == null ? t.detailRemindNone : t.detailRemindDays(d),
                  ),
                  selected: remind == d,
                  onSelected: (_) => setState(() => remind = d),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('save-leftovers'),
            onPressed: servings <= 0
                ? null
                : () async {
                    final ok = await SofraScope.controllerOf(context)
                        .saveLeftovers(
                          widget.name,
                          servings,
                          remindAfterDays: remind,
                        );
                    if (ok && mounted) setState(() => saved = true);
                  },
            child: Text(t.detailPutInFridge),
          ),
        ],
      ),
    );
  }
}

/// Returns the partly stocked lines the user cooked with less of (empty when
/// they bought the rest), or null when they go back.
class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.check});
  final CookingCheck check;
  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final cookedLess = <int>{};

  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    final deduct = check.where(LineStock.inStock).toList();
    final partial = check.lines.where((l) => l.partial).toList();
    final kept = [
      ...check.where(LineStock.missing).where((l) => !l.partial),
      ...check.where(LineStock.unresolved),
    ];
    final unmeasured = check.where(LineStock.unmeasured).toList();
    final t = context.l10n;
    String amount(CookingLine l) {
      if (l.quantity == null) return '';
      final unit = L10n.term(l.ingredient.unit ?? '');
      return l.partial
          ? t.detailHaveOf(
              formatAmount(l.quantity! - l.missing!),
              formatAmount(l.quantity!),
              unit,
            )
          : '${formatAmount(l.quantity!)} $unit';
    }

    // In English the source line (when the data has it) names the line.
    String name(CookingLine l) =>
        L10n.pick(l.ingredient.name, l.ingredient.display);
    Widget group(
      String title,
      String note,
      List<CookingLine> lines,
      Color color,
    ) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          Text(note, style: TextStyle(fontSize: 11, color: Sofra.muted)),
          const SizedBox(height: 6),
          for (final l in lines) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.stockId == null
                          ? name(l)
                          : t.detailUsingStock(
                              name(l),
                              SofraScope.controllerOf(context)
                                  .ingredientName(l.stockId!),
                            ),
                    ),
                  ),
                  Text(amount(l), style: TextStyle(color: Sofra.muted)),
                ],
              ),
            ),
            if (l.partial)
              Wrap(
                spacing: 6,
                children: [
                  SofraChip(
                    key: ValueKey('partial-bought-${l.index}'),
                    label: Text(t.detailBoughtRest),
                    selected: !cookedLess.contains(l.index),
                    onSelected: (_) =>
                        setState(() => cookedLess.remove(l.index)),
                  ),
                  SofraChip(
                    key: ValueKey('partial-less-${l.index}'),
                    label: Text(t.detailCookedLess),
                    selected: cookedLess.contains(l.index),
                    onSelected: (_) => setState(() => cookedLess.add(l.index)),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.detailBeforeDeduct,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (deduct.isNotEmpty)
                group(
                  t.detailWillDeduct,
                  t.detailWillDeductNote,
                  deduct,
                  Sofra.greenDark,
                ),
              if (partial.isNotEmpty)
                group(
                  t.detailPartial,
                  t.detailPartialNote,
                  partial,
                  Sofra.greenDark,
                ),
              if (kept.isNotEmpty)
                group(
                  t.detailNotDeducted,
                  t.detailNotDeductedNote,
                  kept,
                  Sofra.warn,
                ),
              if (unmeasured.isNotEmpty)
                group(
                  t.detailUnmeasuredGroup,
                  t.detailUnmeasuredNote,
                  unmeasured,
                  Sofra.muted,
                ),
              const SizedBox(height: 20),
              DepthButton(
                key: const ValueKey('confirm-cooking'),
                label: t.detailConfirm,
                onPressed: () => Navigator.pop(context, {...cookedLess}),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.detailNotYet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
