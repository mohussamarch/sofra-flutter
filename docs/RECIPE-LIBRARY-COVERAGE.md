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
