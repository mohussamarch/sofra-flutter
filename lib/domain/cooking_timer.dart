/// Serializable wall-clock timer; sleeping/backgrounding does not lose elapsed
/// time. Zero-minute/outside-session steps require a manual advance.
class CookingTimer {
  CookingTimer({
    required List<int> durations,
    this.step = 0,
    int? remaining,
    this.runningSince,
    bool finished = false,
  }) : finished = finished || durations.isEmpty,
       durations = List.unmodifiable(durations),
       remaining = remaining ?? (durations.isEmpty ? 0 : durations[step]) {
    if (durations.any((v) => v < 0) ||
        this.remaining < 0 ||
        step < 0 ||
        (durations.isNotEmpty && step >= durations.length)) {
      throw ArgumentError('Invalid timer');
    }
  }
  final List<int> durations;
  final int step, remaining;
  final DateTime? runningSince;
  final bool finished;
  bool get needsManualAdvance =>
      !finished && durations.isNotEmpty && durations[step] == 0;
  CookingTimer start(DateTime now) =>
      finished || needsManualAdvance || runningSince != null
      ? this
      : CookingTimer(
          durations: durations,
          step: step,
          remaining: remaining,
          runningSince: now,
          finished: durations.isEmpty,
        );
  CookingTimer at(DateTime now) {
    if (runningSince == null || finished) return this;
    var elapsed = now.difference(runningSince!).inSeconds;
    if (elapsed <= 0) return this;
    var index = step, left = remaining - elapsed;
    while (left <= 0 && index < durations.length - 1) {
      index++;
      if (durations[index] == 0) {
        return CookingTimer(durations: durations, step: index, remaining: 0);
      }
      left += durations[index];
    }
    if (left <= 0) {
      return CookingTimer(
        durations: durations,
        step: index,
        remaining: 0,
        finished: true,
      );
    }
    return CookingTimer(
      durations: durations,
      step: index,
      remaining: left,
      runningSince: now,
    );
  }

  CookingTimer pause(DateTime now) {
    final value = at(now);
    return CookingTimer(
      durations: durations,
      step: value.step,
      remaining: value.remaining,
      finished: value.finished,
    );
  }

  CookingTimer advance(DateTime now) {
    final value = at(now), index = value.step + 1;
    if (index >= durations.length) {
      return CookingTimer(
        durations: durations,
        step: value.step,
        remaining: 0,
        finished: true,
      );
    }
    return CookingTimer(durations: durations, step: index).start(now);
  }

  Map<String, dynamic> toJson() => {
    'durations': durations,
    'step': step,
    'remaining': remaining,
    'runningSince': runningSince?.toIso8601String(),
    'finished': finished,
  };
  factory CookingTimer.fromJson(Map<String, dynamic> v) => CookingTimer(
    durations: List<int>.from(v['durations'] as List),
    step: v['step'] as int,
    remaining: v['remaining'] as int,
    runningSince: v['runningSince'] == null
        ? null
        : DateTime.parse(v['runningSince'] as String),
    finished: v['finished'] == true,
  );
}
