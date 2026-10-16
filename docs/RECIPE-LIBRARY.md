# مكتبة الوصفات المقروءة — الحالة الحالية

الحالة الحالية HANDOFF§89:2090 سجلًا مقروءًا،20 حزمة مثبتة و2064 لقطة مصدر؛2064 أرشيفًا+23 موقع طاه+3 أوصاف فيديو مفهرسة. كتالوج التخطيط54وصفة/4مطابخ ثابت. الفقرات القديمة أدناه تاريخية بأرقام تسليمها.

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

## Current §81 — eight more readable drafts

دجاج جيرك جامايكي،سيرنيكي روسية،ياسا غامبية،رولكس أوغندي،كواكوكو كاميرونية،عصيدة ليبية،فاصولياء وأرز زامبي،زيتومبوا ملاوية.73مكونًا+2إجرائية/57خطوة،كلها تحتاج مراجعة. مصدرها إصدارات الأرشيف القائمة برخصها وبصماتها،0طلبات شبكة. المحلي56(10طبخيًا مكتملة/44مراجعة/2غير قابلتين للطبخ) و50وسمًا مصدريًا؛ المكتبة78/14/56. التخطيط54/4 ثابت. COOKBOOK.ar.md فيseventh-reviewed-20261015 للمراجعة، واختيار الغذاء والمنتج فيLIBRARY-FOOD-SELECTION.md.


## Current §82

Six additional offline drafts: Korean bulgogi, Brazilian fish moqueca, Greek saganaki, Norwegian lefse, Indonesian klepon and coconut rice.44listed+4procedural/32steps;all6needreview/151preflightissues. Norwegian is one new source category label; other countries already represented. Local62=10culinaryfullyspecified+50needsreview+2notcookable,457listed+29procedural/339steps. No global deduplication or automatic rights/food/runtime approval. NewpackSHA295b204f9618d52555fe8c0236f9f0ca4feee214943e0b75081101c5dae08a7b;manifestab23f2e62ba34096e40d4ffe7ed2286308c410e2afac784c7c032436439e55ca.


## Current §85

Two indexed-description records attributed specifically to CBCSofra(Verified)/NaglaaElSherbiny: taro _DmSJzc2Ksc(2022-10-31), sayadiya-rice segment aExAOsnzqSI(2022-08-10).16listed+1proceduralwater/10steps;17quantityunknowns,yield/time/cuisine/rightsunknown,0familyclaims/0directbody/media/transcripts. Search2queries+2directopensfailed=4underlyingrequests within8; stoppedat2acceptedsource records. Raw search receipt extracts/content hashes retained; no claim of upstreamsignature. PackSHAc99a0e0ba72c36011eb64b895d637167e001e860b151ecdac1e28f3b1437eb93;manifest508fb8c04b401466c2d63c9b9bd0f0ab1c908a3a02cfe306654883741569ebd6. All15previousselectedpackpinsunchanged;sourcecuisine-labeltotal51unchanged.


## Current §86

Two ChefOmar site-attributed creator-website records: chicken with mushroom cream and mujaddara component. Site/channel ownership link unconfirmed, legacy creator ID/officialSite field is not ownership verification; youtubeDerived=false.18listedingredients/9Arabicsteps from3source methodparts,11amount+unit/7incomplete. Chicken500unitnull; mujaddara componentyield/timenull while combinedpage30min/4servings remain separate evidence.6queries+2failedopens=8/8underlying requests; indexed excerpts only,0directbody/media/transcript/newbooks. No cuisine/family/rights/nutrition/runtime approval. PackSHAe66c8109e43a72c58645ba575ad7e92ca3d17cf58d626da1dd7be84ceed1be7d; manifest4e1a9f2674b7c4290401d712c47c081fdf3e0f1d648138b93964fe84338cadcc; all16priorpackpins unchanged.


## Current §87

90 readable source records=64localarchive+23creatorwebsite+3indexedYTdescriptions;18packs/64snapshots,53local source category labels. Planning54/4 and naanmethodfamily1 unchanged. Bounded explicit-candidate monthly search implemented;292fullFlutter/30relatedNode/analyze clean. HANDOFF§87. Offline existing source236563/r4518607 Egyptian lentilstew and129995/r4518126 Cypriotsalad;16ingredients+2optionalprocedural extras/12steps, bothneeds-review. Exactcategory labels egyptian/cypriot are new local labels, not newly approved cuisines. Preserve salt/soupmix alternative, unknowngarnishes,5–6oliverange/spoon ambiguity/saladtimeyield; no invented80min total.0network/newbooks/runtimeapprovals;53preflightissues. PackSHAea7c1ec0ed013632c8fb1e1326303fa7be09a20db6d91c87c52c72d6cf6d5a94;all17priorpinsunchanged. Manifest85cb5e078705592ecafcdfb8b7440e17bc62a64dd477b08b6d0c818ce30aadde.


## Current §88

1090 readable source records=1064offlinearchive+23creatorwebsite+3indexedYTdescriptions;19packs/1064snapshots,71local source-category labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. Native1000-record batch and snapshot-safe monthly candidate search service implemented;306fullFlutter/31relatedNode/analyze clean. HANDOFF§88. Exact1000 already-parsed archive records converted to native schema with1000immutable source snapshots,9709ingredients/7431steps,53sourcecategories/102untagged. OriginalEnglish retained,0translations/newacquisitions/culinary/nutrition/runtimeapprovals. All9709acceptedamounts/units and1000yield/time values unknown; rawsource/quantity candidates preserved for explicit review. Exactsource/contentdedup versus prior90 and withinbatch, no semantic/crosslanguageuniquedish claim. Eligiblepool3575of3640Englishparsedrecords. Frozen18pack baseline allows own/laterregistration withunchangedoriginalpins. PackSHA26d6ca3ebf32b88f46e3573fdaadf8d5f959e4b230203a9e4b90be783981be02; CLI tool/recipes/bulk-normalize-1000.mjs --check,6focusedNodepassed. No newbooknetwork. This batch meets1000conversiontarget, not1000newacquisitions.


## Current §89

2090 readable source records=2064archive+23website+3indexedYTdescriptions;20packs/2064snapshots,71local source labels unchanged. Planning54/4/methodfamily1 unchanged. Second1000native conversion and explicit repeat/diversity search preferences;319fullFlutter/37Node/analyze clean. HANDOFF§89. Second exact1000 native source records+1000snapshots,8479ingredients/6936steps,0newacquisitions/translations/runtimeapprovals. Frozen19pack baseline coversall1090previous;1064prior archive identities excluded inclfirst1000,2575eligible. Indian42/Italian11,947untagged; no guessedsourcecuisine. All accepted quantity/unit/yield/timeunknown; rawtext/candidates preserved. buildBatch reusable safeone-basename outputFolder, defaultfirstpackbytesunchanged; original6+new6Nodepassed,both--checkpassafterregistration. PackSHA1d65a70f09930fd5b6e375069a6869080d424d3868f43dc55c9e1ea0c82905c7; originalpack26d6ca...unchanged.


## Current library §90 —16October2026

3530 readable source records/22pinned packs/3504 source snapshots:3064 already acquired archive records,440 new Based Cooking content records,23 creator website recipes,3 indexed video descriptions. Third1000 archive batch is reprocessing, not acquisition; Based Cooking only440/1000 accepted because the pinned repository has441 Markdown files and one is metadata.3440 English entries remain untranslated, all newly added amounts/units/time/yield and optionality require explicit review; source categories are not plannable cuisines. Planning54 recipes/4 cuisines unchanged,0 automatic nutrition/runtime approvals. Exact evidence and SHA in HANDOFF§90.

## Current library §91 —16October2026

4530 source records/23 pinned packs/4504 source snapshots:4064 existing archive conversions,440 new Based Cooking records,23 creator website records and3 indexed video descriptions. The fourth archived unit pinned1000 French source records with7167 ingredient lines/6330 steps after deterministic recovery from raw wikitext; the earlier parser had stripped ingredient names in946 rows and omitted125 ingredient lines in77 rows. **988/1000** now have ingredient and method text without unresolved source markup, so the target of1000 fully extracted texts was **short12**. All1000 remain unreviewed and unapproved for cooking, rights and nutrition; no semantic cross-language uniqueness is claimed. Source-language untranslated records4440; planning remains54 recipes/4 cuisines and reviewed naan method family1. New acquisition in this offline unit0. Pack SHA `05964518b95bc6260b8180d112a5907a87a3aa482ec96e6262732f49860c6d09`, manifest SHA `038a62a40cdd528855f5b0b97cbf0ee1e34aa78c0edb8019bd141a30a912435a`; source/quality evidence and tests in `docs/agents/bulk-fourth-thousand-20261016.md`. Person target confidence logic is independent; see `docs/agents/person-target-confidence-20261016.md`.
