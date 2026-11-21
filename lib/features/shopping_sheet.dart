import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../app/scope.dart';
import '../domain/market_profile.dart';
import '../domain/purchase_forecast.dart';
import '../l10n/l10n.dart';
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
      child: const ShoppingSheet(),
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
  static const boughtKey = 'sofra.shopping.bought';
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  List<ForecastPurchase> _items = const [];

  /// Ticks live while the list does: they are kept on the device and
  /// restored when the sheet opens again.
  Future<void> _restore(PurchaseForecast f) async {
    _items = f.purchases;
    try {
      final saved = await _prefs.getStringList(boughtKey) ?? const [];
      if (!mounted || saved.isEmpty) return;
      setState(() {
        for (final (i, p) in _items.indexed) {
          if (saved.contains(p.use.ingredientId)) bought.add(i);
        }
      });
    } on Object {
      // Ticks are a convenience; the list works without them.
    }
  }

  Future<void> _persist() async {
    try {
      final ids = [for (final i in bought) _items[i].use.ingredientId];
      if (ids.isEmpty) {
        await _prefs.remove(boughtKey);
      } else {
        await _prefs.setStringList(boughtKey, ids);
      }
    } on Object {
      // Never block shopping on storage.
    }
  }

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
    list ??= SofraScope.controllerOf(context)
        .shoppingList(DateTime.now())
        .then((f) {
          _restore(f);
          return f;
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    final money = L10n.term(
      MarketProfile(c.kitchen.market.country).currencyLabel,
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: FutureBuilder<PurchaseForecast>(
          future: list,
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorBlock(t.kitShoppingError),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.kitShoppingTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        IconButton(
                          key: const ValueKey('shopping-share'),
                          tooltip: t.kitShareList,
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
                        ? t.kitNothingMissing
                        : f.purchaseTotal != null
                        ? t.kitAboutTotal(
                            formatAmount(f.purchaseTotal!.roundToDouble()),
                            money,
                          )
                        : t.kitKnownSubtotal(
                            formatAmount(
                              f.knownPurchaseSubtotal.roundToDouble(),
                            ),
                            money,
                          ),
                    key: const ValueKey('shopping-total'),
                    style: TextStyle(color: Sofra.muted),
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
                          onChanged: (v) {
                            setState(
                              () => v! ? bought.add(i) : bought.remove(i),
                            );
                            _persist();
                          },
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
                                    hintText: t.kitPaidHint,
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
                            t.kitUnresolvedLines(
                              f.unresolvedRequirements.length,
                            ),
                            style: TextStyle(color: Sofra.muted, fontSize: 12),
                          ),
                        ),
                      if (f.unresolvedStock.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Text(
                            t.kitUnconvertibleStock(
                              f.unresolvedStock
                                  .map(c.ingredientName)
                                  .join(t.kitListSeparator),
                            ),
                            style: TextStyle(color: Sofra.muted, fontSize: 12),
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
                          ? t.kitMarkBought
                          : t.kitPutBoughtAway,
                      onPressed: bought.isEmpty
                          ? null
                          : () async {
                              final ok = await c.addBought(
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
                              if (ok) {
                                bought.clear();
                                await _persist();
                              }
                              if (ok && context.mounted) {
                                Navigator.pop(context);
                              }
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
