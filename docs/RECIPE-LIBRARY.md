# مكتبة الوصفات المقروءة — الحالة الحالية

راجع HANDOFF§71 وLIBRARY-RECIPE-CALCULATOR.md. المكتبة31 سجلًا عربيًا،5 حزم مثبتة و20 لقطة مصدر. أضيفت7 في هذه الدفعة:4 من الأرشيف الموجود و3 من موقع شميشة الرسمي. لم يتغير كتالوج التخطيط54وصفة/4مطابخ.

## ما تحتويه

- محليًا20 سجلًا:8مكتملة بيانات المقادير والطريقة والناتج والزمن (المغذيات ليست مكتملة)،10تحتاج مراجعة و2غير مكتملتين.13وسم مطبخ/منطقة من المصدر، لا13مطبخًا وطنيًا معتمدًا. عائلة نان واحدة بطريقتين؛ خبزا الصودا اختلاف مكونات.
-11 وصفة من مواقع منال العالم وشميشة الرسمية؛ المصدر website وليس YouTube.14اكتشاف فيديو/4أوصاف فيديو ناقصة/0وصفات كاملة مستخرجة من يوتيوب. حقوق الموقع والموافقات لم تتحول إلى قبول تلقائي.
- الدفعة المحلية الجديدة:جريش الذرة، خليط كاكاو جاف، شوربة طماطم حارة بالقشدة، مشروب فاكهة دافئ بجهاز percolator.23سطر مكون و13خطوة. مردود الكاكاو6أكواب/نحو48حصة لا48بالضبط.
- الدفعة الحديثة الثالثة:حرشة بالحليب، طاجين سمك أبو سيف بالخضار، بسطيلة دجاج ولوز؛47مكونًا و15خطوة. بسطيلة المصدر cookTime=0متعارض مع الخطوات ومحفوظ كتحذير لا زمن فعلي صفر.
- توقيتا العصيدة5دقائق والكولفي تجميد نحو360دقيقة مقترحان منفصلان مثبتان؛ الأصل16سجلًا لم يتغير.4مسودات سابقة60→58مشكلة فقط،0جاهزة للنشر.

## API والحفظ

```dart
final library = bundledRecipeLibrary();
final entries = await library.all(); //31،بما فيها حالات النقص
final maqluba = await library.search('مقلوبة');
final naan = await library.familyCandidates('curated-local:naan');
final vietnamese = await library.filterByCuisine('فيتنامي');
```

RecipeLibraryEntry يحمل عنوانًا ومكونات/مقادير/وحدات nullable وخطوات عربية وURLs ووسم مطبخ بدليله، ونسخًا مستقلة من sourceRecord/sourceSnapshot/packMetadata. حالات included/optional/supplemental والمجهول والمدى والتعارض والحقوق تبقى محفوظة. runtimeReady=false وnutrition=null في المكتبة؛ لا نشر أو خصم مخزون عند القراءة.

RecipeLibraryDraftReview مع KitchenService.saveLibraryRecipeDraft يربطان السجل بمحرك حساب مسودة شخصية بعد مراجعة صريحة لكل سطر. التفاصيل LIBRARY-RECIPE-CALCULATOR.md؛ لا إسقاط للمصدر ولا تجاوز لمسار استيراد الحقوق عند النشر.

## الأصول والفحوص

data/recipes/curated-local/flutter-manifest.json يثبت5حزم/20لقطة؛ SHA256=950178af3084996a16ed1c9bdea9170aea309e63ee7c0fd38e2277faf05d85ed مثبت في lib/data/recipe_library_assets.dart. pubspec يحمل المختار فقط،لا6056سجلًا خامًا. build-recipe-library.mjs --check يرفض الانحراف؛ لا يعاد توليده لإخفاء تغير غير مراجع. البصمات ثبات محلي وليست موافقة مصدر أو حقوق.

الكتب العربية المقروءة COOKBOOK.ar.md داخل first-reviewed-20261014 وgap-review-20261014 وحزم مواقع الطهاة. لا جمع كتب جديدة؛ المعالجة المحلية للأرشيف السابق بتفويض المستخدم.

الفحوص الحالية:224Flutter كاملة،analyze بلا مشاكل10.6ثانية،12Node (8gap و4manifest)،validator للدفعة الحديثة الثالثة. أصول فعلية31سجلًا/20لقطة و10وسوم مغربية (1محلي+9مواقع). لاAPK/UI/سحابة في هذه الدفعة.

## الحالة الأحدث — §72

44سجلًا مقروءًا/7حزم/28لقطة مصدر؛28محليًا(10مكتملة معطيات/16مراجعة/2ناقصة) و16من مواقع طهاة رسمية. أضيفت13:8من الأرشيف الموجود و5منال العالم.22وسم مطبخ/منطقة محلي مسند للمصدر؛ليست22مطابخ وطنية معتمدة.9وسوم جديدة تشمل الياباني/التايلندي/التركي؛سوكا سجل واحد فرنسي/إيطالي. لا جمع كتب جديدة أو ترقية تلقائية للتخطيط/التغذية/الحقوق.

الحزمة الحديثة fourth-batch-20261014 تحتفظ بـ81سطر مكون (4إجرائية) و15خطوة عربية مختصرة مع فهارس تغطية الطريقة الأصلية. الحصص ووسم البلد null؛كسور كيك التفاح المعكوسة والمدى لا تصبح أوزانًا مخمنة؛أكياس المكرونة والجبن والحزم ليست جرامات. sourceTimers أطوار فقط،ليست وقتًا كليًا. COOKBOOK.ar.md فهرس مباشر للـrecipes.json والمصادر؛لم ننسخ شرح الموقع كاملًا. المصدر website رغم وجود منطقة فيديو في الصفحات؛0استخراج فيديو جديد.

إصلاح حفظ المصدر يشمل creatorالمفرد وcreatorsالقائمة،مطابقةcreatorIdفقط وإزالة التكرار المتطابق دون دمج أدلة مختلفة. المصدر الكامل للمسودة يحتفظ بالهوية؛السجلات القديمة تظل مفكوكة،والبصمة المحسنة تتطلب مراجعة قبل إعادة حفظها على المصدر الحالي. عقد LIBRARY-RECIPE-CALCULATOR.md.

ManifestSHA352c88ede972629a0526e9ec2d03380858178ce631c2b91158e4dcb6c6ff8a1d. Pubspecيشحن المختار فقط،لا6056سجلًا خامًا. 17Nodeو225Flutterكاملة نجحت؛analyzeنظيف7.2ثانية. كتالوج54/4لم يتغير. الأعداد السابقة أعلاه نقاط تاريخية؛هذه الحالية.

## Import manifest guard — §73

The build tool now rejects duplicate recipe IDs across all selected packs (not only within one pack), empty/whitespace-only IDs and malformed UTF8 before generating trusted pins. It decodes original bytes strictly and continues hashing the original bytes; no reserialization or silent replacement. These are pre-build consistency guards, not source authenticity/rights checks. All7 focused Node tests and actual manifest --check passed. The existing44 records/7packs/28snapshots and manifest SHA are unchanged. Full225Flutter/analyze at361e04a are historical; no Dart, pubspec or source-data change in this unit.

## Source snapshot readability — §74

Before pinning a curated source snapshot, the generator now checks fatal UTF8 decoding, valid JSON and an object root after comparing its exact original-byte hash. A matching hash alone does not prove a file is readable. The same parser handles selected pack roots. No snapshot content/schema facts are approved by this syntactic check. Ten focused Node tests pass, including malformed snapshots with matching expected hashes; actual manifest --check remains unchanged at44records/7packs/28snapshots. No Dart/assets changed; the225Flutter gate at361e04a remains historical.
