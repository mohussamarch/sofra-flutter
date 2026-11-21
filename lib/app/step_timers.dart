import 'package:flutter/foundation.dart';

import '../domain/cooking_timer.dart';
import 'reminders.dart';

/// Per-step cooking timers that outlive the cooking screen: they live on the
/// controller and a notification is scheduled for the moment each one ends.
class StepTimers extends ChangeNotifier {
  StepTimers(this._sink, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final ReminderSink _sink;
  final DateTime Function() _now;
  final _timers = <String, CookingTimer>{};

  /// The timer of [key] as of now; idle at [seconds] when never started.
  CookingTimer timer(String key, int seconds) =>
      (_timers[key] ?? CookingTimer(durations: [seconds])).at(_now());

  bool isRunning(String key, int seconds) {
    final t = timer(key, seconds);
    return t.runningSince != null && !t.finished;
  }

  int _id(String key) {
    var h = 0x811c9dc5;
    for (final c in 'step-timer:$key'.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  void start(String key, int seconds, String title, String body) {
    final t = timer(key, seconds);
    if (t.finished || t.runningSince != null) return;
    final now = _now();
    _timers[key] = t.start(now);
    _sink.scheduleOne(
      Reminder(_id(key), now.add(Duration(seconds: t.remaining)), title, body),
    );
    notifyListeners();
  }

  void pause(String key, int seconds) {
    _timers[key] = timer(key, seconds).pause(_now());
    _sink.cancel(_id(key));
    notifyListeners();
  }

  void reset(String key, int seconds) {
    _timers.remove(key);
    _sink.cancel(_id(key));
    notifyListeners();
  }
}
