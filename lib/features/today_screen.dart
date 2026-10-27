import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/kitchen_core.dart';
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
  'morning': (Color(0xFFFCF8F0), Color(0xFFE8DAC3)),
  'golden': (Color(0xFFF8E9D4), Color(0xFFD9BF9C)),
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
    // Opened straight on the table (after planning a meal): zoom in once the
    // model is up. The shot does nothing before that, so keep asking a while.
    if (widget.mode == HomeMode.table) {
      var tries = 0;
      _arrive = Timer.periodic(const Duration(milliseconds: 400), (t) {
        if (++tries > 12 || widget.mode != HomeMode.table) t.cancel();
        if (widget.mode == HomeMode.table) viewer.table();
      });
    }
  }

  Timer? _arrive;

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
    _arrive?.cancel();
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

  /// The lighting mode carrying the most weight now.
  String get _lighting =>
      weights.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  Future<void> _openZone(StorageZone zone, {bool overDoor = false}) {
    final nav = SofraScope.navOf(context);
    return showShelves(
      context,
      title: zoneName(zone),
      items: (context) => zoneShelfItems(context, zone),
      empty: 'أضف ما عندك هنا، وسنقترح ما تطبخه منه.',
      // Over an open fridge the room stays visible behind the shelves.
      barrier: overDoor ? const Color(0x990D0A08) : null,
      width: overDoor ? .72 : 1,
      // The fridge keeps its lit body still behind the turning shelves.
      interior: overDoor && zone == StorageZone.fridge
          ? fridgeInterior(_lighting)
          : null,
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
  Future<void> _openLeftovers() async {
    viewer.microwave();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await showShelves(
      context,
      title: 'بواقي الأكل',
      items: leftoverShelfItems,
      empty: 'لا توجد بواقٍ مسجّلة. عندما تطبخ ويتبقى شيء، ستجده هنا لتسخينه.',
    );
    if (mounted && widget.mode == HomeMode.kitchen) viewer.overview();
  }

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
    // Paper by day, the dark room at night: the ink follows the page.
    final dark = top.computeLuminance() < .25;
    final ink = dark ? Colors.white : Sofra.ink;
    final nav = SofraScope.navOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final head = media.padding.top + 48;
        final foot = media.padding.bottom + 112;
        final room = box.maxHeight - head - foot;
        final kitchen = widget.mode == HomeMode.kitchen;
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
                          tooltip: 'مخزون مطبخي',
                          onPressed: () => nav.goTab(AppTab.kitchen),
                          icon: const Icon(Icons.kitchen_outlined),
                        ),
                      ),
              ),
              Positioned(
                top: media.padding.top,
                left: 0,
                right: 0,
                height: 48,
                // Only over the room: the book and the table fill the top.
                child: IgnorePointer(
                  ignoring: !kitchen,
                  child: AnimatedOpacity(
                    opacity: kitchen ? 1 : 0,
                    duration: Sofra.motion(context, true),
                    child: _TopBar(ink: ink, dark: dark),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: foot - 8,
                child: IgnorePointer(
                  ignoring: !kitchen,
                  child: AnimatedSlide(
                    offset: kitchen ? Offset.zero : const Offset(0, .3),
                    duration: Sofra.motion(context),
                    curve: Sofra.calmCurve,
                    child: AnimatedOpacity(
                      opacity: kitchen ? 1 : 0,
                      duration: Sofra.motion(context, true),
                      child: _TodayCard(onLeftovers: _openLeftovers),
                    ),
                  ),
                ),
              ),
              if (widget.mode == HomeMode.table)
                Positioned(
                  left: 0,
                  right: 0,
                  top: media.padding.top + 8,
                  height: head - media.padding.top + room * .6,
                  child: _MealCards(night: (weights['night'] ?? 0) > .5),
                ),
              RecipeBook(open: widget.mode == HomeMode.recipes, top: head),
            ],
          ),
        );
      },
    );
  }
}

/// Greeting and the account's name on the start side; the kitchen's own
/// places (style, settings, profile) as quiet icons on the end side.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.ink, required this.dark});
  final Color ink;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
        ? 'نهارك سعيد'
        : 'مساء الخير';
    Widget icon(String key, IconData glyph, String tip, AppTab tab) => Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: PressScale(
        child: LiquidGlass(
          radius: 22,
          dark: dark,
          child: SizedBox.square(
            dimension: 44,
            child: IconButton(
              key: ValueKey(key),
              tooltip: tip,
              onPressed: () => nav.goTab(tab),
              icon: Icon(glyph, color: ink, size: 21),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            // Large system text shrinks to fit the bar instead of spilling.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: ink.withValues(alpha: .65),
                    ),
                  ),
                  Text(
                    c.profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Sofra.heading(19, color: ink),
                  ),
                ],
              ),
            ),
          ),
          icon(
            'circle-style',
            Icons.format_paint_outlined,
            'شكل المطبخ',
            AppTab.style,
          ),
          icon(
            'circle-settings',
            Icons.settings_outlined,
            'الإعدادات',
            AppTab.settings,
          ),
          icon(
            'circle-profile',
            Icons.person_outline_rounded,
            'بروفايلي',
            AppTab.profile,
          ),
        ],
      ),
    );
  }
}

/// What to do now, under the room: the next meal on the table with one
/// action (cook it), or, with nothing planned, a way to pick one. The stock
/// is always one tap away here, since the fridge alone is easy to miss.
class _TodayCard extends StatelessWidget {
  const _TodayCard({this.onLeftovers});

  /// Opens the leftovers, for the due reminder.
  final VoidCallback? onLeftovers;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final now = DateTime.now();
    final next = c.upcoming(now).where((m) => !m.completed).firstOrNull;
    final due = c.leftoversDue(now);
    final today = localDay(now);
    String when(PlannedMeal m) {
      final day = m.date == today
          ? 'اليوم'
          : m.date == localDay(now.add(const Duration(days: 1)))
          ? 'غدًا'
          : m.date;
      return '${slotLabel(m.slot)} · $day';
    }

    final stock = DepthButton(
      key: const ValueKey('today-stock'),
      compact: true,
      secondary: true,
      icon: Icons.kitchen_outlined,
      label: 'المخزون',
      onPressed: () => nav.goTab(AppTab.kitchen),
    );
    return Container(
      key: const ValueKey('today-card'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Sofra.surface,
        borderRadius: BorderRadius.circular(Sofra.r22),
        boxShadow: Sofra.shadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (due.isNotEmpty) ...[
            SofraChip(
              key: const ValueKey('leftovers-due'),
              avatar: const Icon(Icons.microwave_outlined, size: 16),
              label: Text('بواقٍ حان موعدها: ${due.length}'),
              backgroundColor: Sofra.warnTint,
              onPressed: onLeftovers,
            ),
            const SizedBox(height: 8),
          ],
          if (next == null) ...[
            Text('ماذا نطبخ اليوم؟', style: Sofra.heading(20)),
            const SizedBox(height: 4),
            const Text(
              'اختر وصفة، ونعرض لك الناقص من مطبخك قبل البدء.',
              style: TextStyle(color: Sofra.muted, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DepthButton(
                    key: const ValueKey('today-pick'),
                    compact: true,
                    icon: Icons.menu_book_outlined,
                    label: 'اختر وصفة',
                    onPressed: () => nav.goTab(AppTab.recipes),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: stock),
              ],
            ),
          ] else ...[
            Text(
              'التالي على السفرة · ${when(next)}',
              style: const TextStyle(color: Sofra.muted, fontSize: 13),
            ),
            FutureBuilder<String>(
              future: c.planTitle(next),
              builder: (context, snap) => Text(
                snap.data ?? '…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Sofra.heading(21),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DepthButton(
                    key: const ValueKey('today-cook'),
                    compact: true,
                    icon: Icons.soup_kitchen_outlined,
                    label: 'ابدأ الطبخ',
                    onPressed: () => nav.startCooking(next),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: stock),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The table's meals as liquid-glass cards standing over the table, swiped
/// side to side: the centred one faces you, its neighbours swing back like
/// the room's side walls. At night a soft LED pool lights them from above
/// once the camera has settled.
class _MealCards extends StatefulWidget {
  const _MealCards({required this.night});
  final bool night;
  @override
  State<_MealCards> createState() => _MealCardsState();
}

class _MealCardsState extends State<_MealCards> {
  final pages = PageController(viewportFraction: .66);
  bool settled = false;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // The LED comes on after the zoom (about the camera's travel time).
    _settle = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => settled = true);
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
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
                    'السفرة فارغة',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'افتح كتاب الوصفات واختر أكلة لتظهر هنا.',
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
        : [for (final m in meals) PlannedMealCard(m, glass: true)];
    final led = widget.night && settled;
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft LED pool hanging over the table: brightest just above
              // the cards, fading down onto the tabletop.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    key: const ValueKey('table-led'),
                    opacity: led ? 1 : 0,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -1.05),
                          radius: 1.1,
                          colors: [
                            Color(0x66FFE3B3),
                            Color(0x26FFD18A),
                            Color(0x00FFD18A),
                          ],
                          stops: [0, .45, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PageView.builder(
                controller: pages,
                // Mouse drags too, so the web preview swipes like a phone.
                scrollBehavior: ScrollConfiguration.of(context)
                    .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                itemCount: cards.length,
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: pages,
                  builder: (context, child) {
                    final page =
                        pages.hasClients && pages.position.haveDimensions
                        ? pages.page ?? 0
                        : 0.0;
                    // Which side of the screen the card sits on: +1 right.
                    final x = (rtl ? page - i : i - page).clamp(-1.0, 1.0);
                    final s = 1 - x.abs() * .08;
                    return Opacity(
                      opacity: 1 - x.abs() * .25,
                      child: Transform(
                        // Hinged on the inner edge, outer edge toward you.
                        alignment: Alignment(-x, 0),
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, .0016)
                          ..rotateY(x * .85)
                          ..scaleByDouble(s, s, 1, 1),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(child: cards[i]),
                    ),
                  ),
                ),
              ),
            ],
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
                  'الأكلات القادمة',
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
              'لا توجد أكلات مخططة. اختر من كتاب الوصفات.',
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
