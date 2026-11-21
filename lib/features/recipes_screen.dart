import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/recipe_stock_preview.dart';
import '../data/recipe_repository.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';
import 'dish_name_view.dart';
import 'dish_sheet.dart';
import 'my_recipe_screen.dart';

/// Card for one catalog index row (no full recipe load needed).
class RecipeCard extends StatelessWidget {
  const RecipeCard(this.row, {super.key, this.small = false, this.dish});
  final Map<String, dynamic> row;
  final bool small;

  /// A dish made in several countries: the card carries the dish's name and
  /// a countries badge, and opens the dish with its ingredients compared.
  final (String, List<Map<String, dynamic>>)? dish;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final id = row['id'] as String;
    final saved = c.profile.saved.contains(id);
    final kind = artKind(id);
    final t = context.l10n;
    // A name several countries share carries its country by the name.
    final tagged = dish == null && DishName.of(id)?.country != null;
    if (Paper.isOn(context)) return _PaperEntry(row: row, saved: saved);
    return Material(
      color: Sofra.card,
      borderRadius: BorderRadius.circular(Sofra.r22),
      child: InkWell(
        key: ValueKey(dish == null ? 'recipe-$id' : 'dish-$id'),
        onTap: () => nav.openRecipe(id, compare: dish != null),
        borderRadius: BorderRadius.circular(Sofra.r22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!small)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  // One neutral backdrop for every dish at night, so the
                  // food keeps the colour.
                  color: Sofra.isDark
                      ? Sofra.inverse
                      : kind.isEven
                      ? const Color(0xFFF0EDD8)
                      : Sofra.mint,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Sofra.r22),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SoftTag(
                          L10n.term('${row['category'] ?? ''}'),
                          color: Sofra.card,
                          ink: Sofra.ink,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: saved ? t.rcpUnsaveRecipe : t.rcpSaveRecipe,
                          onPressed: () => c.updateProfile(
                            (p) => p.copyWith(
                              saved: saved
                                  ? ({...p.saved}..remove(id))
                                  : {...p.saved, id},
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Sofra.card,
                          ),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: Sofra.greenDark,
                          ),
                        ),
                      ],
                    ),
                    MealArt(kind: kind, size: 170),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dish case (final name, _))
                    Text(name, style: _cardTitle)
                  else
                    DishTitle(
                      L10n.pick('${row['name']}', row['nameEn'] as String?),
                      recipeId: id,
                      style: _cardTitle,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (dish == null && !tagged)
                              SoftTag(
                                L10n.term('${row['cuisine']}'),
                                color: Sofra.sand,
                                ink: Sofra.muted,
                                icon: Icons.public_rounded,
                              ),
                            SoftTag(
                              dish == null
                                  ? minutesLabel(row['totalTime'])
                                  : dishTime(dish!.$2),
                              color: Sofra.sand,
                              ink: Sofra.muted,
                              icon: Icons.schedule_rounded,
                            ),
                            if (row['difficulty'] != null && dish == null)
                              SoftTag(
                                L10n.term('${row['difficulty']}'),
                                color: Sofra.sand,
                                ink: Sofra.muted,
                              ),
                          ],
                        ),
                      ),
                      if (dish case (_, final ways)) CountriesBadge(ways),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _cardTitle = TextStyle(fontWeight: FontWeight.w800, fontSize: 20);

/// A recipe inside the cartoon book: a white card with the book's outline,
/// the dish drawing in an outlined circle, the name and one line of details.
class _PaperEntry extends StatelessWidget {
  const _PaperEntry({required this.row, required this.saved});
  final Map<String, dynamic> row;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final id = row['id'] as String;
    final t = context.l10n;
    final details = [
      if (DishName.of(id)?.country == null) L10n.term('${row['cuisine']}'),
      minutesLabel(row['totalTime']),
      // "Not stated by the source" is noise on a list row; say nothing.
      if (row['difficulty'] != null &&
          !'${row['difficulty']}'.startsWith('غير محدد')) // i18n-data
        L10n.term('${row['difficulty']}'),
    ].join(' · ');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
      side: BorderSide(color: Paper.ink.withValues(alpha: .12)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        child: Material(
          color: Sofra.surface,
          shape: shape,
          child: InkWell(
            key: ValueKey('recipe-$id'),
            customBorder: shape,
            onTap: () => nav.openRecipe(id),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 4, 10),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: artKind(id).isEven
                          ? Sofra.accentTint
                          : Sofra.okTint,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: MealArt(kind: artKind(id), size: 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DishTitle(
                          L10n.pick('${row['name']}', row['nameEn'] as String?),
                          recipeId: id,
                          style: Sofra.heading(18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: TextStyle(fontSize: 13, color: Sofra.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? t.rcpUnsaveRecipe : t.rcpSaveRecipe,
                    onPressed: () => c.updateProfile(
                      (p) => p.copyWith(
                        saved: saved
                            ? ({...p.saved}..remove(id))
                            : {...p.saved, id},
                      ),
                    ),
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? Sofra.accent : Sofra.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key, this.initialFilter = 'الكل'}); // i18n-data
  final String initialFilter;
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  /// Filter ids (also used by the home shell); shown through [_filterLabel].
  static const _filters = [
    'الكل', // i18n-data
    'من الموجود', // i18n-data
    'جاهزة بالموجود', // i18n-data
    'محفوظة', // i18n-data
  ];

  static String _filterLabel(AppLocalizations t, String id) => switch (id) {
    'من الموجود' => t.rcpFilterFromStock, // i18n-data
    'جاهزة بالموجود' => t.rcpFilterReadyFromStock, // i18n-data
    'محفوظة' => t.rcpFilterSaved, // i18n-data
    _ => t.rcpFilterAll,
  };

  static const _page = 20;
  final search = TextEditingController();
  late String filter = widget.initialFilter;
  String? group;

  /// Meal kind ([RecipeRepository.kinds]) and longest time, from the filters.
  String? kind;
  int? maxMinutes;
  int get _filterCount => (kind == null ? 0 : 1) + (maxMinutes == null ? 0 : 1);
  Future<List<Dish>>? dishes;
  int limit = _page;
  Future<List<Map<String, dynamic>>>? results;
  Future<Map<String, RecipeStockPreview>>? fromStock;
  Future<Map<String, RecipeStockPreview>>? _viewStock;
  int? _stockVersion;
  bool get stockFilter =>
      filter == 'من الموجود' || filter == 'جاهزة بالموجود'; // i18n-data
  Future<List<Map<String, dynamic>>>? _viewResults;
  String? _viewFilter;

  /// Cached so rebuilds do not restart the search and flash a spinner.
  Future<List<Object>> get _view {
    if (_viewResults != results ||
        _viewFilter != filter ||
        _viewStock != fromStock) {
      _viewResults = results;
      _viewFilter = filter;
      _viewStock = fromStock;
      _viewFuture = Future.wait<Object>([
        results!,
        dishes!,
        if (stockFilter) fromStock!,
      ]);
    }
    return _viewFuture!;
  }

  Future<List<Object>>? _viewFuture;
  int? _catalog;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    results ??= _query();
    dishes ??= SofraScope.controllerOf(context).recipes.dishes;
    _catalog ??= SofraScope.controllerOf(context).recipes.catalogGeneration;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _query() =>
      SofraScope.controllerOf(context).recipes.search(
        query: search.text.trim(),
        cuisineGroup: group,
        kind: kind,
        maxMinutes: maxMinutes,
      );

  /// Meal kind and time: the filters that do not fit on one line.
  Future<void> _openFilters() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final t = sheet.l10n;
        void pick(VoidCallback change) {
          setSheet(change);
          _refresh();
        }

        Widget section(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(t.rcpKindSection, [
                SofraChip(
                  label: Text(t.rcpFilterAll),
                  selected: kind == null,
                  onSelected: (_) => pick(() => kind = null),
                ),
                for (final k in RecipeRepository.kinds)
                  SofraChip(
                    key: ValueKey('filter-kind-$k'),
                    label: Text(L10n.term(k)),
                    selected: kind == k,
                    onSelected: (_) => pick(() => kind = k),
                  ),
              ]),
              section(t.rcpTimeSection, [
                for (final (label, value) in [
                  (t.rcpTimeAny, null),
                  (t.rcpTime30, 30),
                  (t.rcpTime60, 60),
                ])
                  SofraChip(
                    key: ValueKey('filter-time-$value'),
                    label: Text(label),
                    selected: maxMinutes == value,
                    onSelected: (_) => pick(() => maxMinutes = value),
                  ),
              ]),
              if (_filterCount > 0)
                TextButton(
                  onPressed: () => pick(() {
                    kind = null;
                    maxMinutes = null;
                  }),
                  child: Text(t.rcpClearFilters),
                ),
            ],
          ),
        );
      },
    ),
  );

  void _refresh() => setState(() {
    limit = _page;
    results = _query();
    _stockVersion = null;
  });

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    if (_catalog != c.recipes.catalogGeneration) {
      // A newer library arrived: list it without leaving the screen.
      _catalog = c.recipes.catalogGeneration;
      results = _query();
      dishes = c.recipes.dishes;
      _stockVersion = null;
    }
    if (stockFilter && _stockVersion != c.stockDiscoveryVersion) {
      _stockVersion = c.stockDiscoveryVersion;
      fromStock = c.stockRecipePreviews();
    }
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('recipe-search'),
          controller: search,
          onChanged: (_) => _refresh(),
          decoration: InputDecoration(
            hintText: t.rcpSearchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              key: const ValueKey('recipe-filters'),
              tooltip: t.rcpFilters,
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _filterCount > 0,
                label: Text('$_filterCount'),
                backgroundColor: Sofra.accent,
                child: Icon(
                  Icons.tune_rounded,
                  color: _filterCount > 0 ? Sofra.accent : Sofra.muted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const MyRecipesStrip(),
        const SizedBox(height: 10),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: c.recipes.cuisineGroups,
          builder: (context, snap) {
            final groups = [...?snap.data]
              ..sort(
                (a, b) =>
                    (c.profile.cuisines.contains(b['id']) ? 1 : 0) -
                    (c.profile.cuisines.contains(a['id']) ? 1 : 0),
              );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SofraChip(
                    label: Text(t.rcpAllCuisines),
                    selected: group == null,
                    onSelected: (_) {
                      group = null;
                      _refresh();
                    },
                  ),
                  for (final g in groups)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: SofraChip(
                        label: Text(
                          '${L10n.term('${g['name']}')} · ${g['count']}',
                        ),
                        selected: group == g['id'],
                        onSelected: (_) {
                          group = g['id'] as String;
                          _refresh();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: SofraChip(
                    label: Text(_filterLabel(t, f)),
                    selected: filter == f,
                    onSelected: (_) => setState(() {
                      filter = f;
                      limit = _page;
                    }),
                  ),
                ),
            ],
          ),
        ),
        if (stockFilter)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              t.rcpStockNote('${c.profile.servings}'),
              style: TextStyle(color: Sofra.muted),
            ),
          ),
        const SizedBox(height: 20),
        FutureBuilder<List<Object>>(
          future: _view,
          builder: (context, snap) {
            if (snap.hasError) {
              return Column(
                children: [
                  ErrorBlock(t.rcpLoadFailed),
                  TextButton(onPressed: _refresh, child: Text(t.rcpTryAgain)),
                ],
              );
            }
            final data = snap.data;
            if (data == null || snap.connectionState != ConnectionState.done) {
              return const LoadingBlock();
            }
            final dishList = data[1] as List<Dish>;
            final stock = stockFilter
                ? data.last as Map<String, RecipeStockPreview>
                : <String, RecipeStockPreview>{};
            var rows = (data.first as List<Map<String, dynamic>>).where((r) {
              final id = r['id'] as String;
              return switch (filter) {
                'من الموجود' => (stock[id]?.present ?? 0) > 0, // i18n-data
                'جاهزة بالموجود' => stock[id]?.ready ?? false, // i18n-data
                'محفوظة' => c.profile.saved.contains(id), // i18n-data
                // Saved recipes the library dropped list as saved only.
                _ => r['pinnedOnly'] != true,
              };
            }).toList();
            if (stockFilter || c.profile.quickMeals) {
              rows.sort((first, second) {
                if (stockFilter) {
                  final readiness = (stock[first['id']]?.rank ?? 2).compareTo(
                    stock[second['id']]?.rank ?? 2,
                  );
                  if (readiness != 0) return readiness;
                  final available = (stock[second['id']]?.available ?? 0)
                      .compareTo(stock[first['id']]?.available ?? 0);
                  if (available != 0) return available;
                }
                return ((first['totalTime'] as num?) ?? 1e9).compareTo(
                  (second['totalTime'] as num?) ?? 1e9,
                );
              });
            }
            // A dish made several ways shows once, where its first way falls,
            // unless one cuisine or the stock view is chosen.
            final dishOf = <String, Dish>{
              if (!stockFilter && group == null)
                for (final d in dishList)
                  for (final id in d.recipes) id: d,
            };
            final byId = {for (final r in rows) r['id'] as String: r};
            final entries = <Object>[];
            final placed = <String>{};
            for (final r in rows) {
              final d = dishOf[r['id']];
              final ways = [
                for (final id in d?.recipes ?? const <String>[]) ?byId[id],
              ];
              if (d == null || ways.length < 2) {
                entries.add(r);
              } else if (placed.add(d.id)) {
                entries.add((d, ways));
              }
            }
            final shown = entries.take(limit).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stockFilter ? t.rcpFromStockTitle : t.rcpForYouTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      t.rcpRecipeCount(rows.length),
                      style: TextStyle(color: Sofra.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Surface(
                    child: Column(
                      children: [
                        const ChefArt(size: 170, compact: true),
                        Text(
                          t.rcpEmptyTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DepthButton(
                          secondary: true,
                          label: t.rcpShowAll,
                          onPressed: () {
                            search.clear();
                            filter = 'الكل'; // i18n-data
                            group = null;
                            kind = null;
                            maxMinutes = null;
                            _refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                for (final e in shown)
                  if (e case (
                    final Dish d,
                    final List<Map<String, dynamic>> ways,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RecipeCard(
                        ways.first,
                        dish: (L10n.pick(d.name, d.nameEn), ways),
                      ),
                    )
                  else if (e case final Map<String, dynamic> r)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stockFilter)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                stock[r['id']]!.label,
                                key: ValueKey('stock-readiness-${r['id']}'),
                                style: TextStyle(
                                  color: stock[r['id']]!.ready
                                      ? Sofra.green
                                      : Sofra.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          RecipeCard(r),
                        ],
                      ),
                    ),
                if (entries.length > shown.length)
                  DepthButton(
                    secondary: true,
                    label: t.rcpShowMore(
                      '${entries.length - shown.length > _page ? _page : entries.length - shown.length}',
                    ),
                    onPressed: () => setState(() => limit += _page),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
