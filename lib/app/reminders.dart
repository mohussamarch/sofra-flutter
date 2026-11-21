import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/kitchen_core.dart';
import '../l10n/l10n.dart';

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

  /// Schedules one extra notification (a step timer) that survives
  /// [replaceScheduled]; [cancel] removes it.
  Future<void> scheduleOne(Reminder reminder);
  Future<void> cancel(int id);
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

  final extra = <int, Reminder>{};

  @override
  Future<void> scheduleOne(Reminder reminder) async =>
      extra[reminder.id] = reminder;

  @override
  Future<void> cancel(int id) async => extra.remove(id);
}

/// Android notifications. Best effort: a refused permission or a missing
/// plugin leaves the app working without them.
class LocalReminders implements ReminderSink {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  /// The channel's name and description in the app's language at the time.
  static NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'sofra-reminders',
      L10n.current.profChannelName,
      channelDescription: L10n.current.profChannelDescription,
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
      final now = DateTime.now();
      // A finished step timer is in the past; scheduling it would throw.
      _extra.removeWhere((_, r) => !r.at.isAfter(now));
      for (final r in [...reminders, ..._extra.values]) {
        await _schedule(r);
      }
    } catch (e) {
      debugPrint('Scheduling reminders failed: $e');
    }
  }

  final _extra = <int, Reminder>{};

  Future<void> _schedule(Reminder r) => _plugin.zonedSchedule(
    id: r.id,
    // An absolute instant; no device time-zone name is needed.
    scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
    notificationDetails: _details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: r.title,
    body: r.body,
  );

  @override
  Future<void> scheduleOne(Reminder reminder) async {
    _extra[reminder.id] = reminder;
    if (!await (_ready ??= _init())) return;
    try {
      await _schedule(reminder);
    } catch (e) {
      debugPrint('Scheduling timer failed: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    _extra.remove(id);
    if (!await (_ready ??= _init())) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancelling timer failed: $e');
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
  final t = L10n.current;
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
          // Slot names arrive as the stored Arabic labels.
          t.profReminderMealTitle(L10n.term(slotName(m.slot)), '$before'),
          t.profReminderMealBody(titleOf(m)),
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
            t.profReminderLeftoverTitle(d.name),
            t.profReminderLeftoverBody(_servings(d.servings)),
          ),
        );
      }
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

String _servings(double v) {
  if (v == 1) return L10n.current.profServingOne;
  final n = v == v.roundToDouble() ? v.round().toString() : v.toString();
  return L10n.current.profServings(n);
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
