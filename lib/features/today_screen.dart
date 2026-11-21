import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/kitchen_core.dart';
import '../domain/models.dart';
import '../l10n/l10n.dart';
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

/// The same pools in the dark look: the page dims around the lit room.
const _darkTones = {
  'morning': (Color(0xFF3A3128), Color(0xFF110D0A)),
  'golden': (Color(0xFF3E3024), Color(0xFF100B08)),
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
    // The room's light eases with the hour, like the page behind it.
    viewer.light(weights);
  }

  @override
  void dispose() {
    clock?.cancel();
    _arrive?.cancel();
    super.dispose();
  }

  /// The lighting weights mix the per-mode tones.
  (Color, Color) get _tone {
    final tones = Sofra.isDark ? _darkTones : _tones;
    Color mix(Color Function((Color, Color)) pick) {
      var r = .0, g = .0, b = .0, total = .0;
      for (final MapEntry(key: mode, value: w) in weights.entries) {
        final c = pick(tones[mode] ?? tones['morning']!);
        r += c.r * w;
        g += c.g * w;
        b += c.b * w;
        total += w;
      }
      if (total == 0) return pick(tones['morning']!);
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
      empty: context.l10n.planAddHereEmpty,
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
    if (_busy) return;
    _busy = true;
    try {
      await viewer.open(freezer: zone == StorageZone.freezer);
      // The camera turns to the door, then the door swings: wait for both
      // (with motion reduced the view just changes).
      await Future<void>.delayed(_turn(1400));
      if (!mounted) return;
      await _openZone(zone, overDoor: true);
      viewer.close();
    } finally {
      _busy = false;
    }
  }

  /// A camera move is under way with a sheet to follow: further taps on
  /// the room wait, so two sheets never stack over the wrong view.
  var _busy = false;

  Duration _turn(int ms) => MediaQuery.disableAnimationsOf(context)
      ? const Duration(milliseconds: 250)
      : Duration(milliseconds: ms);

  /// The microwave holds what can be warmed up again.
  Future<void> _openLeftovers() async {
    if (_busy) return;
    _busy = true;
    try {
      viewer.microwave();
      await Future<void>.delayed(_turn(1300));
      if (!mounted) return;
      await showShelves(
        context,
        title: context.l10n.planLeftovers,
        items: leftoverShelfItems,
        // A lighter veil: the open microwave stays visible behind.
        barrier: const Color(0x990D0A08),
        empty: context.l10n.planLeftoversEmpty,
      );
      if (mounted && widget.mode == HomeMode.kitchen) viewer.overview();
    } finally {
      _busy = false;
    }
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
        child: const _PlansSheet(),
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
    final ink = dark ? Sofra.onInverse : Sofra.ink;
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
                        look: SofraScope.controllerOf(context)
                            .profile
                            .kitchenLook,
                        vignette: true,
                        background: Colors.transparent,
                        foreground: ink,
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
                          tooltip: context.l10n.planMyStock,
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
    final t = context.l10n;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t.planGoodMorning
        : hour < 18
        ? t.planGoodDay
        : t.planGoodEvening;
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
            t.planKitchenStyle,
            AppTab.style,
          ),
          icon(
            'circle-settings',
            Icons.settings_outlined,
            t.planSettings,
            AppTab.settings,
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
    final t = context.l10n;
    String when(PlannedMeal m) {
      final day = m.date == today
          ? t.planToday
          : m.date == localDay(now.add(const Duration(days: 1)))
          ? t.planTomorrow
          : m.date;
      return t.planWhen(L10n.term(slotLabel(m.slot)), day);
    }

    final stock = DepthButton(
      key: const ValueKey('today-stock'),
      compact: true,
      secondary: true,
      icon: Icons.kitchen_outlined,
      label: t.planStock,
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
              label: Text(t.planLeftoversDue('${due.length}')),
              backgroundColor: Sofra.warnTint,
              onPressed: onLeftovers,
            ),
            const SizedBox(height: 8),
          ],
          if (next == null) ...[
            Text(t.planWhatToCookToday, style: Sofra.heading(20)),
            const SizedBox(height: 4),
            Text(
              t.planPickRecipeHint,
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
                    label: t.planPickRecipe,
                    onPressed: () => nav.goTab(AppTab.recipes),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: stock),
              ],
            ),
          ] else ...[
            Text(
              t.planNextOnTable(when(next)),
              style: TextStyle(color: Sofra.muted, fontSize: 13),
            ),
            FutureBuilder<String>(
              future: plannedMealTitle(c, next),
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
                    label: t.planStartCooking,
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
    final t = context.l10n;
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
                  Text(
                    t.planTableEmpty,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.planTableEmptyHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Sofra.muted),
                  ),
                  const SizedBox(height: 16),
                  DepthButton(
                    key: const ValueKey('table-open-book'),
                    compact: true,
                    icon: Icons.menu_book_outlined,
                    label: t.planRecipeBook,
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
          t.planOnTable(L10n.term(c.market.today)),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Sofra.onInverse,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 12)],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              key: const ValueKey('open-month-plan'),
              style: TextButton.styleFrom(foregroundColor: Sofra.onInverse),
              onPressed: () => openMonthPlan(context),
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: Text(t.planMonthTitle),
            ),
            TextButton.icon(
              key: const ValueKey('open-shopping'),
              style: TextButton.styleFrom(foregroundColor: Sofra.onInverse),
              onPressed: () => openShopping(context),
              icon: const Icon(Icons.shopping_basket_outlined, size: 20),
              label: Text(t.planShoppingList),
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
    final t = context.l10n;
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
              Expanded(
                child: Text(
                  t.planUpcomingMeals,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('plans-open-table'),
                onPressed: () {
                  Navigator.pop(context);
                  nav.goTab(AppTab.table);
                },
                child: Text(t.planAllPlans),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            Text(t.planNoMealsPlanned, style: TextStyle(color: Sofra.muted))
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
