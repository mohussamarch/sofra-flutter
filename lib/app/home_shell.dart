import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/community_backend.dart';
import '../data/recipe_repository.dart';
import '../data/state_store.dart';
import '../domain/kitchen_core.dart';
import '../features/community_screen.dart';
import '../features/daily_home_screen.dart';
import '../features/recipes_screen.dart';
import '../features/table_screen.dart';
import '../features/cooking_screen.dart';
import '../features/kitchen_screen.dart';
import '../features/kitchen_style_screen.dart';
import '../features/onboarding_screen.dart';
import '../features/profile_screen.dart';
import '../features/recipe_detail_screen.dart';
import '../features/today_screen.dart';
import '../ui/add_tile.dart';
import '../ui/design.dart';
import 'look.dart';
import 'reminders.dart';
import 'scope.dart';
import 'sofra_controller.dart';

enum _View { tabs, addStock, recipe, cooking, kitchen3d }

/// Owns the controller and navigation state; screens live in lib/features.
class SofraHome extends StatefulWidget {
  const SofraHome({
    super.key,
    this.store,
    this.initialData,
    this.signOut,
    this.recipes,
    this.readAsset,
    this.showScene = true,
    this.reminders,
    this.community,
    this.reopen,
    this.communityPreview = false,
  });
  final StateStore? store;
  final Map<String, dynamic>? initialData;
  final Future<void> Function()? signOut;

  /// Injectable for tests; defaults to the bundled catalog.
  final RecipeRepository? recipes;

  /// Injectable asset reader (ingredient directory); defaults to rootBundle.
  final Future<String> Function(String path)? readAsset;

  /// The Blender kitchen on the home tab; off in widget tests.
  final bool showScene;

  /// Injectable for tests; phone notifications by default.
  final ReminderSink? reminders;

  /// Shared kitchen and community; null in local mode.
  final CommunityBackend? community;
  final VoidCallback? reopen;
  final bool communityPreview;

  @override
  State<SofraHome> createState() => _SofraHomeState();
}

class _SofraHomeState extends State<SofraHome> implements SofraNav {
  late final SofraController controller = SofraController(
    store: widget.store,
    initialData: widget.initialData,
    recipes: widget.recipes,
    readAsset: widget.readAsset,
    reminders: widget.reminders ?? (kIsWeb ? null : LocalReminders()),
    community: widget.community,
    reopen: widget.reopen,
    communityPreview: widget.communityPreview,
  );
  final name = TextEditingController();
  final house = TextEditingController();
  AppTab tab = AppTab.today;
  static const primaryTabs = [
    AppTab.today,
    AppTab.recipes,
    AppTab.kitchen,
    AppTab.table,
  ];
  final visitedTabs = <AppTab>{AppTab.today};
  String recipeFilter = 'الكل';
  int recipeVisit = 0;
  _View view = _View.tabs;
  int onboardingStep = 0;
  String? recipeId;
  bool recipeCompare = false;
  PlannedMeal? cookingMeal;

  @override
  void initState() {
    super.initState();
    controller.addListener(_publishLook);
    controller.load().then((_) {
      name.text = controller.profile.name;
      house.text = controller.profile.house;
    });
  }

  @override
  void dispose() {
    controller.removeListener(_publishLook);
    SofraLook.publish(const SofraLook());
    controller.dispose();
    name.dispose();
    house.dispose();
    super.dispose();
  }

  /// Hands the profile's look (theme, text size, colours, motion) to the
  /// app root, which applies it above every screen and dialog.
  void _publishLook() => SofraLook.publish(controller.profile.look);

  void _go(VoidCallback change) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(change);
  }

  @override
  void goTab(AppTab value) => _go(() {
    tab = value;
    visitedTabs.add(value);
    view = _View.tabs;
  });

  @override
  void discoverFromStock() => _go(() {
    recipeFilter = 'من الموجود';
    recipeVisit++;
    tab = AppTab.recipes;
    visitedTabs.add(tab);
    view = _View.tabs;
  });

  @override
  void openKitchen3d() => _go(() => view = _View.kitchen3d);

  @override
  void exploreRecipes() => _go(() {
    recipeFilter = 'الكل';
    recipeVisit++;
    tab = AppTab.recipes;
    visitedTabs.add(tab);
    view = _View.tabs;
  });

  void _back() {
    if (view != _View.tabs) {
      _go(() => view = _View.tabs);
    } else if (tab == AppTab.community &&
        CommunityScreen.closeSub?.call() == true) {
      // A community sub page closes first.
      return;
    } else if (tab == AppTab.profile) {
      // The account opens from settings, so back returns there.
      goTab(AppTab.settings);
    } else {
      goTab(AppTab.today);
    }
  }

  @override
  void openRecipe(String id, {bool compare = false}) => _go(() {
    recipeId = id;
    recipeCompare = compare;
    view = _View.recipe;
  });

  @override
  void openAddStock() => _go(() => view = _View.addStock);

  @override
  void startCooking(PlannedMeal meal) => _go(() {
    cookingMeal = meal;
    view = _View.cooking;
  });

  @override
  void editOnboarding(int step) {
    _go(() => onboardingStep = step);
    controller.updateProfile((p) => p.copyWith(onboarded: false));
  }

  @override
  void notify(String text) {
    if (!mounted) return;
    final horizontal =
        ((MediaQuery.sizeOf(context).width - 480) / 2).clamp(
          0.0,
          double.infinity,
        ) +
        20;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: EdgeInsets.fromLTRB(
            horizontal,
            0,
            horizontal,
            104 + MediaQuery.paddingOf(context).bottom,
          ),
          content: Text(text),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      final c = controller;
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: media.disableAnimations || c.profile.reduceMotion,
        ),
        child: SofraScope(
          controller: c,
          nav: this,
          child: PopScope(
            canPop: view == _View.tabs && tab == AppTab.today,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _back();
            },
            child: Scaffold(
              backgroundColor: Sofra.sand,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Material(
                    color: Sofra.cream,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: SofraBackdrop()),
                        SafeArea(
                          top: true,
                          bottom: false,
                          child: Column(
                            children: [
                              if (c.saveError != null)
                                MaterialBanner(
                                  content: Text(c.saveError!),
                                  actions: [
                                    TextButton(
                                      onPressed: c.retrySave,
                                      child: const Text('إعادة الحفظ'),
                                    ),
                                  ],
                                ),
                              Expanded(child: _body(c)),
                            ],
                          ),
                        ),
                        if (_showsNav(c))
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: MediaQuery.paddingOf(context).bottom + 12,
                            child: _bottomNav(c),
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
    },
  );

  bool _ready(SofraController c) =>
      c.loadError == null && c.ready && c.profile.onboarded;

  /// Settings and the account are their own place, left by the back arrow:
  /// no main bar there.
  bool _showsNav(SofraController c) =>
      _ready(c) &&
      view == _View.tabs &&
      tab != AppTab.settings &&
      tab != AppTab.profile;

  Widget _body(SofraController c) {
    if (c.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعذّر تحميل بيانات البيت. بياناتك لم تُحذف.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DepthButton(label: 'حاول مرة أخرى', onPressed: c.load),
            ],
          ),
        ),
      );
    }
    if (!c.ready) return const Center(child: CircularProgressIndicator());
    if (!c.profile.onboarded) {
      return OnboardingScreen(
        step: onboardingStep,
        onStep: (s) => _go(() => onboardingStep = s.clamp(0, 5)),
        name: name,
        house: house,
      );
    }
    return Column(
      children: [
        _header(c),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Offstage(
                  offstage: view != _View.tabs || !primaryTabs.contains(tab),
                  child: IndexedStack(
                    index: primaryTabs.contains(tab)
                        ? primaryTabs.indexOf(tab)
                        : 0,
                    children: [
                      for (final destination in primaryTabs)
                        if (!visitedTabs.contains(destination))
                          const SizedBox.shrink()
                        else
                          switch (destination) {
                            AppTab.today => const DailyHomeScreen(),
                            AppTab.recipes => RecipesScreen(
                              key: ValueKey('recipes-$recipeVisit'),
                              initialFilter: recipeFilter,
                            ),
                            AppTab.kitchen => const KitchenScreen(),
                            _ => const TableScreen(),
                          },
                    ],
                  ),
                ),
              ),
              if (view != _View.tabs || !primaryTabs.contains(tab))
                Positioned.fill(
                  child: switch (view) {
                    _View.addStock => const AddStockScreen(),
                    _View.recipe => RecipeDetailScreen(
                      key: ValueKey('recipe-view-$recipeId-$recipeCompare'),
                      recipeId: recipeId!,
                      compare: recipeCompare,
                    ),
                    _View.cooking => CookingScreen(
                      meal: cookingMeal!,
                      onDone: () => cookingMeal = null,
                    ),
                    _View.kitchen3d => TodayScreen(showScene: widget.showScene),
                    _View.tabs => switch (tab) {
                      AppTab.profile => const ProfileScreen(),
                      AppTab.settings => SettingsScreen(
                        signOut: widget.signOut,
                      ),
                      AppTab.community => const CommunityScreen(),
                      AppTab.style => KitchenStyleScreen(
                        show3d: widget.showScene,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(SofraController c) {
    if (view != _View.tabs) {
      final saved = recipeId != null && c.profile.saved.contains(recipeId);
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
            ),
            Expanded(
              child: Text(
                switch (view) {
                  _View.addStock => 'نزوّد الخير',
                  _View.recipe => 'وصفة على قدرك',
                  _View.kitchen3d => 'مطبخي 3D',
                  _ => 'نطبخ معًا',
                },
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            if (view == _View.recipe)
              IconButton(
                tooltip: saved ? 'إلغاء الحفظ' : 'حفظ الوصفة',
                onPressed: () => c.updateProfile(
                  (p) => p.copyWith(
                    saved: saved
                        ? ({...p.saved}..remove(recipeId))
                        : {...p.saved, recipeId!},
                  ),
                ),
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: Sofra.green,
                ),
              ),
          ],
        ),
      );
    }
    final primary = primaryTabs.contains(tab);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          if (!primary)
            IconButton(
              key: const ValueKey('page-back'),
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
            ),
          Expanded(
            child: Text(
              switch (tab) {
                AppTab.today => 'سُفرة',
                AppTab.recipes => 'الوصفات',
                AppTab.kitchen => 'الخزين',
                AppTab.table => 'الخطة',
                AppTab.profile => 'حسابي',
                AppTab.settings => 'الإعدادات',
                // The community page opens on its own large handwritten title.
                AppTab.community => '',
                AppTab.style => 'شكل المطبخ',
              },
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          // One way out of the main pages: settings, which opens the
          // account first. The kitchen's look is changed from the 3D kitchen.
          // Sofra's community, always one tap away next to the gear.
          if (primary)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Material(
                color: Sofra.accentTint,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  key: const ValueKey('header-community'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => goTab(AppTab.community),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 20,
                          color: Sofra.accent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'المجتمع',
                          style: TextStyle(
                            color: Sofra.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (primary)
            IconButton(
              key: const ValueKey('circle-settings'),
              tooltip: 'الإعدادات',
              onPressed: () => goTab(AppTab.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
    );
  }

  /// Look of the bottom bar: tint (chosen 17 Nov 2026), glass, dark or white.
  /// `--dart-define=SOFRA_NAV=dark`, or `?nav=dark` on the web preview.
  static final navTrial =
      Uri.base.queryParameters['nav'] ??
      const String.fromEnvironment('SOFRA_NAV', defaultValue: 'tint');

  Widget _bottomNav(SofraController c) {
    final hasPlan = c.upcoming(DateTime.now()).any((m) => !m.completed);
    final look = navTrial;
    final dark = look == 'dark';
    // In the dark the terracotta slab would shout: the bar turns into a
    // calm raised surface and only the chosen tab keeps the brand colour.
    final night = look == 'tint' && Sofra.isDark;
    final tint = look == 'tint' && !night;
    final glass = look == 'glass';
    final pill = look.isNotEmpty;
    // Inactive and active colours for each look.
    final idle = night
        ? Sofra.muted
        : dark
        ? Sofra.onInverse.withValues(alpha: .62)
        : tint
        ? Sofra.onAccent.withValues(alpha: .72)
        : Sofra.ink.withValues(alpha: .7);
    final onColor = !pill
        ? Sofra.accent
        : tint || night
        ? Sofra.accent
        : Sofra.onAccent;
    final pillColor = night
        ? Sofra.accentTint
        : tint
        ? Sofra.onAccent
        : Sofra.accent;
    Widget item(
      AppTab target,
      String key,
      IconData off,
      IconData on,
      String label, {
      bool badge = false,
    }) {
      final active = tab == target;
      return Expanded(
        child: KeyedSubtree(
          key: active ? const ValueKey('nav-active') : null,
          child: Semantics(
            selected: active,
            button: true,
            label: label,
            child: PressScale(
              child: InkWell(
                key: ValueKey('nav-$key'),
                borderRadius: BorderRadius.circular(Sofra.r22),
                onTap: () => goTab(target),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: pill && active ? pillColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(Sofra.r22),
                    boxShadow: pill && active && !night
                        ? [
                            BoxShadow(
                              color: Sofra.accentDark.withValues(alpha: .28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: badge,
                        smallSize: 7,
                        backgroundColor: Sofra.orange,
                        child: Icon(
                          active ? on : off,
                          color: active ? onColor : idle,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: active ? onColor : idle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Row(
      children: [
        item(
          AppTab.today,
          'today',
          Icons.home_outlined,
          Icons.home_rounded,
          'اليوم',
        ),
        item(
          AppTab.recipes,
          'recipes',
          Icons.menu_book_outlined,
          Icons.menu_book_rounded,
          'الوصفات',
        ),
        item(
          AppTab.kitchen,
          'stock',
          Icons.kitchen_outlined,
          Icons.kitchen_rounded,
          'الخزين',
        ),
        item(
          AppTab.table,
          'table',
          Icons.table_restaurant_outlined,
          Icons.table_restaurant_rounded,
          'الخطة',
          badge: hasPlan,
        ),
      ],
    );
    const pad = EdgeInsets.symmetric(horizontal: 6, vertical: 6);
    final radius = BorderRadius.circular(30);
    final Widget bar;
    if (glass) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color:
                  (Sofra.isDark
                          ? Sofra.palette.shadow
                          : const Color(0xFF8A4A2C))
                      .withValues(alpha: .18),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        child: SofraGlass(
          radius: 30,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(padding: pad, child: row),
          ),
        ),
      );
    } else if (night) {
      bar = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Sofra.palette.shadow.withValues(alpha: .45),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: Sofra.inverse.withValues(alpha: .94),
                  border: Border.all(color: Sofra.line),
                ),
                child: Padding(padding: pad, child: row),
              ),
            ),
          ),
        ),
      );
    } else if (tint) {
      // Frosted terracotta: the exact brand colour, barely see-through,
      // with a heavy blur so what passes behind is only a soft hint.
      bar = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Sofra.accentDark.withValues(alpha: .30),
              blurRadius: 26,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: Sofra.accent.withValues(alpha: .92),
                ),
                child: Padding(padding: pad, child: row),
              ),
            ),
          ),
        ),
      );
    } else if (dark) {
      bar = Material(
        color: Sofra.inverse,
        borderRadius: radius,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Sofra.inverse.withValues(alpha: .32),
                blurRadius: 26,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(padding: pad, child: row),
        ),
      );
    } else {
      bar = Surface(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: row,
      );
    }
    return Center(
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 32).clamp(0, 440),
        child: bar,
      ),
    );
  }
}
