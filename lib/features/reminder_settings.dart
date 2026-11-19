import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';

/// Meal times the user sets (each slot off until they pick a time), how
/// early to remind, and the ran-out notice.
class ReminderSettings extends StatelessWidget {
  const ReminderSettings({super.key});

  static String timeText(int minutes) {
    final t = L10n.current;
    final h = minutes ~/ 60, m = minutes % 60;
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:${m.toString().padLeft(2, '0')} ${h < 12 ? t.profAm : t.profPm}';
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    final t = context.l10n;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.profMealTimesIntro,
            style: TextStyle(fontSize: 12, color: Sofra.muted),
          ),
          for (final MapEntry(key: slot, value: stored) in mealSlots.entries)
            ListTile(
              key: ValueKey('reminder-time-$slot'),
              contentPadding: EdgeInsets.zero,
              title: Text(L10n.term(stored)),
              subtitle: Text(
                p.mealTimes[slot] == null
                    ? t.profNoReminder
                    : timeText(p.mealTimes[slot]!),
              ),
              trailing: p.mealTimes[slot] == null
                  ? const Icon(Icons.add_alarm_outlined)
                  : IconButton(
                      key: ValueKey('reminder-clear-$slot'),
                      tooltip: t.profClearReminder,
                      icon: const Icon(Icons.alarm_off_outlined),
                      onPressed: () => c.updateProfile(
                        (p) => p.copyWith(
                          mealTimes: {...p.mealTimes}..remove(slot),
                        ),
                      ),
                    ),
              onTap: () async {
                final current = p.mealTimes[slot];
                final picked = await showTimePicker(
                  context: context,
                  helpText: t.profMealTimeOf(L10n.term(stored)),
                  initialTime: current == null
                      ? TimeOfDay.now()
                      : TimeOfDay(hour: current ~/ 60, minute: current % 60),
                );
                if (picked == null) return;
                await c.updateProfile(
                  (p) => p.copyWith(
                    mealTimes: {
                      ...p.mealTimes,
                      slot: picked.hour * 60 + picked.minute,
                    },
                  ),
                );
              },
            ),
          const SizedBox(height: 4),
          Text(t.profRemindBefore, style: const TextStyle(fontSize: 13)),
          Wrap(
            spacing: 8,
            children: [
              for (final m in const [15, 30, 60, 90])
                SofraChip(
                  key: ValueKey('reminder-before-$m'),
                  label: Text(t.profMinutes('$m')),
                  selected: p.remindBefore == m,
                  onSelected: (_) =>
                      c.updateProfile((p) => p.copyWith(remindBefore: m)),
                ),
            ],
          ),
          SwitchListTile.adaptive(
            key: const ValueKey('reminder-stock'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.profRanOutTitle),
            subtitle: Text(
              t.profRanOutSubtitle,
              style: const TextStyle(fontSize: 11),
            ),
            value: p.stockAlerts,
            onChanged: (v) =>
                c.updateProfile((p) => p.copyWith(stockAlerts: v)),
          ),
        ],
      ),
    );
  }
}
