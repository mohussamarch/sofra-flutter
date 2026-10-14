# محرك الوصفات القابل للتخصيص

13 أكتوبر2026. الهدف الذي حدده المستخدم: بنك وصفات كبير ومتعدد المطابخ، مع تنظيم يسمح لاحقًا بإنشاء وصفة شخصية وتعديلها وحساب تغذيتها من مكوناتها. نسخة العمل الوحيدة `E:\work\SOFRA\app`.

## الفصل الأساسي

**الوصفة تعليمات ومقادير؛ الغذاء مرجع حساب مستقل.** اسم «مكرونة بالبشاميل» لا يحمل رقم بروتين واحدًا ثابتًا. تغيير اللبن أو اللحمة أو الكميات أو الإضافات يغيّر الحساب. بيانات المطابخ تساعد البحث والتخصيص ولا تحدد المغذيات أو البلد/العملة تلقائيًا.

| الطبقة | وظيفتها | الحالة |
|---|---|---|
| بنك المصدر | وصفة أصلية، مؤلف/رخصة، رابط وإصدار، خطوات ومقادير كما نشرها المصدر وتصنيفاته | بحث6مرشحات موجود؛ جمع بالجملة من Wikibooks يجري في مسار مستقل |
| الوصفة المنظمة | عائلة ونسخة كاملة وسطور مكونات واختيارات ووحدات وخطوات | `CatalogRecipe/RecipeRevision/RecipeBook` منفذة؛ المصدر غير المكتمل لا يُرقّى تلقائيًا |
| الغذاء المرجعي | منتج/غذاء وإصدار وحالة وأساس قياس و49مغذيًا ودليل | `FoodRecord` والبنوك وقارئاتها منفذة، مع فجوات مراجعة معلنة |
| محرك الحساب | كميات × قيم المصدر × معاملات التحضير إن وُجدت؛ نواقص مستقلة لكل مغذٍ | `calculateRecipeNutrition` منفذ ويقبل مدخلات وصفة يحددها المستدعي |
| تخصيص وصفة قائمة | تعديل إصدار كامل دون تغيير الأصل أو التاريخ؛ مراجعة روابط السطور الجديدة | `RecipeRevisionKind.personal` و`saveRecipeRevision` موجودان ويشترطان أصلًا |
| وصفة جديدة من الصفر | مسودة يملكها المستخدم، أوقات اختيارية، ثم نشر إصدار خاص قابل للطبخ | **لم تُنفّذ بعد**. يلزم عقد مسودة وتوسعة حفظ مدروسة؛ لا الادعاء بأن APIالوصفة الشخصية الحالي يقبل وصفة بلا أصل |

## تدفق «وصفتي» المستهدف

1. إنشاء مسودة خاصة بعنوان وعدد حصص ومطبخ اختياري؛ لا اشتراط مصر/السعودية لتصنيف الوصفة. بلد المستخدم يظل مرجع العملة واللغة والسوق فقط.
2. إضافة سطور مكونات وكميات ووحدات. لكل سطر هوية مستقرة؛ الاسم للعرض، وربطه بالغذاء منفصل. البدائل والاختياري والمركبات لا تُخفى في اسم واحد.
3. اختيار الغذاء الفعلي أو المنتج/الباركود ومراجعة حالته: نيئ/مطبوخ/كما يُباع. اقتراح الاسم مجرد اقتراح؛ بعد اختيار مرجع مناسب، إعادة الحساب تلقائيًا عند تغيير الكمية أمر حسابي آمن.
4. حساب نتيجة أولية فور اكتمال أي مساهمة. المكون المجهول أو الوحدة غير المحسومة يظهر كنقص؛ لا يخفي بقية المجموع المعروف ولا يعطي رقمًا مكتملًا كاذبًا.
5. اختيار قياسات منزلية أو وزن فعلي وتحديد طريقة التحضير. لا افتراض وزن الكوب/الحبة أو احتفاظ100٪ لكل مغذٍ. الوزن الناتج بعد الطبخ مطلوب فقط لحساب كل100جرام أو توزيع حصة بالجرام.
6. حفظ إصدار خاص كامل مع روابط الغذاء والقياسات وأدلتها. تعديل الوصفة لاحقًا ينشئ إصدارًا جديدًا ويعيد الحساب؛ الطبخ السابق يبقى ثابتًا.
7. التخطيط يحجز اختيارًا وإصدارًا وعدد حصص دون خصم. التأكيد يخصم مرة واحدة ويثبت التكلفة والتغذية. توزيع المأكول على الأشخاص والبواقي حدث صريح لاحق.

## عقد المسودة المقترح — تنظيم للمستقبل، ليس APIحاليًا

| الحقول | القاعدة |
|---|---|
| `draftId/ownerId/revision/title` | ملكية وهوية وإصدارات مستقلة؛ الخصوصية افتراضية، مشاركة الوصفات قرار منفصل |
| `familyId/parentRevisionKey` | اختياريان للمسودة الجديدة؛ يصبح الأصل صريحًا عند الاشتقاق، لا إنشاء أصل وهمي |
| `cuisineTags/sourceCuisineTags` | تصنيف تحريري منفصل عن تصنيفات المصدر الأصلية؛ مصدر كل تصنيف وثقة المطابقة محفوظان |
| `ingredients[].lineId/name/amount/unit/form/optional/choiceGroup` | كمية أو مجهول، وحدات مصدر أو وحدات معتمدة؛ روابط الغذاء حسب إصدار المسودة والسطر |
| `steps[].id/text/durationMinutes/timingPolicy` | وقت مجهول يظلnull؛ الفرن والحرارة والانتظار لا تتضاعف لمجرد زيادة الحصص |
| `source/sourceRevision/license/attribution/changeNotice` | أصل الوصفة ومراجعاتها؛ وصفة المستخدم تختلف عن تعديل محتوى CC BY-SA، فلا تفقد شروط المصدر |
| `foodSelections/measurementEvidence/preparationEvidence` | مراجع بإصدارات ثابتة وأدلة مستقلة؛ لا نسخ روابط غذاء من وصفة شبيهة بلا مراجعة |
| `nutritionPreview` | نتيجة مشتقة قابلة لإعادة الحساب، ليست المصدر الوحيد للحقيقة ولا بديلًا عن المكونات |

لا نضيف المسودة إلى مستند Firestore الحالي قبل تحديد نسختها، حدود حجمها وترحيلها واختبارات الحفظ. حد850KB وسجل الطبخ يتطلبان خطة أرشفة؛ لا قواعدFirebase أوفوترة تغيرت.

## درجة الثقة جزء من المحرك

- اكتمال المغذي وكونه تقديريًا محوران منفصلان. قد يكون المجموع مكتمل التغطية لكنه يعتمد على وزن مصدر أو تقدير تحضير.
- `NutrientTotal.estimated` ينتقل عبر `nutritionMealBatch` إلى `PersonNutrientValue.estimated` وتقرير الشخص. القيمة true تعني وجود مساهمة تقديرية؛false تعني عدم تعليم المساهمات المعروفة كتقديرية، وليست شهادة تحليل معملي؛null يحفظ ثقة التاريخ القديم غير المسجلة.
- التصحيحات لا تعيد كتابة التغذية أو السعر المؤكد؛ لا إعادة تقدير تاريخي صامت. الفجوات العلمية تظل ظاهرة مهما كبر بنك الوصفات.
- عرض المستخدم الأساسي ثابت: السعرات، البروتين، السكريات، الألياف، الدهون الكلية مرة واحدة؛ التخزين49مغذيًا.

## الخطوة التنفيذية التالية

الجمع بالجملة أولًا حسب توجيه المستخدم، وفصل الصفحات الخام عن المرشحات المنظمة والإصدارات الجاهزة. ثم بنك مرادفات/وحدات واختيارات ومراجعة مصدر وتحضير لكل سطر، ومستورد يحفظ provenance ولا يملأ الأوقات المجهولة0. بعده عقد مسودة من الصفر وحفظ إصداراتها واختبارات تغيير الحصص/المكونات/الثقة والتاريخ. لا نقل تلقائي لكل وصفة مجمعة إلى واجهة المستخدم أو الادعاء بأن تغذيتها جاهزة.

[الخريطة الحالية](DATA-MAP.md) · [صيغة بنك البحث](RECIPE-BANK.md) · [الهيكل الغذائي](FOOD-DATA-ARCHITECTURE.md) · [الإصدارات](RECIPE-VARIANTS.md) · [API](BACKEND-API.md)

## لقطة تنفيذ الجمع والثقة

2312 وصفة مشتقة من2428صفحة مصدر،52 تصنيف مصدر في بنك مستقل. [RECIPE-BULK.md](RECIPE-BULK.md) يحدد البيانات والفحوص. لا استيرادruntimeأو اكتمال تغذية. الثقة تصل لسجل وتقرير الشخص،واختباراتFlutterالكاملة100مرت. مرشحات كميات صريحة10227/20277بدون اعتماد حسابي؛التالي مجموعات/اختيارات وربط الغذاء ثم مستورد وإصدارات ومسودة خاصة من الصفر؛التصميم خارج هذا العمل.

## Ingredient structure checkpoint

`wikibooks-sections-v3` preserves nested ingredient headings as `ingredientRows[].sourceGroupPath`: original heading, cleaned title, depth and original extracted line index. Sibling/repeated root sections reset their scope. Derived recipes retain this path per ingredient via `sourceStructure`.

`source-structure-v1` records first lexical `or`, `optional/optionally`, and `to taste/as needed/as required` cues with source text offsets. These are review cues only, not asserted substitutes, selections or clinical exclusions. `or more` may be a quantity phrase: no automatic split. `alternatives/selectedAlternative/optional` stay null; absent cues do not mean required or safe. Group path null means unavailable extraction; [] means no nested heading observed. Original source revision/hash remains attached.

Actual current coverage: 4173 rows with source headings, 1806 with or cues, 737 optional cues, 838 quantity qualifiers. 11194/22394 quantity prefixes remain unreviewed candidates. Corpus 2554/2676/52;0runtime imports/nutrition approvals.48 recipe Node tests passed;7 new behavioral tests failed before implementation then passed. Source hashes and original raw prefix checked. No runtime/Flutter/UI changes.

Next: explicit review tied to recipe revision/line and ingredient identity, then choice application and unknown-aware import. Source cues never automatically exclude ingredients from nutrition or sum every alternative. Recipe-source collection continues only after its own checkpoint gate.


## Quantity parser v2 checkpoint

Current `source-prefix-v2` supports adjacent explicit units (`200g`, `250ml`) and leading decimals (`.5 cup`), with an explicit token boundary: `garlic`, `cupful`, `g3` and ratios such as `g/100g` are not accepted units. Fractions/known aliases remain supported. Every parsed/unresolved candidate now carries its parser version. No count/package inference, canonical mass, food identity or cup/spoon-system conversion is added.

On the same2676-page/2554-recipe corpus (22394 ingredient rows), v1 produced11189 candidates; v2 produces11194:7 newly parsed and2 no longer parsed under stricter token boundaries. This is transcription coverage, not nutrient coverage.48recipe tests passed:19collector/10index/9quantity/10research contract;2additional quantity tests first failed then passed. Older v1 limitation notes above are historical. No runtime/Flutter/UI changes.


## Explicit single ingredient choice API

[RECIPE-INGREDIENT-CHOICES.md](RECIPE-INGREDIENT-CHOICES.md): KitchenService.chooseRecipeIngredient creates one caller-reviewed quantified replacement as a new personal revision. Source/full snapshot/region/method and complete expected recipe guarded;old plans/history frozen,no inherited nutrition bindings.7newtests/full107Fluttertests/analyzeclean. Research source promotion and private from-scratch creation remain separate.

## Import-draft audit checkpoint

[Source import-draft preflight](RECIPE-IMPORT-PREFLIGHT.md) now reports explicit exact-line quantity/form/choice/optional/reference/time review.29linked tests passed; English blank-template baseline3640/31774/24964,0runtime. A complete draft is not a nutrition or runtime approval. Next registered reviewed draft persistence and adapter gates; no UI/state/import changes. HANDOFF§54.

Registered source-draft continuation: [preflight/registry contract](RECIPE-IMPORT-PREFLIGHT.md);1explicit persisted blank draft/9lines/50issues/0complete/0runtime,36linkedtests passed. Exactnext: source-to-runtime adapter with required metadata/provenance and unresolved nutrition/form/retention gates. HANDOFF§55; no auto-discovery or guessed data.

## Structural adapter checkpoint

[Runtime candidate contract](RECIPE-RUNTIME-ADAPTER.md): explicit complete source drafts/metadata become CatalogRecipe-shaped candidates with full source/licence/line maps and remaining gates.44linkedNode+1actualFlutterreader/scalingpassed;analyzeclean. Transport validation rebuilds against currentauthoritativeinputs. No KitchenService import/nutritionapproval yet;next native provenance reader/immutable registration. OFF2287/64(+21/1),5banktestspassed;Saudi503gate23:49:13.371Z. HANDOFF§56.

## Native source import checkpoint

[Native import API/compatibility](NATIVE-RECIPE-IMPORT.md) now verifies exactUTF8 transport/source envelope and persists selectedreviewed roots atomically through KitchenService.importSourceRecipe. Full142Flutter+1additionalnutritionbinding/46Node/analyzeclean;no actualsourcebankpromotion/UI/usercloudwrites/automaticnutritionbindings. Quantity/import infrastructuredone;scientificcoverage remainsopen,preparation30next,privateauthoring34unblocked. OFF2378/67(+91/3),5actualbanktests;sourcegates incheckpoint. HANDOFF§58.


## Explicit category preparation acceptance —14 October2026

See [PREPARATION-ACCEPTANCE.md](PREPARATION-ACCEPTANCE.md). PreparationCategoryRepository verifies the exact generic USDA168927/asSold/version snapshot, LF-normalized whole-shard SHA, pinned review/source and selected candidate rows. Explicit actual method0381 or0382 acknowledgement creates an estimated transform with3vitamins only,46missing factors/nullmassYield/edibleFraction and unknown source-specific licence. It is a category inference, not exact-food/legal/finished-recipe approval.

KitchenService.acceptRecipePreparationEstimate freezes exact recipe/revision/line scope, checks stale async plan/binding and atomic failure/retry, and requires explicit replacement rather than layering methods. confirmCooking(acknowledgePreparationEstimates:true) is required only for included accepted-estimate lines, even with actual weighed grams. History stores estimatedPreparationLines/preparationEstimateEvidence and confidence; stock deduction remains once-only, no person intake. Input-only preview remains before cooking. No UI/Firebase/APK integration. Full155Flutter+6sourceNodepassed,analyzeclean;scientificcoverage staysopen. HANDOFF§59.


## Personal from-scratch drafts —14October2026

[PERSONAL-RECIPE-DRAFTS.md](PERSONAL-RECIPE-DRAFTS.md): owned explicit food/quantity/form/optional/scaling/estimate inputs with unknown cuisine/time/food/amount. KitchenService saves immutable reviewed versions/active pointers without a CatalogRecipe parent, exact expectedActiveKey, same-key collision protection, idempotent older retries and failed-save/850KB rollback. Typed sorted-object fingerprint survives storage map reordering. Separate ingredient/cooked previews use existing calculator. No automatic planning, stock or intake; accepted preparation scoped to another recipe cannot be copied. Full171Flutter/analyzeclean,8domain+8persistence cases. Finalization into a plannable recipe remains next under authoring34; do not invent metadata zeros or a parent. HANDOFF§60.
