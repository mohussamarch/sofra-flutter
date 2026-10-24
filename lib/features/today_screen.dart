import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'recipes_screen.dart';
import 'table_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Future<Map<String, dynamic>?>? inspiration;

  /// First catalog recipe from the user's preferred cuisines.
  Future<Map<String, dynamic>?> _inspiration(SofraController c) async {
    for (final group in c.profile.cuisines) {
      final rows = await c.recipes.search(cuisineGroup: group);
      if (rows.isNotEmpty) {
        return rows[DateTime.now().day % rows.length];
      }
    }
    final rows = await c.recipes.index;
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    inspiration ??= _inspiration(c);
    final stock = c.stock;
    final today = c.plansOn(DateTime.now());
    return ScreenBody(
      children: [
        Surface(
          color: Sofra.mint,
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SoftTag(
                          'حاجة حلوة من الموجود',
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stock.isEmpty
                              ? 'أول أكلة حلوة،\nتبدأ من مطبخك.'
                              : 'في مطبخك خير..\nنحوّله لأكلة؟',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 5,
                    child: FittedBox(child: ChefArt(size: 180, compact: true)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DepthButton(
                label: stock.isEmpty
                    ? 'عرّفني على مطبخك'
                    : 'شوف وصفات من الموجود',
                icon: stock.isEmpty
                    ? Icons.add_rounded
                    : Icons.auto_awesome_rounded,
                onPressed: () =>
                    nav.goTab(stock.isEmpty ? AppTab.kitchen : AppTab.recipes),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Stat(
                '${stock.length}',
                'مكونات في مطبخك',
                Icons.kitchen_outlined,
                Sofra.peach,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                '${c.profile.servings}',
                'أفراد على السفرة',
                Icons.groups_outlined,
                const Color(0xFFF2EDDA),
              ),
            ),
          ],
        ),
        SectionTitle(
          'على سفرة ${c.market.today}',
          action: 'السفرة',
          onAction: () => nav.goTab(AppTab.table),
        ),
        if (today.isNotEmpty)
          for (final m in today) PlannedMealCard(m, compact: true)
        else
          const Surface(
            border: true,
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFFAF6944),
                  size: 28,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'لسه بنفكّر في أكلة. اختار وصفة ونرتّب الوجبة سوا.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        SectionTitle(
          'إلهام لطبخة حلوة',
          action: 'كل الوصفات',
          onAction: () => nav.goTab(AppTab.recipes),
        ),
        FutureBuilder<Map<String, dynamic>?>(
          future: inspiration,
          builder: (context, snap) {
            final row = snap.data;
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingBlock();
            }
            return row == null ? const SizedBox.shrink() : RecipeCard(row);
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.number, this.title, this.icon, this.color);
  final String number, title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 21, color: Sofra.ink),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Sofra.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
