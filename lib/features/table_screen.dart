import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/kitchen_core.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

/// Planned meals for the coming week, each with its live stock check.
class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final meals = c.upcoming(DateTime.now());
    if (meals.isEmpty) {
      return ScreenBody(
        children: [
          const SizedBox(height: 24),
          const Center(child: ChefArt(size: 250)),
          const Center(
            child: Text(
              'سفرة حلوة تستاهل اللمّة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'اختار أكلة، وهنشوف الناقص قبل ما نبدأ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted, fontSize: 16),
            ),
          ),
          const SizedBox(height: 28),
          DepthButton(
            label: 'اختار طبخة للسفرة',
            onPressed: () => nav.goTab(AppTab.recipes),
          ),
        ],
      );
    }
    final byDay = <String, List<PlannedMeal>>{};
    for (final m in meals) {
      byDay.putIfAbsent(m.date, () => []).add(m);
    }
    final today = localDay(DateTime.now());
    final tomorrow = localDay(DateTime.now().add(const Duration(days: 1)));
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        const Text(
          'السفرة الأيام الجاية',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 27),
        ),
        for (final e in byDay.entries) ...[
          SectionTitle(
            e.key == today
                ? c.market.today
                : e.key == tomorrow
                ? 'بكرة'
                : e.key,
          ),
          for (final m in e.value) PlannedMealCard(m, key: ValueKey(m.id)),
        ],
        const SizedBox(height: 16),
        noteText(
          'اختيار الوجبة ما بيخصمش المخزون. الخصم بعد تأكيد إن الطبخة خلصت.',
          align: TextAlign.center,
        ),
      ],
    );
  }
}

class PlannedMealCard extends StatefulWidget {
  const PlannedMealCard(this.meal, {super.key, this.compact = false});
  final PlannedMeal meal;
  final bool compact;
  @override
  State<PlannedMealCard> createState() => _PlannedMealCardState();
}

class _PlannedMealCardState extends State<PlannedMealCard> {
  Future<(String, CookingCheck)>? data;
  int? _stockVersion;

  /// Re-check when inventory changes (identity of the lots list content).
  Future<(String, CookingCheck)> _data(SofraController c) {
    final version = Object.hashAll(
      c.kitchen.inventory.map((l) => '${l.id}:${l.quantity}'),
    );
    if (data == null || version != _stockVersion) {
      _stockVersion = version;
      data = () async {
        final recipe = await c.recipeForPlan(widget.meal.id);
        return (
          recipe.name,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: FutureBuilder<(String, CookingCheck)>(
        future: _data(c),
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorBlock('تعذّر تحميل وصفة الوجبة دي.');
          }
          final d = snap.data;
          if (d == null) return const LoadingBlock();
          final (title, check) = d;
          final missing = check.where(LineStock.missing).toList();
          final unresolved = check.where(LineStock.unresolved).length;
          final unmeasured = check.where(LineStock.unmeasured).length;
          final inStock = check.where(LineStock.inStock).length;
          return Surface(
            color: m.completed ? Sofra.mint : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SoftTag('${slotLabel(m.slot)} · ${m.servings} أفراد'),
                  ],
                ),
                if (m.completed) ...[
                  const SizedBox(height: 10),
                  const SoftTag('اتطبخت', icon: Icons.check_circle_rounded),
                ] else if (!widget.compact) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SoftTag('$inStock موجودين', icon: Icons.check_rounded),
                      if (missing.isNotEmpty)
                        SoftTag(
                          'ناقص ${missing.length}',
                          color: Sofra.peach,
                          ink: const Color(0xFF995333),
                        ),
                      if (unresolved > 0)
                        SoftTag(
                          '$unresolved بوحدة مختلفة',
                          color: Sofra.cream,
                          ink: Sofra.muted,
                        ),
                      if (unmeasured > 0)
                        SoftTag(
                          '$unmeasured مش مقاسين',
                          color: Sofra.cream,
                          ink: Sofra.muted,
                        ),
                    ],
                  ),
                  if (missing.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final l in missing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: Sofra.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l.ingredient.name)),
                            Text(
                              '${formatAmount(l.missing!)} ${l.ingredient.unit}',
                              style: const TextStyle(color: Sofra.muted),
                            ),
                          ],
                        ),
                      ),
                    DepthButton(
                      key: ValueKey('add-missing-${m.id}'),
                      compact: true,
                      secondary: true,
                      label: 'جبت الناقص · ضيفه للمخزون',
                      onPressed: () async {
                        await c.addMissing(check);
                        nav.notify('الناقص اتضاف للمخزون بالكمية المطلوبة');
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  DepthButton(
                    key: ValueKey('start-cooking-${m.id}'),
                    label: 'يلا نطبخ',
                    icon: Icons.soup_kitchen_rounded,
                    onPressed: () => nav.startCooking(m),
                  ),
                  TextButton(
                    onPressed: () => c.removePlan(m.id),
                    child: const Text('شيل الوجبة من السفرة'),
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
