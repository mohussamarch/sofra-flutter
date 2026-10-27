import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/community_backend.dart';
import '../domain/community.dart';
import '../domain/market_profile.dart';
import '../ui/design.dart';
import 'common.dart';

enum _Part { home, kitchen, prices, challenge }

/// "مجتمع سفرة", laid out like a video feed without video: category chips,
/// a row of day-long text stories, circles of Arab cooking channels, then
/// recipes from other homes as large cards.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var part = _Part.home;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return ScreenBody(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (p, label) in const [
                (_Part.home, 'الرئيسية'),
                (_Part.kitchen, 'مطبخ البيت'),
                (_Part.prices, 'أسعار منطقتي'),
                (_Part.challenge, 'تحدي الأسبوع'),
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: SofraChip(
                    key: ValueKey('community-${p.name}'),
                    label: Text(label),
                    selected: part == p,
                    showCheckmark: false,
                    selectedColor: Sofra.ink,
                    labelStyle: TextStyle(
                      color: part == p ? Colors.white : Sofra.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => part = p),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (c.communityPreview)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'معاينة على الجهاز: ما تنشره هنا لا يصل لأحد، ويُحذف عند الإغلاق.',
              key: ValueKey('community-preview'),
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ),
        if (c.community == null && part != _Part.home)
          const _NeedsAccount()
        else
          switch (part) {
            _Part.home => const _Home(),
            _Part.kitchen =>
              c.communityPreview
                  ? const _NeedsAccount()
                  : const _SharedKitchen(),
            _Part.prices => const _Prices(),
            _Part.challenge => const _Challenge(),
          },
      ],
    );
  }
}

class _NeedsAccount extends StatelessWidget {
  const _NeedsAccount();
  @override
  Widget build(BuildContext context) => const Surface(
    child: Text(
      'هذا الجزء يحتاج إلى حساب. هذه النسخة محفوظة على الجهاز فقط.',
      key: ValueKey('community-needs-account'),
      textAlign: TextAlign.center,
      style: TextStyle(color: Sofra.muted),
    ),
  );
}

String _problem(Object e) =>
    e is InviteProblem ? e.message : 'حدثت مشكلة في الاتصال. حاول مرة أخرى.';

/// Story and avatar colours (index stored with each story).
const storyColors = [
  Color(0xFF2E6B4F),
  Color(0xFFE07A2F),
  Color(0xFF8C3B5E),
  Color(0xFF2F5D8C),
  Color(0xFFB8860B),
  Color(0xFF6B4E9B),
  Color(0xFF3F7F7F),
  Color(0xFFA23B2A),
];

Color _colorFor(String key) =>
    storyColors[key.codeUnits.fold(0, (a, b) => a + b) % storyColors.length];

String _initial(String name) {
  final t = name.trim();
  return t.isEmpty ? '؟' : String.fromCharCode(t.runes.first);
}

/// A round avatar drawn from a name (no profile photos are stored).
class _Avatar extends StatelessWidget {
  const _Avatar(this.name, {this.size = 40, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: color ?? _colorFor(name),
    child: Text(
      _initial(name),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * .42,
      ),
    ),
  );
}

// ---- Home: stories, creators, feed ---------------------------------------

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  Future<List<Story>>? stories;
  Future<List<SharedRecipe>>? feed;
  Future<List<Creator>>? creators;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = SofraScope.controllerOf(context);
    creators ??= c.creators();
    if (c.community != null) {
      stories ??= c.community!.liveStories();
      feed ??= c.community!.recentRecipes();
    }
  }

  void _reload() {
    final c = SofraScope.controllerOf(context);
    setState(() {
      stories = c.community!.liveStories();
      feed = c.community!.recentRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.community != null) ...[
          SizedBox(
            height: 124,
            child: FutureBuilder<List<Story>>(
              future: stories,
              builder: (context, snap) {
                final rings = storyRings(snap.data ?? const [], DateTime.now());
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Ring(
                      key: const ValueKey('story-add'),
                      label: 'قصتك',
                      add: true,
                      name: c.profile.displayName,
                      onTap: () async {
                        final posted = await _composeStory(context, c);
                        if (posted) _reload();
                      },
                    ),
                    for (final (i, ring) in rings.indexed)
                      _Ring(
                        key: ValueKey('story-ring-${ring.first.uid}'),
                        label: ring.first.name,
                        name: ring.first.name,
                        color: storyColors[ring.last.colorIndex],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                _StoryViewer(rings: rings, start: i),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 20),
        ],
        const Text(
          'شيفات على يوتيوب',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 124,
          child: FutureBuilder<List<Creator>>(
            future: creators,
            builder: (context, snap) => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cr in snap.data ?? const <Creator>[])
                  _Ring(
                    key: ValueKey('creator-${cr.id}'),
                    label: cr.short,
                    name: cr.name,
                    color: _colorFor(cr.id),
                    onTap: () => _openCreator(context, cr),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
        if (c.community == null)
          const _NeedsAccount()
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'من بيوت سفرة',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (c.myRecipes.isNotEmpty)
                TextButton.icon(
                  key: const ValueKey('share-recipe-open'),
                  onPressed: () async {
                    final shared = await _pickToShare(context, c);
                    if (shared) _reload();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('شارك وصفة'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<List<SharedRecipe>>(
            future: feed,
            builder: (context, snap) {
              if (snap.hasError) {
                return const ErrorBlock('تعذّر جلب الوصفات. حاول مرة أخرى.');
              }
              final items = snap.data;
              if (items == null) return const LoadingBlock();
              if (items.isEmpty) {
                return const Surface(
                  child: Text(
                    'لم يشارك أحد وصفة بعد. ابدأ أنت من «وصفة من عندي».',
                    key: ValueKey('community-recipes-empty'),
                  ),
                );
              }
              return Column(
                children: [for (final r in items) _FeedCard(recipe: r)],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// A circle with a label under it: a story ring or a creator.
class _Ring extends StatelessWidget {
  const _Ring({
    super.key,
    required this.label,
    required this.name,
    required this.onTap,
    this.color,
    this.add = false,
  });
  final String label, name;
  final VoidCallback onTap;
  final Color? color;
  final bool add;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(40),
    onTap: onTap,
    child: SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: add ? Sofra.muted.withValues(alpha: .4) : Sofra.orange,
                width: 2.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(name, size: 58, color: color),
                if (add)
                  const PositionedDirectional(
                    end: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Sofra.green,
                      child: Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.6),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

Future<void> _openCreator(BuildContext context, Creator cr) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(cr.name, size: 72, color: _colorFor(cr.id)),
              const SizedBox(height: 10),
              Text(
                cr.name,
                key: const ValueKey('creator-name'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (cr.country != null)
                Text(cr.country!, style: const TextStyle(color: Sofra.muted)),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('creator-open'),
                onPressed: () => launchUrl(
                  Uri.parse(cr.channelUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('افتح القناة على يوتيوب'),
              ),
            ],
          ),
        ),
      ),
    );

Future<bool> _pickToShare(BuildContext context, SofraController c) async {
  final pick = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'شارك وصفة من وصفاتك',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          for (final (i, r) in c.myRecipes.indexed)
            ListTile(
              key: ValueKey('share-recipe-${r.recipe.id}'),
              leading: const Icon(Icons.ios_share),
              title: Text(r.recipe.name),
              onTap: () => Navigator.pop(context, i),
            ),
        ],
      ),
    ),
  );
  if (pick == null || !context.mounted) return false;
  final nav = SofraScope.navOf(context);
  final r = c.myRecipes[pick];
  try {
    await c.shareMyRecipe(r);
    nav.notify('شُوركت ${r.recipe.name}');
    return true;
  } catch (_) {
    nav.notify('تعذّرت المشاركة. حاول مرة أخرى.');
    return false;
  }
}

/// A recipe from another home as a large card (photo area kept for when
/// photos are switched on).
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.recipe});
  final SharedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final color = _colorFor(recipe.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        key: ValueKey('community-recipe-${recipe.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: _RecipeSheet(recipe: recipe, controller: c),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [color, color.withValues(alpha: .7)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          recipe.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${recipe.lines.length} مكون · ${recipe.steps.length} خطوات',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(recipe.authorName, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      FutureBuilder<List<Rating>>(
                        future: c.community!.ratings(recipe.id),
                        builder: (context, snap) {
                          final avg = averageStars(snap.data ?? const []);
                          return Text(
                            [
                              recipe.authorName,
                              if (recipe.cuisine != null) recipe.cuisine!,
                              '${recipe.servings} أفراد',
                              if (avg != null)
                                '★ ${avg.toStringAsFixed(1)} (${snap.data!.length})',
                            ].join(' · '),
                            style: const TextStyle(
                              color: Sofra.muted,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Stories ----------------------------------------------------------------

Future<bool> _composeStory(BuildContext context, SofraController c) async {
  final posted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _StoryComposer(controller: c),
    ),
  );
  return posted == true;
}

class _StoryComposer extends StatefulWidget {
  const _StoryComposer({required this.controller});
  final SofraController controller;
  @override
  State<_StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<_StoryComposer> {
  final text = TextEditingController();
  final dish = TextEditingController();
  var color = 0;
  var busy = false;

  @override
  void dispose() {
    text.dispose();
    dish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 140,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: storyColors[color],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text.text.isEmpty ? 'ماذا طبخت اليوم؟' : text.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < storyColors.length; i++)
              GestureDetector(
                key: ValueKey('story-color-$i'),
                onTap: () => setState(() => color = i),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: storyColors[i],
                  child: i == color
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('story-text'),
          controller: text,
          maxLength: 200,
          maxLines: 3,
          minLines: 1,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'اكتب قصتك'),
        ),
        TextField(
          key: const ValueKey('story-dish'),
          controller: dish,
          maxLength: 80,
          decoration: const InputDecoration(hintText: 'اسم الأكلة (اختياري)'),
        ),
        const SizedBox(height: 6),
        DepthButton(
          key: const ValueKey('story-post'),
          label: 'انشر لمدة يوم',
          onPressed: busy || text.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await widget.controller.postStory(
                      text.text,
                      dish: dish.text,
                      colorIndex: color,
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
      ],
    ),
  );
}

/// Full-screen stories: tap to go on, each lasts a few seconds.
class _StoryViewer extends StatefulWidget {
  const _StoryViewer({required this.rings, required this.start});
  final List<List<Story>> rings;
  final int start;
  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer>
    with SingleTickerProviderStateMixin {
  late int ring = widget.start;
  var index = 0;
  late final timer =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _next();
        });

  @override
  void initState() {
    super.initState();
    timer.forward();
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  void _next() {
    final stories = widget.rings[ring];
    if (index + 1 < stories.length) {
      setState(() => index++);
    } else if (ring + 1 < widget.rings.length) {
      setState(() {
        ring++;
        index = 0;
      });
    } else {
      Navigator.of(context).maybePop();
      return;
    }
    timer.forward(from: 0);
  }

  void _previous() {
    if (index > 0) {
      setState(() => index--);
    } else if (ring > 0) {
      setState(() {
        ring--;
        index = 0;
      });
    }
    timer.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.rings[ring];
    final s = stories[index];
    final ago = DateTime.now().difference(s.createdAt);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: storyColors[s.colorIndex],
        body: SafeArea(
          child: GestureDetector(
            key: const ValueKey('story-viewer'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final w = MediaQuery.sizeOf(context).width;
              // Right-to-left: the left side goes forward.
              d.localPosition.dx < w / 2 ? _next() : _previous();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < stories.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedBuilder(
                              animation: timer,
                              builder: (_, _) => LinearProgressIndicator(
                                value: i < index
                                    ? 1
                                    : i == index
                                    ? timer.value
                                    : 0,
                                color: Colors.white,
                                backgroundColor: Colors.white30,
                                minHeight: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Avatar(s.name, size: 36, color: Colors.white24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.name} · ${ago.inHours > 0 ? 'من ${ago.inHours} ساعة' : 'الآن'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('story-close'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.dish != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.dish!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          Text(
                            s.text,
                            key: const ValueKey('story-text-shown'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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
          return ErrorBlock('تعذّر فتح بيانات المطبخ. حاول مرة أخرى.');
        }
        final k = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (k == null) ...[
              const Surface(
                child: Text(
                  'اجمع البيت كله على مطبخ واحد: المخزون نفسه، والخطة نفسها، وقائمة الشراء نفسها. ما في مطبخك الآن هو ما ستتم مشاركته.',
                ),
              ),
              const SizedBox(height: 12),
              DepthButton(
                key: const ValueKey('kitchen-share'),
                label: 'أنشئ مطبخًا مشتركًا',
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
                'عند دخولك مطبخًا مشتركًا، يبقى مطبخك الشخصي محفوظًا وتعود إليه عند الخروج.',
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
                      const Text(
                        'أرسل هذا الرمز لأهل البيت (صالح لمدة أسبوع):',
                      ),
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
                label: 'أنشئ رمز دعوة',
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
                child: const Text('العودة إلى مطبخي الشخصي'),
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
                        ? 'لم يقيّمها أحد بعد.'
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
          'منطقتك (المدينة أو الحي). نعرض السعر فقط عندما يشاركه بيتان أو أكثر.',
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
          const Text('اكتب منطقتك أولًا.')
        else
          FutureBuilder<Map<(String, String), AreaPrice>>(
            future: prices,
            builder: (context, snap) {
              if (snap.hasError) {
                return const ErrorBlock('تعذّر جلب الأسعار. حاول مرة أخرى.');
              }
              final map = snap.data;
              if (map == null) return const LoadingBlock();
              if (map.isEmpty) {
                return const Text(
                  'لا توجد أسعار كافية في منطقتك بعد.',
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
                            SofraScope.navOf(context).notify('حُفظ كسعرك');
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
            'تظهر هنا الأسعار التي تكتبها أو تدفعها.',
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
                'أنجزت $progress من ${ch.goal}',
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
              return const ErrorBlock('تعذّر جلب اللوحة. حاول مرة أخرى.');
            }
            final list = snap.data;
            if (list == null) return const LoadingBlock();
            if (list.isEmpty) {
              return const Text('لم يسجّل أحد هذا الأسبوع بعد.');
            }
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
