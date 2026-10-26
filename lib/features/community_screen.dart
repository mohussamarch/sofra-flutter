import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/community_backend.dart';
import '../domain/community.dart';
import '../domain/market_profile.dart';
import '../ui/design.dart';
import 'common.dart';

enum _Part { kitchen, recipes, prices, challenge }

/// "مجتمع سفرة": the household's shared kitchen, recipes from other homes,
/// prices people paid nearby and the weekly challenge. Needs an account.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var part = _Part.kitchen;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    if (c.community == null) {
      return const ScreenBody(
        children: [
          SizedBox(height: 8),
          Surface(
            child: Column(
              children: [
                Icon(Icons.diversity_3_outlined, size: 44, color: Sofra.green),
                SizedBox(height: 12),
                Text(
                  'مجتمع سفرة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'المطبخ المشترك والمجتمع محتاجين حساب. النسخة دي محفوظة على الجهاز بس.',
                  key: ValueKey('community-needs-account'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Sofra.muted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ScreenBody(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (p, label) in const [
              (_Part.kitchen, 'مطبخ البيت'),
              (_Part.recipes, 'وصفات البيوت'),
              (_Part.prices, 'أسعار منطقتي'),
              (_Part.challenge, 'تحدي الأسبوع'),
            ])
              ChoiceChip(
                key: ValueKey('community-${p.name}'),
                label: Text(label),
                selected: part == p,
                onSelected: (_) => setState(() => part = p),
              ),
          ],
        ),
        const SizedBox(height: 16),
        switch (part) {
          _Part.kitchen => const _SharedKitchen(),
          _Part.recipes => const _Recipes(),
          _Part.prices => const _Prices(),
          _Part.challenge => const _Challenge(),
        },
      ],
    );
  }
}

String _problem(Object e) =>
    e is InviteProblem ? e.message : 'حصلت مشكلة في الاتصال. جرب تاني.';

// ---- Shared kitchen --------------------------------------------------------

class _SharedKitchen extends StatefulWidget {
  const _SharedKitchen();
  @override
  State<_SharedKitchen> createState() => _SharedKitchenState();
}

class _SharedKitchenState extends State<_SharedKitchen> {
  Future<SharedKitchen?>? current;
  final code = TextEditingController();
  String? invite, error;
  var busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    current ??= _load();
  }

  Future<SharedKitchen?> _load() async {
    final community = SofraScope.controllerOf(context).community!;
    final id = await community.membership();
    return id == null ? null : community.kitchen(id);
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      error = _problem(e);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return FutureBuilder<SharedKitchen?>(
      future: current,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingBlock();
        }
        if (snap.hasError) {
          return ErrorBlock('معرفناش نفتح بيانات المطبخ. جرب تاني.');
        }
        final k = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (k == null) ...[
              const Surface(
                child: Text(
                  'خلّي البيت كله على مطبخ واحد: نفس الخزين، ونفس الخطة، ونفس قائمة الشراء. اللي في مطبخك دلوقتي هو اللي هيتشارك.',
                ),
              ),
              const SizedBox(height: 12),
              DepthButton(
                key: const ValueKey('kitchen-share'),
                label: 'اعمل مطبخ مشترك',
                onPressed: busy ? null : () => _run(() => c.shareKitchen()),
              ),
              const SizedBox(height: 20),
              const SectionTitle('عندك كود دعوة؟'),
              TextField(
                key: const ValueKey('kitchen-code'),
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'مثلاً: K7PM2QXA'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('kitchen-join'),
                onPressed: busy
                    ? null
                    : () => _run(() => c.joinKitchen(code.text)),
                child: const Text('ادخل المطبخ'),
              ),
              const SizedBox(height: 6),
              const Text(
                'لما تدخل مطبخ مشترك، مطبخك الشخصي بيفضل محفوظ وترجعله لما تخرج.',
                style: TextStyle(color: Sofra.muted, fontSize: 12),
              ),
            ] else ...[
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المطبخ المشترك',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final m in k.members)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(k.nameOf(m)),
                        subtitle: m == k.owner
                            ? const Text('صاحب المطبخ')
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (invite != null)
                Surface(
                  child: Column(
                    children: [
                      const Text('ابعت الكود ده لأهل البيت (صالح أسبوع):'),
                      SelectableText(
                        invite!,
                        key: const ValueKey('kitchen-invite-code'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              DepthButton(
                key: const ValueKey('kitchen-invite'),
                label: 'اعمل كود دعوة',
                onPressed: busy
                    ? null
                    : () => _run(() async {
                        final v = await c.community!.createInvite(k.id);
                        if (mounted) setState(() => invite = v);
                      }),
              ),
              TextButton(
                key: const ValueKey('kitchen-leave'),
                onPressed: busy ? null : () => _run(() => c.leaveKitchen(k.id)),
                child: const Text('ارجع لمطبخي الشخصي'),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  key: const ValueKey('kitchen-error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---- Recipes from other homes ---------------------------------------------

class _Recipes extends StatefulWidget {
  const _Recipes();
  @override
  State<_Recipes> createState() => _RecipesState();
}

class _RecipesState extends State<_Recipes> {
  Future<List<SharedRecipe>>? list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    list ??= SofraScope.controllerOf(context).community!.recentRecipes();
  }

  void _refresh() => setState(() {
    list = SofraScope.controllerOf(context).community!.recentRecipes();
  });

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final mine = c.myRecipes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.isNotEmpty) ...[
          const SectionTitle('شارك وصفة من وصفاتك'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in mine)
                ActionChip(
                  key: ValueKey('share-recipe-${r.recipe.id}'),
                  avatar: const Icon(Icons.ios_share, size: 18),
                  label: Text(r.recipe.name),
                  onPressed: () async {
                    final nav = SofraScope.navOf(context);
                    try {
                      await c.shareMyRecipe(r);
                      nav.notify('اتشاركت ${r.recipe.name}');
                      _refresh();
                    } catch (_) {
                      nav.notify('معرفناش نشاركها. جرب تاني.');
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FutureBuilder<List<SharedRecipe>>(
          future: list,
          builder: (context, snap) {
            if (snap.hasError) {
              return const ErrorBlock('معرفناش نجيب الوصفات. جرب تاني.');
            }
            final items = snap.data;
            if (items == null) return const LoadingBlock();
            if (items.isEmpty) {
              return const Surface(
                child: Text(
                  'لسه محدش شارك وصفة. ابدأ انت بوصفة من «وصفة من عندي».',
                  key: ValueKey('community-recipes-empty'),
                ),
              );
            }
            return Column(
              children: [for (final r in items) _RecipeCard(recipe: r)],
            );
          },
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final SharedRecipe recipe;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Surface(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: ValueKey('community-recipe-${recipe.id}'),
        // Photos slot: shows the first photo once uploads are switched on.
        leading: const Icon(Icons.restaurant_menu, color: Sofra.green),
        title: Text(recipe.title),
        subtitle: Text(
          '${recipe.authorName} · ${recipe.servings} أفراد${recipe.cuisine == null ? '' : ' · ${recipe.cuisine}'}',
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: _RecipeSheet(
              recipe: recipe,
              controller: SofraScope.controllerOf(context),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecipeSheet extends StatefulWidget {
  const _RecipeSheet({required this.recipe, required this.controller});
  final SharedRecipe recipe;
  final SofraController controller;
  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  late Future<List<Rating>> ratings = widget.controller.community!.ratings(
    widget.recipe.id,
  );
  final comment = TextEditingController();
  var stars = 0;

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        children: [
          Text(
            r.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            'من ${r.authorName} · ${r.servings} أفراد',
            style: const TextStyle(color: Sofra.muted),
          ),
          const SectionTitle('المكونات'),
          for (final l in r.lines)
            Text(
              l.amount == null
                  ? '• ${l.name}'
                  : '• ${l.name}: ${formatAmount(l.amount!)} ${l.unit}',
            ),
          const SectionTitle('الطريقة'),
          for (final (i, s) in r.steps.indexed) Text('${i + 1}. $s'),
          const SectionTitle('التقييمات'),
          FutureBuilder<List<Rating>>(
            future: ratings,
            builder: (context, snap) {
              final list = snap.data;
              if (list == null) return const LoadingBlock();
              final avg = averageStars(list);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avg == null
                        ? 'لسه محدش قيّمها.'
                        : '${avg.toStringAsFixed(1)} من 5 (${list.length})',
                    key: const ValueKey('community-rating-average'),
                  ),
                  for (final x in list)
                    if (x.comment.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${x.name} · ${'★' * x.stars}'),
                        subtitle: Text(x.comment),
                      ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var s = 1; s <= 5; s++)
                IconButton(
                  key: ValueKey('rate-$s'),
                  onPressed: () => setState(() => stars = s),
                  icon: Icon(
                    s <= stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Sofra.orange,
                  ),
                ),
            ],
          ),
          TextField(
            key: const ValueKey('rate-comment'),
            controller: comment,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'تعليقك (اختياري)'),
          ),
          FilledButton(
            key: const ValueKey('rate-save'),
            onPressed: stars == 0
                ? null
                : () async {
                    await widget.controller.rateRecipe(
                      r.id,
                      stars,
                      comment.text,
                    );
                    setState(() {
                      ratings = widget.controller.community!.ratings(r.id);
                    });
                  },
            child: const Text('احفظ تقييمي'),
          ),
        ],
      ),
    );
  }
}

// ---- Prices from people nearby --------------------------------------------

class _Prices extends StatefulWidget {
  const _Prices();
  @override
  State<_Prices> createState() => _PricesState();
}

class _PricesState extends State<_Prices> {
  late final area = TextEditingController(
    text: SofraScope.controllerOf(context).profile.area,
  );
  Future<Map<(String, String), AreaPrice>>? prices;
  final shared = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    prices ??= SofraScope.controllerOf(context).areaPrices();
  }

  @override
  void dispose() {
    area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final money = MarketProfile(c.market.country).currencyLabel;
    final hasArea = c.profile.area.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'منطقتك (المدينة أو الحي). بنعرض السعر بس لما بيتين أو أكتر يشاركوه.',
          style: TextStyle(color: Sofra.muted, fontSize: 12),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('price-area'),
                controller: area,
                decoration: const InputDecoration(hintText: 'مثلاً: مدينة نصر'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey('price-area-save'),
              onPressed: () async {
                await c.updateProfile(
                  (p) => p.copyWith(area: area.text.trim()),
                );
                setState(() {
                  prices = c.areaPrices();
                });
              },
              child: const Text('احفظ'),
            ),
          ],
        ),
        const SectionTitle('أسعار الناس في منطقتك'),
        if (!hasArea)
          const Text('اكتب منطقتك الأول.')
        else
          FutureBuilder<Map<(String, String), AreaPrice>>(
            future: prices,
            builder: (context, snap) {
              if (snap.hasError) {
                return const ErrorBlock('معرفناش نجيب الأسعار. جرب تاني.');
              }
              final map = snap.data;
              if (map == null) return const LoadingBlock();
              if (map.isEmpty) {
                return const Text(
                  'لسه مفيش أسعار كفاية في منطقتك.',
                  key: ValueKey('area-prices-empty'),
                );
              }
              return Column(
                children: [
                  for (final MapEntry(key: k, value: p) in map.entries)
                    ListTile(
                      key: ValueKey('area-price-${k.$1}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.ingredientName(k.$1)),
                      subtitle: Text(
                        '${formatAmount(p.medianPerUnit)} $money لكل ${k.$2} · من ${p.households} بيوت',
                      ),
                      trailing: TextButton(
                        key: ValueKey('area-price-use-${k.$1}'),
                        onPressed: () async {
                          await c.setUserPrice(
                            k.$1,
                            1,
                            k.$2,
                            p.medianPerUnit,
                            source: 'user-community',
                          );
                          if (context.mounted) {
                            SofraScope.navOf(context).notify('اتحفظ كسعرك');
                          }
                        },
                        child: const Text('استخدمه'),
                      ),
                    ),
                ],
              );
            },
          ),
        const SectionTitle('شارك أسعارك'),
        if (c.myPrices.isEmpty)
          const Text(
            'الأسعار اللي بتكتبها أو بتدفعها هتظهر هنا.',
            style: TextStyle(color: Sofra.muted),
          ),
        for (final p in c.myPrices)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(c.ingredientName(p.ingredientId)),
            subtitle: Text(
              '${formatAmount(p.amount)} $money لـ ${formatAmount(p.quantity)} ${p.unit}',
            ),
            trailing: shared.contains(p.ingredientId)
                ? const Icon(Icons.check, color: Sofra.green)
                : TextButton(
                    key: ValueKey('price-share-${p.ingredientId}'),
                    onPressed: !hasArea
                        ? null
                        : () async {
                            await c.sharePrice(p);
                            setState(() => shared.add(p.ingredientId));
                          },
                    child: const Text('شارك'),
                  ),
          ),
      ],
    );
  }
}

// ---- Weekly challenge -------------------------------------------------------

class _Challenge extends StatefulWidget {
  const _Challenge();
  @override
  State<_Challenge> createState() => _ChallengeState();
}

class _ChallengeState extends State<_Challenge> {
  final today = DateTime.now();
  Future<List<ChallengeEntry>>? board;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    board ??= SofraScope.controllerOf(context).community!
        .challengeEntries(weekKey(today));
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final ch = challengeFor(today);
    final progress = challengeProgress(ch, today, c.cookedMeals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ch.title,
                key: const ValueKey('challenge-title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(ch.detail, style: const TextStyle(color: Sofra.muted)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (progress / ch.goal).clamp(0, 1).toDouble(),
              ),
              const SizedBox(height: 6),
              Text(
                'إنت عملت $progress من ${ch.goal}',
                key: const ValueKey('challenge-progress'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DepthButton(
          key: const ValueKey('challenge-join'),
          label: 'سجّل تقدمي في اللوحة',
          onPressed: () async {
            await c.joinChallenge(today: today);
            setState(() {
              board = c.community!.challengeEntries(weekKey(today));
            });
          },
        ),
        const SectionTitle('البيوت المشاركة'),
        FutureBuilder<List<ChallengeEntry>>(
          future: board,
          builder: (context, snap) {
            if (snap.hasError) {
              return const ErrorBlock('معرفناش نجيب اللوحة. جرب تاني.');
            }
            final list = snap.data;
            if (list == null) return const LoadingBlock();
            if (list.isEmpty) return const Text('لسه محدش سجّل الأسبوع ده.');
            final sorted = [...list]
              ..sort((a, b) => b.progress.compareTo(a.progress));
            return Column(
              children: [
                for (final e in sorted)
                  ListTile(
                    key: ValueKey('challenge-entry-${e.uid}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      e.done ? Icons.emoji_events : Icons.timelapse,
                      color: e.done ? Sofra.orange : Sofra.muted,
                    ),
                    title: Text(e.name),
                    trailing: Text('${e.progress}/${e.goal}'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
