import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'scene/kitchen_scene.dart';
import 'scene/scene_assets.dart';

/// Standalone performance spike for the 2.5D kitchen (S24 Ultra test).
/// Run: flutter run -t lib/main_scene_spike.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SceneSpikeApp());
}

const kitchenManifest = 'assets/scenes/kitchen/manifest.json';

class SceneSpikeApp extends StatelessWidget {
  const SceneSpikeApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale('ar'),
    supportedLocales: [Locale('ar')],
    localizationsDelegates: [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: SceneSpikePage(),
    ),
  );
}

class SceneSpikePage extends StatefulWidget {
  const SceneSpikePage({super.key});
  @override
  State<SceneSpikePage> createState() => _SceneSpikePageState();
}

class _SceneSpikePageState extends State<SceneSpikePage> {
  final _controller = KitchenSceneController();
  LoadedScene? _scene;
  Object? _error;
  Duration? _loadTime;
  double? _minute;
  bool _ambience = true, _panel = true;
  String _lastTap = '—';
  final _frames = <FrameTiming>[];

  @override
  void initState() {
    super.initState();
    _load();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _load() async {
    final watch = Stopwatch()..start();
    try {
      final scene = await LoadedScene.load(rootBundle, kitchenManifest);
      if (!mounted) return scene.dispose();
      setState(() {
        _scene = scene;
        _loadTime = watch.elapsed;
      });
    } catch (e) {
      setState(() => _error = e);
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
    if (_frames.length > 120) _frames.removeRange(0, _frames.length - 120);
    if (mounted && _panel) setState(() {});
  }

  ({double avg, double worst, int janky}) get _frameStats {
    if (_frames.isEmpty) return (avg: 0, worst: 0, janky: 0);
    final ms = [for (final f in _frames) f.totalSpan.inMicroseconds / 1000];
    return (
      avg: ms.reduce((a, b) => a + b) / ms.length,
      worst: ms.reduce((a, b) => a > b ? a : b),
      janky: ms.where((v) => v > 16.7).length,
    );
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _controller.dispose();
    _scene?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return PopScope(
      canPop: _controller.phase == DoorPhase.closed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.close();
      },
      child: Scaffold(
        body: _error != null
            ? Center(child: SelectableText('تعذّر تحميل المشهد:\n$_error'))
            : scene == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  KitchenScene(
                    scene: scene,
                    controller: _controller,
                    minuteOfDay: _minute,
                    ambience: _ambience,
                    onHotspotTap: (id) => setState(() => _lastTap = id),
                  ),
                  if (!scene.manifest.approved)
                    const PositionedDirectional(
                      top: 48,
                      start: 16,
                      child: _Chip('غير معتمد — اختبار تقني'),
                    ),
                  if (_controller.phase == DoorPhase.open)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _ContentsPlaceholder(onClose: _controller.close),
                    ),
                  if (_controller.phase == DoorPhase.closed) _debugPanel(),
                ],
              ),
      ),
    );
  }

  Widget _debugPanel() {
    final stats = _frameStats;
    final minute = _minute;
    String clock(double m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).floor().toString().padLeft(2, '0')}';
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        minute == null
                            ? 'الوقت: الساعة الحالية'
                            : 'الوقت: ${clock(minute)}',
                      ),
                    ),
                    IconButton(
                      tooltip: _panel ? 'إخفاء' : 'إظهار',
                      icon: Icon(
                        _panel ? Icons.expand_more : Icons.expand_less,
                      ),
                      onPressed: () => setState(() => _panel = !_panel),
                    ),
                  ],
                ),
                if (_panel) ...[
                  Slider(
                    value: minute ?? 600,
                    min: 0,
                    max: 1439,
                    onChanged: (v) => setState(() => _minute = v),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (label, m) in [
                        ('شروق', 5.5 * 60),
                        ('صبح', 10.0 * 60),
                        ('غروب', 17.5 * 60),
                        ('ليل', 22.0 * 60),
                      ])
                        ActionChip(
                          label: Text(label),
                          onPressed: () => setState(() => _minute = m),
                        ),
                      ActionChip(
                        label: const Text('الساعة الحالية'),
                        onPressed: () => setState(() => _minute = null),
                      ),
                      FilterChip(
                        label: const Text('حركة المطبخ'),
                        selected: _ambience,
                        onSelected: (v) => setState(() => _ambience = v),
                      ),
                    ],
                  ),
                  Text(
                    'تحميل ${_loadTime?.inMilliseconds} ms · فريم ${stats.avg.toStringAsFixed(1)} ms'
                    ' · أسوأ ${stats.worst.toStringAsFixed(1)} · بطيء ${stats.janky}/${_frames.length}'
                    ' · آخر لمسة: $_lastTap',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}

class _ContentsPlaceholder extends StatelessWidget {
  const _ContentsPlaceholder({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text('هنا هتظهر مكونات التلاجة. شكل العرض هيتصمم بعدين.'),
            ),
            FilledButton(onPressed: onClose, child: const Text('اقفل')),
          ],
        ),
      ),
    ),
  );
}
