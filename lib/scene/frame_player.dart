import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Plays a pre-rendered image sequence toward [target], forward or back.
///
/// Frames stay compressed in memory and are decoded a few ahead of the
/// playhead, so a 44-frame 1080×2340 move never holds more than [window]
/// decoded images (one decoded frame is ~10 MB at full size).
class FramePlayer extends StatefulWidget {
  const FramePlayer({
    super.key,
    required this.frames,
    required this.target,
    this.fps = 30,
    this.window = 6,
    this.decodeWidth,
    this.onArrived,
    this.onFrame,
    this.initial = 0,
    this.fit = BoxFit.cover,
  });

  final List<Uint8List> frames;

  /// Index the playhead moves toward; changing it reverses or resumes.
  final int target;
  final double fps;
  final int window;

  /// Decode size in physical pixels; defaults to the frames' own size.
  final int? decodeWidth;
  final ValueChanged<int>? onArrived;

  /// Every frame actually shown, for overlays that follow the move.
  final ValueChanged<int>? onFrame;
  final int initial;
  final BoxFit fit;

  @override
  State<FramePlayer> createState() => _FramePlayerState();
}

class _FramePlayerState extends State<FramePlayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final _decoded = <int, ui.Image>{};
  final _pending = <int>{};
  int _current = 0;
  Duration _last = Duration.zero;
  bool _arrived = false;

  int get _step => widget.target.compareTo(_current);

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _prefetch();
    _ticker.start();
  }

  @override
  void didUpdateWidget(FramePlayer old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _arrived = false;
      _prefetch();
      if (!_ticker.isActive) _ticker.start();
    }
  }

  void _prefetch() {
    final dir = _step == 0 ? 1 : _step;
    for (var k = 0; k <= widget.window; k++) {
      final i = _current + dir * k;
      if (i < 0 || i >= widget.frames.length) break;
      _decode(i);
    }
    // Drop decoded frames outside the window around the playhead.
    for (final i in _decoded.keys.toList()) {
      final ahead = (i - _current) * dir;
      if (ahead < -1 || ahead > widget.window) _decoded.remove(i)!.dispose();
    }
  }

  Future<void> _decode(int i) async {
    if (_decoded.containsKey(i) || !_pending.add(i)) return;
    try {
      final codec = await ui.instantiateImageCodec(
        widget.frames[i],
        targetWidth: widget.decodeWidth,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      _decoded[i]?.dispose();
      _decoded[i] = frame.image;
      if (i == _current) setState(() {});
    } finally {
      _pending.remove(i);
    }
  }

  void _onTick(Duration elapsed) {
    if (_step == 0) {
      if (!_arrived && _decoded.containsKey(_current)) {
        _arrived = true;
        _ticker.stop();
        _last = Duration.zero;
        widget.onArrived?.call(_current);
      }
      return;
    }
    final frameTime = Duration(microseconds: (1e6 / widget.fps).round());
    if (_last == Duration.zero) _last = elapsed;
    if (elapsed - _last < frameTime) return;
    final next = _current + _step;
    // Waits for the decoder instead of skipping, so the move never jumps.
    if (!_decoded.containsKey(next)) {
      _prefetch();
      return;
    }
    _last = elapsed;
    setState(() => _current = next);
    widget.onFrame?.call(next);
    _prefetch();
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final image in _decoded.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _decoded[_current];
    return image == null
        ? const SizedBox.expand()
        : RawImage(image: image, fit: widget.fit);
  }
}
