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
  PlannedMeal? cookingMeal;

  @override
  void initState() {
    super.initState();
    controller.load().then((_) {
      name.text = controller.profile.name;
      house.text = controller.profile.house;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    name.dispose();
    house.dispose();
    super.dispose();
  }

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
    } else {
      goTab(AppTab.today);
    }
  }

  @override
  void openRecipe(String id) => _go(() {
    recipeId = id;
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

  bool _showsNav(SofraController c) => _ready(c) && view == _View.tabs;

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
                    _View.recipe => RecipeDetailScreen(recipeId: recipeId!),
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
                AppTab.community => 'مجتمع سفرة',
                AppTab.style => 'شكل المطبخ',
              },
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          // One way out of the main pages: settings, which opens the
          // account first. The kitchen's look is changed from the 3D kitchen.
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

  Widget _bottomNav(SofraController c) {
    final hasPlan = c.upcoming(DateTime.now()).any((m) => !m.completed);
    const ink = Sofra.ink;
    const accent = Sofra.accent;
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: badge,
                        smallSize: 7,
                        backgroundColor: Sofra.orange,
                        child: Icon(
                          active ? on : off,
                          color: active ? accent : ink,
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
                          color: active ? accent : ink.withValues(alpha: .7),
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

    return Center(
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 32).clamp(0, 440),
        child: Surface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
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
          ),
        ),
      ),
    );
  }
}
