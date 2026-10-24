import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../data/state_store.dart';
import '../domain/kitchen_core.dart';
import '../domain/market_profile.dart';
import '../features/cooking_screen.dart';
import '../features/kitchen_screen.dart';
import '../features/onboarding_screen.dart';
import '../features/profile_screen.dart';
import '../features/recipe_detail_screen.dart';
import '../features/recipes_screen.dart';
import '../features/table_screen.dart';
import '../features/today_screen.dart';
import '../ui/design.dart';
import 'scope.dart';
import 'sofra_controller.dart';

enum _View { tabs, addStock, recipe, cooking }

/// Owns the controller and navigation state; screens live in lib/features.
class SofraHome extends StatefulWidget {
  const SofraHome({
    super.key,
    this.store,
    this.initialData,
    this.signOut,
    this.recipes,
  });
  final StateStore? store;
  final Map<String, dynamic>? initialData;
  final Future<void> Function()? signOut;

  /// Injectable for tests; defaults to the bundled catalog.
  final RecipeRepository? recipes;

  @override
  State<SofraHome> createState() => _SofraHomeState();
}

class _SofraHomeState extends State<SofraHome> implements SofraNav {
  late final SofraController controller = SofraController(
    store: widget.store,
    initialData: widget.initialData,
    recipes: widget.recipes,
  );
  final name = TextEditingController();
  final house = TextEditingController();
  AppTab tab = AppTab.today;
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
    view = _View.tabs;
  });

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
          child: Scaffold(
            backgroundColor: const Color(0xFFEDF0E8),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Material(
                  color: Sofra.cream,
                  child: SafeArea(
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
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _body(SofraController c) {
    if (c.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعذّر تحميل بيانات البيت. بياناتك ما اتمسحتش.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DepthButton(label: 'جرّب تاني', onPressed: c.load),
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
          child: AnimatedSwitcher(
            duration: Sofra.motion(context),
            child: KeyedSubtree(
              key: ValueKey('$tab-$view-$recipeId-${cookingMeal?.id}'),
              child: switch (view) {
                _View.addStock => const AddStockScreen(),
                _View.recipe => RecipeDetailScreen(recipeId: recipeId!),
                _View.cooking => CookingScreen(
                  meal: cookingMeal!,
                  onDone: () => cookingMeal = null,
                ),
                _View.tabs => switch (tab) {
                  AppTab.today => const TodayScreen(),
                  AppTab.kitchen => const KitchenScreen(),
                  AppTab.recipes => const RecipesScreen(),
                  AppTab.table => const TableScreen(),
                  AppTab.profile => ProfileScreen(signOut: widget.signOut),
                },
              },
            ),
          ),
        ),
        if (view == _View.tabs) _bottomNav(c),
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
              onPressed: () => _go(() => view = _View.tabs),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
            ),
            Expanded(
              child: Text(
                switch (view) {
                  _View.addStock => 'نزوّد الخير',
                  _View.recipe => 'وصفة على قدّك',
                  _ => 'نطبخ سوا',
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
    final egypt = c.market.country == MarketCountry.egypt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Sofra.mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Sofra.green,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab == AppTab.today
                      ? 'أهلًا يا ${c.profile.displayName}'
                      : c.profile.houseName,
                  style: const TextStyle(fontSize: 13, color: Sofra.muted),
                ),
                Text(
                  switch (tab) {
                    AppTab.today =>
                      egypt ? 'نطبخ إيه النهارده؟' : 'وش بنطبخ اليوم؟',
                    AppTab.kitchen => 'مطبخك بخير',
                    AppTab.recipes => 'وصفات على ذوقك',
                    AppTab.table => 'لمّة سفرتك',
                    AppTab.profile => 'بيتي وتفضيلاتي',
                  },
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (tab == AppTab.today || tab == AppTab.kitchen)
            IconButton(
              key: const ValueKey('open-home-settings'),
              onPressed: () => goTab(AppTab.profile),
              tooltip: 'بيتي',
              style: IconButton.styleFrom(backgroundColor: Sofra.peach),
              icon: const Icon(Icons.face_rounded, color: Color(0xFF995333)),
            ),
        ],
      ),
    );
  }

  Widget _bottomNav(SofraController c) {
    const icons = [
      Icons.home_rounded,
      Icons.kitchen_rounded,
      Icons.menu_book_rounded,
      Icons.restaurant_rounded,
    ];
    final labels = [c.market.today, 'مطبخي', 'وصفات', 'السفرة'];
    const keys = ['today', 'fridge', 'recipes', 'table'];
    final hasPlan = c.upcoming(DateTime.now()).any((m) => !m.completed);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Sofra.line)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final active = tab.index == index;
          return Expanded(
            child: Semantics(
              selected: active,
              child: InkWell(
                key: ValueKey('nav-${keys[index]}'),
                borderRadius: BorderRadius.circular(16),
                onTap: () => goTab(AppTab.values[index]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: Sofra.motion(context, true),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active ? Sofra.mint : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Badge(
                          isLabelVisible: index == 3 && hasPlan,
                          smallSize: 7,
                          backgroundColor: Sofra.orange,
                          child: Icon(
                            icons[index],
                            color: active ? Sofra.greenDark : Sofra.muted,
                            size: 23,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: active ? Sofra.greenDark : Sofra.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
