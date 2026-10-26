import 'dart:async';

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/models.dart';
import '../scene/scene_lighting.dart';
import '../scene3d/kitchen_3d.dart';
import '../ui/design.dart';
import 'common.dart';
import 'month_plan_screen.dart';
import 'recipe_book.dart';
import 'shelf_wheel.dart';
import 'shopping_sheet.dart';
import 'table_screen.dart';

/// What the home kitchen is showing: the room, the recipe book floating over
/// it, or the camera at the dining table with the meals.
enum HomeMode { kitchen, recipes, table }

/// Page light per lighting mode: (glow behind the kitchen, dark edge). The
/// room sits in a pool of warm light and its edges sink into the dark.
const _tones = {
  'morning': (Color(0xFF4B3B2B), Color(0xFF110D0A)),
  'golden': (Color(0xFF573A28), Color(0xFF130C08)),
  'night': (Color(0xFF26323F), Color(0xFF07090D)),
};

/// Tappable places in the 3D kitchen, as boxes in Blender metres (z up),
/// measured on `kitchen-morning.blend`, with room in front for handles and
/// knobs (the floor is excluded by height). Upper zones first: the freezer sits
/// on the fridge.
const _zones = <(String, List<double>, List<double>)>[
  ('freezer', [2.68, 2.50, 1.38], [3.62, 3.64, 2.12]),
  ('fridge', [2.68, 2.50, 0.06], [3.62, 3.64, 1.38]),
  ('pantry', [-0.05, -0.05, 0.0], [0.72, 0.65, 2.12]),
  ('shelves', [-0.05, 3.20, 1.55], [0.65, 3.64, 2.38]),
  ('stove', [1.16, 2.50, 0.06], [2.14, 3.64, 0.95]),
  ('microwave', [0.0, 2.70, 0.88], [0.85, 3.64, 1.35]),
  ('table', [2.15, -0.25, 0.0], [3.85, 1.45, 1.2]),
];

String? _zoneAt(KitchenPoint p) {
  for (final (id, lo, hi) in _zones) {
    if (p.x >= lo[0] &&
        p.x <= hi[0] &&
        p.y >= lo[1] &&
        p.y <= hi[1] &&
        p.z >= lo[2] &&
        p.z <= hi[2]) {
      return id;
    }
  }
  return null;
}

/// The whole home: the kitchen as a real-time 3D room, the four corner
/// circles, the recipe book and the table, all on one stage so the room never
/// reloads between them.
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    this.mode = HomeMode.kitchen,
    this.showScene = true,
  });
  final HomeMode mode;

  /// Off in widget tests, where no WebView exists.
  final bool showScene;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final viewer = Kitchen3DController();
  Timer? clock;
  final schedule = LightingSchedule.provisional();
  Map<String, double> weights = const {'morning': 1};

  @override
  void initState() {
    super.initState();
    _tick();
    clock = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(TodayScreen old) {
    super.didUpdateWidget(old);
    if (old.mode == widget.mode) return;
    if (widget.mode == HomeMode.table) {
      viewer.table();
    } else {
      viewer.overview();
    }
  }

  void _tick() {
    if (!mounted) return;
    setState(() => weights = schedule.weightsAtTime(DateTime.now()));
  }

  @override
  void dispose() {
    clock?.cancel();
    super.dispose();
  }

  /// The lighting weights mix the per-mode tones.
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

  Future<void> _openZone(StorageZone zone, {bool overDoor = false}) {
    final nav = SofraScope.navOf(context);
    return showShelves(
      context,
      title: zoneName(zone),
      items: (context) => zoneShelfItems(context, zone),
      empty: 'ضيف اللي عندك هنا، وهنقولك تطبخ إيه منه.',
      // Over an open fridge the room stays visible behind the shelves.
      barrier: overDoor ? const Color(0x990D0A08) : null,
      width: overDoor ? .72 : 1,
      onAdd: () {
        Navigator.pop(context);
        nav.openAddStock();
      },
      onAll: () {
        Navigator.pop(context);
        nav.goTab(AppTab.kitchen);
      },
    );
  }

  /// The camera turns to the fridge (or freezer), the door swings open, the
  /// shelves come up; closing them shuts the door and returns to the room.
  Future<void> _openFridge(StorageZone zone) async {
    await viewer.open(freezer: zone == StorageZone.freezer);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _openZone(zone, overDoor: true);
    viewer.close();
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
      case 'fridge':
        _openFridge(StorageZone.fridge);
      case 'freezer':
        _openFridge(StorageZone.freezer);
      case 'pantry' || 'shelves':
        _openZone(StorageZone.pantry);
      case 'microwave':
        _openLeftovers();
      case 'table':
        SofraScope.navOf(context).goTab(AppTab.table);
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
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, (head + room / 2) / box.maxHeight * 2 - 1),
              radius: .75,
              colors: [top, bottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: head,
                bottom: foot,
                child: widget.showScene
                    ? Kitchen3D(
                        id: 'home-kitchen',
                        controller: viewer,
                        vignette: true,
                        zoom: false,
                        background: Colors.transparent,
                        onTap: (p) {
                          final zone = _zoneAt(p);
                          if (zone != null) _onHotspot(zone);
                        },
                      )
                    // No viewer (tests): the stock page is one tap away.
                    : Center(
                        child: IconButton.filledTonal(
                          key: const ValueKey('open-stock'),
                          iconSize: 48,
                          tooltip: 'خزين مطبخي',
                          onPressed: () => nav.goTab(AppTab.kitchen),
                          icon: const Icon(Icons.kitchen_outlined),
                        ),
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
                // The table view fills the top; the line steps aside.
                child: AnimatedOpacity(
                  opacity: widget.mode == HomeMode.table ? 0 : 1,
                  duration: Sofra.motion(context, false),
                  child: const _TopLine(ink: ink),
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
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('open-month-plan'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => openMonthPlan(context),
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: const Text('خطة الشهر'),
            ),
            TextButton.icon(
              key: const ValueKey('open-shopping'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => openShopping(context),
              icon: const Icon(Icons.shopping_basket_outlined, size: 20),
              label: const Text('قائمة الشراء'),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
