import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app/scope.dart';
import '../domain/models.dart';
import '../scene/kitchen_scene.dart';
import '../scene/scene_assets.dart';
import '../scene/scene_lighting.dart';
import '../ui/design.dart';
import 'fridge_motion.dart';
import 'kitchen_screen.dart';
import 'recipes_screen.dart';
import 'table_screen.dart';

const kitchenManifest = 'assets/scenes/kitchen/manifest.json';

/// What the home kitchen is showing: the room, the recipe book floating over
/// it, or the camera at the dining table with the meals.
enum HomeMode { kitchen, recipes, table }

/// Page tones per lighting mode (top, bottom).
const _tones = {
  'morning': (Color(0xFFF8F2E8), Color(0xFFEDE1CF)),
  'golden': (Color(0xFFF7E9D8), Color(0xFFE9D0B2)),
  'night': (Color(0xFF2C3540), Color(0xFF1C2229)),
};

/// Empty corners of the 1440px render, where the four circles sit
/// (start = right in Arabic).
const _topStart = Offset(1250, 130);
const _topEnd = Offset(190, 130);
const _bottomStart = Offset(1250, 1250);
const _bottomEnd = Offset(190, 1250);

/// Floor point the camera moves to for the table (render pixels).
const _tableFocus = Offset(720, 1010);

/// The whole home: the Blender kitchen as a clean floating diorama, the four
/// corner circles, the recipe book and the table, all on one stage so the
/// room never reloads between them.
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    this.mode = HomeMode.kitchen,
    this.showScene = true,
  });
  final HomeMode mode;

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
  final motions = <String, Future<FridgeMotion?>>{};
  FridgeMotion? _readyMotion;

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
      final s = await LoadedScene.load(
        rootBundle,
        kitchenManifest,
        keyBackdrop: true,
      );
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
    if (!mounted) return;
    setState(() => weights = schedule.weightsAtTime(DateTime.now()));
    if (loaded != null) _prepareMotion();
  }

  String get _mode =>
      weights.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  void _prepareMotion() {
    final mode = _mode;
    motions.putIfAbsent(mode, () => FridgeMotion.load(mode)).then((m) {
      if (mounted && mode == _mode) _readyMotion = m;
    });
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
      return Color.from(
        alpha: 1,
        red: r / total,
        green: g / total,
        blue: b / total,
      );
    }

    return (mix((t) => t.$1), mix((t) => t.$2));
  }

  bool get _dark => (weights['night'] ?? 0) > .5;

  Future<void> _openZone(StorageZone zone) async {
    await ZoneStockSheet.show(context, zone);
    scene.close();
  }

  void _onHotspot(String id) {
    if (widget.mode != HomeMode.kitchen) return;
    final nav = SofraScope.navOf(context);
    switch (id) {
      case 'fridge' when _readyMotion != null:
        final (top, bottom) = _tone;
        _readyMotion!.play(context, top: top, bottom: bottom);
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
    final ink = _dark ? Colors.white : Sofra.ink;
    final nav = SofraScope.navOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final head = media.padding.top + 48;
        final foot = media.padding.bottom + 96;
        final room = box.maxHeight - head - foot;
        final side = (box.maxWidth * .94).clamp(0.0, room * .9);
        final stage = Rect.fromLTWH(
          (box.maxWidth - side) / 2,
          head + (room - side) / 2,
          side,
          side,
        );
        final k = side / 1440;
        Offset at(Offset canvas) => stage.topLeft + canvas * k;
        final kitchen = widget.mode == HomeMode.kitchen;
        Widget circle(
          Offset point,
          String key,
          IconData icon,
          String label,
          AppTab tab,
        ) => Positioned(
          left: at(point).dx - 40,
          top: at(point).dy - 30,
          width: 80,
          child: _CornerCircle(
            id: key,
            icon: icon,
            label: label,
            dark: _dark,
            visible: kitchen,
            onTap: () => nav.goTab(tab),
          ),
        );
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
              Positioned.fromRect(
                rect: stage,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: widget.mode == HomeMode.table ? 1 : 0),
                  duration: Sofra.motion(context) * 2,
                  curve: Sofra.calmCurve,
                  builder: (context, t, child) {
                    final focus = _tableFocus * k;
                    final s = lerpDouble(1, 2.3, t)!;
                    final target = Offset.lerp(
                      focus,
                      Offset(side / 2, side * .22),
                      t,
                    )!;
                    return Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(target.dx, target.dy, 0, 1)
                        ..scaleByDouble(s, s, 1, 1)
                        ..translateByDouble(-focus.dx, -focus.dy, 0, 1),
                      child: child,
                    );
                  },
                  child: _stage(),
                ),
              ),
              circle(
                _topStart,
                'circle-profile',
                Icons.person_outline_rounded,
                'بروفايلي',
                AppTab.profile,
              ),
              circle(
                _topEnd,
                'circle-settings',
                Icons.settings_outlined,
                'الإعدادات',
                AppTab.settings,
              ),
              circle(
                _bottomEnd,
                'circle-community',
                Icons.diversity_3_outlined,
                'مجتمع سفرة',
                AppTab.community,
              ),
              circle(
                _bottomStart,
                'circle-kitchen',
                Icons.kitchen_outlined,
                'مطبخي',
                AppTab.kitchen,
              ),
              Positioned(
                top: media.padding.top,
                left: 0,
                right: 0,
                height: 48,
                // The zoomed table fills the top; the line steps aside.
                child: AnimatedOpacity(
                  opacity: widget.mode == HomeMode.table ? 0 : 1,
                  duration: Sofra.motion(context, false),
                  child: _TopLine(ink: ink),
                ),
              ),
              if (widget.mode == HomeMode.table)
                Positioned(
                  left: 0,
                  right: 0,
                  top: head + room * .3,
                  bottom: foot,
                  child: const _MealCards(),
                ),
              _RecipeBook(open: widget.mode == HomeMode.recipes, top: head),
            ],
          ),
        );
      },
    );
  }

  /// The diorama with a soft floor shadow beneath it.
  Widget _stage() {
    final s = loaded;
    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(child: CustomPaint(painter: _DioramaShadow())),
        if (s != null)
          KitchenScene(
            scene: s,
            controller: scene,
            schedule: schedule,
            ambience: widget.mode == HomeMode.kitchen,
            onHotspotTap: _onHotspot,
            onDoorOpened: (_) => _openZone(StorageZone.fridge),
            shouldOpenDoor: (door) =>
                widget.mode == HomeMode.kitchen &&
                !(door == 'fridge' && _readyMotion != null),
          )
        else if (sceneError != null)
          const Center(child: Icon(Icons.kitchen_outlined, size: 64)),
      ],
    );
  }
}

/// Grounding shadow under the room's floor slab, so the diorama sits on the
/// page instead of hovering (render pixels, 1440 canvas).
class _DioramaShadow extends CustomPainter {
  const _DioramaShadow();
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1440;
    final floor = Path()
      ..addPolygon([
        for (final p in const [
          Offset(140, 930),
          Offset(720, 1270),
          Offset(1300, 930),
          Offset(720, 1120),
        ])
          p * k,
      ], true);
    canvas.drawPath(
      floor.shift(Offset(0, 34 * k)),
      Paint()
        ..color = const Color(0xFF3B2A18).withValues(alpha: .22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 34 * k),
    );
  }

  @override
  bool shouldRepaint(_DioramaShadow old) => false;
}

/// Greeting small on the start side, the account's name centred.
class _TopLine extends StatelessWidget {
  const _TopLine({required this.ink});
  final Color ink;
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
        ? 'نهارك سعيد'
        : 'مساء الخير';
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          c.profile.displayName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -.2,
          ),
        ),
        PositionedDirectional(
          start: 20,
          child: Text(
            greeting,
            style: TextStyle(fontSize: 12, color: ink.withValues(alpha: .62)),
          ),
        ),
      ],
    );
  }
}

class _CornerCircle extends StatelessWidget {
  const _CornerCircle({
    required this.id,
    required this.icon,
    required this.label,
    required this.dark,
    required this.visible,
    required this.onTap,
  });
  final String id;
  final IconData icon;
  final String label;
  final bool dark, visible;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : Sofra.ink;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Sofra.motion(context),
        curve: Sofra.calmCurve,
        child: AnimatedScale(
          scale: visible ? 1 : .8,
          duration: Sofra.motion(context),
          curve: Sofra.calmCurve,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PressScale(
                child: LiquidGlass(
                  radius: 26,
                  dark: dark,
                  child: SizedBox.square(
                    dimension: 52,
                    child: IconButton(
                      key: ValueKey(id),
                      onPressed: onTap,
                      tooltip: label,
                      icon: Icon(icon, color: ink, size: 23),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: .75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The table's meals as floating 2D panels: the centred one sharp, its
/// neighbours turned slightly away and faded, swiped side to side.
class _MealCards extends StatefulWidget {
  const _MealCards();
  @override
  State<_MealCards> createState() => _MealCardsState();
}

class _MealCardsState extends State<_MealCards> {
  final pages = PageController(viewportFraction: .78);

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final meals = c
        .upcoming(DateTime.now())
        .where((m) => !m.completed)
        .toList();
    final cards = meals.isEmpty
        ? [
            LiquidGlass(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant_outlined, size: 34),
                  const SizedBox(height: 10),
                  const Text(
                    'السفرة لسه فاضية',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'افتح كتاب الوصفات واختار أكلة نحطها هنا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Sofra.muted),
                  ),
                  const SizedBox(height: 16),
                  DepthButton(
                    key: const ValueKey('table-open-book'),
                    compact: true,
                    icon: Icons.menu_book_outlined,
                    label: 'كتاب الوصفات',
                    onPressed: () => nav.goTab(AppTab.recipes),
                  ),
                ],
              ),
            ),
          ]
        : [for (final m in meals) PlannedMealCard(m)];
    return Column(
      children: [
        Text(
          'على سفرة ${c.market.today}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black38, blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: pages,
            itemCount: cards.length,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: pages,
              builder: (context, child) {
                final page = pages.hasClients && pages.position.haveDimensions
                    ? pages.page ?? 0
                    : 0.0;
                final d = (page - i).clamp(-1.0, 1.0);
                final s = 1 - d.abs() * .1;
                return Opacity(
                  opacity: 1 - d.abs() * .5,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0012)
                      ..rotateY(d * .35)
                      ..scaleByDouble(s, s, 1, 1),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(child: cards[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The recipe book: an old sepia page that slides up over the kitchen.
class _RecipeBook extends StatelessWidget {
  const _RecipeBook({required this.open, required this.top});
  final bool open;
  final double top;
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 84;
    return Positioned(
      left: 10,
      right: 10,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !open,
        child: AnimatedSlide(
          offset: open ? Offset.zero : const Offset(0, 1.15),
          duration: Sofra.motion(context),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: open ? 1 : 0,
            duration: Sofra.motion(context, true),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Sofra.r22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B2A18).withValues(alpha: .35),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Sofra.r22),
                child: CustomPaint(
                  painter: const PaperPainter(),
                  child: open
                      ? const Paper(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: Paper.ink,
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                                  child: Column(
                                    children: [
                                      Text(
                                        'كتاب الوصفات',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      _Flourish(),
                                    ],
                                  ),
                                ),
                                Expanded(child: RecipesScreen()),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin ornamental rule under the book's title.
class _Flourish extends StatelessWidget {
  const _Flourish();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 60, height: 1, color: Paper.ink.withValues(alpha: .35)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.spa_outlined, size: 14, color: Paper.ink),
      ),
      Container(width: 60, height: 1, color: Paper.ink.withValues(alpha: .35)),
    ],
  );
}
