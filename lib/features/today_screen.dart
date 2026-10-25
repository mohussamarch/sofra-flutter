import 'dart:async';
import 'dart:ui' as ui show Image, PictureRecorder;
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
import 'common.dart';
import 'recipe_book.dart';
import 'shelf_wheel.dart';
import 'table_screen.dart';

const kitchenManifest = 'assets/scenes/kitchen/manifest.json';

/// What the home kitchen is showing: the room, the recipe book floating over
/// it, or the camera at the dining table with the meals.
enum HomeMode { kitchen, recipes, table }

/// Page tones per lighting mode (top, bottom).
/// Page light per lighting mode: (glow behind the kitchen, dark edge). The
/// room sits in a pool of warm light and its cut walls sink into the dark.
const _tones = {
  'morning': (Color(0xFF4B3B2B), Color(0xFF110D0A)),
  'golden': (Color(0xFF573A28), Color(0xFF130C08)),
  'night': (Color(0xFF26323F), Color(0xFF07090D)),
};

/// The room inside the 1440px render: its centre and width. The room is
/// framed to the screen's width, the empty render margin falls off-screen.
const _roomCenter = Offset(720, 695);
const _roomWidth = 1204.0;
const _roomHeight = 1175.0;

/// The room's outline in the render (measured on the keyed base).
const _roomOutline = [
  Offset(720, 108),
  Offset(1321, 455),
  Offset(1321, 935),
  Offset(720, 1283),
  Offset(117, 935),
  Offset(117, 455),
];

/// Soft mask following the room's outline, drawn a little inside it and
/// blurred, so walls and floor dissolve before their cut edges.
Future<ui.Image> _roomFadeMask() {
  const size = 512;
  const k = size / 1440;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final path = Path()
    ..addPolygon([
      for (final p in _roomOutline) (_roomCenter + (p - _roomCenter) * .9) * k,
    ], true);
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, size * .03),
  );
  return recorder.endRecording().toImage(size, size);
}

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
    if (widget.showScene) {
      _load();
      _roomFadeMask().then((m) {
        if (mounted) {
          setState(() => roomMask = m);
        } else {
          m.dispose();
        }
      });
    }
  }

  ui.Image? roomMask;

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
    roomMask?.dispose();
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

  Future<void> _openZone(StorageZone zone) async {
    final nav = SofraScope.navOf(context);
    await showShelves(
      context,
      title: zoneName(zone),
      items: (context) => zoneShelfItems(context, zone),
      empty: 'ضيف اللي عندك هنا، وهنقولك تطبخ إيه منه.',
      onAdd: () {
        Navigator.pop(context);
        nav.openAddStock();
      },
      onAll: () {
        Navigator.pop(context);
        nav.goTab(AppTab.kitchen);
      },
    );
    scene.close();
  }

  /// The microwave holds what can be warmed up again.
  Future<void> _openLeftovers() => showShelves(
    context,
    title: 'بواقي الأكل',
    items: leftoverShelfItems,
    empty: 'مفيش بواقي متسجلة. لما تطبخ وتفضل حاجة، هتلاقيها هنا تسخنها.',
  );

  /// The oven shows what's coming up; the full plan lives on the table.
  Future<void> _openPlans() {
    final scope = SofraScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: _PlansSheet(),
        ),
      ),
    );
  }

  void _onHotspot(String id) {
    if (widget.mode != HomeMode.kitchen) return;
    switch (id) {
      case 'fridge' when _readyMotion != null:
        final (top, bottom) = _tone;
        _readyMotion!.play(context, top: top, bottom: bottom);
      case 'pantry' || 'shelves':
        _openZone(StorageZone.pantry);
      case 'freezer':
        _openZone(StorageZone.freezer);
      case 'microwave':
        _openLeftovers();
      case 'oven' || 'stove':
        _openPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = _tone;
    final media = MediaQuery.of(context);
    const ink = Colors.white;
    final nav = SofraScope.navOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final head = media.padding.top + 48;
        final foot = media.padding.bottom + 112;
        final room = box.maxHeight - head - foot;
        final fitWidth = box.maxWidth * 1.04 / _roomWidth;
        final fitHeight = room / _roomHeight;
        final k = fitWidth < fitHeight ? fitWidth : fitHeight;
        final side = 1440 * k;
        final centre = Offset(box.maxWidth / 2, head + room / 2);
        final stage = Rect.fromLTWH(
          centre.dx - _roomCenter.dx * k,
          centre.dy - _roomCenter.dy * k,
          side,
          side,
        );
        final kitchen = widget.mode == HomeMode.kitchen;
        // Circles sit in the screen's corners, clear of the room.
        Widget circle(
          bool top,
          bool start,
          String key,
          IconData icon,
          String label,
          AppTab tab,
        ) => PositionedDirectional(
          start: start ? 10 : null,
          end: start ? null : 10,
          top: top ? head : head + room - 78,
          width: 80,
          child: _CornerCircle(
            id: key,
            icon: icon,
            label: label,
            dark: true,
            visible: kitchen,
            onTap: () => nav.goTab(tab),
          ),
        );
        final glowAt = Alignment(
          stage.center.dx / box.maxWidth * 2 - 1,
          stage.center.dy / box.maxHeight * 2 - 1,
        );
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: glowAt,
              radius: side * .8 / box.maxWidth.clamp(1, box.maxHeight),
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
                      Offset(box.maxWidth / 2, head + room * .2) -
                          stage.topLeft,
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
                true,
                true,
                'circle-profile',
                Icons.person_outline_rounded,
                'بروفايلي',
                AppTab.profile,
              ),
              circle(
                true,
                false,
                'circle-settings',
                Icons.settings_outlined,
                'الإعدادات',
                AppTab.settings,
              ),
              circle(
                false,
                false,
                'circle-community',
                Icons.diversity_3_outlined,
                'مجتمع سفرة',
                AppTab.community,
              ),
              circle(
                false,
                true,
                'circle-style',
                Icons.format_paint_outlined,
                'شكل المطبخ',
                AppTab.style,
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
              RecipeBook(open: widget.mode == HomeMode.recipes, top: head),
            ],
          ),
        );
      },
    );
  }

  /// The diorama, its outer walls and floor fading out into the page so no
  /// cut edge shows.
  Widget _stage() {
    final s = loaded;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (s != null && roomMask != null)
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => ImageShader(
              roomMask!,
              TileMode.clamp,
              TileMode.clamp,
              (Matrix4.translationValues(rect.left, rect.top, 0)
                    ..scaleByDouble(rect.width / 512, rect.height / 512, 1, 1))
                  .storage,
            ),
            child: KitchenScene(
              scene: s,
              controller: scene,
              schedule: schedule,
              ambience: widget.mode == HomeMode.kitchen,
              onHotspotTap: _onHotspot,
              onDoorOpened: (_) => _openZone(StorageZone.fridge),
              shouldOpenDoor: (door) =>
                  widget.mode == HomeMode.kitchen &&
                  !(door == 'fridge' && _readyMotion != null),
            ),
          )
        else if (sceneError != null || !widget.showScene)
          // No render to tap: the stock page is still one tap away.
          Center(
            child: IconButton.filledTonal(
              key: const ValueKey('open-stock'),
              iconSize: 48,
              tooltip: 'خزين مطبخي',
              onPressed: () => SofraScope.navOf(context).goTab(AppTab.kitchen),
              icon: const Icon(Icons.kitchen_outlined),
            ),
          ),
      ],
    );
  }
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

class _PlansSheet extends StatelessWidget {
  const _PlansSheet();
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final meals = c
        .upcoming(DateTime.now())
        .where((m) => !m.completed)
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .55,
      maxChildSize: .9,
      builder: (context, scroll) => ListView(
        key: const ValueKey('plans-sheet'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الأكلات الجاية',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                key: const ValueKey('plans-open-table'),
                onPressed: () {
                  Navigator.pop(context);
                  nav.goTab(AppTab.table);
                },
                child: const Text('كل الخطط'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            const Text(
              'مفيش أكلات متخططة. اختار من كتاب الوصفات.',
              style: TextStyle(color: Sofra.muted),
            )
          else
            for (final m in meals)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlannedMealCard(m, compact: true),
              ),
        ],
      ),
    );
  }
}
