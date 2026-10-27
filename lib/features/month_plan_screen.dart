import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/market_profile.dart';
import '../domain/monthly_budget_search.dart';
import '../ui/design.dart';
import 'common.dart';

/// Weekdays in the order an Egyptian week is read, Saturday first
/// (DateTime.weekday numbers).
const _week = [
  (6, 'السبت'),
  (7, 'الأحد'),
  (1, 'الاثنين'),
  (2, 'الثلاثاء'),
  (3, 'الأربع'),
  (4, 'الخميس'),
  (5, 'الجمعة'),
];

/// Opens the month planner over the current page.
Future<void> openMonthPlan(BuildContext context) {
  final scope = SofraScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: MonthPlanScreen(),
        ),
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
    for (final (day, _) in _week)
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
        setState(
          () => error = 'تعذّر حساب هذه الخطة. راجع الأكلات وحاول مرة أخرى.',
        );
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
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('توجد أيام عليها أكل'),
            content: Text(
              'توجد ${conflicts.length} وجبة مخططة في الأيام نفسها. ماذا نفعل بها؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ليس بعد'),
              ),
              TextButton(
                key: const ValueKey('month-replace'),
                onPressed: () => Navigator.pop(ctx, 'replace'),
                child: const Text('استبدلها'),
              ),
              FilledButton(
                key: const ValueKey('month-keep'),
                onPressed: () => Navigator.pop(ctx, 'keep'),
                child: const Text('أبقِ الموجود'),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'keep') {
        // The other days are priced again on their own.
        keepPlanned = true;
        await _calculate();
        if (plan?.outcome != MonthlyBudgetSearchOutcome.affordableFound) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أُضيفت الخطة إلى السفرة.')));
      Navigator.pop(context);
    } else {
      setState(() => error = 'لم تُحفظ الخطة. احسبها مرة أخرى.');
    }
  }

  /// Fills the empty days of each meal with the filled ones, in turn.
  void _fillWeek() => _changed(() {
    for (final slot in slots) {
      final filled = [
        for (final (day, _) in _week)
          if (menu[(day, slot)]?.isNotEmpty ?? false) menu[(day, slot)]!,
      ];
      if (filled.isEmpty) continue;
      var i = 0;
      for (final (day, _) in _week) {
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _RecipePicker(
          rows: rows.where(c.canPlanMonth).toList(),
          saved: c.profile.saved,
        ),
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
    return Scaffold(
      backgroundColor: Sofra.cream,
      appBar: AppBar(
        title: const Text('خطة الشهر'),
        backgroundColor: Sofra.cream,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: index,
        builder: (context, snap) {
          final names = {
            for (final r in snap.data ?? const <Map<String, dynamic>>[])
              r['id'] as String: r['name'] as String,
          };
          return ScreenBody(
            footer: plan?.outcome == MonthlyBudgetSearchOutcome.affordableFound
                ? DepthButton(
                    key: const ValueKey('month-accept'),
                    label: 'ضع الخطة على السفرة',
                    onPressed: busy ? null : _accept,
                  )
                : DepthButton(
                    key: const ValueKey('month-calc'),
                    label: busy ? 'جارٍ الحساب…' : 'احسب الشهر',
                    onPressed: _ready && !busy ? _calculate : null,
                  ),
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  SofraChip(
                    key: const ValueKey('month-this'),
                    label: const Text('هذا الشهر'),
                    selected: !nextMonth,
                    onSelected: (_) => _changed(() => nextMonth = false),
                  ),
                  SofraChip(
                    key: const ValueKey('month-next'),
                    label: const Text('الشهر القادم'),
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
                  labelText: 'ميزانية الأكل للشهر',
                  suffixText: market.currencyLabel,
                ),
                onChanged: (_) => _changed(() {}),
              ),
              const SectionTitle('الوجبات التي سنخطط لها'),
              Wrap(
                spacing: 8,
                children: [
                  for (final MapEntry(key: slot, value: label)
                      in mealSlots.entries)
                    FilterChip(
                      key: ValueKey('month-slot-$slot'),
                      label: Text(label),
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
                'منيو الأسبوع',
                action: 'أكمل الأيام الفارغة',
                onAction: _fillWeek,
              ),
              const Text(
                'يتكرر هذا الأسبوع طوال الشهر. يمكنك وضع أكلتين في الخانة نفسها، ونختار الأوفر.',
                style: TextStyle(color: Sofra.muted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              for (final (day, label) in _week)
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
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      for (final slot in mealSlots.keys)
                        if (slots.contains(slot))
                          Expanded(
                            child: _Cell(
                              key: ValueKey('month-cell-$day-$slot'),
                              slot: slotLabel(slot),
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
                title: const Text('استبعد الأشياء التي ليس لها كمية من الحساب'),
                subtitle: const Text(
                  'مثل «ملح حسب الرغبة». إذا أوقفتها، ستبقى التكلفة غير معروفة.',
                ),
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
      color: names.isEmpty ? Sofra.line.withValues(alpha: .35) : Colors.white,
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
              Text(
                slot,
                style: const TextStyle(fontSize: 11, color: Sofra.muted),
              ),
              if (names.isEmpty)
                const Text('+ اختر', style: TextStyle(color: Sofra.muted))
              else
                for (final (i, n) in names.indexed)
                  Text(
                    i == 0 ? n : 'أو $n',
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
    final shown =
        [
          for (final r in widget.rows)
            if ((r['name'] as String).contains(query.trim())) r,
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
                decoration: const InputDecoration(
                  hintText: 'ابحث عن أكلة',
                  prefixIcon: Icon(Icons.search_rounded),
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
                    title: Text(r['name'] as String),
                    subtitle: Text(r['cuisine'] as String? ?? ''),
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
    final money = MarketProfile(plan.budget.country).currencyLabel;
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
            text:
                'يكلّفك هذا الشهر شراء نحو ${amount(best.forecast.purchaseTotal!)}، ويتبقى من الميزانية ${amount(best.remainingAfterPurchases!)}.',
          ),
        );
      case MonthlyBudgetSearchOutcome.noAffordableInSuppliedPools:
        final cheapest = plan.cheapest!;
        children.add(
          _Line(
            key: const ValueKey('month-over'),
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFF995333),
            text:
                'أوفر اختيار يتجاوز الميزانية بـ ${amount(cheapest.overrun!)}. جرّب أكلات أوفر أو أضف بديلًا في بعض الخانات.',
          ),
        );
      case MonthlyBudgetSearchOutcome.indeterminate:
        children.add(
          const _Line(
            key: ValueKey('month-unknown'),
            icon: Icons.help_outline_rounded,
            color: Sofra.muted,
            text: 'التكلفة الكاملة غير معروفة بعد.',
          ),
        );
    }
    final unpriced = plan.unpriced;
    if (unpriced.isNotEmpty) {
      children
        ..add(const SectionTitle('سجّل هذه الأسعار'))
        ..add(
          const Text(
            'بسعرك أنت، من آخر مرة اشتريت. لا نخمّن الأسعار.',
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
        const _Line(
          icon: Icons.straighten_rounded,
          color: Sofra.muted,
          text: 'بعض المكونات مسجّلة بوحدة لا تتحول إلى وحدة الوصفة. حدد التحويل من صفحة المخزون.',
        ),
      );
    }
    if (plan.search.truncated) {
      children.add(
        _Line(
          icon: Icons.info_outline_rounded,
          color: Sofra.muted,
          text:
              'جرّبنا ${comparison.assessments.length} توليفة فقط من البدائل؛ قد توجد أوفر منها.',
        ),
      );
    }
    if (plan.unmeasured.isNotEmpty) {
      children.add(
        _Line(
          icon: Icons.info_outline_rounded,
          color: Sofra.muted,
          text: 'غير محسوب: ${plan.unmeasured.take(8).join('، ')}.',
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
            child: Text(unitLabel(widget.unit)),
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
            tooltip: 'حفظ السعر',
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
