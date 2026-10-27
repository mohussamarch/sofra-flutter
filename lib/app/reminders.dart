import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/kitchen_core.dart';

/// One notification at a set time.
class Reminder {
  const Reminder(this.id, this.at, this.title, this.body);
  final int id;
  final DateTime at;
  final String title, body;
}

/// Where reminders go: the phone's notifications, or nowhere (tests, web).
abstract class ReminderSink {
  /// Replaces every scheduled reminder with [reminders].
  Future<void> replaceScheduled(List<Reminder> reminders);

  /// Shows a notification right away.
  Future<void> showNow(String title, String body);
}

/// Keeps what it was given; for tests and platforms without notifications.
class SilentReminders implements ReminderSink {
  List<Reminder> scheduled = const [];
  final shown = <(String, String)>[];

  @override
  Future<void> replaceScheduled(List<Reminder> reminders) async =>
      scheduled = List.unmodifiable(reminders);

  @override
  Future<void> showNow(String title, String body) async =>
      shown.add((title, body));
}

/// Android notifications. Best effort: a refused permission or a missing
/// plugin leaves the app working without them.
class LocalReminders implements ReminderSink {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'sofra-reminders',
      'تذكيرات سفرة',
      channelDescription: 'مواعيد الأكل، والبواقي، والأشياء التي نفدت',
    ),
  );

  Future<bool> _init() async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return false;
    }
  }

  @override
  Future<void> replaceScheduled(List<Reminder> reminders) async {
    if (!await (_ready ??= _init())) return;
    try {
      await _plugin.cancelAllPendingNotifications();
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.id,
          // An absolute instant; no device time-zone name is needed.
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      }
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }

  @override
  Future<void> showNow(String title, String body) async {
    if (!await (_ready ??= _init())) return;
    try {
      await _plugin.show(
        id: _id('now-${DateTime.now().microsecondsSinceEpoch}'),
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }
}

/// Stable 31-bit notification id for a key (FNV-1a).
int _id(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// Reminders for the coming [days]: each planned, uncooked meal [before]
/// its slot's time, and each leftover on its reminder day at the lunch
/// time (or the earliest time the user set). Slots without a time the user
/// chose get no reminder; nothing is assumed.
List<Reminder> upcomingReminders({
  required DateTime now,
  required Map<String, int> mealTimes,
  required int before,
  required List<PlannedMeal> meals,
  required String Function(PlannedMeal) titleOf,
  required String Function(String slot) slotName,
  List<LeftoverDish> leftovers = const [],
  int days = 7,
}) {
  final end = now.add(Duration(days: days));
  DateTime at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day).add(Duration(minutes: minutes));
  final result = <Reminder>[];
  for (final m in meals) {
    final time = mealTimes[m.slot];
    if (m.completed || time == null) continue;
    final when = at(parseDay(m.date), time - before);
    if (when.isAfter(now) && when.isBefore(end)) {
      result.add(
        Reminder(
          _id('meal-${m.id}'),
          when,
          '${slotName(m.slot)} بعد $before دقيقة',
          'متخطط: ${titleOf(m)}. ابدأ التحضير.',
        ),
      );
    }
  }
  final leftoverTime =
      mealTimes['lunch'] ??
      (mealTimes.isEmpty
          ? null
          : mealTimes.values.reduce((a, b) => a < b ? a : b));
  if (leftoverTime != null) {
    for (final d in leftovers) {
      final day = d.remindOn;
      if (day == null || d.servings <= 0) continue;
      final when = at(day, leftoverTime);
      if (when.isAfter(now) && when.isBefore(end)) {
        result.add(
          Reminder(
            _id('leftover-${d.id}'),
            when,
            'بواقي ${d.name} في الثلاجة',
            'تبقّى ${_servings(d.servings)}. سخّنها اليوم.',
          ),
        );
      }
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

String _servings(double v) {
  final n = v == v.roundToDouble() ? v.round().toString() : v.toString();
  return '$n حصة';
}

/// Stock IDs that had something (or an unknown amount) in [before] and
/// have nothing left in [after].
Set<String> ranOut(List<InventoryLot> before, List<InventoryLot> after) {
  Set<String> held(List<InventoryLot> lots) => {
    for (final l in lots)
      if (l.quantity == null || l.quantity! > 0) l.ingredientId,
  };
  return held(before).difference(held(after));
}
