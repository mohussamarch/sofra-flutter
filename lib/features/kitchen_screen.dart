import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/demo_data.dart';
import '../domain/ingredient_directory.dart';
import '../domain/kitchen_core.dart';
import '../domain/models.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

/// Inventory by storage zone, read from KitchenService lots.
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});
  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  StorageZone? zone;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final stock = c.stock;
    final visible = stock.where((l) => zone == null || l.zone == zone).toList();
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        Surface(
          color: Sofra.mint,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.kitchen_rounded, size: 48, color: Sofra.green),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.isEmpty
                          ? 'مكان صغير.. لخير كتير'
                          : '${stock.length} مكونات مستنية طبخة',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'التلاجة والفريزر ودولاب المطبخ، في مكان واحد.',
                      style: TextStyle(fontSize: 13, color: Sofra.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DepthButton(
          key: const ValueKey('add-ingredients'),
          label: 'إضافة مكونات',
          icon: Icons.add_rounded,
          onPressed: nav.openAddStock,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('الكل'),
              selected: zone == null,
              onSelected: (_) => setState(() => zone = null),
            ),
            for (final z in StorageZone.values)
              ChoiceChip(
                label: Text(zoneName(z)),
                selected: zone == z,
                onSelected: (_) => setState(() => zone = z),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          Surface(
            border: true,
            child: Column(
              children: [
                const ChefArt(size: 165, compact: true),
                Text(
                  stock.isEmpty ? 'لسه بنتعرف على مطبخك' : 'الرف ده لسه فاضي',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ضيف كام مكوّن كبداية. مش محتاجين جرد كامل عشان نبدأ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Sofra.muted, fontSize: 14),
                ),
              ],
            ),
          )
        else
          for (final lot in visible) _StockRow(lot),
        if (stock.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: DepthButton(
              key: const ValueKey('add-sample-stock'),
              label: 'جرّب بمكونات جاهزة',
              secondary: true,
              onPressed: () async {
                await c.loadSample();
                nav.notify('اتضافت مكونات تجريبية لمطبخك');
              },
            ),
          ),
        const SizedBox(height: 14),
        noteText(
          'الكميات بتتخصم لما تأكد إن الطبخة خلصت، مش وقت اختيار الوصفة.',
          align: TextAlign.center,
        ),
      ],
    );
  }
}

/// What is inside one storage place, shown over the open fridge or pantry.
/// Opened as a modal sheet, so it carries its own scope.
class ZoneStockSheet extends StatelessWidget {
  const ZoneStockSheet({super.key, required this.zone});
  final StorageZone zone;

  static Future<void> show(BuildContext context, StorageZone zone) {
    final scope = SofraScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: .12),
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ZoneStockSheet(zone: zone),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final lots = c.stock.where((l) => l.zone == zone).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .55,
      minChildSize: .3,
      maxChildSize: .9,
      builder: (context, scroll) => ListView(
        key: ValueKey('zone-sheet-${zone.name}'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoneName(zone),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      countText(
                        lots.length,
                        'حاجة',
                        'حاجتين',
                        'حاجات',
                        empty: 'لسه فاضي',
                      ),
                      style: const TextStyle(color: Sofra.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: ValueKey('zone-add-${zone.name}'),
                tooltip: 'إضافة',
                onPressed: () {
                  Navigator.pop(context);
                  nav.openAddStock();
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const ValueKey('zone-all-stock'),
              onPressed: () {
                Navigator.pop(context);
                nav.goTab(AppTab.kitchen);
              },
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('كل الخزين'),
            ),
          ),
          const SizedBox(height: 8),
          if (lots.isEmpty)
            const Surface(
              border: true,
              child: Text(
                'ضيف اللي عندك هنا، وهنقولك تطبخ إيه منه.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Sofra.muted),
              ),
            )
          else
            for (final lot in lots) _StockRow(lot),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow(this.lot);
  final InventoryLot lot;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final name = c.ingredientName(lot.ingredientId);
    final category = c.category(lot.ingredientId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: category == 'خضار' ? Sofra.mint : Sofra.peach,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                categoryIcon(category),
                color: Sofra.greenDark,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    zoneName(lot.zone),
                    style: const TextStyle(fontSize: 11, color: Sofra.muted),
                  ),
                ],
              ),
            ),
            Text(
              lot.quantity == null
                  ? 'كمية غير محددة'
                  : c.amountText(lot.ingredientId, lot.quantity!, lot.unit),
              key: ValueKey('stock-quantity-${lot.ingredientId}'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: 'تعديل $name',
              onPressed: () => _edit(context, name),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Sofra.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, String name) async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    var input = lot.quantity == null ? '' : formatAmount(lot.quantity!);
    final form = GlobalKey<FormState>();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('كمية $name'),
          content: Form(
            key: form,
            child: TextFormField(
              initialValue: input,
              onChanged: (value) => input = value,
              validator: (value) {
                final q = double.tryParse(value ?? '');
                return q == null || !q.isFinite || q < 0
                    ? 'اكتب رقم صحيح يساوي 0 أو أكتر'
                    : null;
              },
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'الكمية (${c.unitName(lot.ingredientId, lot.unit)})',
                helperText: 'اكتب 0 لو خلص',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
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
    if (result == null) return;
    await c.setQuantity(lot.id, result);
    nav.notify('اتحدثت كمية $name');
  }
}

/// Adds existing stock from the ingredient directory (not a purchase: no
/// price or spending is recorded).
class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});
  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// Starter items first when nothing is typed, so the common case is one tap.
  List<IngredientEntry> _items(IngredientDirectory? directory) {
    if (directory == null) return const [];
    final q = search.text.trim();
    if (q.isNotEmpty) return directory.search(q).take(40).toList();
    final starters = [
      for (final id in demoIngredients.keys) ?directory.entry(id),
    ];
    final rest = directory.entries.where((e) => !starters.contains(e));
    return [...starters, ...rest].take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final items = _items(c.directory);
    return ScreenBody(
      footer: DepthButton(
        key: const ValueKey('add-stock-done'),
        label: 'تمام، شوف مطبخي',
        onPressed: () => nav.goTab(AppTab.kitchen),
      ),
      children: [
        const Text(
          'إيه الموجود عندك؟',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'اضغط + لإضافة سريعة، أو اضغط على المكوّن تكتب الكمية والوحدة.',
          style: TextStyle(color: Sofra.muted),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('add-stock-search'),
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'دوّر على مكوّن',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
        if (c.directory == null)
          const LoadingBlock()
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('المكوّن مش في القائمة لسه. جرّب اسم تاني.'),
          ),
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: EdgeInsets.zero,
              child: InkWell(
                key: ValueKey('add-stock-open-${e.id}'),
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openSheet(context, e),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        categoryIcon(e.category),
                        color: Sofra.green,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _have(c.stock, e.id) ?? zoneName(e.zone),
                              style: const TextStyle(
                                color: Sofra.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${c.amountText(e.id, SofraController.quickStep(e.defaultUnit), e.defaultUnit)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Sofra.muted,
                        ),
                      ),
                      IconButton.filledTonal(
                        key: ValueKey('add-stock-${e.id}'),
                        tooltip: 'إضافة ${e.name}',
                        onPressed: () => c.addIngredient(
                          e.id,
                          SofraController.quickStep(e.defaultUnit),
                          e.defaultUnit,
                          e.zone,
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openSheet(BuildContext context, IngredientEntry e) async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _AddAmountSheet(entry: e, controller: c),
      ),
    );
    if (added == true) nav.notify('اتضاف ${e.name} لمطبخك');
  }

  String? _have(List<InventoryLot> stock, String id) {
    final totals = <String, double>{};
    for (final l in stock) {
      if (l.ingredientId == id && l.quantity != null) {
        totals[l.unit] = (totals[l.unit] ?? 0) + l.quantity!;
      }
    }
    if (totals.isEmpty) return null;
    final c = SofraScope.controllerOf(context);
    final parts = totals.entries.map((t) => c.amountText(id, t.value, t.key));
    return 'عندك ${parts.join(' + ')}';
  }
}

/// Amount, unit and place for one directory entry.
class _AddAmountSheet extends StatefulWidget {
  const _AddAmountSheet({required this.entry, required this.controller});
  final IngredientEntry entry;
  final SofraController controller;
  @override
  State<_AddAmountSheet> createState() => _AddAmountSheetState();
}

class _AddAmountSheetState extends State<_AddAmountSheet> {
  /// Older vocabularies without stockUnits still offer the basic measures.
  static const fallback = ['g', 'kg', 'ml', 'l', 'count'];
  late final List<String> units = {
    for (final u
        in widget.entry.stockUnits.isEmpty
            ? [widget.entry.defaultUnit, ...fallback]
            : widget.entry.stockUnits)
      Units.canonical(u),
  }.toList();
  late String unit = units.first;
  late StorageZone zone = widget.entry.zone;
  final amount = TextEditingController();
  final weight = TextEditingController();
  String? error, weightError;

  @override
  void initState() {
    super.initState();
    _fillWeight();
  }

  @override
  void dispose() {
    amount.dispose();
    weight.dispose();
    super.dispose();
  }

  static double? _number(String text) {
    final q = double.tryParse(text.trim().replaceAll('٫', '.'));
    return q == null || !q.isFinite || q <= 0 ? null : q;
  }

  /// A piece, bunch or container can carry the user's own measure (grams, or
  /// millilitres for liquids), so recipes in those units can use it.
  String? get _measure {
    if (const {'g', 'kg', 'ml', 'l'}.contains(unit)) return null;
    if (units.any((u) => u == 'g' || u == 'kg')) return 'g';
    if (units.any((u) => u == 'ml' || u == 'l')) return 'ml';
    return null;
  }

  bool get _asksWeight => _measure != null;

  void _fillWeight() {
    final m = _measure;
    final w = m == null
        ? null
        : widget.controller.measureOf(widget.entry.id, unit, m);
    weight.text = w == null ? '' : formatAmount(w);
  }

  Future<void> _save() async {
    final q = _number(amount.text);
    final w = weight.text.trim().isEmpty ? null : _number(weight.text);
    setState(() {
      error = q == null ? 'اكتب كمية أكبر من صفر' : null;
      weightError = _asksWeight && weight.text.trim().isNotEmpty && w == null
          ? 'اكتب وزن أكبر من صفر أو سيبها فاضية'
          : null;
    });
    if (error != null || weightError != null) return;
    final c = widget.controller;
    final m = _measure;
    if (m != null && w != null && w != c.measureOf(widget.entry.id, unit, m)) {
      await c.saveUnitRule(widget.entry.id, unit, m, w);
    }
    await c.addIngredient(widget.entry.id, q!, unit, zone);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final id = widget.entry.id;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.entry.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('add-amount'),
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'الكمية',
                errorText: error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            const Text('الوحدة', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in units)
                  ChoiceChip(
                    key: ValueKey('add-unit-$u'),
                    label: Text(c.unitName(id, u)),
                    selected: unit == u,
                    onSelected: (_) => setState(() {
                      unit = u;
                      _fillWeight();
                    }),
                  ),
              ],
            ),
            if (_asksWeight) ...[
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('add-piece-weight'),
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'كام ${_measure == 'g' ? 'جرام' : 'مل'} في الـ${c.unitName(id, unit)}؟ (اختياري)',
                  helperText:
                      'من ميزانك أو المكتوب على العبوة. بيساعد في الوصفات.',
                  suffixText: _measure == 'g' ? 'جم' : 'مل',
                  errorText: weightError,
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text('مكانه', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final z in StorageZone.values)
                  ChoiceChip(
                    key: ValueKey('add-zone-${z.name}'),
                    label: Text(zoneName(z)),
                    selected: zone == z,
                    onSelected: (_) => setState(() => zone = z),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DepthButton(
              key: const ValueKey('add-stock-save'),
              label: 'ضيفه لمطبخي',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
