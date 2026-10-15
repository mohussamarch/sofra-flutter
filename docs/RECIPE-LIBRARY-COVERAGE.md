# مراجعة نواقص مكتبة الوصفات

## الغرض

زيادة عدد الوصفات وحدها لا تعني أن محرك الحساب يستطيع استخدامها مباشرة. `RecipeLibraryCoverageReport` يعرض نواقص كمية كل سطر من المصدر ويساعد المراجع على تحديد قراراته، دون اختلاق وزن أو هوية غذاء أو اعتماد وصفة.

الملف: `lib/domain/recipe_library_coverage.dart`. المصدر هو `RecipeLibraryRepository` المثبت بالبصمات؛ لا يقرأ هذا التقرير قرارات المستخدم المحفوظة، ولا يغيّرها أو يحسب تغذية.

```dart
final entries = await bundledRecipeLibrary().all();
final report = RecipeLibraryCoverageReport.fromEntries(entries);
for (final recipe in report.recipes) {
  // Keep recipeId + sourceFingerprint + lineIndex when opening review.
  final pending = recipe.lines.where((line) => line.needsQuantityReview);
}
```

## ما الذي يحفظه؟

- كل سطر، بنفس الترتيب والفهرس، بما فيه المكرر والاختياري والمستبعد وإضافات الطريقة. لا دمج بحسب الاسم ولا إسقاط للسطر المستبعد.
- الكمية والوحدة والنص الأصلي وحالات `optional` و`included` و`supplemental`. يبقى المجهول null، وصفر المصدر صفرًا مع وسم `nonPositiveAmount`؛ لا يصبح الصفر كمية صالحة للحساب.
- `missingAmount` و`missingUnit` و`unitNeedsReview` و`needsQuantityReview`. الوحدتان الخام `g` و`kg` فقط معروفتان هنا؛ غيرهما يحتاج مراجعة تحويل/مقياس. هذا لا يعني أن كل الوحدات الأخرى غير كتلية: `oz` مثلًا يحتاج تحويلًا صريحًا أيضًا.
- البصمة من `recipeLibrarySourceFingerprint` نفسها المستخدمة في مراجعة المسودة؛ تتغير عند تغير المصدر. هوية الوصفة وحدها لا تكفي لإعادة استخدام مراجعة قديمة.
- قوائم غير قابلة للتعديل، و`toJson()` يعطي نسخة جديدة. رفض تكرار هوية وصفة في مدخل التقرير؛ مجموعة فارغة تقرير صفر، وليست بنكًا مكتملًا.

## حدود الحساب

الأعداد قد تتداخل: السطر الناقص كمية ووحدة يُحسب في المؤشرين. كمية موجبة بوحدة g/kg لا تكفي لاعتماد الطعام أو شكله أو مصدره أو استبقائه بعد الطبخ. كل سطر يظل `requiresExplicitFoodReview=true` في هذا التقرير البحثي، و`runtimeApprovedRecipes=0`.

التقرير لا يعلن أن جميع المراجعات الشخصية ناقصة؛ نطاقه أدلة المكتبة قبل المراجعة فقط. بعد اتخاذ القرارات تستخدم `RecipeLibraryDraftReview` و`KitchenService.saveLibraryRecipeDraft` حسب `LIBRARY-RECIPE-CALCULATOR.md`. لا استنتاج سعر أو تغذية أو مدة صلاحية أو قاعدة صحية.

الفحوص تشمل سطرين بنفس الاسم، وكمية مجهولة وصفرًا ووحدة كوب ومكونًا اختياريًا ومستبعدًا وإضافة إجرائية؛ حفظ الفهارس، عزل النسخ، تغير بصمة المصدر، رفض المكرر، والتقرير عن الأصول الفعلية. النتائج الحالية وأعداد التقرير في HANDOFF §76 وDELIVERY.json.

## عدد السطور دون تكرار — §78

`quantityReviewLineCount` متاح كخاصية وفي `toJson()`: يحسب كل سطر له `needsQuantityReview` مرة واحدة، ولو كانت الكمية والوحدة معًا ناقصتين. لا تجمع عدادات النواقص للحصول على حجم العمل. التقرير الحالي:592 سطرًا مختلفًا من669 يحتاج مراجعة كمية، عبر65سجلًا. باقي77سطرًا لا يحمل هذه الرايات في حقول المصدر؛ يظل كل سطر محتاجًا مراجعة هوية/شكل/اختيارات صريحة، ولا يعني العدد اعتمادًا غذائيًا.

اختبار التداخل:5سطور، منها4تحتاج مراجعة رغم أن مجموع عدادات المشكلات6؛ المجموعة الفارغة تعطي0.4اختبارات مرتبطة نجحت والتحليل نظيف5.0ثانية. فحص239Flutter الكامل فيd7e444c تاريخي، لم يعد لهذا الحقل التجميعي الصغير؛ الأصول والبصمات وبيانات الوصفات لم تتغير.

## Current §79 — actual source review inputs

66records/681lines,603distinctquantity-reviewlines.105missingamount/98missingunit/505unitreview/0nonpositive/39procedural/7optional;66recipeswithgaps,0runtimeapprovals.78unflaggedquantityrows still require identity/form/choice/scaling review. RecipeLibraryFoodSearch now opens the next explicit step using sourcepin+lineIndex+query, preserving rawsource and independent candidate evidence. Counts come from actual fullFlutter audit, not sum of overlapping flags. HANDOFF§79 records247fullFlutter and31Node.

## Current §80 — actual source workload after offline curation

70recipes/722indexedlines,642uniquequantityreviewlines:118missingamount/111missingunit/531unitreview/0nonpositive/42procedural/8optional;all70recipeswithgaps/0runtimeapproval.80unflaggedquantityrows stillneedidentity/form/choice/scaling review. RecipeLibraryFoodSearch andexplicitresolveUsdaCandidate helpreviewerchooseanexactfoodidentity/version; selectiondoesnotchoosequantityor inspectstoreduserreviews.250fullFlutter/34Node/analyze5.2sclean;detailsHANDOFF§80.

## Current §81 — actual merged source audit

78recipes/797indexed lines;715 distinct quantity-review lines,133missing amount/126missing unit/589unit review/0nonpositive/44procedural/12optional. All78 have quantity gaps and0runtime approval;82 quantity-unflagged rows still require identity/form/choice/scaling review. Explicit package selection adds source consistency, not accepted quantities or saved-personal-review coverage. Actual full Flutter audit is recorded inHANDOFF§81 (254tests);33Node and cleananalysis6.1s.


## Current §82

84 readable source records =62 offline archive +21 creator website +1 indexed video description;15 pinned packs/62 snapshots,51 local source cuisine/region labels. Planning54/4 and reviewed method family1 unchanged;0 new runtime/nutrition approvals. Source audit845lines/756distinctquantityreview,145missingamount/138missingunit/618unitreview/0nonpositive/48procedural/17optional;all84recipes have quantity gaps. Counts overlap;89lines without quantity flags still need identity/form/inclusion/scaling review. Mass proposal does not reduce this source audit or prove saved user reviews. Four new mass tests cover immutable originalunit/estimated roundtrip, invalid/unknown units/amounts, drift/ack/index and exclusion override;14focused/258fullFlutter/27Node/analyze clean.


## Current §85

86 source records=62localarchive+21creatorwebsite+3indexedYTdescriptions;16packs/62snapshots,51local source labels. Planning54/4 unchanged. New read-only monthly explicit alternative comparison and runtime OFF contact/privacy guards;269Flutter/62Node/analyze clean. HANDOFF§85. Sourceaudit86recipes/862lines/773distinctquantityreview,162missingamount/155missingunit/618unitreview/0nonpositive/49procedural/17optional;all86withgaps/0runtime.89quantity-unflagged lines stillneedidentity/form/inclusion/scaling review. New2 indexedsource records have17unknown quantities; no resolved saveduserreview inferred.


## Current §86

88 readable source records=62localarchive+23creatorwebsite+3indexedYTdescriptions;17packs/62snapshots,51local source labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. KitchenService snapshot-safe monthly advisory adapter implemented;282fullFlutter/36relatedNode/analyze clean. HANDOFF§86. Actual audit88recipes/880ingredientlines/789distinctquantityreview;168missingamount/162missingunit/627unitreview/0nonpositive/49procedural/17optional;all88withgaps/0runtime.91otherlines still need explicit identity/form/inclusion/scaling review; counts overlap, no saved review completion inferred.


## Current §87

90 readable source records=64localarchive+23creatorwebsite+3indexedYTdescriptions;18packs/64snapshots,53local source category labels. Planning54/4 and naanmethodfamily1 unchanged. Bounded explicit-candidate monthly search implemented;292fullFlutter/30relatedNode/analyze clean. HANDOFF§87. Actual audit {"schemaVersion": 1, "scope": "source-library-review-triage", "recipeCount": 90, "ingredientCount": 898, "quantityReviewLineCount": 807, "missingAmountCount": 172, "missingUnitCount": 166, "nonPositiveAmountCount": 0, "unitNeedsReviewCount": 641, "supplementalCount": 51, "optionalCount": 20, "recipesWithQuantityGaps": 90, "runtimeApprovedRecipes": 0}. Counters overlap; unflagged quantity lines still require food/form/inclusion/scaling review, no saved acceptance inferred.
