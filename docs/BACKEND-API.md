> ربط جديد: اقرأ RECIPE-VARIANTS.md. استخدم recipeForMeal(planId) للوصفة المثبتة؛ RecipeRepository وحده لا يحل النسخ الشخصية أو القديمة.

> تحديث12أكتوبر: نواة الغذاء والأشخاص وبنوك المصادر نُفذت الآن؛ اقرأFOOD-DATA-ARCHITECTURE.md وHANDOFF§15–16. نتائج التحقق الأقدم أدناه تاريخية.

# طبقة المنطق — دليل الربط للواجهات

المصدر الوحيد للعمل: `E:\work\SOFRA\app`، والمرجع `origin/main`. هذه الدفعة تكمل المنطق؛ تصميم المشاهد الجديد يتم في مكان آخر. التعديلات المرئية هنا مقتصرة على طلبات المستخدم: النوع والطرحة، البلد والصياغة، نقل بيتي، والتقويم واختيار شراء جديد.

## خريطة الملفات

| الملف | الوظيفة |
|---|---|
| `lib/domain/recipe_catalog.dart` | نموذج الوصفة الكاملة، تعديل المقادير والوقت وجدول الخطوات؛ مطابق لمكتبة TypeScript المصححة |
| `lib/data/recipe_repository.dart` | تحميل فهرس وملفات JSON المضمّنة، بحث عربي وفلاتر وتحميل كسول وكاش وإعادة المحاولة عند فشل القراءة |
| `lib/domain/kitchen_core.dart` | أفراد البيت والمقاعد، مخزون بكمية معلومة/مجهولة، عبوات ووحدات وتحويلات، تخطيط يوم/أسبوع/شهر وبواقي وميزانيات |
| `lib/domain/market_profile.dart` | مصر/السعودية، الصياغة والعملة والسعر الخاص بالبلد |
| `lib/data/kitchen_service.dart` | مالك الحالة، حفظ عبر StateStore الحالي، تخطيط وشراء وأسعار وميزانية وطبخ مرة واحدة وسجل ومؤقّت |
| `lib/domain/cooking_timer.dart` | مؤقّت قابل للحفظ، يحسب الوقت الحقيقي بعد الخلفية/الإغلاق، ويدعم الإيقاف والاستئناف والانتظار اليدوي |
| `test/backend_test.dart` | اختبار المكتبة الحقيقية والحفظ والمخزون والمقاعد والمال والمؤقّت والتطابق بين اللغتين |
| `tool/recipes/export-dart-fixtures.mjs` | إعادة توليد 216 حالة مرجعية من TypeScript عند تغيير المكتبة |
| `docs/MONEY-RULES.md` | القرارات المالية الستة التي أجاب عنها المستخدم والحدود المؤجلة |

`pubspec.yaml` يضمّن `recipes/data/` دون صور أو مكتبات جديدة. مخزون Flutter القديم ومحركه ما زالا يعملان، مع حماية جديدة من الخصم الجزئي أو التقدير القديم أو احتساب المكوّن المكرر مرتين. حفظ التأكيد القديم أصبح يحتوي سجلًا ثابتًا للطبخ.

## بدء الربط

```dart
final recipes = RecipeRepository();
final kitchen = KitchenService(
  store, // LocalStateStore أو CloudStateStore الخاص بحساب المستخدم الحالي
  recipes,
  legacyUnits: {for (final e in demoIngredients.entries) e.key: e.value.unit},
);
await kitchen.load();
final matches = await recipes.search(query: 'كشري', cuisine: 'مصري');
final recipe = await recipes.get(matches.first['id'] as String);
final scaled = recipe.forServings(1);
final steps = scaled.schedule;
```

- استخدم `KitchenService` مالكًا واحدًا للحالة في الواجهة الجديدة. لا تشغّله مع كاتب واجهة Flutter القديمة على نفس الحالة في الوقت نفسه؛ المنطقان ليسا مزامنة ثنائية للمخزون.
- بياناته تحت `kitchen` داخل مستند الحالة الحالي، بإصدار داخلي `version:1`. يحتفظ بمفاتيح الجذر القديمة و`schema:1`، لذلك لا يتطلب تغيير قواعد Firebase. البلد يُحفظ في الجذر والامتداد معًا.
- ترحيل مخزون النسخة القديمة يتطلب `legacyUnits` الصريح؛ إذا جُهلت الوحدة يفشل التحميل بدل إسقاط المكوّن أو تخمينها. لا تمسح بيانات الحساب عند خطأ تحميل أو تعارض نسخة.
- `snapshot` نسخة مستقلة؛ لتعديل الحالة استخدم أساليب الخدمة وانتظر Future. أي فشل حفظ يبقي الحالة السابقة، والكتابات مرتبة. تعارض Firestore يُعرض ويُعالج بإعادة التحميل؛ لا يوجد دمج تلقائي بين الأجهزة.

## الوحدات والمخزون

```dart
final pack = StockPurchase(count: 2, content: 5, unit: 'kg');
await kitchen.addStock(
  InventoryLot(id: 'lot-unique', ingredientId: 'rice', quantity: pack.quantity,
    unit: pack.unit, zone: StorageZone.pantry),
  newPurchase: true, paid: 400, purchasedAt: DateTime.now(),
);
```

- `newPurchase:false` للموجود من قبل؛ لا يسجل مصروفًا. `true` يتطلب مبلغًا وتاريخًا، ويسجل الشراء والمخزون في حفظ واحد.
- `quantity:null` يعني كمية غير محددة، ولا يعد كمية متاحة للخصم.
- التحويل التلقائي: جرام↔كيلو ومل↔لتر أو الوحدة نفسها. الحبات والكوب والحزمة لا تتحول لوزن بالتخمين.
- القياس الصريح مثل `UnitRule('rice','كوب','g',200)` يخص هذا المكوّن فقط، ويجب أن يأتي من إدخال المستخدم أو بيانات قياس موثوقة؛ المثال برمجي وليس وزنًا عامًا للكوب.
- `assessStock` يوزّع كل الاحتياجات على الدفعات معًا، ويحفظ الأصل. `missing` و`unresolved` تشرح النواقص والوحدات التي تحتاج مراجعة.
- التعديل على الكمية لا ينشئ عملية شراء. البواقي لها حصص وتاريخ، و`consumeLeftover` لا يعيد خصم المكونات أو تسجيل مصروف شراء.

## التقويم والطبخ

```dart
await kitchen.plan(PlannedMeal(
  id: 'meal-unique', date: '2026-10-12', slot: 'lunch',
  recipeId: 'eg-koshari', servings: 1,
));
final week = kitchen.calendar(DateTime(2026, 10, 12), CalendarMode.week);
```

- التاريخ محلي بصيغة YYYY-MM-DD؛ الأيام غير الصحيحة مرفوضة. الأسبوع يبدأ الاثنين، والشهر يحترم حدوده، بما فيها ديسمبر/يناير. نطاق النهاية غير شامل.
- `slot` مفتوح: breakfast/lunch/dinner أو وجبة إضافية. يمكن تسجيل أكثر من طبق لنفس اليوم والوجبة. التخطيط لا يخصم أو يسجل مصروفًا.
- `confirmCooking(planId,operationId)` يشتق المقادير من الوصفة، ويعيد فحص المخزون الحالي؛ يرفض النقص أو وحدات لا يمكن تحويلها.
- المكوّن غير المقاس يتطلب قياسًا صريحًا في `measuredUses` أو إقرارًا بعدم خصمه في `omitUnmeasured`. الاختياري لا يُخصم إلا عند اختياره في `optionalIds`.
- أنشئ operationId مرة واحدة لكل تأكيد واحتفظ به لإعادة المحاولة. تكرار نفس العملية، حتى بالتزامن أو بعد إعادة الفتح، يرجع السجل نفسه؛ محاولة طبخ خطة مكتملة بعملية جديدة مرفوضة.
- المخزون والسجل وحالة الخطة تحفظ معًا. السجل يجمد المقادير والسعر المعروف والعملة والبلد ووقت التأكيد؛ السعر المجهول يبقى `null` مع قائمة بالمكونات غير المسعرة، ولا يتحول إلى صفر.

## المال والأشخاص والمؤقّت

- `savePrice(...userOverride:true)` له أولوية على المتوسط؛ لا تُنقل أسعار مصر إلى السعودية ولا يُستخدم تحويل عملة مخمّن. `estimatedCost` قد يرجع null؛ لا تعرض تقديرًا ناقصًا باعتباره ميزانية مؤكدة.
- `saveBudget` ينشئ ميزانية الفترة بقيمة صريحة، و`budgetSummary(...plannedPurchases:...)` يفصل المصروف الفعلي عن الشراء المخطط والتجاوز. لا يغيّر خطة الوجبات ولا يرحّل الباقي تلقائيًا.
- `HouseholdMember` يمنع طرحة مع ذكر. ترتيب الإضافة يبقى ثابتًا، وتعديل عضو لا يغيّر كرسيه. `swapSeats` و`removeMember` يدعمان الكرسي الفارغ. شخص واحد صالح، مع ثلاثة مقاعد للمشهد كما اتُفق.
- الحساسية والملاحظة الصحية والتفضيلات بيانات لكل شخص؛ ليست خوارزمية توصية طبية أو ضمان سلامة. لم تُبن استنتاجات غذائية من نصوص حرة.
- مؤقّت: `CookingTimer(durations: seconds).start(now)` ثم `saveTimer(id,timer)` و`timer(id,now)`. `pause` و`start` للاستئناف، و`advance` للخطوة التالية. الخطوة ذات مدة صفر انتظار يدوي خارج جلسة الطبخ؛ لا تُعدّ منتهية تلقائيًا. لا أصوات أو إشعارات OS أو خدمة خلفية أُضيفت.

## حدود الدفعة والتحقق

الطبقة الجديدة جاهزة لربط التصميم الخارجي. شاشة وصفات Flutter القديمة ما زالت بعينات demo، ونموذج HTML يعرض ثلاث وصفات مثال؛ لم نعد تصميمها أو نستبدلها بكتالوج جديد بصريًا. الـ54 وصفة متاحة بالفعل من API والأصول، واختُبرت كاملة.

نجح Flutter analyze، و23 اختبارًا، وبناء الويب بالإعدادات الحالية. مرجع TypeScript/Dart يفحص المقادير ونصوصها ومدد الخطوات في 216 حالة. اختبارات المتصفح الحالية والسابقة نجحت على 412 و360 بلا أخطاء JS.

لم يُبن APK أو يُنشر Hosting أو تُعدّل خدمات Firebase بهذه الدفعة. مصادر الأسعار الفعلية وتوليد خطة شهر والبدائل وسكان الكاميرا والفواتير مؤجلة. نواة التغذية والبنك الحقيقي متاحان الآن بدليلFOOD-DATA-ARCHITECTURE؛ ربط الوصفات والملصقات المعتمد يحتاج مراجعة، ولا قيم مفترضة.


## Recipe source proposals —13October2026

See RECIPE-REFERENCES.md for the implemented `RecipeReferenceRepository`, explicit generic acceptance/choices, atomic `KitchenService.applyRecipeReferences`, source freshness guards and `previewIngredientNutrition`. Ingredient-input estimates remain separate from conservative cooked nutrition and person intake.197 identity proposals/53 recipes are not197 verified nutrition bindings. Legacy UI and previous APK do not consume these APIs automatically. The older23-test/build statement above is historical; latest actual gates are recorded in STATUS/HANDOFF§22.


## Accepted source measures and actual cooking quantities

See docs/HOUSEHOLD-MEASURES.md. KitchenService.acceptRecipeHouseholdMeasure saves explicit exact-revision/line source estimates with immutable evidence after async race checks. confirmCooking(actualUsesByLine: ...) accepts actual amounts for numeric/count lines as well; acknowledgeSourceMeasureEstimates is required only for source estimates actually used. The same resolved amount drives stock/cost/nutrition. History freezes quantity evidence/confidence and once-only deduction. Source measures do not make prepared nutrition complete; no UI/Firebase migration/APK integration in this unit.


## Compound line revision API

KitchenService.splitRecipeIngredient creates a new reviewed personal revision with2+explicit quantified components, exact parent stamp and no inherited food selections. See COMPOUND-REVISIONS.md for contract and retry semantics. Preparation evidence index is separate in PREPARATION-EVIDENCE.md; no approved transforms yet.


## Explicit single ingredient choice API

[RECIPE-INGREDIENT-CHOICES.md](RECIPE-INGREDIENT-CHOICES.md): KitchenService.chooseRecipeIngredient creates one caller-reviewed quantified replacement as a new personal revision. Source/full snapshot/region/method and complete expected recipe guarded;old plans/history frozen,no inherited nutrition bindings.7newtests/full107Fluttertests/analyzeclean. Research source promotion and private from-scratch creation remain separate.

## Structural adapter checkpoint

[Runtime candidate contract](RECIPE-RUNTIME-ADAPTER.md): explicit complete source drafts/metadata become CatalogRecipe-shaped candidates with full source/licence/line maps and remaining gates.44linkedNode+1actualFlutterreader/scalingpassed;analyzeclean. Transport validation rebuilds against currentauthoritativeinputs. No KitchenService import/nutritionapproval yet;next native provenance reader/immutable registration. OFF2287/64(+21/1),5banktestspassed;Saudi503gate23:49:13.371Z. HANDOFF§56.

## Native source import checkpoint

[Native import API/compatibility](NATIVE-RECIPE-IMPORT.md) now verifies exactUTF8 transport/source envelope and persists selectedreviewed roots atomically through KitchenService.importSourceRecipe. Full142Flutter+1additionalnutritionbinding/46Node/analyzeclean;no actualsourcebankpromotion/UI/usercloudwrites/automaticnutritionbindings. Quantity/import infrastructuredone;scientificcoverage remainsopen,preparation30next,privateauthoring34unblocked. OFF2378/67(+91/3),5actualbanktests;sourcegates incheckpoint. HANDOFF§58.


## Explicit category preparation acceptance —14 October2026

See [PREPARATION-ACCEPTANCE.md](PREPARATION-ACCEPTANCE.md). PreparationCategoryRepository verifies the exact generic USDA168927/asSold/version snapshot, LF-normalized whole-shard SHA, pinned review/source and selected candidate rows. Explicit actual method0381 or0382 acknowledgement creates an estimated transform with3vitamins only,46missing factors/nullmassYield/edibleFraction and unknown source-specific licence. It is a category inference, not exact-food/legal/finished-recipe approval.

KitchenService.acceptRecipePreparationEstimate freezes exact recipe/revision/line scope, checks stale async plan/binding and atomic failure/retry, and requires explicit replacement rather than layering methods. confirmCooking(acknowledgePreparationEstimates:true) is required only for included accepted-estimate lines, even with actual weighed grams. History stores estimatedPreparationLines/preparationEstimateEvidence and confidence; stock deduction remains once-only, no person intake. Input-only preview remains before cooking. No UI/Firebase/APK integration. Full155Flutter+6sourceNodepassed,analyzeclean;scientificcoverage staysopen. HANDOFF§59.


## Personal from-scratch drafts —14October2026

[PERSONAL-RECIPE-DRAFTS.md](PERSONAL-RECIPE-DRAFTS.md): owned explicit food/quantity/form/optional/scaling/estimate inputs with unknown cuisine/time/food/amount. KitchenService saves immutable reviewed versions/active pointers without a CatalogRecipe parent, exact expectedActiveKey, same-key collision protection, idempotent older retries and failed-save/850KB rollback. Typed sorted-object fingerprint survives storage map reordering. Separate ingredient/cooked previews use existing calculator. No automatic planning, stock or intake; accepted preparation scoped to another recipe cannot be copied. Full171Flutter/analyzeclean,8domain+8persistence cases. Finalization into a plannable recipe remains next under authoring34; do not invent metadata zeros or a parent. HANDOFF§60.
