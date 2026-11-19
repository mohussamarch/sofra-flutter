import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/market_profile.dart';
import '../domain/monthly_budget_search.dart';
import '../ui/design.dart';
import '../l10n/l10n.dart';
import 'common.dart';

/// Weekdays in the order an Egyptian week is read, Saturday first
/// (DateTime.weekday numbers).
const _week = [6, 7, 1, 2, 3, 4, 5];

/// A weekday's name (DateTime.weekday number) in the current language.
String _dayName(AppLocalizations t, int day) => switch (day) {
  DateTime.saturday => t.planSaturday,
  DateTime.sunday => t.planSunday,
  DateTime.monday => t.planMonday,
  DateTime.tuesday => t.planTuesday,
  DateTime.wednesday => t.planWednesday,
  DateTime.thursday => t.planThursday,
  _ => t.planFriday,
};

/// Opens the month planner over the current page.
Future<void> openMonthPlan(BuildContext context) {
  final scope = SofraScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: const MonthPlanScreen(),
      ),
    ),
  );
}

/// A month from a weekly menu: the user fills a week (a second recipe in a
/// cell is a cheaper alternative), sets the month's budget, and sees whether
/// it fits with their own prices before anything is saved.
class MonthPlanScreen extends StatefulWidget {
  const MonthPlanScreen({super.key});
  @override
  State<MonthPlanScreen> createState() => _MonthPlanScreenState();
}

class _MonthPlanScreenState extends State<MonthPlanScreen> {
  final budget = TextEditingController();
  bool nextMonth = false;
  Set<String> slots = {'lunch'};
  bool omitUnmeasured = true;

  /// Leave the meals already on the table and fill the other days only.
  bool keepPlanned = false;
  final menu = <(int, String), List<String>>{};
  Future<List<Map<String, dynamic>>>? index;
  MonthPlan? plan;
  bool busy = false;
  String? error;

  SofraController get c => SofraScope.controllerOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    index ??= c.recipes.index;
  }

  @override
  void dispose() {
    budget.dispose();
    super.dispose();
  }

  DateTime get _month {
    final now = DateTime.now();
    return DateTime(now.year, now.month + (nextMonth ? 1 : 0));
  }

  double? get _limit => double.tryParse(budget.text.trim());

  Map<(int, String), List<String>> get _activeMenu => {
    for (final day in _week)
      for (final slot in slots) (day, slot): menu[(day, slot)] ?? const [],
  };

  bool get _ready =>
      (_limit ?? 0) > 0 && _activeMenu.values.every((ids) => ids.isNotEmpty);

  void _changed(VoidCallback change) => setState(() {
    change();
    plan = null;
    error = null;
    keepPlanned = false;
  });

  Future<void> _calculate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await c.previewMonth(
        month: _month,
        limit: _limit!,
        menu: _activeMenu,
        omitUnmeasured: omitUnmeasured,
        keepPlanned: keepPlanned,
      );
      if (mounted) setState(() => plan = result);
    } catch (_) {
      if (mounted) {
        setState(() => error = L10n.current.planMonthCalcError);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _accept() async {
    var replace = false;
    final conflicts = c.monthConflicts(plan!);
    if (conflicts.isNotEmpty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final t = ctx.l10n;
          return AlertDialog(
            title: Text(t.planConflictTitle),
            content: Text(t.planConflictBody(conflicts.length)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.planNotYet),
              ),
              TextButton(
                key: const ValueKey('month-replace'),
                onPressed: () => Navigator.pop(ctx, 'replace'),
                child: Text(t.planReplace),
              ),
              FilledButton(
                key: const ValueKey('month-keep'),
                onPressed: () => Navigator.pop(ctx, 'keep'),
                child: Text(t.planKeepExisting),
              ),
            ],
          );
        },
      );
      if (choice == null || !mounted) return;
      if (choice == 'keep') {
        // The other days are priced again on their own.
        keepPlanned = true;
        await _calculate();
        if (plan?.acceptable != true) {
          return;
        }
      }
      replace = choice == 'replace';
    }
    setState(() => busy = true);
    final ok = await c.acceptMonth(plan!, replace: replace);
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.planMonthAdded)));
      Navigator.pop(context);
    } else {
      setState(() => error = context.l10n.planMonthNotSaved);
    }
  }

  /// Fills the empty days of each meal with the filled ones, in turn.
  void _fillWeek() => _changed(() {
    for (final slot in slots) {
      final filled = [
        for (final day in _week)
          if (menu[(day, slot)]?.isNotEmpty ?? false) menu[(day, slot)]!,
      ];
      if (filled.isEmpty) continue;
      var i = 0;
      for (final day in _week) {
        if (menu[(day, slot)]?.isNotEmpty ?? false) continue;
        menu[(day, slot)] = List.of(filled[i++ % filled.length]);
      }
    }
  });

  Future<void> _pick(int day, String slot) async {
    final rows = await index!;
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecipePicker(
        rows: rows.where(c.canPlanMonth).toList(),
        saved: c.profile.saved,
      ),
    );
    if (picked == null) return;
    _changed(() {
      final cell = menu[(day, slot)] ??= [];
      if (!cell.contains(picked) && cell.length < 2) cell.add(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final market = MarketProfile(c.kitchen.market.country);
    final t = context.l10n;
    return Scaffold(
      backgroundColor: Sofra.cream,
      appBar: AppBar(
        title: Text(t.planMonthTitle),
        backgroundColor: Sofra.cream,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: index,
        builder: (context, snap) {
          final names = {
            for (final r in snap.data ?? const <Map<String, dynamic>>[])
              r['id'] as String: L10n.pick(
                r['name'] as String,
                r['nameEn'] as String?,
              ),
          };
          return ScreenBody(
            footer: plan?.acceptable == true
                ? DepthButton(
                    key: const ValueKey('month-accept'),
                    label: t.planPutOnTable,
                    onPressed: busy ? null : _accept,
                  )
                : DepthButton(
                    key: const ValueKey('month-calc'),
                    label: busy ? t.planCalculating : t.planCalculateMonth,
                    onPressed: _ready && !busy ? _calculate : null,
                  ),
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  SofraChip(
                    key: const ValueKey('month-this'),
                    label: Text(t.planThisMonth),
                    selected: !nextMonth,
                    onSelected: (_) => _changed(() => nextMonth = false),
                  ),
                  SofraChip(
                    key: const ValueKey('month-next'),
                    label: Text(t.planNextMonth),
                    selected: nextMonth,
                    onSelected: (_) => _changed(() => nextMonth = true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('month-budget'),
                controller: budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: t.planMonthBudget,
                  suffixText: L10n.term(market.currencyLabel),
                ),
                onChanged: (_) => _changed(() {}),
              ),
              SectionTitle(t.planMealsToPlan),
              Wrap(
                spacing: 8,
                children: [
                  for (final MapEntry(key: slot, value: label)
                      in mealSlots.entries)
                    SofraChip(
                      key: ValueKey('month-slot-$slot'),
                      label: Text(L10n.term(label)),
                      selected: slots.contains(slot),
                      onSelected: (on) => _changed(() {
                        if (on) {
                          slots = {...slots, slot};
                        } else if (slots.length > 1) {
                          slots = {...slots}..remove(slot);
                        }
                      }),
                    ),
                ],
              ),
              SectionTitle(
                t.planWeekMenu,
                action: t.planFillEmptyDays,
                onAction: _fillWeek,
              ),
              Text(
                t.planWeekMenuHint,
                style: TextStyle(color: Sofra.muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              for (final day in _week)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _dayName(t, day),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      for (final slot in mealSlots.keys)
                        if (slots.contains(slot))
                          Expanded(
                            child: _Cell(
                              key: ValueKey('month-cell-$day-$slot'),
                              slot: L10n.term(slotLabel(slot)),
                              names: [
                                for (final id in menu[(day, slot)] ?? [])
                                  names[id] ?? id,
                              ],
                              onAdd: () => _pick(day, slot),
                              onClear: () =>
                                  _changed(() => menu.remove((day, slot))),
                            ),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const ValueKey('month-omit'),
                contentPadding: EdgeInsets.zero,
                value: omitUnmeasured,
                onChanged: (v) => _changed(() => omitUnmeasured = v),
                title: Text(t.planOmitUnmeasured),
                subtitle: Text(t.planOmitUnmeasuredHint),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ErrorBlock(error!),
                ),
              if (plan case final p?) _Result(plan: p, onPriced: _calculate),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.slot,
    required this.names,
    required this.onAdd,
    required this.onClear,
  });
  final String slot;
  final List<String> names;
  final VoidCallback onAdd, onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Material(
      color: names.isEmpty ? Sofra.line.withValues(alpha: .35) : Sofra.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: names.length < 2 ? onAdd : null,
        onLongPress: names.isEmpty ? null : onClear,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot, style: TextStyle(fontSize: 11, color: Sofra.muted)),
              if (names.isEmpty)
                Text(
                  context.l10n.planPick,
                  style: TextStyle(color: Sofra.muted),
                )
              else
                for (final (i, n) in names.indexed)
                  Text(
                    i == 0 ? n : context.l10n.planOrAlternative(n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RecipePicker extends StatefulWidget {
  const _RecipePicker({required this.rows, required this.saved});
  final List<Map<String, dynamic>> rows;

  /// Bookmarked recipes come first.
  final Set<String> saved;
  @override
  State<_RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends State<_RecipePicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final saved = widget.saved;
    final q = query.trim();
    String name(Map<String, dynamic> r) =>
        L10n.pick(r['name'] as String, r['nameEn'] as String?);
    // Either name matches, so a search typed in either language works.
    bool matches(Map<String, dynamic> r) =>
        (r['name'] as String).contains(q) ||
        ((r['nameEn'] as String?) ?? '').toLowerCase().contains(
          q.toLowerCase(),
        );
    final shown =
        [
          for (final r in widget.rows)
            if (matches(r)) r,
        ]..sort((a, b) {
          final sa = saved.contains(a['id']) ? 0 : 1;
          final sb = saved.contains(b['id']) ? 0 : 1;
          return sa.compareTo(sb);
        });
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const ValueKey('month-pick-search'),
                decoration: InputDecoration(
                  hintText: context.l10n.planSearchMeal,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final r = shown[i];
                  return ListTile(
                    key: ValueKey('month-pick-${r['id']}'),
                    title: Text(name(r)),
                    subtitle: Text(L10n.term(r['cuisine'] as String? ?? '')),
                    trailing: saved.contains(r['id'])
                        ? const Icon(Icons.bookmark_rounded, size: 18)
                        : null,
                    onTap: () => Navigator.pop(context, r['id'] as String),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the month costs, or what is still needed to know.
class _Result extends StatelessWidget {
  const _Result({required this.plan, required this.onPriced});
  final MonthPlan plan;
  final VoidCallback onPriced;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    final money = L10n.term(MarketProfile(plan.budget.country).currencyLabel);
    String amount(double v) => '${formatAmount(v.roundToDouble())} $money';
    final comparison = plan.search.comparison;
    final children = <Widget>[];
    switch (plan.outcome) {
      case MonthlyBudgetSearchOutcome.affordableFound:
        final best = plan.best!;
        children.add(
          _Line(
            key: const ValueKey('month-fits'),
            icon: Icons.check_circle_outline_rounded,
            color: Sofra.greenDark,
            text: t.planMonthFits(
              amount(best.forecast.purchaseTotal!),
              amount(best.remainingAfterPurchases!),
            ),
          ),
        );
      case MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools:
        final cheapest = plan.cheapest!;
        children.add(
          _Line(
            key: const ValueKey('month-over'),
            icon: Icons.warning_amber_rounded,
            color: Sofra.warn,
            text: t.planMonthOver(amount(cheapest.overrun!)),
          ),
        );
      case MonthlyBudgetSearchOutcome.indeterminate when plan.acceptable:
        final best = plan.best!;
        children.add(
          _Line(
            key: const ValueKey('month-fits'),
            icon: Icons.check_circle_outline_rounded,
            color: Sofra.greenDark,
            text: t.planMonthBestFits(
              amount(best.forecast.purchaseTotal!),
              amount(best.remainingAfterPurchases!),
            ),
          ),
        );
      case MonthlyBudgetSearchOutcome.indeterminate:
        children.add(
          _Line(
            key: ValueKey('month-unknown'),
            icon: Icons.help_outline_rounded,
            color: Sofra.muted,
            text: t.planMonthUnknown,
          ),
        );
    }
    final unpriced = plan.unpriced;
    if (unpriced.isNotEmpty) {
      children
        ..add(SectionTitle(t.planRecordPrices))
        ..add(
          Text(
            t.planRecordPricesHint,
            style: TextStyle(color: Sofra.muted, fontSize: 13),
          ),
        );
      for (final MapEntry(key: id, value: unit) in unpriced.entries) {
        children.add(
          _PriceRow(
            key: ValueKey('month-price-$id'),
            name: c.ingredientName(id),
            unit: unit,
            money: money,
            onSave: (quantity, price) async {
              if (await c.setUserPrice(id, quantity, unit, price)) onPriced();
            },
          ),
        );
      }
    }
    if (plan.unresolved.isNotEmpty &&
        plan.outcome == MonthlyBudgetSearchOutcome.indeterminate) {
      children.add(
        _Line(
          icon: Icons.straighten_rounded,
          color: Sofra.muted,
          text: t.planUnresolvedUnits,
        ),
      );
    }
    if (plan.search.truncated) {
      children.add(
        _Line(
          icon: Icons.info_outline_rounded,
          color: Sofra.muted,
          text: t.planTruncated(comparison.assessments.length),
        ),
      );
    }
    if (plan.unmeasured.isNotEmpty) {
      children.add(
        _Line(
          icon: Icons.info_outline_rounded,
          color: Sofra.muted,
          text: t.planUncounted(
            plan.unmeasured.take(8).join(t.planListSeparator),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 12), ...children],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    ),
  );
}

class _PriceRow extends StatefulWidget {
  const _PriceRow({
    super.key,
    required this.name,
    required this.unit,
    required this.money,
    required this.onSave,
  });
  final String name, unit, money;
  final Future<void> Function(double quantity, double price) onSave;
  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();

  @override
  void dispose() {
    quantity.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = double.tryParse(quantity.text.trim());
    final p = double.tryParse(price.text.trim());
    const number = TextInputType.numberWithOptions(decimal: true);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(widget.name)),
          Expanded(
            flex: 2,
            child: TextField(
              key: const ValueKey('price-quantity'),
              controller: quantity,
              keyboardType: number,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(L10n.term(unitLabel(widget.unit))),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              key: const ValueKey('price-amount'),
              controller: price,
              keyboardType: number,
              decoration: InputDecoration(suffixText: widget.money),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            key: const ValueKey('price-save'),
            tooltip: context.l10n.planSavePrice,
            onPressed: q != null && q > 0 && p != null && p >= 0
                ? () => widget.onSave(q, p)
                : null,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}
