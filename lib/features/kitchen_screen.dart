import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../data/demo_data.dart';
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

class _StockRow extends StatelessWidget {
  const _StockRow(this.lot);
  final InventoryLot lot;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final name = c.ingredientName(lot.ingredientId);
    final category = demoIngredients[lot.ingredientId]?.category;
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
                  : '${formatAmount(lot.quantity!)} ${lot.unit}',
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
                labelText: 'الكمية (${lot.unit})',
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

/// Quick add from the starter ingredient list (existing stock, not a
/// purchase: no price or spending is recorded).
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

  static double _step(Ingredient i) =>
      i.unit == 'جم' || i.unit == 'مل' ? 100 : 1;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final items = demoIngredients.values
        .where((i) => i.name.contains(search.text.trim()))
        .toList();
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
          'اضغط + لإضافة الكمية، وتقدر تعدّلها من مطبخك.',
          style: TextStyle(color: Sofra.muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'دوّر على مكوّن',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('المكوّن مش في القائمة لسه. جرّب مكوّن تاني.'),
          ),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(categoryIcon(i.category), color: Sofra.green, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _have(c.stock, i) ?? zoneName(i.zone),
                          style: const TextStyle(
                            color: Sofra.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${formatAmount(_step(i))} ${i.unit}',
                    style: const TextStyle(fontSize: 12, color: Sofra.muted),
                  ),
                  IconButton.filledTonal(
                    key: ValueKey('add-stock-${i.id}'),
                    tooltip: 'إضافة ${i.name}',
                    onPressed: () => c.addIngredient(i, _step(i)),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String? _have(List<InventoryLot> stock, Ingredient i) {
    final lots = stock.where(
      (l) =>
          l.ingredientId == i.id &&
          l.quantity != null &&
          Units.canonical(l.unit) == Units.canonical(i.unit),
    );
    if (lots.isEmpty) return null;
    final total = lots.fold<double>(0, (t, l) => t + l.quantity!);
    return 'عندك ${formatAmount(total)} ${i.unit}';
  }
}
