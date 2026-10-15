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


## Reviewed draft publication —14October2026

[PERSONAL-RECIPE-PUBLICATION.md](PERSONAL-RECIPE-PUBLICATION.md) supersedes the earlier unimplemented bridge checkpoint. PersonalRecipeFinalization owns the full draft, explicit metadata/durations/inventory IDs/review and canonical derived IDs. KitchenService.finalizePersonalRecipe publishes an authored root and exact food selections atomically from the saved active draft, with expected active recipe guard and immutable retries. Existing planning/cooking now works; no fake parent, stock/intake on publication, UI/cloud activation or automatic scientific approval. Missing metadata, unsupported estimated quantities and base precision loss reject; unknown food remains unknown. Full183Flutter/analyzeclean. Older clients do not support authored kind. HANDOFF§61.

## Price research boundary

tool/prices/price-observations.mjs is an offline research calculator, not a production KitchenService price provider.34observations retain source/kind/date/pack/uncertainty but0runtime-approved prices. PRICE-SOURCES-EG-SA.md defines required source permission, exact item/city/store and freshness before integration. User overrides and frozen purchase/cooking history remain unchanged. AR/DE source candidates likewise require registered reader/review/import, not direct runtime JSON.

## Purchase forecast and readable Arabic recipe library —14October2026

`KitchenService.previewPurchases(planIds, rules:, optionalLinesByPlan:, measuredByPlan:)` computes unfinished pinned/scaled plans against one shared inventory snapshot. Returns `PurchaseForecast`: purchaseTotal versus consumptionTotal, known subtotals and unresolved/unpriced sets. User prices outrank country averages; unknown quantities/incompatible relevant stock block complete totals. Explicit optional/measured line decisions; stale state rejects. No writes/reservations/history changes. Example400gneeded/250gstock/60perkg =>9purchase,24consumption.18focused tests plus full integration gate. No package rounding/monthly solver/current price feed inferred.

`bundledRecipeLibrary()` and `RecipeLibraryRepository` expose22Arabic readable source records with nullable amounts, preserved raw status/time/yield/licence and pinned source envelopes. `all/search/filterByCuisine/familyCandidates` are read-only; no CatalogRecipe planning or nutrient promotion. See RECIPE-LIBRARY.md for fields/assets/remaining gates. FEATURE-STATUS.md separates backend work from mobile UI availability.

##14October — market-first source correction

Latest user priority: real retailer and delivery-app prices first; government sources are secondary, no waiting for government exports. See MARKET-PRICE-INTEGRATIONS.md, new official-source EG/SA dossiers, and offline partner-catalog-candidates.mjs (8tests). Talabat/HungerStation partner scope is own chain/vendor; Salla/Zid can read consenting merchant catalogs. No live feed or reuse permission acquired. GASTATJuly2026 workbook/100food rows saved as raw source checkpoint only; no normalized/livepricebank/currency approval. Arabiccreatorsecondbatch adds2website recipes with explicit source omissions;22bundled readable entries unchanged, nextassetintegration separate.

## Library-to-calculator persistence — current §71

Readable library now31records/5pinnedpacks/20source snapshots. `RecipeLibraryDraftReview.create` requires a current full source pin, explicit caller servings and every line's food/quantity/form/selection/scaling decision. `KitchenService.saveLibraryRecipeDraft(review,library:,acknowledgeInputsReviewed:,reviewNote:,reviewedAt:,expectedActiveKey:)` stores complete librarySource plus draft atomically; `libraryRecipeDraftReview(id,revisionKey:)` retrieves provenance. Reload/source drift/rollback/old retry/origin guards retain the evidence. `finalizePersonalRecipe` blocks library-origin drafts pending separate source-import approval; genuine from-scratch publication remains supported. No automatic nutrition or stock/plan writes. See LIBRARY-RECIPE-CALCULATOR.md. Full224Flutter/analyze clean10.6s,14bridge+persistence cases included; older gates above are historical.

## Current §72 integration

Readablelibrary44records/7packs/28snapshots. Library-source review now retains matching singularcreator metadata as well as scopedcreatorlists; canonicaldedup preserves distinct evidence. Storedold envelopes remain decodable; enrichedcurrentsourcefingerprint may require fresh review before save.225fullFlutter/analyze clean7.2s and17recipeNode verified. New data/food/allergen-evidence/20261014/official-evidence.json is research-only official vocabulary/semantics evidence:15proposals,0runtime aliases/product declarations/clinical or current-law approval. It is not a KitchenService allergen provider.

## Manufacturer label research API — §75

ProductLabelEvidenceRepository exposes all/search/byProposedAllergen; ManufacturerLabelObservation holds copied product/source/batch context and immutable contains/mayContain lists. It checks raw byteSHA then strict schema/source/status linkage. This is a research reader, not a KitchenService writer or product allergy approval. Contract PRODUCT-LABEL-EVIDENCE.md. Selected recipe library now55records/9packs/36snapshots; explicit private-calculator source/quantity review still applies.

## Read-only library quantity review — §76

`RecipeLibraryCoverageReport.fromEntries(await library.all())` returns immutable per-recipe/per-line source triage, indexed optional/excluded/procedural lines, raw quantity/unit gaps and existing recipeLibrarySourceFingerprint. `toJson()` gives owned copies. Duplicate input recipes reject. No automatic conversion, food binding, saved-personal-review inspection, write or runtime approval. Contract RECIPE-LIBRARY-COVERAGE.md; selected library now63/10packs/44snapshots. Full237Flutter/analyze clean verified after integration.

## Source request context compatibility — §77

RecipeLibraryDraftReview includes recipe-scoped sourceIndex request evidence when supplied by the pinned pack; original request indexes/outcomes are retained, unrelated URLs excluded, explicit missing/duplicate references rejected. Existing source fingerprints cover the subset. Old reviews remain readable; assertSource rejects reusing them against newly enriched evidence. This is consistency/provenance, not food/medical/rights approval. Library65/11packs/44snapshots; contracts LIBRARY-RECIPE-CALCULATOR.md and RECIPE-LIBRARY-COVERAGE.md.

## Unique quantity review count — §78

RecipeLibraryCoverageReport.quantityReviewLineCount and its additive JSON field count each indexed source line needing quantity review once, despite overlapping missing-amount/unit flags. Current592of669 lines; not nutrition/identity completion, and saved user reviews remain outside scope. No state writer or asset/source pin change.

## Current §79 — library ingredient food search and video source kind

`RecipeLibraryFoodSearch(foods: FoodRepository()).search(entry:, expectedSourceFingerprint:, lineIndex:, query:, market:, packagedOnly:, limit:)` returns RecipeLibraryFoodSearchResult. Nonempty caller query, exact supplied source pin and valid indexed line are required before bank reads. Result keeps recipeId/sourceFingerprint/lineIndex/ingredient/query/options, deep-owned candidate maps and toJson; requiresExplicitReview=true/runtimeApproved=false. Read candidates, choose food/form/amount explicitly via existing FoodRepository.usdaFood/packagedFood and RecipeLibraryLineDecision; save the complete private review. No automatic name matching, translation, quantity conversion, market proof, nutrition or state write. Market filters packaged products; genericUSDA results remain generic. Later save compares current library source; old search results cannot silently refresh pins.

Selected66records/12packs/44snapshots now include creator-youtube indexed video-description facts alongside creator-website/archive. Canonical sourceVideoId/URL and youtubeDerived are checked; original access failures/title/rights unknowns remain in source record. Website legacy omission is readable, explicit conflicting derivation rejects.247fullFlutter/31relatedNode passed; detailed evidenceHANDOFF§79.

## Current §80 — explicit chosen USDA identity

RecipeLibraryFoodSearch.resolveUsdaCandidate(result:,currentEntry:,foodId:,form:,acknowledgeFoodIdentity:) checks explicitack/form andrecipeID/sourcepin, requiresuniquereturnedUSDAcandidate(no barcode), comparesindexname/versiontoloadedrawfood,thenusdaFood. It returnsFoodRecord forcallerreview, with no quantity/binding/save orsource/marketapproval. Callerobtainscurrententry; laterprivate-draftsave checks currentlibrary. FullcontractLIBRARY-FOOD-SELECTION.md. Version/nameconsistency isdistinctfromrawnutrientbyteintegrity. Currentlibrary70records/13packs/48snapshots;250fullFlutter/34Node/analyzeclean.

## Current §81 — explicit packaged candidate

`resolvePackagedCandidate(result:,currentEntry:,barcode:,market:,acknowledgeProductIdentity:,reviewedBasis:,reviewSource:)` extends the source-pinned search flow. Require explicit identity/market, matching scoped search market, recipe ID/pin and unique returned barcode. Before raw lookup, paired basis/source must refer to the exact barcode (`reviewSource.recordId`) and100g/ml. Compare the whole processed product row canonically before existingpackagedFood; key reordering is harmless, changed nutrients/markets/names/source require fresh review. Without basis review, unknown basis blocks quantitative calculation. No quantity/state write or local physical product/rights approval. See LIBRARY-FOOD-SELECTION.md; current78/14packs/56snapshots,254fullFlutter/33Node/analyze6.1s.


## Current §82

RecipeLibraryMassProposal.fromSource requires full source fingerprint, exact line and explicit acknowledgement of an existing positive numeric g/kg declaration. It preserves amount/unit/raw text without parsing or conversion. toDecision rechecks current recipe/source and applicable exclusion override; food/forms/inclusion/scaling/as-purchased/preparation remain explicit and quantityEstimated is always true. No measurement, food match, source approval or state write. Contract docs/LIBRARY-SOURCE-MASS.md. 84 readable source records =62 offline archive +21 creator website +1 indexed video description;15 pinned packs/62 snapshots,51 local source cuisine/region labels. Planning54/4 and reviewed method family1 unchanged;0 new runtime/nutrition approvals. Final258Flutter/27relatedNode/analyze clean; earlier counts are historical.


## Current §85

86 source records=62localarchive+21creatorwebsite+3indexedYTdescriptions;16packs/62snapshots,51local source labels. Planning54/4 unchanged. New read-only monthly explicit alternative comparison and runtime OFF contact/privacy guards;269Flutter/62Node/analyze clean. HANDOFF§85. `compareMonthlyBudgetChoices` compares only supplied matching date/slot coverage with stock once perwholeoption and frozen matching-periodspend. Unknown totals remainnull/unranked; no autosave/clinicalrules/fullmonthlygenerator. Contract MONTHLY-BUDGET-CHOICES.md. Pure API currently separate from KitchenService stale-snapshot adapter. OFF503sourcewait doesnotblocklocalcore.


## Current §86

88 readable source records=62localarchive+23creatorwebsite+3indexedYTdescriptions;17packs/62snapshots,51local source labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. KitchenService snapshot-safe monthly advisory adapter implemented;282fullFlutter/36relatedNode/analyze clean. HANDOFF§86. `KitchenService.previewMonthlyBudgetChoices(savedBudgetId, options:, rules:, optionalLinesByOption:, measuredByOption:)` resolves explicit unsaved PlannedMeal candidates using current/pinned revisions and existing serving/optional/measured review semantics. Owns nested inputs before await; same-country saved budget, current stock/frozen ledger/private user-first prices; full snapshot/current write-tail guard rejects intervening price/budget/stock/revision changes. Shared _purchasePreviewMeal preserves previous purchase-preview behavior. Returned candidateId is exact resolved revision.key. Read-only, no save/plan/stock/ledger/intake changes. Request a new preview after subsequent data changes; no stale acceptance API. Full automatic month generator/person targets/clinical suitability remain separate; next bounded explicit-candidate combination search.


## Current §87

90 readable source records=64localarchive+23creatorwebsite+3indexedYTdescriptions;18packs/64snapshots,53local source category labels. Planning54/4 and naanmethodfamily1 unchanged. Bounded explicit-candidate monthly search implemented;292fullFlutter/30relatedNode/analyze clean. HANDOFF§87. `searchMonthlyBudgetChoices` (lib/domain/monthly_budget_search.dart) consumes explicit reviewed MonthlyBudgetSlotPool candidates, month/frozen purchases/stock/rules and pure country/user-first pricing. Validates ALL candidates before callbacks, including unexamined; owns collections. Lazy deterministic odometer evaluates at most maxEvaluations whole combinations via unchanged comparator, exact BigInt total. Returns evaluated/truncated/unknown and bestKnownAffordable; capped OR unknown costs yield indeterminate. Exhaustive known negative is only noAffordableInSuppliedPools, not global infeasibility or clinical fitness. No partial-cost pruning, source approval, writes or automatic plan selection. KitchenService only compares caller-built whole options so far; a later search adapter must retain revision/line/snapshot guards.
