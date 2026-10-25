import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../ui/design.dart';
import '../ui/illustrations.dart';
import 'common.dart';

/// Card for one catalog index row (no full recipe load needed).
class RecipeCard extends StatelessWidget {
  const RecipeCard(this.row, {super.key, this.small = false});
  final Map<String, dynamic> row;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final nav = SofraScope.navOf(context);
    final id = row['id'] as String;
    final saved = c.profile.saved.contains(id);
    final kind = artKind(id);
    if (Paper.isOn(context)) return _PaperEntry(row: row, saved: saved);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: ValueKey('recipe-$id'),
        onTap: () => nav.openRecipe(id),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!small)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  color: kind.isEven ? const Color(0xFFF0EDD8) : Sofra.mint,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SoftTag(
                          '${row['category'] ?? ''}',
                          color: Colors.white,
                          ink: Sofra.ink,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: saved ? 'إلغاء الحفظ' : 'حفظ الوصفة',
                          onPressed: () => c.updateProfile(
                            (p) => p.copyWith(
                              saved: saved
                                  ? ({...p.saved}..remove(id))
                                  : {...p.saved, id},
                            ),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
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
                  Text(
                    '${row['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SoftTag(
                        '${row['cuisine']}',
                        color: Sofra.cream,
                        ink: Sofra.muted,
                        icon: Icons.public_rounded,
                      ),
                      SoftTag(
                        minutesLabel(row['totalTime']),
                        color: Sofra.cream,
                        ink: Sofra.muted,
                        icon: Icons.schedule_rounded,
                      ),
                      if (row['difficulty'] != null)
                        SoftTag(
                          '${row['difficulty']}',
                          color: Sofra.cream,
                          ink: Sofra.muted,
                        ),
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
    final details = [
      '${row['cuisine']}',
      minutesLabel(row['totalTime']),
      if (row['difficulty'] != null) '${row['difficulty']}',
    ].join(' · ');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
      side: const BorderSide(color: Paper.ink, width: 2),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        child: Material(
          color: Colors.white,
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
                          ? const Color(0xFFFFE7B8)
                          : const Color(0xFFDDEFD9),
                      shape: BoxShape.circle,
                      border: Border.all(color: Paper.ink, width: 2),
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
                        Text(
                          '${row['name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Paper.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 13,
                            color: Paper.ink.withValues(alpha: .65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: saved ? 'إلغاء الحفظ' : 'حفظ الوصفة',
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
                      color: saved ? const Color(0xFFD9534F) : Paper.ink,
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
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  static const _filters = ['الكل', 'من الموجود', 'سريعة', 'محفوظة'];
  static const _page = 20;
  final search = TextEditingController();
  String filter = 'الكل';
  String? group;
  int limit = _page;
  Future<List<Map<String, dynamic>>>? results;
  Future<Set<String>>? fromStock;
  Future<List<Map<String, dynamic>>>? _viewResults;
  String? _viewFilter;

  /// Cached so rebuilds do not restart the search and flash a spinner.
  Future<List<Object>> get _view {
    if (_viewResults != results || _viewFilter != filter) {
      _viewResults = results;
      _viewFilter = filter;
      _viewFuture = Future.wait<Object>([
        results!,
        if (filter == 'من الموجود') fromStock!,
      ]);
    }
    return _viewFuture!;
  }

  Future<List<Object>>? _viewFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    results ??= _query();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _query() =>
      SofraScope.controllerOf(context).recipes
          .search(query: search.text.trim(), cuisineGroup: group);

  void _refresh() => setState(() {
    limit = _page;
    results = _query();
  });

  /// IDs of recipes with at least two non-optional ingredients in stock.
  Future<Set<String>> _fromStock(SofraController c) async {
    final have = {for (final l in c.stock) l.ingredientId};
    final all = await c.recipes.loadAll();
    return {
      for (final r in all)
        if (r.ingredients
                .where((i) => !i.optional && have.contains(c.stockId(i.id)))
                .length >=
            2)
          r.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    if (filter == 'من الموجود') fromStock ??= _fromStock(c);
    return ScreenBody(
      children: [
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('recipe-search'),
          controller: search,
          onChanged: (_) => _refresh(),
          decoration: const InputDecoration(
            hintText: 'نفسك في أكلة إيه؟',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
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
                  ChoiceChip(
                    label: const Text('كل المطابخ'),
                    selected: group == null,
                    onSelected: (_) {
                      group = null;
                      _refresh();
                    },
                  ),
                  for (final g in groups)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: ChoiceChip(
                        label: Text('${g['name']} · ${g['count']}'),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _filters)
              ChoiceChip(
                label: Text(f),
                selected: filter == f,
                selectedColor: Sofra.mint,
                onSelected: (_) => setState(() {
                  filter = f;
                  limit = _page;
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<Object>>(
          future: _view,
          builder: (context, snap) {
            if (snap.hasError) {
              return const ErrorBlock('تعذّر تحميل الوصفات. جرّب تاني.');
            }
            final data = snap.data;
            if (data == null) return const LoadingBlock();
            var rows = (data.first as List<Map<String, dynamic>>).where((r) {
              final id = r['id'] as String;
              return switch (filter) {
                'من الموجود' => (data.last as Set<String>).contains(id),
                'سريعة' =>
                  r['totalTime'] is num && (r['totalTime'] as num) <= 30,
                'محفوظة' => c.profile.saved.contains(id),
                _ => true,
              };
            }).toList();
            if (c.profile.quickMeals) {
              rows.sort(
                (a, b) => ((a['totalTime'] as num?) ?? 1e9).compareTo(
                  (b['totalTime'] as num?) ?? 1e9,
                ),
              );
            }
            final shown = rows.take(limit).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'وصفات على ذوقك',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Text(
                      '${rows.length} وصفة',
                      style: const TextStyle(color: Sofra.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Surface(
                    child: Column(
                      children: [
                        const ChefArt(size: 170, compact: true),
                        const Text(
                          'ندوّر على حاجة تانية؟',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DepthButton(
                          secondary: true,
                          label: 'عرض كل الوصفات',
                          onPressed: () {
                            search.clear();
                            filter = 'الكل';
                            group = null;
                            _refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                for (final r in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RecipeCard(r),
                  ),
                if (rows.length > shown.length)
                  DepthButton(
                    secondary: true,
                    label:
                        'اعرض ${rows.length - shown.length > _page ? _page : rows.length - shown.length} كمان',
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
