import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/scope.dart';
import '../app/sofra_controller.dart';
import '../data/community_backend.dart';
import '../domain/community.dart';
import '../l10n/l10n.dart';
import '../ui/design.dart';
import 'common.dart';
import 'community_prices.dart';

enum _Part { home, mine, prices }

/// Pages opened from cards on the home part.
enum _Sub { kitchen, challenge }

/// "مجتمع سفرة": a large handwritten welcome over the Sofra mark, then three
/// parts: the home feed (stories, channels, the week's challenge, the shared
/// kitchen, recipes from other homes), the user's own shared recipes, and
/// prices in their area.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  /// Set while a sub page is open: closes it and returns true. The shell's
  /// back (header arrow and system back) calls it before leaving.
  static bool Function()? closeSub;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var part = _Part.home;
  _Sub? sub;

  bool _closeSub() {
    if (!mounted || sub == null) return false;
    setState(() => sub = null);
    return true;
  }

  @override
  void initState() {
    super.initState();
    CommunityScreen.closeSub = _closeSub;
  }

  @override
  void dispose() {
    if (CommunityScreen.closeSub == _closeSub) CommunityScreen.closeSub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    if (sub != null) {
      return ScreenBody(
        children: [
          TextButton.icon(
            key: const ValueKey('community-sub-back'),
            onPressed: () => setState(() => sub = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(t.commTitle),
          ),
          Text(
            sub == _Sub.kitchen ? t.commKitchen : t.commChallenge,
            style: Sofra.heading(26),
          ),
          const SizedBox(height: 12),
          if (c.community == null ||
              (sub == _Sub.kitchen && c.communityPreview))
            const _NeedsAccount()
          else if (sub == _Sub.kitchen)
            const _SharedKitchen()
          else
            const _Challenge(),
        ],
      );
    }
    return ScreenBody(
      children: [
        const CommunityWelcome(),
        const SizedBox(height: 18),
        _Parts(value: part, onChanged: (p) => setState(() => part = p)),
        const SizedBox(height: 16),
        if (c.communityPreview)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              t.commPreviewNote,
              key: ValueKey('community-preview'),
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ),
        if (c.community == null && part != _Part.home)
          const _NeedsAccount()
        else
          switch (part) {
            _Part.home => _Home(open: (s) => setState(() => sub = s)),
            _Part.mine => const _Mine(),
            _Part.prices => const AreaPricesView(),
          },
      ],
    );
  }
}

/// The welcome: «مجتمع سفرة» large and quick, as if written by hand, over a
/// big faint Sofra mark (a round table seen from above with seats around it,
/// everyone at one table). It settles in once, gently.
class CommunityWelcome extends StatelessWidget {
  const CommunityWelcome({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Sofra.motion(context, false) * 2,
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.scale(scale: .92 + .08 * t, child: child),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 230,
        minWidth: double.infinity,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _TableMark(Sofra.accent)),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -.06,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final title = context.l10n.commTitle;
                    // "Community" at 66 is wider than a phone and broke
                    // mid-word, so the Latin title starts smaller, and
                    // any title shrinks until its longest word fits.
                    var style = TextStyle(
                      fontFamily: 'ArefRuqaa',
                      fontSize: L10n.isEnglish ? 52 : 66,
                      height: 1.6,
                      color: Sofra.ink,
                    );
                    final widest = _widestWord(
                      title,
                      style,
                      Directionality.of(context),
                      MediaQuery.textScalerOf(context),
                    );
                    if (box.maxWidth.isFinite && widest > box.maxWidth) {
                      style = style.copyWith(
                        fontSize: style.fontSize! * box.maxWidth / widest * .98,
                      );
                    }
                    return Text(
                      title,
                      key: const ValueKey('community-welcome'),
                      textAlign: TextAlign.center,
                      style: style,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.commTagline,
                style: TextStyle(
                  color: Sofra.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Width of the widest single word of [text] in [style].
double _widestWord(
  String text,
  TextStyle style,
  TextDirection direction,
  TextScaler scaler,
) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, painter.width);
    painter.dispose();
  }
  return widest;
}

class _TableMark extends CustomPainter {
  const _TableMark(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * .36;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: .16),
            accent.withValues(alpha: .05),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent.withValues(alpha: .18),
    );
    final seat = Paint()..color = accent.withValues(alpha: .14);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * (r + 22),
        13,
        seat,
      );
    }
  }

  @override
  bool shouldRepaint(_TableMark old) => old.accent != accent;
}

/// The three parts as one segmented bar.
class _Parts extends StatelessWidget {
  const _Parts({required this.value, required this.onChanged});
  final _Part value;
  final ValueChanged<_Part> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Sofra.card.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(Sofra.r16 + 4),
      border: Border.all(color: Sofra.card),
    ),
    child: Row(
      children: [
        for (final (p, label) in [
          (_Part.home, context.l10n.commPartHome),
          (_Part.mine, context.l10n.commPartMine),
          (_Part.prices, context.l10n.commPartPrices),
        ])
          Expanded(
            child: Semantics(
              button: true,
              selected: value == p,
              child: GestureDetector(
                key: ValueKey('community-${p.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: Sofra.motion(context, true),
                  curve: Sofra.quickCurve,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == p ? Sofra.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(Sofra.r16),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: value == p ? Sofra.onAccent : Sofra.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A card on the home part that opens one of the [_Sub] pages.
class _OpenCard extends StatelessWidget {
  const _OpenCard({
    super.key,
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
  });
  final IconData icon;
  final String title, note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
    child: Material(
      color: Sofra.card,
      borderRadius: BorderRadius.circular(Sofra.r22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sofra.r22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Sofra.accentTint,
                  borderRadius: BorderRadius.circular(Sofra.r12),
                ),
                child: Icon(icon, color: Sofra.accent),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Sofra.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// «وصفاتي»: recipes this home shared, and a way to share another.
class _Mine extends StatefulWidget {
  const _Mine();
  @override
  State<_Mine> createState() => _MineState();
}

class _MineState extends State<_Mine> {
  Future<List<SharedRecipe>>? feed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    feed ??= _load();
  }

  Future<List<SharedRecipe>> _load() {
    final community = SofraScope.controllerOf(context).community!;
    return community.recipesBy(community.uid);
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.myRecipes.isNotEmpty)
          DepthButton(
            key: const ValueKey('share-recipe-open'),
            label: t.commShareOwnRecipe,
            onPressed: () async {
              final shared = await _pickToShare(context, c);
              if (shared && mounted) setState(() => feed = _load());
            },
          ),
        const SizedBox(height: 14),
        FutureBuilder<List<SharedRecipe>>(
          future: feed,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorBlock(t.commRecipesLoadError);
            }
            final mine = snap.data;
            if (mine == null) return const LoadingBlock();
            if (mine.isEmpty) {
              return Surface(
                child: Text(
                  c.myRecipes.isEmpty ? t.commMineEmptyWrite : t.commMineEmpty,
                  key: const ValueKey('community-mine-empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Sofra.muted),
                ),
              );
            }
            return Column(
              children: [
                for (final r in mine)
                  _FeedCard(
                    recipe: r,
                    onDeleted: () => setState(() => feed = _load()),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NeedsAccount extends StatelessWidget {
  const _NeedsAccount();
  @override
  Widget build(BuildContext context) => Surface(
    child: Text(
      context.l10n.commNeedsAccount,
      key: ValueKey('community-needs-account'),
      textAlign: TextAlign.center,
      style: TextStyle(color: Sofra.muted),
    ),
  );
}

String _problem(Object e) =>
    e is InviteProblem ? e.message : L10n.current.commConnectionProblem;

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
  return t.isEmpty
      ? L10n.current.commNoInitial
      : String.fromCharCode(t.runes.first);
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
  const _Home({required this.open});
  final ValueChanged<_Sub> open;
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
    final t = context.l10n;
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
                      label: t.commYourStory,
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
                        onTap: () async {
                          final deleted = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (_) => _StoryViewer(
                                    rings: rings,
                                    start: i,
                                    community: c.community!,
                                  ),
                                ),
                              );
                          if (deleted == true && mounted) _reload();
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: _OpenCard(
                key: const ValueKey('community-challenge'),
                icon: Icons.emoji_events_rounded,
                title: t.commChallenge,
                note: t.commChallengeNote,
                onTap: () => widget.open(_Sub.challenge),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OpenCard(
                key: const ValueKey('community-kitchen'),
                icon: Icons.house_rounded,
                title: t.commKitchen,
                note: t.commKitchenNote,
                onTap: () => widget.open(_Sub.kitchen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          t.commYoutubeChefs,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
              Expanded(
                child: Text(
                  t.commFromSofraHomes,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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
                  label: Text(t.commShareRecipe),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<List<SharedRecipe>>(
            future: feed,
            builder: (context, snap) {
              if (snap.hasError) {
                return ErrorBlock(t.commRecipesLoadError);
              }
              final items = snap.data;
              if (items == null) return const LoadingBlock();
              if (items.isEmpty) {
                return Surface(
                  child: Text(
                    t.commFeedEmpty,
                    key: const ValueKey('community-recipes-empty'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in items)
                    _FeedCard(recipe: r, onDeleted: _reload),
                ],
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
                  PositionedDirectional(
                    end: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Sofra.green,
                      child: Icon(Icons.add, size: 16, color: Sofra.onAccent),
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
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(cr.name, size: 72, color: _colorFor(cr.id)),
            const SizedBox(height: 10),
            Text(
              cr.name,
              key: const ValueKey('creator-name'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (cr.country != null)
              Text(
                L10n.term(cr.country!),
                style: TextStyle(color: Sofra.muted),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('creator-open'),
              onPressed: () => launchUrl(
                Uri.parse(cr.channelUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.l10n.commOpenChannel),
            ),
          ],
        ),
      ),
    );

Future<bool> _pickToShare(BuildContext context, SofraController c) async {
  final pick = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            sheet.l10n.commShareFromYours,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
  );
  if (pick == null || !context.mounted) return false;
  final nav = SofraScope.navOf(context);
  final t = context.l10n;
  final r = c.myRecipes[pick];
  try {
    await c.shareMyRecipe(r);
    nav.notify(t.commSharedNotice(r.recipe.name));
    return true;
  } catch (_) {
    nav.notify(t.commShareFailed);
    return false;
  }
}

/// A recipe from another home as a large card (photo area kept for when
/// photos are switched on).
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.recipe, required this.onDeleted});
  final SharedRecipe recipe;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
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
          builder: (_) => _RecipeSheet(
            recipe: recipe,
            controller: c,
            nav: SofraScope.navOf(context),
          ),
        ),
        // Only the author can delete a shared recipe (long-press).
        onLongPress: c.community?.uid != recipe.authorUid
            ? null
            : () async {
                final done = await deleteOwn(
                  context,
                  () => c.community!.deleteSharedRecipe(recipe.id),
                );
                if (done && context.mounted) onDeleted();
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
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
                          t.commFeedCounts(
                            recipe.lines.length,
                            recipe.steps.length,
                          ),
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
                              if (recipe.cuisine != null)
                                L10n.term(recipe.cuisine!),
                              t.commServings(recipe.servings),
                              if (avg != null)
                                '★ ${avg.toStringAsFixed(1)} (${snap.data!.length})',
                            ].join(' · '),
                            style: TextStyle(color: Sofra.muted, fontSize: 12),
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
    builder: (_) =>
        _StoryComposer(controller: c, nav: SofraScope.navOf(context)),
  );
  return posted == true;
}

class _StoryComposer extends StatefulWidget {
  const _StoryComposer({required this.controller, required this.nav});
  final SofraController controller;
  final SofraNav nav;
  @override
  State<_StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<_StoryComposer> {
  final text = TextEditingController();
  final dish = TextEditingController();
  var color = 0;
  var busy = false;

  Future<void> _post() async {
    setState(() => busy = true);
    try {
      await widget.controller.postStory(
        text.text,
        dish: dish.text,
        colorIndex: color,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => busy = false);
      widget.nav.notify(
        L10n.current.commStoryFailed,
        actionLabel: L10n.current.commRetry,
        onAction: () {
          if (mounted && !busy && text.text.trim().isNotEmpty) _post();
        },
      );
    }
  }

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
            text.text.isEmpty ? context.l10n.commStoryPrompt : text.text,
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
          decoration: InputDecoration(hintText: context.l10n.commStoryHint),
        ),
        TextField(
          key: const ValueKey('story-dish'),
          controller: dish,
          maxLength: 80,
          decoration: InputDecoration(hintText: context.l10n.commStoryDishHint),
        ),
        const SizedBox(height: 6),
        DepthButton(
          key: const ValueKey('story-post'),
          label: context.l10n.commStoryPost,
          onPressed: busy || text.text.trim().isEmpty ? null : _post,
        ),
      ],
    ),
  );
}

/// Full-screen stories: tap to go on, each lasts a few seconds.
class _StoryViewer extends StatefulWidget {
  const _StoryViewer({
    required this.rings,
    required this.start,
    required this.community,
  });
  final List<List<Story>> rings;
  final int start;
  final CommunityBackend community;
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

  /// The author can delete a story; the feed reloads when this pops true.
  Future<void> _delete(Story s) async {
    timer.stop();
    final done = await deleteOwn(
      context,
      () => widget.community.deleteStory(s.id),
    );
    if (!mounted) return;
    if (done) {
      Navigator.of(context).pop(true);
    } else {
      timer.forward();
    }
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
    final t = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: storyColors[s.colorIndex],
      body: SafeArea(
        child: GestureDetector(
          key: const ValueKey('story-viewer'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final w = MediaQuery.sizeOf(context).width;
            // The end side (left in Arabic, right in English) goes forward.
            (d.localPosition.dx < w / 2) == rtl ? _next() : _previous();
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
                        '${s.name} · ${ago.inHours > 0 ? t.commStoryHoursAgo(ago.inHours) : t.commStoryNow}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (s.uid == widget.community.uid)
                      IconButton(
                        key: const ValueKey('story-delete'),
                        tooltip: t.commDelete,
                        onPressed: () => _delete(s),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
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
    final t = context.l10n;
    return FutureBuilder<SharedKitchen?>(
      future: current,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingBlock();
        }
        if (snap.hasError) {
          return ErrorBlock(t.commKitchenLoadError);
        }
        final k = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (k == null) ...[
              Surface(child: Text(t.commKitchenIntro)),
              const SizedBox(height: 12),
              DepthButton(
                key: const ValueKey('kitchen-share'),
                label: t.commKitchenCreate,
                onPressed: busy ? null : () => _run(() => c.shareKitchen()),
              ),
              const SizedBox(height: 20),
              SectionTitle(t.commHaveInvite),
              TextField(
                key: const ValueKey('kitchen-code'),
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: t.commCodeExample),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('kitchen-join'),
                onPressed: busy
                    ? null
                    : () => _run(() => c.joinKitchen(code.text)),
                child: Text(t.commKitchenJoin),
              ),
              const SizedBox(height: 6),
              Text(
                t.commKitchenJoinNote,
                style: TextStyle(color: Sofra.muted, fontSize: 12),
              ),
            ] else ...[
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.commSharedKitchen,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final m in k.members)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(k.nameOf(m)),
                        subtitle: m == k.owner
                            ? Text(t.commKitchenOwner)
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
                      Text(t.commInviteSend),
                      SelectableText(
                        invite!,
                        key: const ValueKey('kitchen-invite-code'),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          // Latin code only: never space Arabic letters.
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              DepthButton(
                key: const ValueKey('kitchen-invite'),
                label: t.commInviteCreate,
                onPressed: busy
                    ? null
                    : () => _run(() async {
                        final v = await c.community!.createInvite(k.id);
                        if (mounted) setState(() => invite = v);
                      }),
              ),
              // The owner stays: leaving would lock them out of their own
              // kitchen, since coming back needs an invite.
              if (k.owner != c.community!.uid)
                TextButton(
                  key: const ValueKey('kitchen-leave'),
                  onPressed: busy
                      ? null
                      : () async {
                          if (await _confirmLeave(context)) {
                            await _run(() => c.leaveKitchen(k.id));
                          }
                        },
                  child: Text(t.commBackToMyKitchen),
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
  const _RecipeSheet({
    required this.recipe,
    required this.controller,
    required this.nav,
  });
  final SharedRecipe recipe;
  final SofraController controller;
  final SofraNav nav;
  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  late Future<List<Rating>> ratings = widget.controller.community!.ratings(
    widget.recipe.id,
  );
  final comment = TextEditingController();
  var stars = 0;

  Future<void> _save() async {
    try {
      await widget.controller.rateRecipe(widget.recipe.id, stars, comment.text);
      if (!mounted) return;
      setState(() {
        ratings = widget.controller.community!.ratings(widget.recipe.id);
      });
    } catch (_) {
      widget.nav.notify(
        L10n.current.commRatingFailed,
        actionLabel: L10n.current.commRetry,
        onAction: () {
          if (mounted) _save();
        },
      );
    }
  }

  Future<void> _deleteMine() async {
    final c = widget.controller.community!;
    final done = await deleteOwn(
      context,
      () => c.deleteRating(widget.recipe.id),
    );
    if (done && mounted) setState(() => ratings = c.ratings(widget.recipe.id));
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final t = context.l10n;
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
            '${t.commByAuthor(r.authorName)} · ${t.commServings(r.servings)}',
            style: TextStyle(color: Sofra.muted),
          ),
          SectionTitle(t.commIngredients),
          for (final l in r.lines)
            Text(
              l.amount == null
                  ? '• ${l.name}'
                  : '• ${l.name}: ${formatAmount(l.amount!)} ${L10n.term(l.unit ?? '')}',
            ),
          SectionTitle(t.commMethod),
          for (final (i, s) in r.steps.indexed) Text('${i + 1}. $s'),
          SectionTitle(t.commRatings),
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
                        ? t.commNoRatings
                        : t.commRatingAverage(
                            avg.toStringAsFixed(1),
                            '${list.length}',
                          ),
                    key: const ValueKey('community-rating-average'),
                  ),
                  for (final x in list)
                    if (x.comment.isNotEmpty ||
                        x.uid == widget.controller.community!.uid)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${x.name} · ${'★' * x.stars}'),
                        subtitle: x.comment.isEmpty ? null : Text(x.comment),
                        trailing: x.uid != widget.controller.community!.uid
                            ? null
                            : IconButton(
                                key: const ValueKey('rating-delete'),
                                tooltip: t.commDelete,
                                onPressed: _deleteMine,
                                icon: const Icon(Icons.delete_outline),
                              ),
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
            decoration: InputDecoration(hintText: t.commCommentHint),
          ),
          FilledButton(
            key: const ValueKey('rate-save'),
            onPressed: stars == 0 ? null : _save,
            child: Text(t.commSaveRating),
          ),
        ],
      ),
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

  Future<void> _log(SofraController c) async {
    final nav = SofraScope.navOf(context);
    try {
      await c.joinChallenge(today: today);
      if (!mounted) return;
      setState(() {
        board = c.community!.challengeEntries(weekKey(today));
      });
    } catch (_) {
      nav.notify(
        L10n.current.commChallengeFailed,
        actionLabel: L10n.current.commRetry,
        onAction: () {
          if (mounted) _log(c);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SofraScope.controllerOf(context);
    final t = context.l10n;
    final ch = challengeFor(today);
    final progress = challengeProgress(ch, today, c.cookedMeals);
    final (title, detail) = switch (ch.kind) {
      ChallengeKind.cookPlanned => (
        t.commChallengeCookPlanned('${ch.goal}'),
        t.commChallengeCookPlannedDetail,
      ),
      ChallengeKind.differentRecipes => (
        t.commChallengeDifferent('${ch.goal}'),
        t.commChallengeDifferentDetail,
      ),
      ChallengeKind.newRecipes => (
        t.commChallengeNew(ch.goal),
        t.commChallengeNewDetail,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: const ValueKey('challenge-title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(detail, style: TextStyle(color: Sofra.muted)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (progress / ch.goal).clamp(0, 1).toDouble(),
              ),
              const SizedBox(height: 6),
              Text(
                t.commChallengeProgress('$progress', '${ch.goal}'),
                key: const ValueKey('challenge-progress'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DepthButton(
          key: const ValueKey('challenge-join'),
          label: t.commChallengeLog,
          onPressed: () => _log(c),
        ),
        SectionTitle(t.commChallengeHomes),
        FutureBuilder<List<ChallengeEntry>>(
          future: board,
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorBlock(t.commBoardLoadError);
            }
            final list = snap.data;
            if (list == null) return const LoadingBlock();
            if (list.isEmpty) {
              return Text(t.commBoardEmpty);
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
                    trailing: Text(
                      '${e.progress}/${e.goal}',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

Future<bool> _confirmLeave(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.commLeaveTitle),
        content: Text(context.l10n.commLeaveBody),
        actions: [
          TextButton(
            key: const ValueKey('kitchen-leave-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commCancel),
          ),
          TextButton(
            key: const ValueKey('kitchen-leave-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commLeave),
          ),
        ],
      ),
    ) ??
    false;
