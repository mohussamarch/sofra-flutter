import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../domain/community.dart';
import '../domain/ingredient_directory.dart';
import '../domain/market_profile.dart';
import '../domain/places.dart';
import '../ui/design.dart';
import 'common.dart';

/// «أسعار منطقتي»: a map to choose the area (a tap, a search or the phone's
/// position), then food groups; an open group lists its items with two
/// columns at the far left: what people in the chosen area paid, and the
/// user's own price. An area price shows only when two homes or more shared
/// one in the last 60 days; nothing is estimated.
class AreaPricesView extends StatefulWidget {
  const AreaPricesView({super.key});

  /// Off in widget tests: no map tiles from the network and no location
  /// prompt.
  static bool live = true;

  @override
  State<AreaPricesView> createState() => _AreaPricesViewState();
}

/// Food groups in shelf order: the vocabulary category, its name here and
/// its picture.
const priceGroups = [
  ('خضار', 'خضار', 'carrot'),
  ('فاكهة', 'فاكهة', 'red_apple'),
  ('بروتين', 'لحوم ودواجن وأسماك', 'poultry_leg'),
  ('ألبان', 'ألبان وبيض', 'glass_of_milk'),
  ('حبوب', 'أرز وحبوب', 'sheaf_of_rice'),
  ('بقوليات', 'بقوليات', 'beans'),
  ('مخبوزات', 'خبز ومخبوزات', 'bread'),
  ('زيوت', 'زيوت وسمن', 'olive'),
  ('توابل', 'توابل وبهارات', 'salt'),
  ('صوصات', 'صوصات ومعلبات', 'jar'),
  ('مكسرات', 'مكسرات', 'peanuts'),
  ('مشروبات', 'مشروبات', 'beverage_box'),
  ('أخرى', 'أخرى', 'basket'),
];

class _AreaPricesViewState extends State<AreaPricesView> {
  final search = TextEditingController();
  final map = MapController();
  final open = <String>{};
  Places? places;
  String area = '';

  /// The place shown on the map. Kept as chosen, so two places with close
  /// labels never swap; the saved label is looked up only once, on opening.
  Place? place;

  /// Where the map opens when no area is chosen: the country's capital.
  LatLng fallback = const LatLng(27, 38);
  Future<Map<(String, String), AreaPrice>>? prices;
  List<Place> hits = const [];
  bool locating = false, started = false;
  String? note;

  /// Areas the user picked so far; an automatic lookup that finishes after
  /// a pick does not replace it.
  int picks = 0;

  /// The automatic position lookup runs at most once per app run.
  static bool _autoAsked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    final c = SofraScope.controllerOf(context);
    area = c.profile.area.trim();
    prices = _fetch(c);
    c.places().then((p) {
      if (!mounted) return;
      final capital = p.byLabel(
        c.market.country == MarketCountry.egypt ? 'القاهرة' : 'الرياض',
      );
      setState(() {
        places = p;
        place ??= p.byLabel(area);
        if (capital != null) fallback = LatLng(capital.lat, capital.lon);
      });
      // First visit with no area: ask for the position once per run.
      if (AreaPricesView.live && c.profile.area.trim().isEmpty && !_autoAsked) {
        _autoAsked = true;
        _locate(auto: true);
      }
    }, onError: (_) {});
  }

  /// The shown area's prices. A failure shows in the list, so it is not
  /// also reported as unhandled when it comes before the list listens.
  Future<Map<(String, String), AreaPrice>> _fetch(SofraController c) =>
      c.areaPrices(area: area)..ignore();

  @override
  void dispose() {
    search.dispose();
    map.dispose();
    super.dispose();
  }

  /// Finds the area at the phone's position. An [auto] lookup gives way to
  /// any area the user picks while it runs; the «موقعي» button always
  /// applies.
  Future<void> _locate({bool auto = false}) async {
    final before = picks;
    bool overtaken() => auto && picks != before;
    setState(() {
      locating = true;
      note = null;
    });
    String? problem;
    var applied = false;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        problem = 'خدمة الموقع مغلقة. اختر منطقتك من الخريطة أو البحث.';
      } else {
        var allowed = await Geolocator.checkPermission();
        if (allowed == LocationPermission.denied) {
          allowed = await Geolocator.requestPermission();
        }
        if (allowed == LocationPermission.denied ||
            allowed == LocationPermission.deniedForever) {
          problem = 'لم يُسمح بالموقع. اختر منطقتك من الخريطة أو البحث.';
        } else {
          final at = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 20),
            ),
          );
          final place = places?.nearest(at.latitude, at.longitude);
          if (place == null) {
            problem = 'لا نعرف منطقة قريبة من موقعك. اختر من الخريطة.';
          } else if (mounted && !overtaken()) {
            applied = true;
            _select(place);
          }
        }
      }
    } on Object {
      problem = 'تعذّر تحديد موقعك. اختر منطقتك من الخريطة أو البحث.';
    }
    if (mounted) {
      setState(() {
        locating = false;
        if (!applied && !overtaken()) note = problem;
      });
    }
  }

  /// Shows [place]'s prices. It becomes the user's own area (where their
  /// shared prices count) only when they have none yet.
  void _select(Place place) {
    final c = SofraScope.controllerOf(context);
    picks++;
    setState(() {
      this.place = place;
      area = place.label;
      prices = _fetch(c);
      hits = const [];
      search.clear();
      note = null;
    });
    FocusScope.of(context).unfocus();
    if (AreaPricesView.live) {
      try {
        map.move(LatLng(place.lat, place.lon), place.isCity ? 11 : 14);
      } on Object {
        // The map is not on screen yet; it opens on the area next time.
      }
    }
    if (c.profile.area.trim().isEmpty) _makeMine();
  }

  Future<void> _makeMine() async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    await c.updateProfile((p) => p.copyWith(area: area));
    if (mounted) setState(() {});
    nav.notify('منطقتك الآن: $area');
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final own = c.profile.area.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('price-area'),
          controller: search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث عن منطقة أو مدينة',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح',
                    onPressed: () => setState(() {
                      search.clear();
                      hits = const [];
                    }),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (v) =>
              setState(() => hits = places?.search(v) ?? const []),
          onSubmitted: (_) {
            if (hits.isNotEmpty) _select(hits.first);
          },
        ),
        if (hits.isEmpty && places != null && search.text.trim().isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(top: 6, start: 12),
            child: Text(
              'لا نتائج',
              key: ValueKey('price-area-none'),
              style: TextStyle(color: Sofra.muted, fontSize: 13),
            ),
          ),
        if (hits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Surface(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final p in hits)
                    ListTile(
                      key: ValueKey('place-${p.label}'),
                      dense: true,
                      leading: Icon(
                        p.isCity
                            ? Icons.location_city_rounded
                            : Icons.place_rounded,
                        color: Sofra.accent,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: p.city == null || p.city == p.name
                          ? null
                          : Text(p.city!),
                      onTap: () => _select(p),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        _map(context),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.place_rounded, color: Sofra.accent, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                area.isEmpty ? 'اختر منطقتك' : area,
                key: const ValueKey('price-area-shown'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (area.isNotEmpty && normalizePlace(area) != normalizePlace(own))
              TextButton(
                key: const ValueKey('price-area-save'),
                onPressed: _makeMine,
                child: const Text('اجعلها منطقتي'),
              ),
            Tooltip(
              message: 'سعر المنطقة هو ما دفعه الناس فيها في آخر 60 يومًا، ويظهر فقط عندما يشاركه بيتان أو أكثر.',
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 5),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Sofra.muted,
                ),
              ),
            ),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              note!,
              key: const ValueKey('price-locate-note'),
              style: TextStyle(color: Sofra.muted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        FutureBuilder<Map<(String, String), AreaPrice>>(
          future: prices,
          builder: (context, snap) {
            // Without the area's prices the user's own still show.
            final failed = snap.hasError;
            final found = failed
                ? const <(String, String), AreaPrice>{}
                : snap.data;
            if (found == null) return const LoadingBlock();
            return Column(
              children: [
                if (failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تعذّر جلب أسعار المنطقة.',
                            key: ValueKey('area-prices-failed'),
                            style: TextStyle(color: Sofra.muted, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('area-prices-retry'),
                          onPressed: () => setState(() {
                            prices = _fetch(c);
                          }),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                for (final g in priceGroups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _group(context, g, found),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _map(BuildContext context) {
    final p = place;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sofra.r22),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            Positioned.fill(
              child: !AreaPricesView.live || places == null
                  ? ColoredBox(color: Sofra.sand)
                  : FlutterMap(
                      key: const ValueKey('price-map'),
                      mapController: map,
                      options: MapOptions(
                        initialCenter: p == null
                            ? fallback
                            : LatLng(p.lat, p.lon),
                        initialZoom: p == null ? 10 : (p.isCity ? 11 : 14),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onTap: (_, at) {
                          final hit = places!.nearest(
                            at.latitude,
                            at.longitude,
                          );
                          if (hit != null) {
                            _select(hit);
                          } else {
                            SofraScope.navOf(context)
                                .notify('لا نعرف منطقة هنا. جرّب البحث.');
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mohussamarch.sofra',
                        ),
                        if (p != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(p.lat, p.lon),
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: Sofra.accent,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        const SimpleAttributionWidget(
                          source: Text('OpenStreetMap'),
                        ),
                      ],
                    ),
            ),
            PositionedDirectional(
              start: 10,
              top: 10,
              child: Material(
                color: Sofra.card,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  key: const ValueKey('price-locate'),
                  tooltip: 'موقعي',
                  onPressed: locating || places == null ? null : _locate,
                  icon: locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location_rounded, color: Sofra.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(
    BuildContext context,
    (String, String, String) g,
    Map<(String, String), AreaPrice> found,
  ) {
    final c = SofraScope.controllerOf(context);
    final (category, title, symbol) = g;
    final mine = {for (final p in c.myPrices) p.ingredientId: p};
    AreaPrice? areaFor(IngredientEntry e) {
      final exact = found[(e.id, e.defaultUnit)];
      if (exact != null) return exact;
      for (final MapEntry(key: k, value: v) in found.entries) {
        if (k.$1 == e.id) return v;
      }
      return null;
    }

    String? areaUnit(IngredientEntry e) {
      if (found.containsKey((e.id, e.defaultUnit))) return e.defaultUnit;
      for (final k in found.keys) {
        if (k.$1 == e.id) return k.$2;
      }
      return null;
    }

    final items = [
      for (final e in c.directory?.entries ?? const <IngredientEntry>[])
        if (e.category == category) e,
    ];
    int rank(IngredientEntry e) =>
        (areaFor(e) != null ? 0 : 2) + (mine.containsKey(e.id) ? 0 : 1);
    items.sort((a, b) {
      final r = rank(a) - rank(b);
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    final known = items.where((e) => areaFor(e) != null).length;
    final isOpen = open.contains(category);
    return Surface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            key: ValueKey('price-group-$category'),
            borderRadius: BorderRadius.circular(Sofra.r22),
            onTap: () => setState(
              () => isOpen ? open.remove(category) : open.add(category),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/symbols/$symbol.png',
                    width: 30,
                    height: 30,
                    errorBuilder: (_, _, _) => const SizedBox(width: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (known > 0)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SoftTag(
                          '$known بسعر المنطقة',
                          color: Sofra.mint,
                          ink: Sofra.greenDark,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: isOpen ? .5 : 0,
                    duration: Sofra.motion(context, true),
                    child: Icon(Icons.expand_more_rounded, color: Sofra.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Sofra.motion(context, true),
            curve: Sofra.quickCurve,
            alignment: Alignment.topCenter,
            child: !isOpen
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                    child: Column(
                      children: [
                        Divider(height: 1, color: Sofra.line),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(child: SizedBox()),
                              _Head('سعر المنطقة'),
                              SizedBox(width: 8),
                              _Head('سعرك'),
                            ],
                          ),
                        ),
                        for (final e in items)
                          _row(context, e, areaFor(e), areaUnit(e), mine[e.id]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    IngredientEntry e,
    AreaPrice? there,
    String? thereUnit,
    MarketPrice? mine,
  ) {
    final unit = mine?.unit ?? thereUnit ?? e.defaultUnit;
    final myValue = mine == null ? null : mine.amount / mine.quantity;
    return Container(
      key: ValueKey('price-row-${e.id}'),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Sofra.line, width: .6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              e.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _Cell(
            key: ValueKey('area-price-${e.id}'),
            value: there?.medianPerUnit,
            unit: thereUnit,
            semantic: there == null
                ? 'لا يوجد سعر للمنطقة'
                : 'سعر المنطقة، اضغط لتجعله سعرك',
            // Opens the price dialog filled with the area price; nothing is
            // saved until the user confirms.
            onTap: there == null
                ? null
                : () => _editPrice(context, e, thereUnit!, there.medianPerUnit),
          ),
          const SizedBox(width: 8),
          _Cell(
            key: ValueKey('my-price-${e.id}'),
            value: myValue,
            unit: unit,
            mine: true,
            semantic: myValue == null ? 'أضف سعرك' : 'سعرك، اضغط لتعديله',
            onTap: () => _editPrice(context, e, unit, myValue),
          ),
        ],
      ),
    );
  }

  Future<void> _editPrice(
    BuildContext context,
    IngredientEntry e,
    String unit,
    double? current,
  ) async {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final money = MarketProfile(c.market.country).currencyLabel;
    final own = c.profile.area.trim();
    final canShare = c.community != null && own.isNotEmpty;
    final result = await showDialog<(double, bool)>(
      context: context,
      builder: (_) => _PriceDialog(
        name: e.name,
        suffix: '$money / ${unitLabel(unit)}',
        current: current,
        shareTo: canShare ? own : null,
      ),
    );
    if (result == null) return;
    final (value, share) = result;
    if (!await c.setUserPrice(e.id, 1, unit, value)) {
      nav.notify('تعذّر حفظ السعر. حاول مرة أخرى.');
      return;
    }
    var shared = false;
    if (share) {
      try {
        await c.sharePrice(
          MarketPrice(
            country: c.market.country,
            ingredientId: e.id,
            unit: unit,
            quantity: 1,
            amount: value,
            recordedAt: DateTime.now(),
            source: 'user',
          ),
        );
        shared = true;
      } on Object {
        shared = false;
      }
    }
    if (mounted) {
      setState(() {
        // The area on screen now has this price too.
        if (shared && normalizePlace(area) == normalizePlace(own)) {
          prices = _fetch(c);
        }
      });
    }
    nav.notify(
      !share
          ? 'حُفظ سعرك'
          : shared
          ? 'حُفظ سعرك وشاركته مع منطقتك'
          : 'حُفظ سعرك، وتعذّرت مشاركته.',
    );
  }
}

/// The user's price for one item, and whether to share it with their area.
/// It owns its field, which outlives the call while the dialog animates away.
class _PriceDialog extends StatefulWidget {
  const _PriceDialog({
    required this.name,
    required this.suffix,
    required this.current,
    required this.shareTo,
  });
  final String name, suffix;
  final double? current;

  /// The user's own area, or null when sharing is not possible.
  final String? shareTo;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final field = TextEditingController(
    text: widget.current == null ? '' : priceText(widget.current!),
  );
  var share = false;
  var invalid = false;

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  void _save() {
    final v = parsePrice(field.text);
    if (v == null) {
      setState(() => invalid = true);
    } else {
      Navigator.of(context).pop((v, share));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.name),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('price-input'),
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: 'السعر',
            suffixText: widget.suffix,
            errorText: invalid ? 'اكتب سعرًا أكبر من صفر' : null,
          ),
        ),
        if (widget.shareTo != null)
          CheckboxListTile(
            key: const ValueKey('price-share'),
            contentPadding: EdgeInsets.zero,
            value: share,
            onChanged: (v) => setState(() => share = v ?? false),
            title: Text('شاركه مع ${widget.shareTo}'),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        key: const ValueKey('price-save'),
        onPressed: _save,
        child: const Text('حفظ'),
      ),
    ],
  );
}

/// A positive price from what the user typed; Arabic digits and the Arabic
/// decimal mark are accepted.
double? parsePrice(String text) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final latin = StringBuffer();
  for (final ch in text.trim().split('')) {
    final i = arabic.indexOf(ch);
    latin.write(
      i >= 0
          ? '$i'
          : ch == '٫' || ch == ','
          ? '.'
          : ch,
    );
  }
  final v = double.tryParse(latin.toString());
  return v == null || v <= 0 || v.isNaN || v.isInfinite ? null : v;
}

/// A price in Latin digits: a whole number plain, otherwise up to two
/// decimals without trailing zeros, never a fraction sign such as ½.
String priceText(double v) {
  final fixed = v.toStringAsFixed(2);
  if (!fixed.contains('.')) return fixed;
  final text = fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return text == '-0' ? '0' : text;
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Sofra.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// One price in a row: the number with its unit under it, or a dash (the
/// area) or a plus (the user's own) when there is none.
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.value,
    required this.unit,
    required this.semantic,
    required this.onTap,
    this.mine = false,
  });
  final double? value;
  final String? unit;
  final String semantic;
  final VoidCallback? onTap;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return Semantics(
      button: onTap != null,
      label: has ? '$semantic: ${priceText(value!)}' : semantic,
      excludeSemantics: true,
      child: SizedBox(
        width: 78,
        child: Material(
          color: mine
              ? (has ? Sofra.accentTint : Colors.transparent)
              : (has ? Sofra.mint : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sofra.r12),
            side: mine && !has
                ? BorderSide(color: Sofra.line)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Sofra.r12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: !has
                    ? Icon(
                        mine ? Icons.add_rounded : Icons.remove_rounded,
                        size: 18,
                        color: Sofra.muted,
                      )
                    // Large text shrinks the number to fit the cell rather
                    // than breaking it across lines.
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                priceText(value!),
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: mine ? Sofra.accent : Sofra.greenDark,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            if (unit != null)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '/ ${unitLabel(unit)}',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: Sofra.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
