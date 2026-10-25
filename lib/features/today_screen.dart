import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/models.dart';
import '../scene/kitchen_scene.dart';
import '../scene/scene_assets.dart';
import '../scene/scene_lighting.dart';
import '../ui/design.dart';
import 'common.dart';
import 'kitchen_screen.dart';
import 'recipes_screen.dart';
import 'table_screen.dart';

const kitchenManifest = 'assets/scenes/kitchen/manifest.json';

/// Background tones per lighting mode (top, bottom), picked from the renders'
/// own walls and floor so the scene melts into the page.
const _tones = {
  'morning': (Color(0xFFF7F0E5), Color(0xFFEBDDC9)),
  'golden': (Color(0xFFF6E6D3), Color(0xFFE5C9A8)),
  'night': (Color(0xFF2F3843), Color(0xFF1F262E)),
};

/// Opening screen: the Blender kitchen, edges dissolved into the page, with
/// today's plan in a sheet underneath. Tapping the fridge or pantry shows
/// what is inside; the stove leads to the table.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.showScene = true});

  /// Off in widget tests: the scene decodes images and runs ambient timers.
  final bool showScene;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final scene = KitchenSceneController();
  LoadedScene? loaded;
  Object? sceneError;
  Timer? clock;
  LightingSchedule schedule = LightingSchedule.provisional();
  Map<String, double> weights = const {'morning': 1};

  @override
  void initState() {
    super.initState();
    scene.addListener(_onScene);
    _tick();
    clock = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    if (widget.showScene) _load();
  }

  Future<void> _load() async {
    try {
      final s = await LoadedScene.load(rootBundle, kitchenManifest);
      if (!mounted) return s.dispose();
      setState(() {
        loaded = s;
        schedule = LightingSchedule.provisional().restrictTo(
          s.manifest.lightingModes.map((m) => m.id),
        );
      });
      _tick();
    } catch (e) {
      if (mounted) setState(() => sceneError = e);
    }
  }

  void _tick() {
    if (mounted) setState(() => weights = schedule.weightsAtTime(DateTime.now()));
  }

  void _onScene() => setState(() {});

  @override
  void dispose() {
    clock?.cancel();
    scene.removeListener(_onScene);
    scene.dispose();
    loaded?.dispose();
    super.dispose();
  }

  /// The lighting weights mix the per-mode tones like the scene mixes renders.
  (Color, Color) get _tone {
    Color mix(Color Function((Color, Color)) pick) {
      var r = .0, g = .0, b = .0, total = .0;
      for (final MapEntry(key: mode, value: w) in weights.entries) {
        final c = pick(_tones[mode] ?? _tones['morning']!);
        r += c.r * w;
        g += c.g * w;
        b += c.b * w;
        total += w;
      }
      if (total == 0) return pick(_tones['morning']!);
      return Color.from(alpha: 1, red: r / total, green: g / total, blue: b / total);
    }

    return (mix((t) => t.$1), mix((t) => t.$2));
  }

  bool get _dark => (weights['night'] ?? 0) > .5;

  Future<void> _openZone(StorageZone zone) async {
    await ZoneStockSheet.show(context, zone);
    scene.close();
  }

  void _onHotspot(String id) {
    final nav = SofraScope.navOf(context);
    switch (id) {
      case 'pantry' || 'shelves':
        _openZone(StorageZone.pantry);
      case 'freezer':
        _openZone(StorageZone.freezer);
      case 'stove':
        nav.goTab(AppTab.table);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = _tone;
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.maxWidth * 1.24).clamp(0.0, box.maxHeight * .7);
        final sceneTop = media.padding.top + 30;
        final zoomed = scene.phase != DoorPhase.closed;
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: sceneTop,
                left: (box.maxWidth - side) / 2,
                width: side,
                height: side,
                child: _scene(top, bottom, zoomed),
              ),
              Positioned(
                top: media.padding.top,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: zoomed ? 0 : 1,
                  duration: Sofra.motion(context, true),
                  child: IgnorePointer(ignoring: zoomed, child: _Header(dark: _dark)),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: .36,
                minChildSize: .2,
                maxChildSize: .92,
                snap: true,
                snapSizes: const [.36],
                builder: (context, scroll) => _TodaySheet(scroll: scroll),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scene(Color top, Color bottom, bool zoomed) {
    final s = loaded;
    final edge = IgnorePointer(
      child: AnimatedOpacity(
        opacity: zoomed ? 0 : 1,
        duration: Sofra.motion(context),
        curve: Sofra.calmCurve,
        child: CustomPaint(
          size: Size.infinite,
          painter: _RoomEdgeFade(top: top, bottom: bottom),
        ),
      ),
    );
    if (s == null) {
      return sceneError == null
          ? const SizedBox.shrink()
          : const Center(child: Icon(Icons.kitchen_outlined, size: 64));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        KitchenScene(
          scene: s,
          controller: scene,
          schedule: schedule,
          onHotspotTap: _onHotspot,
          onDoorOpened: (_) => _openZone(StorageZone.fridge),
        ),
        edge,
      ],
    );
  }
}

/// Paints the page gradient over the scene with a soft hexagonal hole cut to
/// the room's interior, so the render's background and the cut wall/floor
/// edges never show. Canvas coordinates are the 1440px render's.
class _RoomEdgeFade extends CustomPainter {
  _RoomEdgeFade({required this.top, required this.bottom});
  final Color top, bottom;

  static const _canvas = 1440.0;
  static const _room = [
    Offset(720, 250),
    Offset(1195, 520),
    Offset(1195, 860),
    Offset(720, 1130),
    Offset(245, 860),
    Offset(245, 520),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _canvas;
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds.inflate(2), Paint());
    final page = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    );
    canvas.drawRect(bounds.inflate(2), Paint()..shader = page.createShader(bounds));
    final hole = Path()..addPolygon([for (final p in _room) p * k], true);
    canvas.drawPath(
      hole,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 42 * k),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomEdgeFade old) => old.top != top || old.bottom != bottom;
}

class _Header extends StatelessWidget {
  const _Header({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final ink = dark ? Colors.white : Sofra.ink;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
        ? 'نهارك سعيد'
        : 'مساء الخير';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting يا ${c.profile.displayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: ink.withValues(alpha: .7),
                  ),
                ),
                Text(
                  c.profile.houseName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -.3,
                  ),
                ),
              ],
            ),
          ),
          PressScale(
            child: Glass(
              radius: Sofra.r16,
              opacity: dark ? .16 : .7,
              tint: dark ? Colors.black : Colors.white,
              child: IconButton(
                key: const ValueKey('open-home-settings'),
                onPressed: () => nav.goTab(AppTab.profile),
                tooltip: 'بيتي',
                icon: Icon(Icons.person_outline_rounded, color: ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's plan and a nudge from what is in stock.
class _TodaySheet extends StatefulWidget {
  const _TodaySheet({required this.scroll});
  final ScrollController scroll;
  @override
  State<_TodaySheet> createState() => _TodaySheetState();
}

class _TodaySheetState extends State<_TodaySheet> {
  Future<Map<String, dynamic>?>? inspiration;

  /// First catalog recipe from the user's preferred cuisines.
  Future<Map<String, dynamic>?> _inspiration(SofraController c) async {
    for (final group in c.profile.cuisines) {
      final rows = await c.recipes.search(cuisineGroup: group);
      if (rows.isNotEmpty) return rows[DateTime.now().day % rows.length];
    }
    final rows = await c.recipes.index;
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    inspiration ??= _inspiration(c);
    final stock = c.stock;
    final today = c.plansOn(DateTime.now());
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Sofra.cream,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Sofra.r28),
        ),
        boxShadow: Sofra.shadow(1.4),
      ),
      child: ListView(
        controller: widget.scroll,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Sofra.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'على سفرة ${c.market.today}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (today.isNotEmpty)
            for (final m in today) PlannedMealCard(m, compact: true)
          else
            Surface(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Sofra.peach,
                      borderRadius: BorderRadius.circular(Sofra.r12),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Sofra.orange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      stock.isEmpty
                          ? 'افتح التلاجة وعرّفنا على اللي عندك.'
                          : 'لسه ما اخترناش أكلة. نشوف وصفات من الموجود؟',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DepthButton(
                  compact: true,
                  label: stock.isEmpty ? 'عرّفني على مطبخك' : 'وصفات من الموجود',
                  icon: stock.isEmpty
                      ? Icons.add_rounded
                      : Icons.auto_awesome_rounded,
                  onPressed: () => stock.isEmpty
                      ? nav.goTab(AppTab.kitchen)
                      : nav.goTab(AppTab.recipes),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DepthButton(
                  compact: true,
                  secondary: true,
                  label: '${stock.length} في مطبخك',
                  icon: Icons.kitchen_outlined,
                  onPressed: () => nav.goTab(AppTab.kitchen),
                ),
              ),
            ],
          ),
          SectionTitle(
            'إلهام لطبخة حلوة',
            action: 'كل الوصفات',
            onAction: () => nav.goTab(AppTab.recipes),
          ),
          FutureBuilder<Map<String, dynamic>?>(
            future: inspiration,
            builder: (context, snap) {
              final row = snap.data;
              if (snap.connectionState != ConnectionState.done) {
                return const LoadingBlock();
              }
              return row == null ? const SizedBox.shrink() : RecipeCard(row);
            },
          ),
        ],
      ),
    );
  }
}
