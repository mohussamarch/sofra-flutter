import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../data/recipe_repository.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

/// One dish that is made several ways: its name, how many ways, and the
/// countries they come from. Opens the dish with all its ways.
class DishCard extends StatelessWidget {
  const DishCard({super.key, required this.dish, required this.ways});
  final Dish dish;

  /// Index rows of the dish's recipes, in the dish's order.
  final List<Map<String, dynamic>> ways;

  @override
  Widget build(BuildContext context) {
    final countries = {for (final w in ways) '${w['cuisine']}'}.toList();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: ValueKey('dish-${dish.id}'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => showDish(context, dish, ways),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              MealArt(kind: artKind(ways.first['id'] as String), size: 84),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ways.length} طرق',
                      style: const TextStyle(
                        color: Sofra.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in countries)
                          SoftTag(
                            c,
                            color: Sofra.cream,
                            ink: Sofra.muted,
                            icon: Icons.public_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Sofra.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dish with each way of making it; choosing one opens that recipe.
Future<void> showDish(
  BuildContext context,
  Dish dish,
  List<Map<String, dynamic>> ways,
) {
  final nav = SofraScope.navOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Sofra.paper,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (context, scroll) => ListView(
        key: ValueKey('dish-sheet-${dish.id}'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            dish.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          Text(
            '${ways.length} طرق لعملها',
            style: const TextStyle(color: Sofra.muted),
          ),
          const SizedBox(height: 16),
          for (final w in ways)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Way(
                row: w,
                onTap: () {
                  Navigator.of(sheet).pop();
                  nav.openRecipe(w['id'] as String);
                },
              ),
            ),
        ],
      ),
    ),
  );
}

class _Way extends StatelessWidget {
  const _Way({required this.row, required this.onTap});
  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = row['id'] as String;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('dish-way-$id'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MealArt(kind: artKind(id), size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['cuisine']}',
                      style: const TextStyle(
                        color: Sofra.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${row['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      minutesLabel(row['totalTime']),
                      style: const TextStyle(color: Sofra.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Sofra.muted),
            ],
          ),
        ),
      ),
    );
  }
}
