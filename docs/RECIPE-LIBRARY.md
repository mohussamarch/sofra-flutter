# مكتبة الوصفات المقروءة — الحالة الحالية

الحالة الحالية HANDOFF§80:70سجلًا مقروءًا،13حزمة مثبتة و48لقطة مصدر؛48أرشيفًا+21موقع طاه+1وصف فيديو مفهرس. كتالوج التخطيط54وصفة/4مطابخ ثابت. الفقرات القديمة أدناه تاريخية بأرقام تسليمها.

## تفصيل تسليم§71 التاريخي

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

## Current selected library — §75

55readable records/9pinned packs/36source snapshots =36local archived Arabic curations+19modern creator website recipes. Local10fullyspecified culinary/24needsreview/2notcookable;30exact source cuisine/region labels, not30approved national cuisines. New8labels: Chinese/Korean/Indonesian/Greek/Caribbean/Ethiopian/Brazilian/Swedish. Chinese Chews is a Caribbean source category, not a guessed Chinese cuisine.

New archived8: Taro Fish, Korean Shortribs, Awug, Greek Yogurt Sauce, Chinese Chews, Ayib, Brigadeiro, Candied Almonds.52source ingredient lines+4procedural supplements/48Arabic steps;0newfullyspecified/native-ready. Existing archived title encoding artifacts remain source evidence, not repaired by invented spelling or lossy decoding.

New Chef Omar website3: Turkish shish tawook with bulgur, meat shawarma, Syrian meat shawarma.67listed+10procedural ingredients/6mapped concise method parts. One directly opened page and two cached primary search extracts, not videos/full archived bodies. Channel identity pending; no unverified creator merge. Source50/60/90minute headers remain publishedTotalMinutes while total/actual null because optional overnight/refrigeration and conflicts remain explicit. Two shawarmas have a pending family proposal, not an approved second method family.14video discoveries/4partial/0completeYT remain unchanged.

ManifestSHAfa2a3968ef46d070c4f532903bb5b68328ec9df2f0d8d6749391363278600c33. Original54planning recipes/4cuisines,1reviewed distinct-method naan family,0automatic food/nutrition/rights approvals unchanged. All selected records retain source and explicit private-calculator review paths; quantity and identity coverage still require work.

## Current library and quantity audit — §76

63 readable records =44 local Arabic archived curations +19 modern creator website recipes;10 selected packs/44 source snapshots. Local10 fully specified culinary/32 need review/2 not cookable.38 source cuisine/region labels, not38 approved national cuisines. New8 exact labels: Albanian/Argentine/Austrian/Bulgarian/Colombian/Cuban/Palestinian/Malaysian. Original54 planning recipes/4 cuisines, one reviewed distinct-method naan family,14 video discoveries/4 partial/0 complete YouTube-derived stay unchanged. No new book network or automatic food/nutrition/rights/runtime approval.

The fifth archived pack adds84 source ingredient lines +1 procedural line/59 ordered steps,278 unresolved native preflight issues. Source ranges, alternatives, unknown yields/quantities and time conflicts remain explicit. PackSHA1df899307df2cf630c3fe850dc5ddb997a1f179dd8a1e2ea67bdb7eb77fbf6be. ManifestSHA832cc02a2388db284505fad121783b916f1ecd5c0881b81736c828ce23498b6c.

RecipeLibraryCoverageReport records every indexed line with its existing calculator source fingerprint. Actual63-record report:632 lines,98 missing amounts,91 missing units,465 units needing explicit review,34 procedural lines,7 optional lines;63 recipes have source quantity gaps. Counters overlap. Only raw g/kg are recognised by this audit; positive mass alone does not approve food/form/nutrition. Saved personal review decisions are outside its scope. Contract RECIPE-LIBRARY-COVERAGE.md.16 Node +237 full Flutter passed, analyze clean8.7seconds; prior §75 counts are historical.

## Modern indexed website extracts and source request scope — §77

65readable records vs63:44 archived Arabic curations +21creator website records;11packs/44snapshots. Added Manal quick musakhan rolls and eggplant/chicken/cream casserole,37ingredient lines (33listed+4procedural supplements)/10concise Arabic steps covering12source steps per recipe.7bounded source requests. One official-video search found no verifiable video; direct recipe open showed relaunch page. Accepted facts came from indexed extracts on the official domain, not a retrieved current full body or videos. Publication/yield/total-time/cuisine/channel/rights/food/nutrition remain unknown; no modern publication-date claim.

Rolls preserve source pan/oven options; this is not a second reviewed native variant family.38local source cuisine/region labels and one reviewed distinct-method naan family unchanged. No new completeYT, approvedplanning/nutrition/rights or country label. PackSHA7e66851ecd92b42860545c4f3d2879cbb6667de198891b3cced3a5149e2994c2; manifestSHAa151e6e058adfa1d6c2e7701218043568883a60aeeb8e1522f3c76821addc024.

Review source envelopes now retain related original request indexes/outcomes, including failed direct access, and reject losing a referenced request. Old envelopes remain readable; enriched pins need explicit re-review. Actual source-gap report65recipes/669lines:104missingamounts/97missingunits/495units needing explicit review/38procedural/7optional. Counters overlap; no saved personal decision is inspected. Final30Node/239Flutter/analyze clean5.2sec; preceding checkpoints historical.

## Current §79 — description-derived source and calculation review

كفتة بصلصة اللبن والثوم والكزبرة من وصف فيديو منال العالم المفهرس؛11مكونًا+صنوبر بلا كمية و5خطوات. مصدرcreator-youtube، العنوان وصفي، الجلب المباشر فشل؛الحصص/التغذية/الحقوق/الزمن الإجمالي مجهولة. COOKBOOK.ar.md داخلseventh-batch-20261015 يتيح مراجعتها.0مصدر فيديو كامل مباشر و0اعتمادتشغيل جديد. بحثFoodRepositoryموصول بكل سطر عبرRecipeLibraryFoodSearchوبصمةمصدره؛هويته/كميته/شكله تقبل صراحةً. المكتبة66/12/44و38وسمًا محليًا؛ تقرير603/681مراجعةكمية. الأصل المحلي44(10/32/2)وعائلةنان1وكتالوج54/4ثابتة.

## Current §80 — four offline drafts

زلابية مجرية بالجبن،صيادية لبنانية،شوربة فول سوداني غانية،لحم مشوي تنزاني؛38مكونًا+3إجرائية/30خطوة،كلهاneeds-review. المصدرمنالأرشيف الموجودبإصدارهورخصتهوبصماته؛0جمعكتب. المحلي48(10مكتملةطبخيًا/36مراجعة/2غيرقابلتينللطبخ)،42وسممصدري،المكتبة70/13/48. لااعتمادغذائيتلقائي. COOKBOOK.ar.md فيsixth-reviewed-20261015 للمراجعة؛LIBRARY-FOOD-SELECTION.md يربط اختيارالغذاءبالمحركبعدقراراتالكميةوالشكلالصريحة.
