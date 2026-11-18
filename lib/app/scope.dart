import 'package:flutter/widgets.dart';

import '../domain/kitchen_core.dart';
import 'sofra_controller.dart';

enum AppTab {
  today,
  kitchen,
  recipes,
  table,
  profile,
  settings,
  community,
  style,
}

/// Navigation the screens may request from the shell.
abstract class SofraNav {
  void goTab(AppTab tab);
  void discoverFromStock();
  void exploreRecipes();
  void openKitchen3d();

  /// [compare] opens a dish made in several countries with no country
  /// chosen, its ingredients compared.
  void openRecipe(String recipeId, {bool compare = false});
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
const mealSlots = {'breakfast': 'فطار', 'lunch': 'غداء', 'dinner': 'عشاء'};
String slotLabel(String slot) => mealSlots[slot] ?? slot;
