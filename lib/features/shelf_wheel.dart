import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../domain/ingredient_directory.dart';
import '../domain/kitchen_core.dart';
import '../domain/models.dart';
import '../domain/recipe_catalog.dart' show recipeNumber;
import '../ui/design.dart';
import '../ui/ingredient_art.dart';
import 'common.dart';
import 'kitchen_screen.dart';

/// One thing floating on a shelf: its art, name and amount underneath.
class ShelfItem {
  const ShelfItem({
    required this.id,
    required this.art,
    required this.label,
    required this.amount,
    this.onTap,
    this.group,
  });
  final String id;
  final Widget art;
  final String label, amount;
  final VoidCallback? onTap;

  /// Category the shelves can be narrowed to ("خضار", "ألبان", "بواقي").
  final String? group;
}

/// What a storage zone holds, three to a shelf; the fridge also keeps the
/// leftovers as covered dishes on their own shelves.
List<ShelfItem> zoneShelfItems(BuildContext context, StorageZone zone) {
  final c = SofraScope.controllerOf(context);
  return [
    for (final lot in c.stock.where((l) => l.zone == zone))
      ShelfItem(
        id: lot.ingredientId,
        art: _Glyph(
          ingredientGlyph(lot.ingredientId, c.category(lot.ingredientId)),
        ),
        label: c.ingredientName(lot.ingredientId),
        amount: lot.quantity == null
            ? 'كمية مش محددة'
            : c.amountText(lot.ingredientId, lot.quantity!, lot.unit),
        onTap: () => editStockQuantity(context, lot),
        group: c.category(lot.ingredientId) ?? 'أخرى',
      ),
    if (zone == StorageZone.fridge) ...leftoverShelfItems(context),
  ];
}

List<ShelfItem> leftoverShelfItems(BuildContext context) => [
  for (final (i, dish) in SofraScope.controllerOf(context).leftovers.indexed)
    ShelfItem(
      id: 'leftover-${dish.id}',
      art: CoveredDish(variant: i % 3),
      label: dish.name,
      amount: dish.dueOn(DateTime.now())
          ? '${recipeNumber(dish.servings)} حصة · جه معادها'
          : '${recipeNumber(dish.servings)} حصة',
      onTap: () => _warmUp(context, dish),
      group: 'بواقي',
    ),
];

/// How much of a leftover dish was warmed up and eaten.
Future<void> _warmUp(BuildContext context, LeftoverDish dish) async {
  final c = SofraScope.controllerOf(context);
  var eat = dish.servings < 1 ? dish.servings : 1.0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(
        builder: (ctx, set) {
          Widget step(String key, IconData icon, double by) => IconButton(
            key: ValueKey(key),
            icon: Icon(icon),
            onPressed: () =>
                set(() => eat = (eat + by).clamp(.5, dish.servings)),
          );
          return AlertDialog(
            title: Text(dish.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('سخّنت كام حصة؟'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    step('eat-less', Icons.remove_rounded, -.5),
                    Text(
                      '${recipeNumber(eat)} من ${recipeNumber(dish.servings)}',
                      key: const ValueKey('eat-servings'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    step('eat-more', Icons.add_rounded, .5),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لسه'),
              ),
              FilledButton(
                key: const ValueKey('eat-leftover'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('سخّنت وأكلت'),
              ),
            ],
          );
        },
      ),
    ),
  );
  if (ok == true) await c.eatLeftover(dish.id, eat);
}

/// Full-screen shelves for a place in the kitchen, over a dark backdrop.
Future<void> showShelves(
  BuildContext context, {
  required String title,
  required List<ShelfItem> Function(BuildContext) items,
  String empty = 'لسه فاضي.',
  VoidCallback? onAdd,
  VoidCallback? onAll,
  Color? barrier,
  double width = 1,
}) {
  final scope = SofraScope.of(context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: barrier ?? const Color(0xE60D0A08),
      transitionDuration: Sofra.motion(context),
      reverseTransitionDuration: Sofra.motion(context, true),
      pageBuilder: (_, _, _) => SofraScope(
        controller: scope.notifier!,
        nav: scope.nav,
        child: Builder(
          builder: (context) => ShelfWheel(
            title: title,
            items: items(context),
            empty: empty,
            onAdd: onAdd,
            onAll: onAll,
            width: width,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 1.04, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    ),
  );
}

/// Shelves on a wheel: scrolling turns them, and the ones leaving tip back
/// into the depth. Items hover a little above their shelf.
class ShelfWheel extends StatefulWidget {
  const ShelfWheel({
    super.key,
    required this.title,
    required this.items,
    required this.onClose,
    this.empty = 'لسه فاضي.',
    this.onAdd,
    this.onAll,
    this.width = 1,
  });
  final String title, empty;

  /// Share of the screen the shelves span (inside a fridge, its walls).
  final double width;
  final List<ShelfItem> items;
  final VoidCallback onClose;
  final VoidCallback? onAdd;

  /// Opens the whole stock page.
  final VoidCallback? onAll;

  @override
  State<ShelfWheel> createState() => _ShelfWheelState();
}

class _ShelfWheelState extends State<ShelfWheel>
    with SingleTickerProviderStateMixin {
  late final hover = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  final wheel = FixedExtentScrollController();
  static const _extent = 176.0;
  String query = '';
  String? group;
  bool searching = false;

  /// Shelves sorted by kind (one category per run) or by what went in last.
  bool byKind = true;

  List<ShelfItem> get _shown {
    final q = IngredientDirectory.normalizeArabic(query);
    final order = byKind
        ? ([...widget.items.indexed]..sort((a, b) {
                final g = (a.$2.group ?? '').compareTo(b.$2.group ?? '');
                return g != 0 ? g : a.$1.compareTo(b.$1);
              }))
              .map((e) => e.$2)
        : widget.items.reversed;
    return [
      for (final item in order)
        if ((group == null || item.group == group) &&
            (q.isEmpty ||
                IngredientDirectory.normalizeArabic(item.label).contains(q)))
          item,
    ];
  }

  void _filter(VoidCallback change) {
    setState(change);
    if (wheel.hasClients) wheel.jumpToItem(0);
  }

  /// Search field and category chips; only worth showing past one shelf.
  Widget _filters() {
    final groups = <String>{
      for (final item in widget.items)
        if (item.group != null) item.group!,
    }.toList();
    Widget chip(String key, String label, String? value) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: ChoiceChip(
        key: ValueKey(key),
        label: Text(label),
        selected: group == value,
        onSelected: (_) => _filter(() => group = value),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          if (searching)
            LiquidGlass(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                key: const ValueKey('shelves-query'),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'دوّر على حاجة',
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => _filter(() => query = v),
              ),
            ),
          if (groups.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 6),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ActionChip(
                      key: const ValueKey('shelves-order'),
                      avatar: const Icon(Icons.swap_vert_rounded, size: 18),
                      label: Text(byKind ? 'حسب النوع' : 'آخر ما وُضع'),
                      onPressed: () => _filter(() => byKind = !byKind),
                    ),
                  ),
                  chip('shelves-group-all', 'الكل', null),
                  for (final g in groups) chip('shelves-group-$g', g, g),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The wheel's viewport doesn't hit-test its children, so taps are placed
  /// here: the centred shelf opens the item under the finger (three columns,
  /// first on the right); a shelf above or below turns to the centre first.
  void _tap(TapUpDetails d, Size size, List<List<ShelfItem>> shelves) {
    final current = wheel.selectedItem.clamp(0, shelves.length - 1);
    final dy = d.localPosition.dy - size.height / 2;
    if (dy.abs() > _extent / 2) {
      wheel.animateToItem(
        (current + dy.sign.toInt()).clamp(0, shelves.length - 1),
        duration: Sofra.motion(context),
        curve: Sofra.calmCurve,
      );
      return;
    }
    final third = (size.width - 40) / 3;
    final fromStart = size.width - 20 - d.localPosition.dx;
    final column = (fromStart / third).floor();
    final shelf = shelves[current];
    if (column >= 0 && column < shelf.length) shelf[column].onTap?.call();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      hover.stop();
    } else if (!hover.isAnimating) {
      hover.repeat();
    }
  }

  @override
  void dispose() {
    hover.dispose();
    wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _shown;
    final filtered = items.length != widget.items.length;
    final shelves = [
      for (var i = 0; i < items.length; i += 3)
        items.sublist(i, math.min(i + 3, items.length)),
    ];
    final media = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top + 8,
            bottom: media.padding.bottom + 16,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LiquidGlass(
                  radius: 24,
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              countText(
                                widget.items.length,
                                'حاجة',
                                'حاجتين',
                                'حاجات',
                                empty: 'فاضي',
                              ),
                              style: const TextStyle(
                                color: Sofra.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.items.length > 3)
                        IconButton(
                          key: const ValueKey('shelves-search'),
                          tooltip: 'بحث',
                          onPressed: () => _filter(() {
                            searching = !searching;
                            if (!searching) query = '';
                          }),
                          icon: Icon(
                            searching
                                ? Icons.search_off_rounded
                                : Icons.search_rounded,
                          ),
                        ),
                      if (widget.onAdd != null)
                        IconButton(
                          key: const ValueKey('shelves-add'),
                          tooltip: 'إضافة',
                          onPressed: widget.onAdd,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      if (widget.onAll != null)
                        IconButton(
                          key: const ValueKey('shelves-all'),
                          tooltip: 'كل الخزين',
                          onPressed: widget.onAll,
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                      IconButton(
                        key: const ValueKey('shelves-close'),
                        tooltip: 'قفل',
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.items.length > 3) _filters(),
              Expanded(
                child: shelves.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: LiquidGlass(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              filtered
                                  ? 'مفيش حاجة بالاسم ده هنا.'
                                  : widget.empty,
                              key: const ValueKey('shelves-empty'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : FractionallySizedBox(
                        widthFactor: widget.width,
                        child: LayoutBuilder(
                          builder: (context, box) => GestureDetector(
                            onTapUp: (d) => _tap(d, box.biggest, shelves),
                            child: ListWheelScrollView(
                              key: const ValueKey('shelf-wheel'),
                              controller: wheel,
                              itemExtent: _extent,
                              diameterRatio: 1.6,
                              perspective: .003,
                              overAndUnderCenterOpacity: .35,
                              physics: const FixedExtentScrollPhysics(),
                              children: [
                                for (final (i, shelf) in shelves.indexed)
                                  _Shelf(items: shelf, hover: hover, row: i),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.items, required this.hover, required this.row});
  final List<ShelfItem> items;
  final Animation<double> hover;
  final int row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: AnimatedBuilder(
                  animation: hover,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      math.sin(
                            (hover.value + (row * 3 + i) * .23) * 2 * math.pi,
                          ) *
                          4,
                    ),
                    child: child,
                  ),
                  child: _Floating(item),
                ),
              ),
            for (var i = items.length; i < 3; i++) const Spacer(),
          ],
        ),
        const SizedBox(height: 6),
        const _GlassShelf(),
      ],
    ),
  );
}

class _Floating extends StatelessWidget {
  const _Floating(this.item);
  final ShelfItem item;

  @override
  Widget build(BuildContext context) => Semantics(
    button: item.onTap != null,
    onTap: item.onTap,
    label: '${item.label}، ${item.amount}',
    child: KeyedSubtree(
      key: ValueKey('shelf-item-${item.id}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 58, child: Center(child: item.art)),
          // Contact shadow: the item hovers, its shadow stays on the shelf.
          Container(
            width: 34,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .85),
              borderRadius: BorderRadius.circular(Sofra.r12),
            ),
            child: Text(
              item.amount,
              key: ValueKey('shelf-amount-${item.id}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Sofra.ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A glass shelf seen slightly from above: a lit top face and a thin edge.
class _GlassShelf extends StatelessWidget {
  const _GlassShelf();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 16,
    width: double.infinity,
    child: CustomPaint(painter: _GlassShelfPainter()),
  );
}

class _GlassShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final top = Path()
      ..moveTo(14, 0)
      ..lineTo(size.width - 14, 0)
      ..lineTo(size.width, 9)
      ..lineTo(0, 9)
      ..close();
    canvas.drawPath(
      top,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .18),
            Colors.white.withValues(alpha: .42),
            Colors.white.withValues(alpha: .18),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 9, size.width, 5),
      Paint()..color = const Color(0xFFBFD8D2).withValues(alpha: .55),
    );
    canvas.drawLine(
      Offset(14, .5),
      Offset(size.width - 14, .5),
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_GlassShelfPainter old) => false;
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.glyph);
  final String glyph;
  @override
  Widget build(BuildContext context) => Text(
    glyph,
    textScaler: TextScaler.noScaling,
    style: const TextStyle(fontSize: 44, height: 1),
  );
}

/// A closed dish of leftovers: a lidded box, a glass-lidded bowl or a small
/// pot, so a shelf of them is told apart at a glance.
class CoveredDish extends StatelessWidget {
  const CoveredDish({super.key, this.variant = 0});
  final int variant;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 52,
    child: CustomPaint(painter: _CoveredDishPainter(variant % 3)),
  );
}

class _CoveredDishPainter extends CustomPainter {
  _CoveredDishPainter(this.variant);
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFFF4EEE3);
    final edge = Paint()
      ..color = const Color(0xFF8A7A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final lid = Paint()
      ..color = switch (variant) {
        0 => Sofra.orange,
        1 => const Color(0xFFBFD8D2).withValues(alpha: .85),
        _ => const Color(0xFF5E6B63),
      };
    switch (variant) {
      case 0: // Lidded box.
        final box = RRect.fromLTRBR(
          6,
          h * .38,
          w - 6,
          h - 4,
          const Radius.circular(7),
        );
        canvas.drawRRect(box, body);
        canvas.drawRRect(box, edge);
        final cover = RRect.fromLTRBR(
          3,
          h * .26,
          w - 3,
          h * .42,
          const Radius.circular(5),
        );
        canvas.drawRRect(cover, lid);
        canvas.drawRRect(
          RRect.fromLTRBR(
            w / 2 - 8,
            h * .18,
            w / 2 + 8,
            h * .28,
            const Radius.circular(3),
          ),
          lid,
        );
      case 1: // Bowl under a glass dome.
        final bowl = Path()
          ..moveTo(6, h * .62)
          ..quadraticBezierTo(w / 2, h + 6, w - 6, h * .62)
          ..close();
        canvas.drawPath(bowl, body);
        canvas.drawPath(bowl, edge);
        final dome = Rect.fromLTRB(8, h * .12, w - 8, h * 1.1);
        canvas.drawArc(dome, math.pi, math.pi, true, lid);
        canvas.drawArc(dome, math.pi, math.pi, false, edge);
        canvas.drawCircle(
          Offset(w / 2, h * .12),
          3.5,
          edge..style = PaintingStyle.fill,
        );
      default: // Small pot.
        final pot = RRect.fromLTRBR(
          9,
          h * .4,
          w - 9,
          h - 4,
          const Radius.circular(8),
        );
        canvas.drawRRect(pot, lid);
        canvas.drawRect(Rect.fromLTWH(2, h * .5, 8, 4), lid);
        canvas.drawRect(Rect.fromLTWH(w - 10, h * .5, 8, 4), lid);
        final cover = Rect.fromLTRB(7, h * .26, w - 7, h * .5);
        canvas.drawArc(
          cover,
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF7C8A82),
        );
        canvas.drawCircle(
          Offset(w / 2, h * .24),
          3.5,
          Paint()..color = const Color(0xFF3F4A44),
        );
    }
  }

  @override
  bool shouldRepaint(_CoveredDishPainter old) => old.variant != variant;
}
