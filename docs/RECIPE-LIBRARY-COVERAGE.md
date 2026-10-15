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
