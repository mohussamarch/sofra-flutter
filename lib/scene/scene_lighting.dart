/// One lighting mode starting at [minute] of the local day (0..1439).
class LightingKey {
  const LightingKey(this.minute, this.mode);
  final int minute;
  final String mode;
}

/// Daily cycle of lighting modes with a cross-fade centred on every change.
/// Provisional fixed clock times until the user chooses a policy (sunrise/
/// sunset, location, golden duration): see docs/SCENE-CONTRACT.md.
class LightingSchedule {
  LightingSchedule(List<LightingKey> keys, {this.transitionMinutes = 45})
    : keys = List.unmodifiable(
        [...keys]..sort((a, b) => a.minute.compareTo(b.minute)),
      ) {
    if (this.keys.isEmpty) throw ArgumentError('Schedule needs a mode');
    if (transitionMinutes < 0) throw ArgumentError('Negative transition');
    for (final k in this.keys) {
      if (k.minute < 0 || k.minute >= _day) {
        throw ArgumentError('Minute ${k.minute} outside the day');
      }
    }
    for (var i = 0; i < this.keys.length && this.keys.length > 1; i++) {
      final span = _span(i);
      if (span < transitionMinutes) {
        throw ArgumentError('Mode ${this.keys[i].mode} shorter than fade');
      }
    }
  }

  static const _day = 24 * 60;

  /// Dawn and dusk use the golden art state; subject to user approval.
  static LightingSchedule provisional() => LightingSchedule(const [
    LightingKey(5 * 60, 'golden'),
    LightingKey(6 * 60 + 30, 'morning'),
    LightingKey(16 * 60 + 30, 'golden'),
    LightingKey(18 * 60 + 30, 'night'),
  ]);

  final List<LightingKey> keys;
  final int transitionMinutes;

  /// Drops modes the scene lacks and merges neighbours that became equal, so
  /// a pack with only morning/night still cycles smoothly.
  LightingSchedule restrictTo(Iterable<String> available) {
    final set = available.toSet();
    final kept = <LightingKey>[];
    for (final k in keys.where((k) => set.contains(k.mode))) {
      if (kept.isEmpty || kept.last.mode != k.mode) kept.add(k);
    }
    if (kept.length > 1 && kept.first.mode == kept.last.mode) kept.removeAt(0);
    if (kept.isEmpty) kept.add(LightingKey(0, set.first));
    return LightingSchedule(kept, transitionMinutes: transitionMinutes);
  }

  int _span(int i) {
    final next = keys[(i + 1) % keys.length].minute;
    final span = (next - keys[i].minute) % _day;
    return span == 0 ? _day : span;
  }

  /// Weights summing to 1 with at most two non-zero modes.
  Map<String, double> weightsAt(double minuteOfDay) {
    if (keys.length == 1) return {keys.single.mode: 1};
    final m = minuteOfDay % _day;
    final half = transitionMinutes / 2;
    for (var i = 0; i < keys.length; i++) {
      final prev = keys[(i - 1 + keys.length) % keys.length];
      final distance = _signedDistance(m, keys[i].minute.toDouble());
      if (half > 0 && distance.abs() < half) {
        final t = _smooth((distance + half) / transitionMinutes);
        return _mix(prev.mode, keys[i].mode, t);
      }
    }
    var current = keys.last;
    for (final k in keys) {
      if (k.minute <= m) current = k;
    }
    return {current.mode: 1};
  }

  Map<String, double> weightsAtTime(DateTime local) => weightsAt(
    local.hour * 60 +
        local.minute +
        local.second / 60 +
        local.millisecond / 6e4,
  );

  static double _signedDistance(double m, double key) {
    var d = (m - key) % _day;
    if (d > _day / 2) d -= _day;
    return d;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  static Map<String, double> _mix(String from, String to, double t) =>
      from == to ? {to: 1} : {from: 1 - t, to: t};
}
