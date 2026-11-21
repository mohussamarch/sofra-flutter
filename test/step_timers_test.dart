import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/app/scope.dart';
import 'package:tabkha_demo/app/sofra_controller.dart';
import 'package:tabkha_demo/app/step_timers.dart';
import 'package:tabkha_demo/features/cooking_screen.dart';
import 'package:tabkha_demo/l10n/l10n.dart';

class _Nav implements SofraNav {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

void main() {
  group('StepTimers', () {
    test('start, pause, resume, reset and a notification at the end', () {
      var now = DateTime(2026, 1, 1, 12);
      final sink = SilentReminders();
      final hub = StepTimers(sink, now: () => now);
      expect(hub.timer('a', 120).remaining, 120);
      expect(hub.isRunning('a', 120), isFalse);

      hub.start('a', 120, 'done', 'step 1');
      expect(hub.isRunning('a', 120), isTrue);
      expect(sink.extra.length, 1);
      expect(sink.extra.values.single.at, now.add(const Duration(minutes: 2)));

      now = now.add(const Duration(seconds: 30));
      expect(hub.timer('a', 120).remaining, 90);

      hub.pause('a', 120);
      expect(sink.extra, isEmpty);
      now = now.add(const Duration(minutes: 5));
      expect(hub.timer('a', 120).remaining, 90);
      expect(hub.isRunning('a', 120), isFalse);

      hub.start('a', 120, 'done', 'step 1');
      expect(sink.extra.values.single.at, now.add(const Duration(seconds: 90)));
      now = now.add(const Duration(seconds: 91));
      expect(hub.timer('a', 120).finished, isTrue);
      expect(hub.isRunning('a', 120), isFalse);

      hub.reset('a', 120);
      expect(hub.timer('a', 120).remaining, 120);
      expect(hub.timer('a', 120).finished, isFalse);
    });

    test('timers of different steps are independent', () {
      final hub = StepTimers(SilentReminders());
      hub.start('m:0', 60, 't', 'b');
      expect(hub.isRunning('m:0', 60), isTrue);
      expect(hub.isRunning('m:1', 60), isFalse);
    });
  });

  group('StepTimerControl', () {
    Widget app(SofraController c, Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.delegates,
      home: SofraScope(
        controller: c,
        nav: _Nav(),
        child: Scaffold(body: child),
      ),
    );

    testWidgets('starts, pauses, resets and survives leaving the step', (
      tester,
    ) async {
      final c = SofraController();
      final sink = c.reminders as SilentReminders;
      const control = StepTimerControl(
        timerKey: 'meal:2',
        minutes: 10,
        stepNumber: 3,
      );
      await tester.pumpWidget(app(c, control));
      expect(find.text('10:00'), findsOneWidget);
      expect(find.byKey(const ValueKey('step-timer-reset')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('step-timer-start')));
      await tester.pump();
      expect(find.byKey(const ValueKey('step-timer-pause')), findsOneWidget);
      expect(sink.extra.length, 1);
      expect(sink.extra.values.single.body, 'Step 3 time is up');

      // Leave the screen: the timer keeps running and its notification stays.
      await tester.pumpWidget(app(c, const SizedBox()));
      expect(c.stepTimers.isRunning('meal:2', 600), isTrue);
      expect(sink.extra.length, 1);

      // Come back to it still running.
      await tester.pumpWidget(app(c, control));
      expect(find.byKey(const ValueKey('step-timer-pause')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('step-timer-pause')));
      await tester.pump();
      expect(find.byKey(const ValueKey('step-timer-start')), findsOneWidget);
      expect(sink.extra, isEmpty);

      await tester.tap(find.byKey(const ValueKey('step-timer-start')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('step-timer-reset')));
      await tester.pump();
      expect(find.text('10:00'), findsOneWidget);
      expect(find.byKey(const ValueKey('step-timer-reset')), findsNothing);
      await tester.pumpWidget(app(c, const SizedBox()));
    });
  });
}
