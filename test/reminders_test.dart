import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/domain/kitchen_core.dart';
import 'package:tabkha_demo/domain/models.dart';

PlannedMeal meal(String id, String date, String slot, {bool done = false}) =>
    PlannedMeal(
      id: id,
      date: date,
      slot: slot,
      recipeId: 'r',
      servings: 2,
      completed: done,
    );

InventoryLot lot(String id, String ingredient, double? quantity) =>
    InventoryLot(
      id: id,
      ingredientId: ingredient,
      quantity: quantity,
      unit: 'g',
      zone: StorageZone.pantry,
    );

void main() {
  final now = DateTime(2026, 10, 26, 10);
  List<Reminder> remind(
    List<PlannedMeal> meals, {
    Map<String, int> times = const {'lunch': 14 * 60, 'dinner': 20 * 60},
    List<LeftoverDish> leftovers = const [],
  }) => upcomingReminders(
    now: now,
    mealTimes: times,
    before: 30,
    meals: meals,
    titleOf: (m) => 'كشري',
    slotName: (s) => s == 'lunch' ? 'الغدا' : 'العشا',
    leftovers: leftovers,
  );

  test('a meal is reminded before the time the user set for its slot', () {
    final r = remind([meal('a', '2026-10-26', 'lunch')]);
    expect(r.single.at, DateTime(2026, 10, 26, 13, 30));
    expect(r.single.title, contains('30'));
    expect(r.single.body, contains('كشري'));
  });

  test('no reminder for a slot without a time, a cooked or past meal', () {
    expect(
      remind([
        meal('b', '2026-10-26', 'breakfast'),
        meal('c', '2026-10-26', 'dinner', done: true),
        meal('d', '2026-10-25', 'lunch'),
        meal('e', '2026-11-10', 'lunch'),
      ]),
      isEmpty,
    );
    expect(remind([meal('a', '2026-10-27', 'lunch')], times: {}), isEmpty);
  });

  test('ids are stable so rescheduling replaces, not duplicates', () {
    final a = remind([meal('a', '2026-10-27', 'lunch')]).single.id;
    final b = remind([meal('a', '2026-10-27', 'lunch')]).single.id;
    final other = remind([meal('z', '2026-10-27', 'lunch')]).single.id;
    expect(a, b);
    expect(a, isNot(other));
  });

  test('a leftover is reminded at lunch time on its day', () {
    final r = remind(
      const [],
      leftovers: [
        LeftoverDish(
          id: 'l1',
          name: 'محشي',
          servings: 2,
          preparedOn: '2026-10-26',
          remindAfterDays: 2,
        ),
        LeftoverDish(
          id: 'l2',
          name: 'رز',
          servings: 1,
          preparedOn: '2026-10-26',
        ),
      ],
    );
    expect(r.single.at, DateTime(2026, 10, 28, 14));
    expect(r.single.title, contains('محشي'));
  });

  test('ran out lists only what had stock and has none left', () {
    expect(
      ranOut(
        [lot('1', 'rice', 500), lot('2', 'salt', null), lot('3', 'oil', 0)],
        [lot('1', 'rice', 0), lot('2', 'salt', null), lot('3', 'oil', 0)],
      ),
      {'rice'},
    );
  });

  test('reminder settings survive a save and reload', () {
    final p = const Profile().copyWith(
      mealTimes: {'lunch': 840},
      remindBefore: 45,
      stockAlerts: false,
    );
    final again = Profile.fromRoot(p.toJson());
    expect(again.mealTimes, {'lunch': 840});
    expect(again.remindBefore, 45);
    expect(again.stockAlerts, isFalse);
    final old = Profile.fromRoot(const {});
    expect(old.mealTimes, isEmpty);
    expect(old.stockAlerts, isTrue);
  });
}
