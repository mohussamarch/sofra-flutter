import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ui/design.dart';
import 'common.dart';
import 'table_screen.dart';
import 'shelf_wheel.dart';

class DailyHomeScreen extends StatelessWidget {
  const DailyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final today = controller
        .plansOn(DateTime.now())
        .where((meal) => !meal.completed)
        .toList();
    final leftovers = controller.leftoversDue(DateTime.now());
    return ScreenBody(
      children: [
        const SizedBox(height: 16),
        Text(
          controller.profile.name.isEmpty
              ? 'أهلًا بيك في سفرة'
              : 'أهلًا يا ${controller.profile.name}',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'نطلع أكلة حلوة من الموجود؟',
          style: TextStyle(color: Sofra.muted, fontSize: 16),
        ),
        const SizedBox(height: 22),
        Surface(
          color: Sofra.mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.soup_kitchen_outlined, color: Sofra.green, size: 36),
              const SizedBox(height: 12),
              const Text(
                'أطبخ إيه باللي عندي؟',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'اقتراحات من خزينك، مع توضيح الكميات والناقص. لا نخصم أي شيء قبل تأكيد الطبخ.',
              ),
              const SizedBox(height: 20),
              DepthButton(
                key: const ValueKey('discover-from-stock'),
                label: 'اكتشف من الموجود',
                onPressed: nav.discoverFromStock,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: nav.exploreRecipes,
                child: const Text('أو استكشف كل الوصفات'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('open-stock'),
              avatar: const Icon(Icons.kitchen_outlined),
              label: Text('الخزين · ${controller.stock.length} مكونات'),
              onPressed: () => nav.goTab(AppTab.kitchen),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month_outlined),
              label: const Text('رتّب وجباتك'),
              onPressed: () => nav.goTab(AppTab.table),
            ),
          ],
        ),
        if (leftovers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Surface(
            border: true,
            child: Row(
              children: [
                Icon(Icons.restaurant_outlined, color: Sofra.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('عندك ${leftovers.length} بواقي عليها تذكير'),
                ),
                TextButton(
                  onPressed: () => showShelves(
                    context,
                    title: 'بواقي الأكل',
                    items: leftoverShelfItems,
                    empty: 'لا توجد بواقي مسجلة.',
                  ),
                  child: const Text('شوفها'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'وجبات اليوم',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (today.isEmpty)
          Surface(
            border: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لسه مفيش وجبة مخططة لليوم. تقدر تختار وتطبخ مباشرة أو ترتّب الأيام الجاية.',
                ),
                TextButton(
                  onPressed: () => nav.goTab(AppTab.table),
                  child: const Text('افتح الخطة'),
                ),
              ],
            ),
          ),
        for (final meal in today)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PlannedMealCard(meal),
          ),
      ],
    );
  }
}
