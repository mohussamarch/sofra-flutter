import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../l10n/l10n.dart';
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
    final t = context.l10n;
    return ScreenBody(
      children: [
        const SizedBox(height: 16),
        Text(
          controller.profile.name.isEmpty
              ? t.planWelcome
              : t.planWelcomeName(controller.profile.name),
          style: Sofra.heading(24),
        ),
        const SizedBox(height: 6),
        Text(
          t.planCookFromStockQuestion,
          style: TextStyle(color: Sofra.muted, fontSize: 16),
        ),
        const SizedBox(height: 22),
        // At night a card with an accent hairline, not a brown block.
        Surface(
          color: Sofra.isDark ? Sofra.card : Sofra.mint,
          outline: Sofra.isDark ? Sofra.accent.withValues(alpha: .25) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.soup_kitchen_outlined, color: Sofra.green, size: 36),
              const SizedBox(height: 12),
              Text(t.planWhatCanICook, style: Sofra.heading(22)),
              const SizedBox(height: 8),
              Text(t.planWhatCanICookHint),
              const SizedBox(height: 20),
              DepthButton(
                key: const ValueKey('discover-from-stock'),
                label: t.planDiscoverFromStock,
                onPressed: nav.discoverFromStock,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: nav.exploreRecipes,
                child: Text(t.planExploreAll),
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
              label: Text(t.planPantryCount(controller.stock.length)),
              onPressed: () => nav.goTab(AppTab.kitchen),
            ),
            ActionChip(
              avatar: const Icon(Icons.calendar_month_outlined),
              label: Text(t.planArrangeMeals),
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
                  child: Text(t.planLeftoversReminder(leftovers.length)),
                ),
                TextButton(
                  onPressed: () => showShelves(
                    context,
                    title: t.planLeftovers,
                    items: leftoverShelfItems,
                    empty: t.planLeftoversNone,
                  ),
                  child: Text(t.planSeeThem),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          t.planTodayMeals,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (today.isEmpty)
          SizedBox(
            width: double.infinity,
            child: Surface(
              border: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.planNoMealToday),
                  TextButton(
                    onPressed: () => nav.goTab(AppTab.table),
                    child: Text(t.planOpenPlan),
                  ),
                ],
              ),
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
