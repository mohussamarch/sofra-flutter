import 'package:flutter/material.dart';

import 'package:share_plus/share_plus.dart';

import '../app/scope.dart';
import '../domain/market_profile.dart';
import '../domain/purchase_forecast.dart';
import '../ui/design.dart';
import 'common.dart';

/// Opens the coming week's shopping list.
Future<void> openShopping(BuildContext context) {
  final scope = SofraScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SofraScope(
      controller: scope.notifier!,
      nav: scope.nav,
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: ShoppingSheet(),
      ),
    ),
  );
}

/// What the planned meals of the next seven days still need, after the
/// stock, with the user's own prices where they gave one.
class ShoppingSheet extends StatefulWidget {
  const ShoppingSheet({super.key});
  @override
  State<ShoppingSheet> createState() => _ShoppingSheetState();
}

class _ShoppingSheetState extends State<ShoppingSheet> {
  Future<PurchaseForecast>? list;
  final bought = <int>{};
  final paid = <int, TextEditingController>{};

  @override
  void dispose() {
    for (final t in paid.values) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    list ??= SofraScope.controllerOf(context).shoppingList(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final money = MarketProfile(c.kitchen.market.country).currencyLabel;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: FutureBuilder<PurchaseForecast>(
          future: list,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: ErrorBlock('معرفناش نجهز القائمة. جرب تاني.'),
              );
            }
            final f = snap.data;
            if (f == null) return const LoadingBlock();
            final items = f.purchases;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'قائمة الشراء للأسبوع',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        IconButton(
                          key: const ValueKey('shopping-share'),
                          tooltip: 'ابعتها (واتساب وغيره)',
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(text: c.shoppingText(f)),
                          ),
                          icon: const Icon(Icons.share_outlined),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    items.isEmpty
                        ? 'مش ناقصك حاجة للأكلات المتخططة.'
                        : f.purchaseTotal != null
                        ? 'حوالي ${formatAmount(f.purchaseTotal!.roundToDouble())} $money بأسعارك.'
                        : 'المعروف سعره: ${formatAmount(f.knownPurchaseSubtotal.roundToDouble())} $money، وفيه حاجات من غير سعر.',
                    key: const ValueKey('shopping-total'),
                    style: const TextStyle(color: Sofra.muted),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final (i, p) in items.indexed)
                        CheckboxListTile(
                          key: ValueKey('shopping-${p.use.ingredientId}'),
                          value: bought.contains(i),
                          onChanged: (v) => setState(
                            () => v! ? bought.add(i) : bought.remove(i),
                          ),
                          title: Text(c.ingredientName(p.use.ingredientId)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.amountText(
                                  p.use.ingredientId,
                                  p.use.quantity,
                                  p.use.unit,
                                ),
                              ),
                              if (bought.contains(i))
                                TextField(
                                  key: ValueKey(
                                    'shopping-paid-${p.use.ingredientId}',
                                  ),
                                  controller: paid[i] ??=
                                      TextEditingController(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'دفعت كام؟ (اختياري)',
                                    suffixText: money,
                                  ),
                                ),
                            ],
                          ),
                          secondary: Text(
                            p.estimatedCost == null
                                ? '—'
                                : '${formatAmount(p.estimatedCost!.roundToDouble())} $money',
                          ),
                        ),
                      if (f.unresolvedRequirements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text(
                            'فيه ${f.unresolvedRequirements.length} سطر من غير كمية (زي «حسب الرغبة») مش في القائمة.',
                            style: const TextStyle(
                              color: Sofra.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (f.unresolvedStock.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Text(
                            'وحدة الخزين لـ ${f.unresolvedStock.map(c.ingredientName).join('، ')} مش بتتحول لوحدة الوصفة؛ راجعها في الخزين.',
                            style: const TextStyle(
                              color: Sofra.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: DepthButton(
                      key: const ValueKey('shopping-bought'),
                      label: bought.isEmpty
                          ? 'علّم اللي اشتريته'
                          : 'حط اللي اشتريته في المطبخ',
                      onPressed: bought.isEmpty
                          ? null
                          : () async {
                              await c.addBought(
                                [for (final i in bought) items[i].use],
                                paid: {
                                  for (final i in bought)
                                    if (double.tryParse(
                                          paid[i]?.text.trim() ?? '',
                                        )
                                        case final v? when v >= 0)
                                      items[i].use: v,
                                },
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
