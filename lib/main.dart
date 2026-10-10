import 'package:flutter/material.dart';

import 'data/demo_data.dart';
import 'domain/models.dart';
import 'domain/recipe_engine.dart';
import 'ui/design.dart';
import 'ui/illustrations.dart';

void main() => runApp(const TabkhaApp());

class TabkhaApp extends StatelessWidget {
  const TabkhaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'سفرة',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: Sofra.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Sofra.green,
        primary: Sofra.green,
        onPrimary: Colors.white,
        surface: Sofra.cream,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Sofra.ink, fontSize: 15, height: 1.45),
        bodyLarge: TextStyle(color: Sofra.ink, fontSize: 16, height: 1.45),
        titleLarge: TextStyle(color: Sofra.ink, fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: Sofra.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.green, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Sofra.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const SofraHome(),
  );
}

enum AppTab { today, fridge, recipes, table, profile }

enum AppView { tabs, addStock, recipe, cooking }

class SofraHome extends StatefulWidget {
  const SofraHome({super.key});
  @override
  State<SofraHome> createState() => _SofraHomeState();
}

class _SofraHomeState extends State<SofraHome> {
  final name = TextEditingController();
  final house = TextEditingController();
  final allergySearch = TextEditingController();
  final recipeSearch = TextEditingController();
  final ingredientSearch = TextEditingController();
  final scroll = ScrollController();
  final engine = const RecipeEngine(demoIngredients);
  int onboarding = 0;
  bool onboarded = false;
  int servings = 4;
  final cuisines = <String>{'مصري'};
  final allergies = <String>{};
  final meals = <String>{'غدا', 'عشا'};
  bool quickMeals = true;
  bool reduceMotion = false;
  AppTab tab = AppTab.today;
  AppView view = AppView.tabs;
  StorageZone? zone;
  String recipeFilter = 'الكل';
  List<StockItem> stock = [];
  Recipe selected = demoRecipes.first;
  Recipe? planned;
  int cookingStep = 0;
  bool cooked = false;
  final saved = <String>{};

  String get displayName =>
      name.text.trim().isEmpty ? 'صاحب السفرة' : name.text.trim();
  String get houseName =>
      house.text.trim().isEmpty ? 'بيت $displayName' : house.text.trim();
  RecipeEstimate estimate(Recipe recipe) =>
      engine.evaluate(recipe, servings, stock);

  @override
  void dispose() {
    name.dispose();
    house.dispose();
    allergySearch.dispose();
    recipeSearch.dispose();
    ingredientSearch.dispose();
    scroll.dispose();
    super.dispose();
  }

  void change(VoidCallback mutation) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(mutation);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void goTab(AppTab value) => change(() {
    tab = value;
    view = AppView.tabs;
  });
  void notify(String text) {
    final horizontal =
        ((MediaQuery.sizeOf(context).width - 480) / 2).clamp(
          0.0,
          double.infinity,
        ) +
        20;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
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

  void addIngredient(Ingredient ingredient, [double? amount]) {
    final quantity =
        amount ??
        ((ingredient.unit == 'جم' || ingredient.unit == 'مل') ? 100 : 1);
    final index = stock.indexWhere(
      (item) => item.ingredientId == ingredient.id,
    );
    if (index < 0) {
      stock.add(StockItem(ingredient.id, quantity, ingredient.zone));
    } else {
      stock[index] = stock[index].copyWith(
        quantity: stock[index].quantity + quantity,
      );
    }
  }

  void loadSample() {
    setState(() {
      for (final item in demoStarterStock) {
        addIngredient(demoIngredients[item.ingredientId]!, item.quantity);
      }
    });
    notify('اتضافت 7 مكونات تجريبية لمطبخك');
  }

  void openRecipe(Recipe recipe) => change(() {
    selected = recipe;
    cooked = false;
    view = AppView.recipe;
  });

  List<String> recipeAllergens(Recipe recipe) {
    final ids = recipe.ingredients.map((e) => e.ingredientId).toSet();
    return [
      if (ids.contains('eggs')) 'بيض',
      if (ids.contains('yogurt')) 'ألبان',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || reduceMotion,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF0E8),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: Sofra.cream,
              child: SafeArea(child: onboarded ? _app() : _onboarding()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _onboarding() {
    final optional = onboarding == 3 || onboarding == 4;
    return Column(
      children: [
        if (onboarding == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: Sofra.green,
                  size: 25,
                ),
                const SizedBox(width: 8),
                const Text(
                  'سفرة',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                const SoftTag(
                  'من البيت.. للبيت',
                  color: Sofra.peach,
                  ink: Sofra.ink,
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('onboarding-back'),
                  onPressed: () => change(() => onboarding--),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'رجوع',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: onboarding / 5,
                      minHeight: 10,
                      backgroundColor: Sofra.line,
                      color: Sofra.green,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '$onboarding / 5',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Sofra.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (optional)
                  TextButton(
                    key: const ValueKey('onboarding-skip'),
                    onPressed: () => change(() => onboarding++),
                    child: const Text('تخطي'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : Sofra.motion(context),
              child: KeyedSubtree(
                key: ValueKey(onboarding),
                child: _onboardingBody(),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: const BoxDecoration(
            color: Sofra.cream,
            border: Border(top: BorderSide(color: Sofra.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DepthButton(
                key: const ValueKey('onboarding-next'),
                label: onboarding == 0
                    ? 'يلا نجهّز سفرتك'
                    : onboarding == 5
                    ? 'افتحي سفرتي'
                    : 'كمّلي',
                onPressed: onboarding == 1 && name.text.trim().isEmpty
                    ? null
                    : () => change(() {
                        if (onboarding == 5) {
                          onboarded = true;
                        } else {
                          onboarding++;
                        }
                      }),
              ),
              const SizedBox(height: 10),
              Text(
                onboarding == 0
                    ? 'خطوات صغيرة.. وطبخ أسهل كل يوم'
                    : onboarding == 5
                    ? 'تقدري تعدّلي اختياراتك من «بيتي» في أي وقت'
                    : 'على راحتك، تقدري ترجعي وتغيّري أي اختيار',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Sofra.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _onboardingBody() {
    switch (onboarding) {
      case 0:
        return Column(
          children: [
            const SizedBox(height: 28),
            const ChefArt(size: 290),
            const SizedBox(height: 18),
            const SoftTag(
              'أهلًا بيكي في سفرة',
              color: Sofra.peach,
              ink: Color(0xFF995333),
            ),
            const SizedBox(height: 18),
            const Text(
              'كل اللي في بيتك،\nيعمل أكلة حلوة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Sofra.ink,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'نعرف الموجود، نفكّر سوا، ونطبخ على قدّنا.\nمن غير حيرة «هناكل إيه النهاردة؟»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Sofra.muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                SoftTag('هدر أقل', icon: Icons.eco_outlined),
                SoftTag('على ذوق بيتك', icon: Icons.favorite_border_rounded),
                SoftTag('حيرة أقل', icon: Icons.lightbulb_outline_rounded),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(
              'نتعرف الأول؟',
              'قولي لنا نناديكي إيه، ونجهّز مكان صغير على قد بيتك.',
              icon: Icons.waving_hand_outlined,
            ),
            const SizedBox(height: 24),
            const Text('اسمك', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('field-name'),
              controller: name,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'مثلًا: مريم',
                counterText: '',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اسم البيت  ·  اختياري',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('field-house'),
              controller: house,
              maxLength: 35,
              decoration: const InputDecoration(
                hintText: 'بيت العيلة',
                counterText: '',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Surface(
              color: Sofra.mint,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Sofra.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مصر',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'أول سفرة لينا · الأسعار بالجنيه المصري',
                          style: TextStyle(color: Sofra.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: Sofra.green),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'دي تجربة محلية. معلوماتك هنا لتخصيص التجربة، والحفظ بين الزيارات لسه مش متاح.',
              style: TextStyle(fontSize: 12, color: Sofra.muted),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(
              'كام حد على السفرة؟',
              'هنظبط كميات الوصفات على عددكم. وتقدري تغيّريه لكل طبخة.',
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 24),
            Surface(
              color: Sofra.mint,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      servings.clamp(1, 5),
                      (i) => Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          Icons.face_rounded,
                          size: i == 0 ? 42 : 32,
                          color: i.isEven
                              ? Sofra.green
                              : const Color(0xFF80A76C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Counter(
                    value: servings,
                    onChanged: (value) => setState(() => servings = value),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أفراد في البيت',
                    style: TextStyle(color: Sofra.muted),
                  ),
                ],
              ),
            ),
            const SectionTitle('غالبًا بتطبخوا إيه في البيت؟'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['فطار', 'غدا', 'عشا']
                  .map(
                    (meal) => FilterChip(
                      label: Text(meal),
                      selected: meals.contains(meal),
                      onSelected: (_) => setState(() {
                        meals.contains(meal)
                            ? meals.remove(meal)
                            : meals.add(meal);
                      }),
                      selectedColor: Sofra.mint,
                      showCheckmark: true,
                      padding: const EdgeInsets.all(10),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'مش لازم كل أفراد البيت ياكلوا نفس الكمية. دي نقطة بداية تقديرية للوصفات.',
              style: TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(
              'طعم البيت عندك إيه؟',
              'اختاري المطابخ اللي بتحبوها. ممكن تختاري أكتر من واحد.',
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(height: 24),
            ...['مصري', 'شامي', 'خليجي', 'إيطالي'].map(
              (cuisine) => ChoiceTile(
                key: ValueKey(
                  cuisine == 'مصري' ? 'cuisine-egyptian' : 'cuisine-$cuisine',
                ),
                title: cuisine,
                subtitle: switch (cuisine) {
                  'مصري' => 'أكل بيتي ولمّة حلوة',
                  'شامي' => 'نكهات خفيفة ومتنوعة',
                  'خليجي' => 'رز وبهارات على أصولها',
                  _ => 'مكرونة وأكلات بسيطة',
                },
                selected: cuisines.contains(cuisine),
                icon: Icons.ramen_dining_rounded,
                onTap: () => setState(() {
                  cuisines.contains(cuisine)
                      ? cuisines.remove(cuisine)
                      : cuisines.add(cuisine);
                }),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'بحب الأكلات السريعة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'خلّي وصفات 30 دقيقة ظاهرة الأول',
                style: TextStyle(fontSize: 12),
              ),
              value: quickMeals,
              onChanged: (v) => setState(() => quickMeals = v),
            ),
          ],
        );
      case 4:
        final choices = [
          'بيض',
          'ألبان',
          'مكسرات',
          'قمح',
          'سمك',
          'سمسم',
          'فول سوداني',
        ];
        final query = allergySearch.text.trim();
        final filtered = {
          ...choices,
          ...allergies,
        }.where((v) => v.contains(query)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(
              'في حاجة ناخد بالنا منها؟',
              'لو عندكم حساسية من مكوّن، سجّليها هنا. والخطوة دي اختيارية.',
              icon: Icons.favorite_border_rounded,
            ),
            const SizedBox(height: 22),
            TextField(
              key: const ValueKey('field-allergy-search'),
              controller: allergySearch,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'دوري على مكوّن أو اكتبيه',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filtered
                  .map(
                    (item) => FilterChip(
                      key: ValueKey(
                        item == 'بيض' ? 'allergy-eggs' : 'allergy-$item',
                      ),
                      label: Text(item),
                      selected: allergies.contains(item),
                      padding: const EdgeInsets.all(10),
                      selectedColor: Sofra.peach,
                      onSelected: (_) => setState(() {
                        allergies.contains(item)
                            ? allergies.remove(item)
                            : allergies.add(item);
                      }),
                    ),
                  )
                  .toList(),
            ),
            if (query.isNotEmpty &&
                !choices.contains(query) &&
                !allergies.contains(query))
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: DepthButton(
                  secondary: true,
                  label: 'إضافة «$query»',
                  onPressed: () => setState(() {
                    allergies.add(query);
                    allergySearch.clear();
                  }),
                ),
              ),
            const SizedBox(height: 24),
            Surface(
              color: Sofra.peach,
              padding: const EdgeInsets.all(16),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF995333),
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هنظهر تنبيه للمكونات المسجّلة. راجعي كل وصفة وعبوات المكونات؛ التنبيه مش ضمان لخلو الأكل من مسببات الحساسية.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF79513D)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            const SizedBox(height: 12),
            const ChefArt(size: 250, celebrate: true),
            Text(
              'يا أهلًا يا $displayName!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'سفرتك جاهزة تتفتح. نبدأ بالموجود عندك،\nحتى لو 3 مكونات بس.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                children: [
                  _summaryLine(Icons.home_outlined, houseName, 'مصر'),
                  const Divider(height: 28, color: Sofra.line),
                  _summaryLine(
                    Icons.groups_outlined,
                    '$servings أفراد',
                    cuisines.isEmpty ? 'كل المطابخ' : cuisines.join(' · '),
                  ),
                  const Divider(height: 28, color: Sofra.line),
                  _summaryLine(
                    Icons.favorite_border_rounded,
                    'حساسية مسجّلة',
                    allergies.isEmpty ? 'لا يوجد' : allergies.join('، '),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _intro(String title, String subtitle, {required IconData icon}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Sofra.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Sofra.green, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Sofra.muted, fontSize: 16),
          ),
        ],
      );

  Widget _summaryLine(IconData icon, String title, String subtitle) => Row(
    children: [
      Icon(icon, color: Sofra.green, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          subtitle,
          textAlign: TextAlign.end,
          style: const TextStyle(color: Sofra.muted, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _app() => Column(
    children: [
      _appHeader(),
      Expanded(
        child: SingleChildScrollView(
          controller: scroll,
          key: ValueKey('$tab-$view'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : Sofra.motion(context),
            child: KeyedSubtree(
              key: ValueKey(
                '$tab-$view-${view == AppView.cooking ? cookingStep : ''}-$cooked',
              ),
              child: switch (view) {
                AppView.addStock => _addStock(),
                AppView.recipe => _recipeDetail(),
                AppView.cooking => _cooking(),
                AppView.tabs => switch (tab) {
                  AppTab.today => _today(),
                  AppTab.fridge => _fridge(),
                  AppTab.recipes => _recipes(),
                  AppTab.table => _table(),
                  AppTab.profile => _profile(),
                },
              },
            ),
          ),
        ),
      ),
      if (view == AppView.recipe)
        _footer(
          DepthButton(
            key: const ValueKey('plan-meal'),
            label: 'ضيفي الوجبة للسفرة',
            onPressed: () {
              change(() {
                planned = selected;
                tab = AppTab.table;
                view = AppView.tabs;
                cooked = false;
              });
              notify('الوجبة على السفرة.. والمخزون لسه زي ما هو');
            },
          ),
        ),
      if (view == AppView.cooking && !cooked)
        _footer(
          DepthButton(
            key: ValueKey(
              cookingStep == selected.steps.length - 1
                  ? 'finish-cooking'
                  : 'next-cooking-step',
            ),
            label: cookingStep == selected.steps.length - 1
                ? 'خلصنا الطبخ · اخصمي المكونات'
                : 'الخطوة اللي بعدها',
            onPressed: () => change(() {
              if (cookingStep < selected.steps.length - 1) {
                cookingStep++;
              } else {
                stock = engine.consume(estimate(selected), stock);
                cooked = true;
                planned = null;
              }
            }),
          ),
        ),
      if (view == AppView.tabs || cooked) _bottomNav(),
    ],
  );

  Widget _appHeader() {
    if (view != AppView.tabs) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () => change(() => view = AppView.tabs),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
            ),
            Expanded(
              child: Text(
                switch (view) {
                  AppView.addStock => 'نزود الخير',
                  AppView.recipe => 'وصفة على قدّك',
                  _ => 'نطبخ سوا',
                },
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
            ),
            if (view == AppView.recipe)
              IconButton(
                tooltip: saved.contains(selected.id)
                    ? 'إلغاء الحفظ'
                    : 'حفظ الوصفة',
                onPressed: () => setState(() {
                  saved.contains(selected.id)
                      ? saved.remove(selected.id)
                      : saved.add(selected.id);
                }),
                icon: Icon(
                  saved.contains(selected.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: Sofra.green,
                ),
              ),
          ],
        ),
      );
    }
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
                  tab == AppTab.today ? 'أهلًا يا $displayName' : houseName,
                  style: const TextStyle(fontSize: 13, color: Sofra.muted),
                ),
                Text(
                  switch (tab) {
                    AppTab.today => 'نطبخ إيه النهاردة؟',
                    AppTab.fridge => 'مطبخك بخير',
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
          IconButton(
            onPressed: () => goTab(AppTab.profile),
            tooltip: 'بيتي',
            style: IconButton.styleFrom(backgroundColor: Sofra.peach),
            icon: const Icon(Icons.face_rounded, color: Color(0xFF995333)),
          ),
        ],
      ),
    );
  }

  Widget _footer(Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: const BoxDecoration(
      color: Sofra.cream,
      border: Border(top: BorderSide(color: Sofra.line)),
    ),
    child: child,
  );

  Widget _bottomNav() {
    const icons = [
      Icons.home_rounded,
      Icons.kitchen_rounded,
      Icons.menu_book_rounded,
      Icons.restaurant_rounded,
      Icons.person_rounded,
    ];
    const labels = ['النهاردة', 'تلجتي', 'وصفات', 'السفرة', 'بيتي'];
    const keys = ['today', 'fridge', 'recipes', 'table', 'profile'];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Sofra.line)),
      ),
      child: Row(
        children: List.generate(5, (index) {
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
                        duration: reduceMotion
                            ? Duration.zero
                            : Sofra.motion(context, true),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active ? Sofra.mint : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Badge(
                          isLabelVisible: index == 3 && planned != null,
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

  Widget _today() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Surface(
        color: Sofra.mint,
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SoftTag(
                        'حاجة حلوة من الموجود',
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stock.isEmpty
                            ? 'أول أكلة حلوة،\nتبدأ من تلجتك.'
                            : 'في مطبخك خير..\nنحوّله لأكلة؟',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 5,
                  child: FittedBox(child: ChefArt(size: 180, compact: true)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DepthButton(
              label: stock.isEmpty
                  ? 'عرّفيني على مطبخك'
                  : 'شوفي وصفات من الموجود',
              icon: stock.isEmpty
                  ? Icons.add_rounded
                  : Icons.auto_awesome_rounded,
              onPressed: () =>
                  goTab(stock.isEmpty ? AppTab.fridge : AppTab.recipes),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: _stat(
              '${stock.length}',
              'مكونات في مطبخك',
              Icons.kitchen_outlined,
              Sofra.peach,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _stat(
              '$servings',
              'أفراد على السفرة',
              Icons.groups_outlined,
              const Color(0xFFF2EDDA),
            ),
          ),
        ],
      ),
      SectionTitle(
        'على سفرة النهاردة',
        action: 'السفرة',
        onAction: () => goTab(AppTab.table),
      ),
      if (planned != null)
        _recipeCard(planned!, small: true)
      else
        Surface(
          border: true,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Sofra.peach,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFFAF6944),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لسه بنفكّر في أكلة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اختاري وصفة ونرتّب الوجبة سوا.',
                      style: TextStyle(fontSize: 12, color: Sofra.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      SectionTitle(
        'إلهام لطبخة حلوة',
        action: 'كل الوصفات',
        onAction: () => goTab(AppTab.recipes),
      ),
      _recipeCard(demoRecipes.first),
      const SizedBox(height: 18),
      Surface(
        color: const Color(0xFFFFF3D4),
        padding: const EdgeInsets.all(16),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.eco_outlined, color: Color(0xFF8C7230)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اللقمة اللي بتوفّريها بتفرق',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'قبل أي مشوار للسوق، بصّي على الموجود عندك. ممكن نص طبخة يكون مستنيكي!',
                    style: TextStyle(fontSize: 13, color: Sofra.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _stat(String number, String title, IconData icon, Color color) =>
      Surface(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 21, color: Sofra.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Sofra.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _fridge() {
    final visible = stock
        .where((item) => zone == null || item.zone == zone)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Surface(
          color: Sofra.mint,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.kitchen_rounded, size: 48, color: Sofra.green),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.isEmpty
                          ? 'مكان صغير.. لخير كتير'
                          : '${stock.length} مكونات مستنيين طبخة',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'التلجة والفريزر ودولاب المطبخ، في مكان واحد.',
                      style: TextStyle(fontSize: 13, color: Sofra.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DepthButton(
          key: const ValueKey('add-ingredients'),
          label: 'ضيفي مكونات',
          icon: Icons.add_rounded,
          onPressed: () => change(() => view = AppView.addStock),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('الكل'),
              selected: zone == null,
              onSelected: (_) => setState(() => zone = null),
            ),
            ...StorageZone.values.map(
              (z) => ChoiceChip(
                label: Text(_zoneName(z)),
                selected: zone == z,
                onSelected: (_) => setState(() => zone = z),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          Surface(
            border: true,
            child: Column(
              children: [
                const ChefArt(size: 165, compact: true),
                Text(
                  stock.isEmpty ? 'لسه بنتعرف على مطبخك' : 'الرف ده لسه فاضي',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ضيفي كام مكوّن كبداية. مش محتاجين جرد كامل عشان نبدأ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Sofra.muted, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...visible.map(_stockRow),
        if (stock.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: DepthButton(
              key: const ValueKey('add-sample-stock'),
              label: 'جرّبي بمكونات جاهزة',
              secondary: true,
              onPressed: loadSample,
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          'الكميات بتتخصم لما تأكدي انتهاء الطبخ، مش وقت اختيار الوصفة.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Sofra.muted, fontSize: 11),
        ),
      ],
    );
  }

  String _zoneName(StorageZone value) => switch (value) {
    StorageZone.fridge => 'التلجة',
    StorageZone.freezer => 'الفريزر',
    StorageZone.pantry => 'الدولاب',
  };
  IconData _ingredientIcon(Ingredient i) => switch (i.category) {
    'خضار' => Icons.eco_outlined,
    'بروتين' => Icons.egg_alt_outlined,
    'حبوب' => Icons.grain_rounded,
    'ألبان' => Icons.local_drink_outlined,
    _ => Icons.kitchen_outlined,
  };

  Widget _stockRow(StockItem item) {
    final ingredient = demoIngredients[item.ingredientId]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ingredient.category == 'خضار' ? Sofra.mint : Sofra.peach,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _ingredientIcon(ingredient),
                color: Sofra.greenDark,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _zoneName(item.zone),
                    style: const TextStyle(fontSize: 11, color: Sofra.muted),
                  ),
                ],
              ),
            ),
            Text(
              '${formatQuantity(item.quantity)} ${ingredient.unit}',
              key: ValueKey('stock-quantity-${ingredient.id}'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: 'تعديل ${ingredient.name}',
              onPressed: () => _editStock(item),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Sofra.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editStock(StockItem item) async {
    final ingredient = demoIngredients[item.ingredientId]!;
    var input = formatQuantity(item.quantity);
    final form = GlobalKey<FormState>();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('كمية ${ingredient.name}'),
          content: Form(
            key: form,
            child: TextFormField(
              initialValue: input,
              onChanged: (value) => input = value,
              validator: (value) {
                final quantity = double.tryParse(value ?? '');
                return quantity == null || !quantity.isFinite || quantity < 0
                    ? 'اكتبي رقم صحيح يساوي 0 أو أكتر'
                    : null;
              },
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'الكمية (${ingredient.unit})',
                helperText: 'اكتبي 0 لإزالة المكوّن',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                final q = double.tryParse(input);
                if (q != null && q.isFinite && q >= 0) Navigator.pop(ctx, q);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      stock = stock.where((s) => s.ingredientId != item.ingredientId).toList();
      if (result > 0) stock.add(item.copyWith(quantity: result));
    });
    notify('اتحدثت كمية ${ingredient.name}');
  }

  Widget _addStock() {
    final items = demoIngredients.values
        .where((i) => i.name.contains(ingredientSearch.text.trim()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إيه الموجود عندك؟',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'اضغطي + لإضافة الكمية. تقدري تظبطيها من تلجتك.',
          style: TextStyle(color: Sofra.muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: ingredientSearch,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'دوري على مكوّن',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('المكوّن مش في قائمة التجربة لسه. جرّبي مكوّن تاني.'),
          ),
        ...items.map((i) {
          final qty = stock
              .where((s) => s.ingredientId == i.id)
              .fold<double>(0, (total, s) => total + s.quantity);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(_ingredientIcon(i), color: Sofra.green, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          qty > 0
                              ? 'عندك ${formatQuantity(qty)} ${i.unit}'
                              : _zoneName(i.zone),
                          style: const TextStyle(
                            color: Sofra.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${i.unit == 'جم' || i.unit == 'مل' ? '100' : '1'} ${i.unit}',
                    style: const TextStyle(fontSize: 12, color: Sofra.muted),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'إضافة ${i.name}',
                    onPressed: () => setState(() => addIngredient(i)),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        DepthButton(
          label: 'تمام، شوفي تلجتي',
          onPressed: () => goTab(AppTab.fridge),
        ),
      ],
    );
  }

  Widget _recipes() {
    var recipes = demoRecipes
        .where((r) => r.title.contains(recipeSearch.text.trim()))
        .where(
          (r) => switch (recipeFilter) {
            'من الموجود' => estimate(r).hasMainIngredient,
            'سريعة' => r.minutes <= 30,
            'محفوظة' => saved.contains(r.id),
            _ => true,
          },
        )
        .toList();
    if (quickMeals) recipes.sort((a, b) => a.minutes.compareTo(b.minutes));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: recipeSearch,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'نفسك في أكلة إيه؟',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['الكل', 'من الموجود', 'سريعة', 'محفوظة']
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter),
                  selected: recipeFilter == filter,
                  selectedColor: Sofra.mint,
                  onSelected: (_) => setState(() => recipeFilter = filter),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'أكلات من قلب البيت',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ),
            Text(
              '${recipes.length} وصفات',
              style: const TextStyle(color: Sofra.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recipes.isEmpty)
          Surface(
            child: Column(
              children: [
                const ChefArt(size: 170, compact: true),
                const Text(
                  'ندور على حاجة تانية؟',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'مفيش وصفات تطابق الاختيار ده في التجربة. غيّري البحث أو الفلتر.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Sofra.muted),
                ),
                const SizedBox(height: 18),
                DepthButton(
                  secondary: true,
                  label: 'عرض كل الوصفات',
                  onPressed: () => setState(() {
                    recipeSearch.clear();
                    recipeFilter = 'الكل';
                  }),
                ),
              ],
            ),
          ),
        ...recipes.map(
          (recipe) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _recipeCard(recipe),
          ),
        ),
        const Text(
          '4 وصفات مصرية تجريبية. هنوسّع المطابخ حسب اختياراتك.',
          style: TextStyle(fontSize: 11, color: Sofra.muted),
        ),
      ],
    );
  }

  Widget _recipeCard(Recipe recipe, {bool small = false}) {
    final e = estimate(recipe);
    final kind = demoRecipes.indexOf(recipe);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: ValueKey(
          recipe.id == 'chicken_meal'
              ? 'recipe-chicken-rice'
              : 'recipe-${recipe.id}',
        ),
        onTap: () => openRecipe(recipe),
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
                          recipe.category,
                          color: Colors.white,
                          ink: Sofra.ink,
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: saved.contains(recipe.id)
                              ? 'إلغاء الحفظ'
                              : 'حفظ الوصفة',
                          onPressed: () => setState(() {
                            saved.contains(recipe.id)
                                ? saved.remove(recipe.id)
                                : saved.add(recipe.id);
                          }),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          icon: Icon(
                            saved.contains(recipe.id)
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: Sofra.greenDark,
                          ),
                        ),
                      ],
                    ),
                    MealArt(kind: kind, size: 215),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe.description,
                    style: const TextStyle(color: Sofra.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      SoftTag(
                        '${recipe.minutes} دقيقة',
                        color: Sofra.cream,
                        ink: Sofra.muted,
                        icon: Icons.schedule_rounded,
                      ),
                      SoftTag(
                        '$servings أفراد',
                        color: Sofra.cream,
                        ink: Sofra.muted,
                        icon: Icons.groups_outlined,
                      ),
                      SoftTag(
                        e.fullyAvailable
                            ? 'كل المكونات موجودة'
                            : 'ناقص ${e.missing.length} مكونات',
                        color: e.fullyAvailable ? Sofra.mint : Sofra.peach,
                        ink: e.fullyAvailable
                            ? Sofra.greenDark
                            : const Color(0xFF995333),
                      ),
                    ],
                  ),
                  if (recipeAllergens(recipe).any(allergies.contains))
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'تنبيه: تحتوي على مكوّن من الحساسية المسجّلة',
                        style: TextStyle(
                          color: Color(0xFF9F4C36),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recipeDetail() {
    final e = estimate(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Surface(
          color: const Color(0xFFF0EDD8),
          padding: const EdgeInsets.all(12),
          child: Center(
            child: MealArt(kind: demoRecipes.indexOf(selected), size: 280),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          selected.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 27,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(selected.description, style: const TextStyle(color: Sofra.muted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SoftTag('${selected.minutes} دقيقة', icon: Icons.schedule_rounded),
            SoftTag(selected.cuisine),
            SoftTag(selected.category),
          ],
        ),
        const SizedBox(height: 20),
        Surface(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هنطبخ لكام حد؟',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'الكميات بتتظبط لوحدها',
                      style: TextStyle(fontSize: 11, color: Sofra.muted),
                    ),
                  ],
                ),
              ),
              Counter(
                value: servings,
                onChanged: (v) => setState(() => servings = v),
              ),
            ],
          ),
        ),
        if (allergies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Surface(
              color: Sofra.peach,
              padding: const EdgeInsets.all(16),
              child: Text(
                recipeAllergens(selected).any(allergies.contains)
                    ? 'خدي بالك: الوصفة فيها ${recipeAllergens(selected).where(allergies.contains).join('، ')} من الحساسية المسجّلة.'
                    : 'راجعي مكونات الوصفة والعبوات مع الحساسية المسجّلة: ${allergies.join('، ')}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF79513D)),
              ),
            ),
          ),
        const SectionTitle('المكونات على قدّكم'),
        ...e.needs.map(
          (need) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    need.isEnough
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: need.isEnough ? Sofra.green : Sofra.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          need.ingredient.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          need.isEnough
                              ? 'موجود عندك'
                              : 'ناقص ${formatQuantity(need.missingQuantity)} ${need.ingredient.unit}',
                          style: TextStyle(
                            color: need.isEnough
                                ? Sofra.muted
                                : const Color(0xFFA05233),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatQuantity(need.requiredQuantity)} ${need.ingredient.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionTitle('حسبة الطبخة'),
        Surface(
          color: Sofra.mint,
          child: Column(
            children: [
              _moneyLine(
                'تكلفة المكونات المستخدمة',
                '${formatMoney(e.consumedCost)} ج.م',
              ),
              const SizedBox(height: 12),
              _moneyLine(
                'نصيب الفرد تقريبًا',
                '${formatMoney(e.costPerServing)} ج.م',
              ),
              const Divider(height: 28, color: Color(0xFFCFDEC9)),
              _moneyLine(
                'شراء عبوات الناقص',
                '${formatMoney(e.purchaseCost)} ج.م',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'الأسعار توضيحية للتجربة. تكلفة الشراء تحسب العبوة الكاملة، والباقي يفضل في مخزونك.',
          style: TextStyle(fontSize: 11, color: Sofra.muted),
        ),
      ],
    );
  }

  Widget _moneyLine(String label, String value) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      const SizedBox(width: 12),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ],
  );

  Widget _table() {
    if (planned == null) {
      return Column(
        children: [
          const SizedBox(height: 24),
          const ChefArt(size: 250),
          const Text(
            'سفرة حلوة تستاهل اللمّة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'اختاري أكلة، وهنرتّب أطباقها ونشوف الناقص قبل ما نبدأ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Sofra.muted, fontSize: 16),
          ),
          const SizedBox(height: 28),
          DepthButton(
            label: 'اختاري طبخة للسفرة',
            onPressed: () => goTab(AppTab.recipes),
          ),
        ],
      );
    }
    final meal = planned!;
    final e = estimate(meal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const SoftTag('خطة وجبتك', icon: Icons.restaurant_rounded),
        const SizedBox(height: 16),
        const Text(
          'السفرة جاهزة للتخطيط',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 27),
        ),
        const SizedBox(height: 8),
        Text(
          'وجبة لـ $servings أفراد. كل طبق في مكانه.',
          style: const TextStyle(color: Sofra.muted),
        ),
        const SizedBox(height: 20),
        Surface(
          color: const Color(0xFFF0EDD8),
          child: Column(
            children: [
              MealArt(kind: demoRecipes.indexOf(meal), size: 235),
              Text(
                meal.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: meal.parts
                    .map(
                      (part) =>
                          SoftTag(part, color: Colors.white, ink: Sofra.ink),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        SectionTitle(e.fullyAvailable ? 'كل حاجة جاهزة!' : 'فاضل كام حاجة'),
        if (e.fullyAvailable)
          Surface(
            color: Sofra.mint,
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Sofra.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المكونات كلها موجودة. نغسل إيدينا ونبدأ؟',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else
          Surface(
            child: Column(
              children: [
                ...e.missing.map(
                  (need) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: Sofra.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            need.ingredient.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${formatQuantity(need.missingQuantity)} ${need.ingredient.unit}',
                          style: const TextStyle(color: Sofra.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Sofra.line),
                const SizedBox(height: 8),
                _moneyLine(
                  'عبوات الشراء تقريبًا',
                  '${formatMoney(e.purchaseCost)} ج.م',
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        if (!e.fullyAvailable) ...[
          DepthButton(
            key: const ValueKey('simulate-shopping'),
            label: 'حاكي شراء الناقص وإضافته للمخزون',
            secondary: true,
            onPressed: () {
              setState(() {
                for (final need in e.missing) {
                  addIngredient(
                    need.ingredient,
                    (need.missingQuantity /
                                need.ingredient.purchasePackQuantity)
                            .ceil() *
                        need.ingredient.purchasePackQuantity,
                  );
                }
              });
              notify('الناقص اتضاف للمخزون بعبوات كاملة');
            },
          ),
          const SizedBox(height: 14),
        ],
        DepthButton(
          key: const ValueKey('start-cooking'),
          label: 'ابدئي طبخة النهاردة',
          icon: Icons.soup_kitchen_rounded,
          onPressed: !e.fullyAvailable
              ? null
              : () => change(() {
                  selected = meal;
                  cookingStep = 0;
                  cooked = false;
                  view = AppView.cooking;
                }),
        ),
        const SizedBox(height: 16),
        const Text(
          'اختيار الوجبة ما بيخصمش المخزون. الخصم بعد تأكيد انتهاء الطبخ.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Sofra.muted, fontSize: 11),
        ),
        TextButton(
          onPressed: () => setState(() => planned = null),
          child: const Text('شيلي الوجبة من السفرة'),
        ),
      ],
    );
  }

  Widget _cooking() {
    if (cooked) {
      return Column(
        children: [
          const SizedBox(height: 24),
          const ChefArt(size: 285, celebrate: true),
          const SizedBox(height: 18),
          const Text(
            'بالهنا والشفا!',
            key: ValueKey('cooking-success'),
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'أكلة حلوة، ومخزون مظبوط.\nخصمنا المكونات المستخدمة وسيبنا الباقي لطبخة جاية.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Sofra.muted),
          ),
          const SizedBox(height: 24),
          Surface(
            color: Sofra.mint,
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Sofra.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اتطبخت ${selected.title}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DepthButton(
            label: 'شوفي اللي فاضل في تلجتك',
            onPressed: () => goTab(AppTab.fridge),
          ),
        ],
      );
    }
    final step = selected.steps[cookingStep];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                selected.title,
                style: const TextStyle(color: Sofra.muted, fontSize: 14),
              ),
            ),
            SoftTag('${cookingStep + 1} من ${selected.steps.length}'),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (cookingStep + 1) / selected.steps.length,
            minHeight: 8,
            backgroundColor: Sofra.line,
            color: Sofra.green,
          ),
        ),
        const SizedBox(height: 28),
        Surface(
          color: Sofra.mint,
          child: Center(
            child: ChefArt(
              size: 245,
              celebrate: cookingStep == selected.steps.length - 1,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          step.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 29),
        ),
        const SizedBox(height: 14),
        Text(
          step.detail,
          style: const TextStyle(color: Sofra.muted, fontSize: 18, height: 1.7),
        ),
        const SizedBox(height: 20),
        SoftTag(
          'حوالي ${step.minutes} دقيقة',
          icon: Icons.schedule_rounded,
          color: Sofra.peach,
          ink: const Color(0xFF995333),
        ),
        const SizedBox(height: 20),
        if (cookingStep > 0)
          TextButton.icon(
            onPressed: () => change(() => cookingStep--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('الخطوة اللي فاتت'),
          ),
      ],
    );
  }

  Widget _profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Surface(
        color: Sofra.mint,
        child: Row(
          children: [
            const ChefArt(size: 92, compact: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    houseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 23,
                    ),
                  ),
                  const Text(
                    'كل بيت له طعم.. ودي سفرتك',
                    style: TextStyle(color: Sofra.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SectionTitle('أهل البيت'),
      Surface(
        child: Column(
          children: [
            _summaryLine(Icons.person_outline_rounded, displayName, 'مصر'),
            const Divider(height: 28, color: Sofra.line),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'عدد أفراد السفرة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Counter(
                  value: servings,
                  onChanged: (v) => setState(() => servings = v),
                ),
              ],
            ),
          ],
        ),
      ),
      const SectionTitle('ذوقك في الأكل'),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['مصري', 'شامي', 'خليجي', 'إيطالي']
                  .map(
                    (c) => FilterChip(
                      label: Text(c),
                      selected: cuisines.contains(c),
                      onSelected: (_) => setState(() {
                        cuisines.contains(c)
                            ? cuisines.remove(c)
                            : cuisines.add(c);
                      }),
                    ),
                  )
                  .toList(),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'الوصفات السريعة الأول',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              value: quickMeals,
              onChanged: (v) => setState(() => quickMeals = v),
            ),
          ],
        ),
      ),
      const SectionTitle('حساسية الأكل'),
      Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              allergies.isEmpty ? 'مفيش حساسية مسجّلة' : allergies.join('، '),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'تفضيلاتك بتظهر كتنبيه، وبتحتاجي تراجعي المكونات بنفسك.',
              style: TextStyle(fontSize: 12, color: Sofra.muted),
            ),
            TextButton(
              onPressed: () => change(() {
                onboarded = false;
                onboarding = 4;
              }),
              child: const Text('تعديل الحساسية'),
            ),
          ],
        ),
      ),
      const SectionTitle('راحتك في التطبيق'),
      Surface(
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'تقليل الحركة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'انتقالات أهدى من غير ارتداد',
                style: TextStyle(fontSize: 11),
              ),
              value: reduceMotion,
              onChanged: (v) => setState(() => reduceMotion = v),
            ),
            const Divider(color: Sofra.line),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.info_outline_rounded,
                color: Sofra.green,
              ),
              title: const Text(
                'نسخة نجرب فيها سوا',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'البيانات خلال الجلسة فقط. الأسعار والوصفات تجريبية، والحساب والمزامنة لسه مش متاحين.',
                style: TextStyle(fontSize: 12, color: Sofra.muted),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      DepthButton(
        secondary: true,
        label: 'راجعي بيانات البيت',
        onPressed: () => change(() {
          onboarded = false;
          onboarding = 1;
        }),
      ),
      const SizedBox(height: 22),
      const Center(
        child: Text(
          'سفرة  ·  معمول بحب للبيوت',
          style: TextStyle(color: Sofra.muted, fontSize: 12),
        ),
      ),
    ],
  );
}
