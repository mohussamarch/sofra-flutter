# خطة قايمة المكونات ووحدات المطبخ — 25 أكتوبر 2026

## المشكلة
- الوصفات النشطة (446) فيها 4841 سطر مكوّن، و4381 ID مختلف. 76 ID بس بيتكرروا في أكتر من وصفة. يعني معظم السطور ليها ID خاص بيها (مثلًا `ma650-...-i12` = ماء)، فعمر ما هتطابق المخزون.
- الوحدات: كوب 704، ملعقة كبيرة 683، ملعقة صغيرة 620، حبة 462، جرام 279، فص 127، رطل 100، أونصة/oz 52... ومن غير تحويلات بين الحجوم (كوب↔مل) ولا الأوزان الأمريكية (رطل، أونصة).

## القرارات
- **هوية المخزون منفصلة عن الوصفة.** بيانات الوصفة المصدرية ما بتتغيرش. فيه ملف ربط `rawId → canonicalId`. المطابقة التلقائية بس لما **الاسم بعد التنظيف يطابق بالظبط** اسم أو مرادف في القاموس، والباقي يفضل من غير ربط. ده للمخزون بس، مش ربط تغذية.
- **تحويلات بتعريف ثابت بس:** ملعقة كبيرة = 15 مل، ملعقة صغيرة = 5 مل، كوب = 240 مل (كوب قياس، مكتوب في الواجهة)، رطل = 453.59237 جم، أونصة = 28.349523125 جم (أونصة وزن)، كوارت = 946.352946 مل، باينت = 473.176473 مل، ديسيلتر = 100 مل، كيلوغرام/ملليلتر مرادفات. **لا تحويل من حجم لوزن** من غير قاعدة صريحة للمكوّن (مثلًا "كوب رز = 200 جم") يدخلها المستخدم وتتحفظ.
- الوحدات العددية (فص، ورقة، قطعة...) بتتطابق مع نفسها بس.

## العقود بين الأجزاء (لازم تتطابق بالظبط)

### A — بيانات المكونات (agent: ingredient-data)
- `data/ingredients/vocabulary.json`: قاموس مكتوب يدويًا، من 150 لـ250 مكوّن شائع. كل مكوّن: `{id, name, aliases[], zone: fridge|freezer|pantry, category, defaultUnit}`. الـIDs إنجليزي kebab-case، ولو فيه ID مشترك في الكتالوج زي `rice` و`onion` يتعاد استخدامه بالظبط. ولازم يشمل IDs التجريبية: chicken, rice, tomato, cucumber, onion, oil, salt, lentils, eggs, yogurt, honey.
- `tool/ingredients/build-directory.mjs`: بيقرا الكتالوج النشط وبيطلّع `data/ingredients/directory.json`: `{version, vocabularySha256, idMap: {rawId: canonicalId}, unmapped: count, stats}`. التنظيف: يشيل الأقواس والأرقام وكلمات الوصف (مفروم، طازج، مبشور، حسب الذوق...). التطابق بالظبط مع name/aliases، وأي غموض يفضل من غير ربط.
- `lib/domain/ingredient_directory.dart`:
  ```dart
  class IngredientEntry { final String id, name, category, defaultUnit; final List<String> aliases; final StorageZone zone; }
  class IngredientDirectory {
    static Future<IngredientDirectory> load(Future<String> Function(String path) read);
    List<IngredientEntry> get entries;
    IngredientEntry? entry(String id);
    String stockId(String rawId);           // idMap[rawId] ?? rawId
    List<IngredientEntry> search(String q);  // تطابق عربي مع name/aliases
  }
  ```
- المسارين في `pubspec.yaml`: `data/ingredients/vocabulary.json` و`data/ingredients/directory.json`.
- الاختبارات `test/ingredient_directory_test.dart`: الـIDs فريدة، المرادفات ما تتكررش بين مكوّنين، الملف المولّد مطابق للقاموس (sha)، أمثلة ربط معروفة (ماء، ملح، بصل مفروم → onion).

### B — وحدات وقواعد (agent: kitchen-units)
- `lib/domain/kitchen_core.dart` → `Units`: canonical للمرادفات الجديدة، والتحويلات اللي فوق. `convert` يفضل يرجّع null للحجم↔الوزن من غير قاعدة.
- `lib/data/kitchen_service.dart`:
  - `List<UnitRule> get unitRules` من `kitchen.unitRules`.
  - `Future<void> saveUnitRule(UnitRule rule)`: بيستبدل القاعدة اللي ليها نفس ingredientId/from/to.
  - `Future<void> removeUnitRule(String ingredientId, String from, String to)`.
  - `confirmCooking` بيدمج القواعد المحفوظة مع `rules` الممرّرة.
  - `KitchenService(..., String Function(String rawId)? stockIdOf)`: بيُطبّق على ingredientId في الخصم والتكلفة وسجل `consumed` (القيمة الافتراضية identity). الـvalidation بتاعة السطور تفضل على rawId.
  - الحقل `unitRules` اختياري في الحالة: البيانات القديمة من غيره تتحمل عادي.
- الاختبارات `test/kitchen_units_test.dart`: التحويلات المعرّفة، رفض حجم↔وزن من غير قاعدة، حفظ القاعدة واستبدالها وحذفها وتحميلها تاني، الخصم بـstockIdOf، والقواعد المحفوظة بتشتغل في الطبخ.

### C — الواجهة (Claude، في النسخة الرئيسية)
- `SofraController` بيحمّل `IngredientDirectory` وبيمرّر `stockIdOf: directory.stockId`. و`checkStock` بيستخدم stockId والقواعد المحفوظة.
- شاشة الإضافة: بحث في القاموس، واختيار وحدة (الافتراضية + الشائعة)، وكتابة الكمية، والمكان افتراضي من القاموس وقابل للتغيير.
- السطر اللي وحدته مختلفة: زرار "حدد التحويل" بيفتح حوار "1 كوب من الرز = ؟ جم"، وبيحفظها عن طريق `saveUnitRule`.
- المخزون التجريبي بـIDs القاموس.

## الترتيب والمتابعة
1. A وB بالتوازي، كل واحد في worktree وbranch، وكل واحد بيـcommit على الـbranch بتاعه ومن غير push لـmain.
2. Claude بيكتب C بالتوازي على العقود دي، وبعدين يدمج A وB في main ويشغّل الفحص الكامل ويعمل push.
3. مراجعة دورية (cron) بتقارن الحالة بالخطة دي وبتكتب النتيجة في قسم «سجل المتابعة» تحت.
4. لو الليمت خلص، الشغل يكمّل الساعة 03:40 من نفس الخطة.

## سجل المتابعة
- 01:26 — الخطة اتكتبت. A وB هيبدأوا. C بيبدأ عند Claude.
- C اتكتب على العقود: الـcontroller بيحمّل القاموس (قارئ أصول قابل للحقن في الاختبارات)، و`stockId` في فحص المخزون و"جبت الناقص" وفلتر "من الموجود"، وشاشة إضافة بالبحث والوحدة والمكان، وزرار "حدد التحويل"، وأسماء الوحدات بالعربي (`unitLabel`). اتبعت لـA قايمة الفئات وصيغة `defaultUnit`، ولـB أسماء الوحدات الموحدة. مستني الدمج عشان الكود يتبني.
- B خلص (commit 83d5705f) واتدمج. A خلص (commit db789280): 233 مكوّن، 65.1% من السطور، واتدمج. الواجهة اتبنت عليهم: analyze نظيف، و407 اختبار ناجحين. الخطة خلصت.
