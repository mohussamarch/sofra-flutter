import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'data/demo_data.dart';
import 'domain/models.dart';
import 'domain/recipe_engine.dart';

void main() => runApp(const TabkhaApp());

const ink = Color(0xFF173F39);
const mint = Color(0xFFE7F3E9);
const orange = Color(0xFFE98254);
const cream = Color(0xFFFBF7F0);
const muted = Color(0xFF71817A);

class TabkhaApp extends StatelessWidget {
  const TabkhaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'سفرة',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: cream),
          scaffoldBackgroundColor: cream,
          useMaterial3: true,
          fontFamily: 'Segoe UI',
        ),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const DemoFlow(),
      );
}

enum DemoPage { setup, add, fridge, recipes, detail, table, cooking }

class DemoFlow extends StatefulWidget {
  const DemoFlow({super.key});

  @override
  State<DemoFlow> createState() => _DemoFlowState();
}

class _DemoFlowState extends State<DemoFlow> {
  final engine = const RecipeEngine(demoIngredients);
  final houseController = TextEditingController(text: 'بيت مريم');
  DemoPage page = DemoPage.setup;
  int servings = 4;
  List<StockItem> stock = [];
  Recipe selectedRecipe = demoRecipes.first;
  bool mealPlanned = false;
  bool cooked = false;
  int stepIndex = 0;
  String recipeFilter = 'الكل';
  StorageZone expandedZone = StorageZone.fridge;

  RecipeEstimate get estimate => engine.evaluate(selectedRecipe, servings, stock);

  @override
  void dispose() {
    houseController.dispose();
    super.dispose();
  }

  void go(DemoPage next) => setState(() => page = next);

  void addIngredient(Ingredient ingredient, double quantity) {
    setState(() {
      final index = stock.indexWhere((item) => item.ingredientId == ingredient.id);
      if (index < 0) {
        stock.add(StockItem(ingredient.id, quantity, ingredient.zone));
      } else {
        stock[index] = stock[index].copyWith(quantity: stock[index].quantity + quantity);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('أضفنا ${ingredient.name} إلى تلجتي'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void addSampleStock() {
    setState(() {
      stock = demoStarterStock.map((item) => item.copyWith()).toList();
    });
  }

  void simulateShopping() {
    final missing = estimate.missing;
    setState(() {
      for (final need in missing) {
        final packs = (need.missingQuantity / need.ingredient.purchasePackQuantity).ceil();
        final purchasedQuantity = packs * need.ingredient.purchasePackQuantity;
        final index = stock.indexWhere((item) => item.ingredientId == need.ingredient.id);
        if (index < 0) {
          stock.add(StockItem(need.ingredient.id, purchasedQuantity, need.ingredient.zone));
        } else {
          stock[index] = stock[index].copyWith(
            quantity: stock[index].quantity + purchasedQuantity,
          );
        }
      }
    });
  }

  void finishCooking() {
    final current = estimate;
    if (!current.fullyAvailable) return;
    setState(() {
      stock = engine.consume(current, stock);
      cooked = true;
    });
  }

  void reset() {
    setState(() {
      page = DemoPage.setup;
      stock = [];
      selectedRecipe = demoRecipes.first;
      mealPlanned = false;
      cooked = false;
      stepIndex = 0;
      servings = 4;
      recipeFilter = 'الكل';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Center(
        child: Container(
          width: math.min(430, screen.width),
          height: screen.height,
          decoration: BoxDecoration(
            color: cream,
            boxShadow: screen.width > 520
                ? [BoxShadow(color: ink.withValues(alpha: 0.13), blurRadius: 45)]
                : null,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                _progress(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    child: switch (page) {
                      DemoPage.setup => _setupPage(),
                      DemoPage.add => _addPage(),
                      DemoPage.fridge => _fridgePage(),
                      DemoPage.recipes => _recipesPage(),
                      DemoPage.detail => _detailPage(),
                      DemoPage.table => _tablePage(),
                      DemoPage.cooking => _cookingPage(),
                    },
                  ),
                ),
                _bottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 13, 22, 8),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(13)),
              child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 9),
            const Text('سُفرة', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)),
            const Spacer(),
            const _Tag('نموذج تجريبي', color: Color(0xFFFFEBD9), textColor: Color(0xFF9B5A2E)),
          ],
        ),
      );

  Widget _progress() {
    const labels = ['البيت', 'المكونات', 'تلجتي', 'الوصفات', 'الوجبة', 'السفرة', 'الطبخ'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 5, 22, 10),
      child: Column(children: [
        Row(children: List.generate(labels.length, (index) {
          final active = page.index == index;
          final done = page.index > index;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(height: 5, decoration: BoxDecoration(
              color: active ? orange : done ? ink : const Color(0xFFE7E5DC),
              borderRadius: BorderRadius.circular(10),
            )),
          ));
        })),
        const SizedBox(height: 5),
        Text('خطوة ${page.index + 1} من 7 · ${labels[page.index]}',
            style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _heading(String eyebrow, String title, String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: const TextStyle(color: orange, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: ink, fontSize: 28, height: 1.25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(description, style: const TextStyle(color: muted, fontSize: 13, height: 1.55)),
          const SizedBox(height: 20),
        ],
      );

  Widget _setupPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('👩‍🍳  أهلاً بيكي في مطبخك', style: TextStyle(color: Color(0xFFFFD5A8), fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              const Text('الموجود في البيت\nيعمل أكلة حلوة.', style: TextStyle(color: Colors.white, height: 1.3, fontSize: 29, fontWeight: FontWeight.w900)),
              const SizedBox(height: 13),
              Text('ابدئي بحاجات بسيطة. مش لازم تجردي التلاجة كلها.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 14),
              const Text('🍅    🥒    🧅    🍗    🍚', style: TextStyle(fontSize: 29)),
            ]),
          ),
          const SizedBox(height: 24),
          _heading('يلا نبدأ', 'جهّزي بيتك', 'بيانات الإعداد دي داخل النموذج على جهازك فقط.'),
          const _SectionLabel('اسم البيت'),
          TextField(
            controller: houseController,
            textDirection: TextDirection.rtl,
            decoration: _inputDecoration('مثلاً: بيت مريم'),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('كام شخص هياكلوا؟'),
          _servingStepper(),
          const SizedBox(height: 18),
          _infoBox('🇪🇬', 'البلد: مصر', 'الأسعار المعروضة بالجنيه المصري وبياناتها تجريبية.'),
        ],
      );

  Widget _servingStepper() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        decoration: _cardDecoration(),
        child: Row(children: [
          const Text('أفراد الوجبة', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const Spacer(),
          _roundButton(Icons.remove, () => setState(() => servings = math.max(1, servings - 1))),
          SizedBox(width: 42, child: Center(child: Text('$servings', style: const TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w900)))),
          _roundButton(Icons.add, () => setState(() => servings = math.min(12, servings + 1))),
        ]),
      );

  Widget _addPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('خطوة خفيفة', 'ضيفي الموجود عندك', 'الضغط على «إضافة» يغيّر المخزون فعلًا في النموذج.'),
        _infoBox('✨', 'جرّبي بسرعة', 'حمّلي مكونات بيت مصري تجريبية ثم زوّدي عليها براحتك.'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: addSampleStock,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('حمّل مكونات المثال'),
          style: _outlinedStyle(),
        ),
        const SizedBox(height: 19),
        Row(children: [
          const Expanded(child: _SectionLabel('إضافة يدوية سريعة')),
          Text('${stock.length} مكونات في تلجتي', style: const TextStyle(color: muted, fontSize: 12)),
        ]),
        ...demoIngredients.values.map((ingredient) => _ingredientAddCard(ingredient)),
        const SizedBox(height: 12),
        const Text('الصوت · الباركود · الصور · الفاتورة: مخطط لها، وليست عاملة في هذا النموذج.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
      ]);

  Widget _ingredientAddCard(Ingredient ingredient) {
    final amount = ingredient.unit == 'حبة' || ingredient.unit == 'علبة' ? 1.0 : 100.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: _cardDecoration(),
        child: Row(children: [
          Text(ingredient.emoji, style: const TextStyle(fontSize: 29)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ingredient.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
            Text('${ingredient.category} · ${_zoneName(ingredient.zone)}', style: const TextStyle(color: muted, fontSize: 11)),
          ])),
          TextButton(onPressed: () => addIngredient(ingredient, amount),
            child: Text('+ ${formatQuantity(amount)} ${ingredient.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }

  Widget _fridgePage() {
    final total = stock.fold<double>(0, (sum, item) => sum + item.quantity);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading(houseController.text.isEmpty ? 'مطبخك' : houseController.text,
          'دي تلجتك', 'اضغطي على أي مكان تخزين علشان تشوفي اللي جواه.'),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Icon(Icons.kitchen_outlined, size: 35, color: ink),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${stock.length} أنواع مكونات', style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900)),
            Text(total == 0 ? 'ابدئي بإضافة أول مكوّن' : 'المخزون بيتحدّث مع كل إضافة', style: const TextStyle(color: muted, fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      _zoneCard(StorageZone.fridge, '🧊', 'التلاجة', const Color(0xFFE7F2F4)),
      _zoneCard(StorageZone.freezer, '❄️', 'الفريزر', const Color(0xFFEAF0FB)),
      _zoneCard(StorageZone.pantry, '🧺', 'الدولاب / المخزن', const Color(0xFFFFF0D9)),
      const SizedBox(height: 10),
      _infoBox('ℹ️', 'مشهد مبسّط', 'المجموعات تفتح التفاصيل. ده تمثيل بصري، مش صورة حقيقية لمطبخك.'),
    ]);
  }

  Widget _zoneCard(StorageZone zone, String emoji, String title, Color color) {
    final entries = stock.where((item) => item.zone == zone).toList();
    final expanded = expandedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(23)),
        child: Column(children: [
          InkWell(
            onTap: () => setState(() => expandedZone = zone),
            borderRadius: BorderRadius.circular(23),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('${entries.length} مكونات', style: const TextStyle(color: muted, fontSize: 12)),
                ])),
                Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: ink),
              ]),
            ),
          ),
          if (expanded) Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
              child: entries.isEmpty
                  ? const Text('لسه فاضي', style: TextStyle(color: muted))
                  : Wrap(spacing: 7, runSpacing: 7, children: entries.map((item) {
                      final ingredient = demoIngredients[item.ingredientId]!;
                      return _Tag('${ingredient.emoji} ${ingredient.name} ${formatQuantity(item.quantity)} ${ingredient.unit}');
                    }).toList()),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _recipesPage() {
    final evaluated = demoRecipes.map((recipe) => engine.evaluate(recipe, servings, stock)).toList()
      ..sort((a, b) => b.availabilityFraction.compareTo(a.availabilityFraction));
    final visible = evaluated.where((item) => switch (recipeFilter) {
      'كل المكونات موجودة' => item.fullyAvailable,
      'بعضها ناقص' => !item.fullyAvailable && item.hasMainIngredient,
      _ => true,
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('من الموجود عندك', 'نطبخ إيه النهاردة؟', 'الاقتراحات مرتّبة حسب قرب المكونات من مخزونك.'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: ['الكل', 'كل المكونات موجودة', 'بعضها ناقص'].map((filter) => Padding(
          padding: const EdgeInsets.only(left: 7),
          child: ChoiceChip(
            label: Text(filter, style: const TextStyle(fontSize: 12)),
            selected: recipeFilter == filter,
            onSelected: (_) => setState(() => recipeFilter = filter),
            selectedColor: mint,
            side: BorderSide.none,
          ),
        )).toList()),
      ),
      const SizedBox(height: 14),
      if (visible.isEmpty) _infoBox('🍳', 'مفيش وصفة في الفلتر ده', 'ضيفي مكونات أكتر أو جرّبي فلتر تاني.'),
      ...visible.map(_recipeCard),
      const SizedBox(height: 4),
      const Text('الوصفات والأسعار والصور الرمزية بيانات تجريبية للمراجعة، وليست مكتبة منشورة.',
        style: TextStyle(color: muted, fontSize: 11, height: 1.4)),
    ]);
  }

  Widget _recipeCard(RecipeEstimate item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => setState(() { selectedRecipe = item.recipe; page = DemoPage.detail; }),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: _cardDecoration(),
            child: Row(children: [
              Container(width: 80, height: 90,
                decoration: BoxDecoration(color: const Color(0xFFFFEAD7), borderRadius: BorderRadius.circular(19)),
                child: Center(child: Text(item.recipe.emoji, style: const TextStyle(fontSize: 45)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.recipe.title, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 3),
                Text('${item.recipe.category} · ${item.recipe.cuisine} · ${item.recipe.minutes} دقيقة',
                    style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 9),
                _Tag(item.fullyAvailable ? 'كل المكونات موجودة' : 'ناقص ${item.missing.length} مكونات',
                    color: item.fullyAvailable ? mint : const Color(0xFFFFEFE1),
                    textColor: item.fullyAvailable ? ink : const Color(0xFF9A633E)),
              ])),
              const Icon(Icons.arrow_back_ios_new, size: 14, color: ink),
            ]),
          ),
        ),
      );

  Widget _detailPage() {
    final item = estimate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _backButton(DemoPage.recipes, 'كل الوصفات'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity, height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE4C4), Color(0xFFF9CFAF)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(children: [
          Center(child: Text(selectedRecipe.emoji, style: const TextStyle(fontSize: 86))),
          const Positioned(bottom: 11, left: 12, child: _Tag('رسم توضيحي · ليس صورة الطبق')),
        ]),
      ),
      const SizedBox(height: 16),
      Text(selectedRecipe.title, style: const TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
      Text('${selectedRecipe.description} · ${selectedRecipe.minutes} دقيقة', style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 17),
      _servingStepper(),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _metric('تكلفة الطبخة', '${formatMoney(item.consumedCost)} ج.م', 'تقدير لما يُستهلك')),
        const SizedBox(width: 9),
        Expanded(child: _metric('لشراء الناقص', '${formatMoney(item.purchaseCost)} ج.م', 'عبوات كاملة تقديرية')),
      ]),
      const SizedBox(height: 6),
      Text('≈ ${formatMoney(item.costPerServing)} ج.م للحصة · أسعار مصرية تجريبية غير محدثة',
        style: const TextStyle(color: muted, fontSize: 11)),
      const SizedBox(height: 21),
      const _SectionLabel('المكونات على قدّ الأشخاص'),
      ...item.needs.map(_needRow),
      const SizedBox(height: 13),
      _infoBox('💡', 'الناقص باين بوضوح', 'الكمية الموجودة تُقارن بالمطلوب؛ وجود اسم المكوّن وحده مش كفاية.'),
    ]);
  }

  Widget _needRow(IngredientNeed need) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: _cardDecoration(),
          child: Row(children: [
            Text(need.ingredient.emoji, style: const TextStyle(fontSize: 23)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(need.ingredient.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
              Text('مطلوب ${formatQuantity(need.requiredQuantity)} ${need.ingredient.unit} · موجود ${formatQuantity(need.availableQuantity)}',
                style: const TextStyle(color: muted, fontSize: 11)),
            ])),
            _Tag(need.isEnough ? 'موجود' : 'ناقص ${formatQuantity(need.missingQuantity)}',
              color: need.isEnough ? mint : const Color(0xFFFFE9E0),
              textColor: need.isEnough ? ink : const Color(0xFFB05E3B)),
          ]),
        ),
      );

  Widget _tablePage() {
    final item = estimate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('وجبة $servings أشخاص', 'السفرة جاهزة للتخطيط', 'اختيار الوجبة لم يخصم شيئًا من المخزون.'),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E7CD), borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEED7B5), width: 2),
        ),
        child: Column(children: [
          const Text('🍴  سفرتنا النهاردة  🍴', style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
            children: selectedRecipe.parts.map((part) => Container(
              constraints: const BoxConstraints(minWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(60),
                boxShadow: [BoxShadow(color: ink.withValues(alpha: 0.07), blurRadius: 8)]),
              child: Column(children: [
                Text(part.contains('فراخ') ? '🍗' : part.contains('رز') ? '🍚' : part.contains('سلطة') ? '🥗' : selectedRecipe.emoji,
                    style: const TextStyle(fontSize: 31)),
                Text(part, style: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            )).toList()),
          const SizedBox(height: 14),
          const Text('الرموز للشرح، وليست صورًا حقيقية للأطباق', style: TextStyle(color: muted, fontSize: 10)),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _metric('عدد الأطباق', '${selectedRecipe.parts.length}', 'وجبة واحدة')),
        const SizedBox(width: 9),
        Expanded(child: _metric('وقت تقريبي', '${selectedRecipe.minutes} دقيقة', 'بعد بدء الطبخ')),
      ]),
      const SizedBox(height: 20),
      if (item.missing.isNotEmpty) ...[
        const _SectionLabel('لسه محتاجين'),
        ...item.missing.map((need) => _needRow(need)),
        Text('شراء العبوات الناقصة ≈ ${formatMoney(item.purchaseCost)} ج.م (تقديري)',
          style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: simulateShopping,
          icon: const Icon(Icons.shopping_basket_outlined),
          label: const Text('حاكي شراء الناقص وإضافته للمخزون'),
          style: _outlinedStyle(),
        ),
        const SizedBox(height: 8),
        const Text('محاكاة فقط: لا يوجد طلب شراء أو دفع فعلي.', style: TextStyle(color: muted, fontSize: 11)),
      ] else _infoBox('✅', 'كل المقادير متوفرة', 'تقدري تبدئي الطبخ. الخصم يحصل بعد تأكيد الانتهاء.'),
    ]);
  }

  Widget _cookingPage() {
    final steps = selectedRecipe.steps;
    if (cooked) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 35),
        Center(child: Container(width: 112, height: 112,
          decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
          child: const Center(child: Text('🎉', style: TextStyle(fontSize: 61))))),
        const SizedBox(height: 24),
        const Center(child: Text('بالهنا والشفا!', style: TextStyle(color: ink, fontSize: 29, fontWeight: FontWeight.w900))),
        const SizedBox(height: 7),
        const Center(child: Text('اتخصمت المقادير من المخزون بعد تأكيد الطبخ.', textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 13))),
        const SizedBox(height: 23),
        _infoBox('🧺', 'مخزونك دلوقتي', '${stock.length} أنواع مكونات متبقية. تقدري ترجعي تشوفيها في تلجتي.'),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () => go(DemoPage.fridge), icon: const Icon(Icons.kitchen_outlined),
          label: const Text('شوفي تلجتي بعد الطبخ'), style: _outlinedStyle()),
      ]);
    }
    final current = steps[stepIndex];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('وضع هادي', 'طبخة النهاردة 👩‍🍳', '${selectedRecipe.title} · ${selectedRecipe.minutes} دقيقة تقريبًا'),
      _infoBox('🔕', 'الخطوات بإيدك', 'انتقلي باللمس. الصوت والأنيميشن والمؤقت الفعلي ضمن مراحل لاحقة.'),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: Text('الخطوة ${stepIndex + 1} من ${steps.length}', style: const TextStyle(color: ink, fontWeight: FontWeight.w900))),
        const SizedBox(width: 8),
        Flexible(child: Text('${current.minutes} دقيقة تقريبًا', style: const TextStyle(color: muted, fontSize: 12))),
      ]),
      const SizedBox(height: 9),
      LinearProgressIndicator(value: (stepIndex + 1) / steps.length, color: orange,
        backgroundColor: const Color(0xFFE8E5DD), borderRadius: BorderRadius.circular(10), minHeight: 8),
      const SizedBox(height: 18),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(27)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(current.emoji, style: const TextStyle(fontSize: 58)),
          const SizedBox(height: 14),
          Text(current.title, style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Text(current.detail, style: const TextStyle(color: muted, fontSize: 15, height: 1.7)),
        ]),
      ),
      const SizedBox(height: 18),
      if (selectedRecipe.id == 'chicken_meal')
        _infoBox('⏱️', 'خطوات ممكن تتعمل بالتوازي', 'ابدئي الرز والسلطة والفراخ في الفرن. المدد هنا إرشادية وليست مؤقتًا يعمل تلقائيًا.'),
      const SizedBox(height: 17),
      Row(children: List.generate(steps.length, (index) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(height: 7, decoration: BoxDecoration(
          color: index <= stepIndex ? ink : const Color(0xFFE6E5DF),
          borderRadius: BorderRadius.circular(8))),
      )))),
    ]);
  }

  Widget _bottomAction() {
    final (label, action) = switch (page) {
      DemoPage.setup => ('يلا نضيف المكونات', () => go(DemoPage.add)),
      DemoPage.add => ('شوفي تلجتي', () => go(DemoPage.fridge)),
      DemoPage.fridge => ('اقترحي وصفات', () => go(DemoPage.recipes)),
      DemoPage.recipes => ('اختاري وصفة من فوق', null),
      DemoPage.detail => ('ضيفي الوجبة للسفرة', () { setState(() { mealPlanned = true; page = DemoPage.table; }); }),
      DemoPage.table => ('ابدئي طبخة النهاردة', estimate.fullyAvailable ? () => go(DemoPage.cooking) : null),
      DemoPage.cooking => cooked
          ? ('ابدئي تجربة جديدة', reset)
          : stepIndex < selectedRecipe.steps.length - 1
              ? ('الخطوة اللي بعدها', () => setState(() => stepIndex++))
              : ('خلصنا الطبخ · اخصمي المكونات', finishCooking),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
      decoration: BoxDecoration(color: cream, boxShadow: [BoxShadow(color: ink.withValues(alpha: 0.05), blurRadius: 12)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (page.index > 0 && page != DemoPage.cooking && page != DemoPage.recipes)
          Align(alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => go(DemoPage.values[page.index - 1]),
              child: const Text('رجوع', style: TextStyle(color: muted, fontSize: 12)))),
        SizedBox(width: double.infinity, height: 52,
          child: FilledButton(
            onPressed: action,
            style: FilledButton.styleFrom(backgroundColor: ink, disabledBackgroundColor: const Color(0xFFB9C5BE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          )),
        if (page == DemoPage.table && !estimate.fullyAvailable)
          const Padding(padding: EdgeInsets.only(top: 6), child: Text('استكملي النواقص التجريبية الأول', style: TextStyle(color: muted, fontSize: 10))),
      ]),
    );
  }

  Widget _backButton(DemoPage target, String label) => InkWell(
        onTap: () => go(target),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_forward_ios, size: 14, color: muted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _metric(String label, String value, String detail) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900)),
          Text(detail, style: const TextStyle(color: muted, fontSize: 10)),
        ]),
      );

  Widget _infoBox(String emoji, String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(18)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(switch (emoji) {
            '✨' => Icons.auto_awesome,
            'ℹ️' => Icons.info_outline,
            '💡' => Icons.lightbulb_outline,
            '✅' => Icons.check_circle_outline,
            '🔕' => Icons.notifications_off_outlined,
            '⏱️' => Icons.schedule,
            '🧺' => Icons.kitchen_outlined,
            _ => Icons.lightbulb_outline,
          }, size: 23, color: ink),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(color: ink, fontSize: 11, height: 1.5)),
          ])),
        ]),
      );

  Widget _roundButton(IconData icon, VoidCallback onPressed) => InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(width: 30, height: 30,
          decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: ink, size: 18)),
      );

  String _zoneName(StorageZone zone) => switch (zone) {
    StorageZone.fridge => 'التلاجة',
    StorageZone.freezer => 'الفريزر',
    StorageZone.pantry => 'الدولاب',
  };

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EEE8)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: ink),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.color = const Color(0xFFF1F4ED), this.textColor = ink});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 15)),
      );
}
