import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ui/design.dart';

/// Meal times the user sets (each slot off until they pick a time), how
/// early to remind, and the ran-out notice.
class ReminderSettings extends StatelessWidget {
  const ReminderSettings({super.key});

  static String timeText(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:${m.toString().padLeft(2, '0')} ${h < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final p = c.profile;
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ميعاد كل وجبة عندك، علشان نفكرك قبلها.',
            style: TextStyle(fontSize: 12, color: Sofra.muted),
          ),
          for (final MapEntry(key: slot, value: name) in mealSlots.entries)
            ListTile(
              key: ValueKey('reminder-time-$slot'),
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              subtitle: Text(
                p.mealTimes[slot] == null
                    ? 'من غير تذكير'
                    : timeText(p.mealTimes[slot]!),
              ),
              trailing: p.mealTimes[slot] == null
                  ? const Icon(Icons.add_alarm_outlined)
                  : IconButton(
                      key: ValueKey('reminder-clear-$slot'),
                      tooltip: 'شيل التذكير',
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
                  helpText: 'ميعاد $name',
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
          const Text('فكرني قبلها بـ', style: TextStyle(fontSize: 13)),
          Wrap(
            spacing: 8,
            children: [
              for (final m in const [15, 30, 60, 90])
                ChoiceChip(
                  key: ValueKey('reminder-before-$m'),
                  label: Text('$m دقيقة'),
                  selected: p.remindBefore == m,
                  onSelected: (_) =>
                      c.updateProfile((p) => p.copyWith(remindBefore: m)),
                ),
            ],
          ),
          SwitchListTile.adaptive(
            key: const ValueKey('reminder-stock'),
            contentPadding: EdgeInsets.zero,
            title: const Text('لما مكوّن يخلص'),
            subtitle: const Text(
              'تنبيه بعد الطبخ لو استخدمت آخر حاجة في الخزين',
              style: TextStyle(fontSize: 11),
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
