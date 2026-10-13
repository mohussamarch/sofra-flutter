# خريطة بيانات سُفرة — مدخل واحد

13 أكتوبر 2026. نسخة العمل: `E:\work\SOFRA\app`؛ المرجع `origin/main`.
هذه خريطة الكود والبنوك الموجودة، مع فصلها عن الروابط المقترحة والعمل المتبقي. لا تعني أن واجهة الهاتف تعرض كل هذا بالفعل.

## المسار من الوصفة إلى الشخص

```mermaid
flowchart TD
  Sources[مصدر ورخصة وتاريخ] --> Candidates[بنك وصفات بحثية]
  Candidates -. مراجعة ثم استيراد مستقبلي .-> Revision[عائلة وطريقة وإصدار وصفة ثابت]
  Catalog[دفتر الوصفات الحالي] --> Revision
  Revision --> Line[سطر مكون في إصدار محدد]
  Food[غذاء عام أو منتج بإصدار] --> Binding[ربط صريح للغذاء والكمية والتحضير]
  Line --> Binding
  Measures[قياس منزلي بمصدر أو وزن فعلي] --> Binding
  Preparation[دليل تحضير واحتفاظ لكل مغذ] --> Binding
  Revision --> Plan[وجبة مخططة بتاريخ وعدد حصص]
  Binding --> Nutrition[تقدير تغذية ونواقص وثقة]
  Plan --> Confirm[تأكيد الطبخ مرة واحدة]
  Nutrition --> Confirm
  Stock[دفعات مخزون وأسعار] --> Confirm
  Confirm --> Frozen[سجل ثابت وتكلفة ودفعة طعام]
  Frozen --> Events[أكل أو بواقي أو هدر صريح]
  Member[فرد البيت] --> Profile[ملف حساسية وتفضيلات وأهداف]
  Events --> Report[تقرير الشخص]
  Profile --> Report
  Profile --> Interaction[تنبيه أو احتفال للعارض]
```

الخط المتقطع مسار لم يُنفّذ بعد. بنك الوصفات البحثية لا يدخل الحساب أو مخزون المستخدم تلقائيًا.

## ملفات الهيكل الفعلي

| المجال | النماذج المنفذة | المصدر |
|---|---|---|
| الوصفة والكميات والخطوات | `CatalogRecipe`, `CatalogIngredient`, `CatalogStep`, `ScaledCatalogRecipe` | [recipe_catalog.dart](../lib/domain/recipe_catalog.dart)، و[types.ts](../recipes/src/types.ts) للمكتبة الأصلية |
| عائلات وطرق وإصدارات | `RecipeFamily`, `RecipeRevision`, `RecipeBook` | [recipe_variants.dart](../lib/domain/recipe_variants.dart)، [دليل الإصدارات](RECIPE-VARIANTS.md) |
| الغذاء والمغذيات والمصدر | `FoodRecord`, `FoodSource`, `NutrientProfile`, `FoodConversion`, `PreparationTransform` | [food_nutrition.dart](../lib/domain/food_nutrition.dart) |
| ربط الوصفة بالغذاء | `RecipeFoodSelection`, `IngredientNutritionEstimate` | [recipe_nutrition.dart](../lib/domain/recipe_nutrition.dart)، [دليل المراجع](RECIPE-REFERENCES.md) |
| المخزون والتخطيط والمال | `InventoryLot`, `StockPurchase`, `PlannedMeal`, `BudgetPeriod`, `MoneyEntry` | [kitchen_core.dart](../lib/domain/kitchen_core.dart)، [قرارات المال](MONEY-RULES.md) |
| البلد والعملة والصياغة | `MarketProfile` | [market_profile.dart](../lib/domain/market_profile.dart) |
| الشخص والحصص والتفاعل | `NutritionPersonProfile`, `NutrientTarget`, `MealBatch`, `NutritionEvent`, `NutritionLedger` | [person_nutrition.dart](../lib/domain/person_nutrition.dart) |
| الحفظ والتنسيق | `KitchenService` الكاتب الوحيد؛ `StateStore` محلي أو لحساب Firebase | [kitchen_service.dart](../lib/data/kitchen_service.dart)، [state_store.dart](../lib/data/state_store.dart)، [API](BACKEND-API.md) |

## مفاتيح الربط التي يجب الحفاظ عليها

| الرابط | المفتاح والقيد |
|---|---|
| عائلة ← طريقة ← إصدار | `familyId` ثم `variantId` و`revision`؛ `RecipeRevision.key` هو JSON للزوج `[variantId, revision]`. لا توريث حي أو استبدال محتوى إصدار قديم |
| خطة ← وصفة | `PlannedMeal.recipeId` و`recipeRevisionKey`؛ القراءة عبر `recipeForMeal(planId)` |
| سطر ← غذاء | `recipeId + recipeRevisionKey + line` مع لقطة `FoodRecord.id/version`؛ رقم السطر مهم لأن ingredientId قد يتكرر |
| مخزون ← استخدام | `InventoryLot.id/ingredientId` وكمية بوحدة قابلة للتحويل؛ اسم المكون لا يحدد ماركة الغذاء تلقائيًا |
| طبخ ← تاريخ | `operationId` يمنع الخصم المكرر، ويجمد الوصفة والكميات والسعر والتغذية؛ التخطيط وحده لا يخصم |
| شخص ← تغذية | `NutritionPersonProfile.memberId` يطابق `HouseholdMember.id`؛ لا إنشاء شخص آخر من شكل الشخصية |
| حصة ← دفعة وشخص | `NutritionEvent.batchId/personId`؛ `personId` يطابق فرد البيت، مع هوية حدث وتصحيح إلحاقي؛ الطبخ لا يسجل الأكل تلقائيًا |

## البنوك الحالية وحدودها

| البنك | مكانه | الوضع |
|---|---|---|
| الوصفات المستخدمة حاليًا | [recipes/data/index.json](../recipes/data/index.json) وملفات المطابخ الأربعة | 54 وصفة أصلية محفوظة؛ 605 أسطر مكونات. ليست كلها ذات تغذية مكتملة |
| وصفات جديدة من مصادر | [data/recipes/research-candidates.json](../data/recipes/research-candidates.json) | 6 مرشحات/61 سطرًا/46 خطوة من مجموعتي مصدر؛ بنك بحث منفصل،0 جاهزة لـruntime؛ صيغة وفحوص في [RECIPE-BANK.md](RECIPE-BANK.md) |
| الوصفات بالجملة | [الفهرس](../data/recipes/bulk/wikibooks-cookbook/index.json)،[مراجعة الهوية](RECIPE-IDENTITY-REVIEW.md) | 3640وصفة/3796صفحة/53تصنيف؛16اقتراحًا/22مرشحًا/5أغذية؛0runtime؛المصدر الحالي انتهى والتوسيع مستمر |
| USDA | [manifest](../data/usda/manifest.json) و32 ملفًا في `data/usda/shards` | 8156 مرجعًا عامًا؛ CC0، لا يمثل توافر المنتج في سوق معين |
| منتجات Open Food Facts | `data/food/openfoodfacts/`، [PRODUCT-DATA.md](PRODUCT-DATA.md) | 2266 منتجًا/63 أرشيفًا في آخر نقطة موثقة؛ مجتمع وغير مراجع، أساس القياس مجهول؛ ODbL/DbCL منفصل |
| تغطية ومقترحات هوية الوصفات | [recipe-coverage.json](../data/usda/recipe-coverage.json)، [RECIPE-REFERENCES.md](RECIPE-REFERENCES.md) | 197 مقترح هوية عبر53 وصفة؛ **0 ربط تغذية كامل معتمد**. قبول الهوية وحده لا يحل الوزن والتحضير |
| مقاييس منزلية | [household-measures-review.json](../data/nutrition/household-measures-review.json)، [HOUSEHOLD-MEASURES.md](HOUSEHOLD-MEASURES.md) | 36 غذاء/103 خيارات؛ قبول صريح حسب الغذاء وشكله والإصدار، و6 فجوات بلا خيار |
| التحضير | [retention-candidates.json](../data/nutrition/retention-candidates.json)، [PREPARATION-EVIDENCE.md](PREPARATION-EVIDENCE.md) | 9 مرشحات لـ3 طرق و3 فيتامينات؛ مراجعة فئتين للمكرونة في [preparation-category-review.json](../data/nutrition/preparation-category-review.json)، **0 تحويلات runtime معتمدة**؛ الوزن الناتج وبقية المعاملات مجهولة |

الأعداد لقطة تسليم وليست حدود اكتمال. المصدر والإصدار والترخيص وتاريخ الجمع وحالة المراجعة جزء من البيانات؛ لا نخزن المجهول صفرًا. نخزن49 مغذيًا، ونُظهر5: السعرات، البروتين، السكريات، الألياف، الدهون الكلية مرة واحدة.

## الموجود في الحفظ وما يزال مطلوبًا

- `KitchenService` يحفظ حالة المستخدم فقط عبر `StateStore`؛ مسار Firestore الحالي `users/{uid}/state/current`. البنوك الكبيرة أصول محلية ولا تُنسخ كاملة إلى هذا المستند. حد850KB يحتاج أرشفة تاريخ منفصلة لاحقًا.
- آليات الإصدار والربط والتأكيد والحصص موجودة. مراجعة كل وصفة وملصق، أدلة التحضير الكاملة، التغذية الجاهزة للأطباق، وإيصال هذه APIs بالواجهة الخارجية ما زالت غير مكتملة.
- بنك أسعار موثق، مخطط تلقائي متوازن، قواعد طبية مراجعة، كاميرا باركود وOCR فواتير، وأمان تخزين البواقي مراحل مستقلة؛ لا تُستنتج من الاسم أو البلد.
- أول عمل للوصفات الجديدة: مراجعة المصدر والترخيص، المقادير والمفردات والوحدات، مدد الخطوات وسياسة تغييرها مع الحصص، ثم استيراد إصدار كامل وربط كل سطر. وقت الفرن ودرجة الحرارة لا يصبحان مدة مؤكدة بمجرد استدعاء دالة scaling الحالية.

## بقية الوثائق

[الهيكل الغذائي المفصل](FOOD-DATA-ARCHITECTURE.md) · [ربط الواجهة](BACKEND-API.md) · [إصدارات الوصفات](RECIPE-VARIANTS.md) · [خطة البحث](RESEARCH-ROADMAP.md) · [قائمة العمل](WORK-QUEUE.json) · [الحالة](STATUS.md) · [التسليم](HANDOFF.md)

## French source expansion —16:56

| Source bank | Path | Coverage |
| --- | --- | --- |
| French Wikibooks research | [index](../data/recipes/bulk/fr-wikibooks-cuisine/index.json), [source contract](RECIPE-FRENCH-SOURCE.md) | 1218 source pages/838 parsed recipes/5849 ingredient lines/5319 steps; CC BY-SA4.0 policy, exceptions unreviewed;0runtime/nutrition approvals |

French language is not a cuisine tag. Source IDs/cursors remain separate; duplicates between English/French or dish families are not resolved. Personal recipe calculation still needs explicit food/quantity/form inputs; this research source does not automatically fill them.

## Additional identity curation

[first-review.json](../data/recipes/identity-proposals/first-review.json) plus [spices-leavening-review.json](../data/recipes/identity-proposals/spices-leavening-review.json):16distinctproposals/16recipes/22candidate references/5rawUSDAfoods,0accepted or runtime-ready. Cinnamon/baking-soda records preserve source/food hashes and soaking/draining unknowns. Both banks are research-only;French still has no identity proposals.

## Latest source snapshot

French450parsed/625pages/2862ingredientlines/2591steps;English3640/3796/53tagsunchanged. SourceIDs/licences/cursorsseparate;cross-languageduplicatesunresolved. Identitybanks16proposals/16recipes/22references/5foods,0accepted/runtime;OFF2266/63. LatestFrenchgate2026-10-13T17:49:47.599Z;readactualcheckpoints. SeeHANDOFF§43–44.

## Validated catalog entry point

[identity catalog](../data/recipes/identity-proposals/catalog.json) + `tool/recipes/validate-identity-catalog.mjs`: explicit three-bank inventory, exact bytes/current source-food checks, cross-bank target dedup,24targets/22recipes/9foods/50refs/1withoutcandidates/0runtime. Only registered English-source banks are included; French source counts remain separate.

## Source alternatives registered

[alternatives-review.json](../data/recipes/identity-proposals/alternatives-review.json) adds8lines to [catalog.json](../data/recipes/identity-proposals/catalog.json);qualifiedvegan identity unresolved,no automatic substitution or nutrient sum. Actualaggregate3/24/22/9/50/1/0runtime. Frenchliteralcategorylabels have explicitraw-vs-parsed denominators inHANDOFF§46;not cuisineclaims.

CurrentFrenchsnapshot:804/1169,allcanonicalquantities/nutritionunreviewed. English3640/3796unchanged;catalog3/24/22/9/50/1/0runtime. No combinedunique-dishcount;source continuation/quotachecks inHANDOFF§47.

Heartbeat18:29 snapshot:French838/1218,English3640/3796/catalog3/24/22/9/50/1/0runtimeunchanged. Sourceavailable;actualquota90reserve delays research,not a sourcefailure. SeeHANDOFF§48.


## Current checkpoint — heartbeat21:29 UTC

French inventory completed: 1489 source pages/1011 conservatively parsed recipes/7128 ingredient lines/6408 steps/128 request archives. SourceExhausted=true, no pending IDs, no listing continuation. English3796/3640 unchanged. Next licensed source discovery remains open; no source cursor reset or final bank count cap, no combined unique-dish sum.

New [ingredient-fate research](RECIPE-INGREDIENT-FATE.md) pins2source ingredient lines and6method steps; retained amounts and nutrient factors remain null,0runtime approvals.18linked tests/current source validators passed. Existing identity catalog3/24/22/9/50/1/0 unchanged. OFF2266/63 unchanged,503 gates saved. See HANDOFF§49 for exact requests, verification and next actions.
