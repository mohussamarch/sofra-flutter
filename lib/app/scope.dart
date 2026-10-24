import 'package:flutter/widgets.dart';

import '../domain/kitchen_core.dart';
import 'sofra_controller.dart';

enum AppTab { today, kitchen, recipes, table, profile }

/// Navigation the screens may request from the shell.
abstract class SofraNav {
  void goTab(AppTab tab);
  void openRecipe(String recipeId);
  void openAddStock();
  void startCooking(PlannedMeal meal);
  void editOnboarding(int step);
  void notify(String text);
}

/// Gives screens the controller (rebuilding on change) and the shell's nav.
class SofraScope extends InheritedNotifier<SofraController> {
  const SofraScope({
    super.key,
    required SofraController controller,
    required this.nav,
    required super.child,
  }) : super(notifier: controller);

  final SofraNav nav;

  static SofraScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SofraScope>()!;
  static SofraController controllerOf(BuildContext context) =>
      of(context).notifier!;
  static SofraNav navOf(BuildContext context) => of(context).nav;
}

/// Meal slots stored by KitchenService, with their Arabic labels.
const mealSlots = {'breakfast': 'فطار', 'lunch': 'غدا', 'dinner': 'عشا'};
String slotLabel(String slot) => mealSlots[slot] ?? slot;
