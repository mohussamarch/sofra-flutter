# اختيار غذاء من بحث مكون الوصفة

هذه الخطوة تكمل بحث `RecipeLibraryFoodSearch` في النواة، وتعيد `FoodRecord` لغذاء USDA اختاره المراجع صراحةً. الكمية وشكل الغذاء المستخدم في الوصفة وقرارات كل سطر تُراجع ضمن المسودة الشخصية.

```dart
final search = RecipeLibraryFoodSearch(foods: foodRepository);
final found = await search.search(
  entry: currentEntry,
  expectedSourceFingerprint: recipeLibrarySourceFingerprint(currentEntry),
  lineIndex: ingredientLineIndex,
  query: reviewerQuery,
);
final food = await search.resolveUsdaCandidate(
  result: found,
  currentEntry: currentEntry,
  foodId: selectedGenericFoodId,
  form: reviewedSourceForm,
  acknowledgeFoodIdentity: reviewerConfirmedIdentity,
);
```

المتغيرات أعلاه مدخلات المراجع. يُجلب `currentEntry` من المكتبة الحالية عند المراجعة، ويُختار المعرف من نتائج البحث نفسها. لا يُستخدم أول مرشح تلقائيًا.

## ما الذي يتحقق منه؟

- إقرار الهوية وشكل المصدر الصريح: `raw` أو `cooked` أو `asSold` أو `prepared`، حسب الغذاء الذي راجعه المستخدم.
- تطابق هوية الوصفة وبصمة مصدرها مع نتيجة البحث. تغيير سطر أو كمية مصدرية يقتضي إعادة المراجعة.
- وجود مرشح USDA واحد بالمعرف المختار، مع اسم وإصدار مصدريين، ومن دون حقل باركود منتج.
- تطابق اسم وإصدار صف البحث مع صف الغذاء الكامل الذي يقرؤه `FoodRepository.usdaRaw` قبل استخدام `usdaFood`.

الفحص الأخير يثبت اتساق المعرف والاسم والإصدار بين بيانات البنك المقروءة؛ ليس فحص بصمة كل قيمة غذائية أو إثبات مطابقة منتج محلي. عند تعارض بيانات البنك يلزم تحميل مصادر حالية متسقة وإعادة البحث والمراجعة؛ القارئ يحتفظ بأصوله في ذاكرة التخزين خلال الجلسة.

## بعد الاختيار

يستعمل المراجع الغذاء في `RecipeFoodInput` بكمية وشكل وقرارات إدراج وتحضير صريحة، ويقدم قرارًا لكل سطر عند إنشاء `RecipeLibraryDraftReview`. يحفظ `KitchenService.saveLibraryRecipeDraft` الغلاف كاملًا ويفحص المصدر الحالي حسب عقد المكتبة. التفاصيل في `LIBRARY-RECIPE-CALCULATOR.md`.

هذا API لا يختار كمية أو وزن كوب، ولا يكتب مسودة أو مخزونًا أو أكل أشخاص، ولا يمنح موافقة حقوق أو نشر. البحث يستمر في عرض المنتجات المعبأة؛ هذا المحلل مخصص لمرشح USDA العام. قراءة منتج معبأ ومراجعة ملصقه تبقى عبر `FoodRepository.packagedFood` بعقدها الحالي.

## أدلة التحقق

`test/recipe_library_food_selection_test.dart`: اختيار معرف وإصدار محددين؛ رفض غياب الإقرار والمعرف غير الموجود والمنتج وتغير الوصفة والشكل غير المدعوم قبل قراءة الغذاء الكامل؛ رفض تغير إصدار الغذاء أو وصفه. بيانات التغذية في تجهيزات هذه الاختبارات صناعية، ولا تمثل ربطًا غذائيًا مقبولًا لوصفة فعلية. نتائج الوحدة النهائية في `HANDOFF §80` و`E:\work\SOFRA\DELIVERY.json`.
