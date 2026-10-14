# سُفرة — أولويات البحث والمنطق والبنوك

13أكتوبر2026. نسخة واحدة E:\work\SOFRA\app؛ origin/main. طلب المستخدم صراحة ترتيب كل النواقص، التنفيذ بالترتيب، وجدولة ومراقب يفسر التوقف ويستأنف العمل الممكن. هذه خطة تشغيل مستمرة؛ ليست وعدًا باكتمال كل المراحل في جلسة واحدة.

## القرار الحالي

كان جدول المتابعة السابق يجمعOFFفقط؛ عند503كان ينتهي التشغيل رغم وجود عمل محلي في التغذية. السبب تنظيمي بالإضافة لتعطل المصدر. يتغير نطاق المتابعة الآن إلى منسق أولويات ومراقب في نفسautomation-2كل30دقيقة؛ لا مؤقت ثانٍ يكتب في نفس النسخة. يبدأ كل تشغيل بتشخيص ثم ينفذ أعلى مهمة قابلة للعمل. لا تُعدّل واجهات أو أصوات أو صور أوFirebase/فوترة.

| الترتيب | البحث والبنك المطلوب | المنطق/الناتج ومعيار الإغلاق |
|---|---|---|
|0| قائمة مهام وتبعيات وأدلة تقدم وأسباب انتظار | watchdogيميز حد الاستخدام/مهمة جارية/توقف بلا تقدم/انتظار مصدر؛ ينتقل لمهمة متاحة ولا يعتبر503وقفًا للمشروع |
|1أ| مقاييس منزلية وأوزان حصص USDA لكل غذاء وشكله وإصداره | بنك103خيارات مصدرية لـ36غذاء؛ تحويل صريح بعد قبول حجم/نوع الحصة، لا وزن حبة أوكوب عام مخمّن؛اختبارات مصدر وهوية وحساب |
|1ب| كميات المستخدم الفعلية، المركبات مثلملح+فلفل، وحدات العبوات | حفظ قبول المقياس حسب إصدار/سطر، فصل المركبات بإصدار جديد، نفس الكمية للمخزون/التكلفة/التغذية عند التأكيد؛لا تحوّل التقدير لقياس فعلي |
|2| حالات raw/asSold/cooked، الجزء المأكول، مردود الوزن وعوامل احتفاظ المغذيات | حساب طبق كامل وحصة/100gفقط مع أدلة كافية؛ اختبار بشاميل/كشري/كبسة، وفصل البيانات الناقصة عنصفر؛49مغذيًا/العرض5 |
|3| بيانات الحساسية والمكونات المركبة وcontains/mayContain/unknown | مراجعة مكونات لا استدلال من الاسم؛تحديد خطرفردي وأثرالبدائل، غيابالبيانات ليس أمانًا |
|4| بنك وصفات عائلات/أنواع/إصدارات/طرق طبخ ومقادير مجرّبة | توسيع54وصفة تدريجيًا مع تغطية الهوية/الكمية/التحضير ومصدر كل مراجعة؛لا نسخ أنواع تغير تاريخ الطبخ |
|5| منتجات مصر/السعودية وGTIN والملصق وأساس100g/100ml/الحصة | استمرارOFFبشكل مساعد دون حد اكتمال عددي؛مراجعة ملصق وأساس،بحث وتوزيعshardsقبل توسع المحمول؛الرخص منفصلة |
|6| أسعار موثقة حسب البلد/العملة/وحدة/حجم العبوة/المدينة/المصدر/التاريخ | المستخدم أولًا ثم متوسط موثق؛سعر مجهول ليسصفرًا،تجميد المؤكد،وحساب شراء الناقص مقابل المخزون |
|7| ملفات الأشخاص والأهداف الصريحة،قواعد إرشادية موثقة حسب العمر/البلد | مقارنة التغذية بالأهداف بوضوح التغطية؛الحالة الصحية الحرة ليست تشخيصًا ولا قاعدة حذف طعام؛مصادر صحية رسمية ومراجعة مستقلة |
|8| بدائل الوجبات والمكونات،القيود والميزانية وتوفر المخزون | تخطيط من مبلغ/مدة،تنبيه تجاوز واقتراحات محسوبة؛لا تعديل تلقائي،لا ادعاء توازن عند نقص البيانات |
|9| باركود/QR وأنواع العبوات،وقراراتOCRللفواتير | lookupأولًا؛صورة الفاتورة قائمة مراجعة اسم/كمية/سعر قبلالحفظ؛تكرار/منتجغيرمعروف/ثقةواضحة؛لا شراء تلقائي |
|10| سلامة التخزين/تاريخ الصلاحية/البواقي مع مصادر البلد | دفعات ومواعيد وفتح العبوة/تبريد/تجميد منفصلة؛لا اختلاق صلاحية أوضمانسلامة،لا خصم مزدوج |
|11| اختبارات الحسابات والحفظ/العزل/offline/conflicts،وأرشفة التاريخ | إزالة اعتماد850KBقبل تراكم كبير،ترحيل بإصدار/rollback،اختبارات عزل المستخدم محليًا؛أيFirebaseفقطsofra-c03a1بلا فوترة |
|12| عقد بيانات الواجهة/Blenderومناطق اللمس/ميزانية الأصول | ربطAPIللتصميم الخارجي،تقليل أصول3DواختبارS24UltraثمAPKموثق؛لا بناء مشاهد/تصميم جديد هنا |

## الموجود والحدود

الحساب والحفظ ونسخةAPKسابقة موجودة؛نواة المال/المخزون/الأشخاص/الوصفات بإصدارات وتغذية موجودة.1690منتجOFFغيرمراجع،8156USDA،197مقترح هوية/53وصفة،وليس197ربطتغذيةكامل. نبدأ المقاييس ثم تكاملها؛لا نؤجل التنفيذ حتى يكبر بنكOFF.

## التشغيل والمراقبة

- docs/WORK-QUEUE.jsonهو سجل قابل للاستكمال؛لكل مهمةID/أولوية/حالة/تبعيات/خطوةتالية ومعيارقبول. آخر تقدم يحمل ملفات/فحصًا فعليًا؛تعديلالتاريخ أوعدد محاولات503ليس تقدمًا فيالمنتج.
- tool/work/watchdog.mjsقراءة فقط:يفحص الحدود،آخر تقدم،المهام الجارية والتبعيات،ومواعيد مصدرOFFالفعلية. إذا مر60دقيقة بلا تقدم علىمهمةجارية يطلب تشخيص المالك/العملية قبل أي عامل جديد؛لا يقتل عملية تلقائيًا.
- كل30دقيقة:فحص توقف ثم وحدةعمل قابلة للفحص. إن كانت مهمةجارية بالفعل لايبدأ كاتبًا ثانيًا؛يفحصالعمل ويستكمله. إذاsourcebackoffيختار مهمةمحلية متاحة. أي انتظاريسجل السبب والدليل والموعد والخطوةالبديلة.
- حد90%أوأordinaryUsageAllowed=falseأوالحدغيرمتاح:لا دفعة مكلفة،لا شراءرصيد أوreset. البياناتالمجهولة تبقىمجهولة. الإبلاغعند تقدم مهم أوتوقف بلا تفسير أوحاجةلتدخل؛لا تقارير503متكررة.
- جامع مصادر واحداقتصاديgpt-6-luna/mediumبسياق قصير؛الأعمال المعقدة ينفذها المنسق حسب الخطة. يدفعGitبعد وحدةمكتملة معفحوص مرتبطة وهاندأوف كامل/ملخص، ولا commitلمجرد مرورموعد.
- الجهاز وCodexلازم يكونوا شغالين للوصول للمشروع المحلي؛المراقب المجدول ليس خدمة سحابية تعمل والجهازمقفول. المرجع الرسمي:https://learn.chatgpt.com/docs/automations?surface=app.

## نقطة التنفيذ الحالية

أول وحدة:السجل والمراقب واختيارالعمل،ثم قارئ/حساب المقاييس المصدرية. الناتج الحالي مقترحات قياس تحتاج قبول صريح،وليس إعادة تفسير كميةالمستخدم أوتعديل مخزونه. وحدة1بالتالي توصل قبولالمقياس للحالة والتأكيد معاختبارات تطابق المخزون/التكلفة/التغذية؛تظل مفتوحة حتىاختبارها.


## تفاصيل الفجوات داخل المراحل

- **هوية الغذاء والبحث:** اسم موحد مع مرادفات مصرية وسعودية، نوع الغذاء وشكله وطريقة تقطيعه، فصل العلامة والمنتج والحجم والباركود. تدخل مع المقاييس وتغطية الوصفات؛ لا مطابقة مؤكدة بالاسم وحده.
- **العبوات والمخزون:** محتوى العبوة، الوحدات القابلة للتحويل ودليلها، دفعات الشراء وأسعارها، الموجود السابق مقابل شراء جديد، الحجز في الخطة مقابل الاستهلاك الفعلي، ترتيب اختيار الدفعة والبواقي والهدر. القرار غير المحسوم يوثق بسيناريو قبل تنفيذه؛ لا خصم عند مجرد التخطيط.
- **الطبخ والوصفات:** تغيير عدد الحصص يغيّر المقادير وفق الوحدة؛ وقت الفرن ودرجة الحرارة لا يتضاعفان تلقائيًا. بنك خطوات واعتماديات ومؤقتات وأدوات، اختلاف الطريقة والبديل، أوزان الناتج الفعلية مقابل عوامل المصدر، نسخ ثابتة للتاريخ.
- **الأشخاص والتفاعل:** شخص واحد أو أسرة وضيوف، فئات عمرية وتفضيلات وحساسية منفصلة، حضور الوجبة والحصة المقدمة والمأكول الفعلي. شكل الشخصية وترتيب الكراسي عقود للتصميم الخارجي؛ فرحة الشخصية ليست دليل ملاءمة صحية. لا أهداف طبية تستنتج من الجنس أو العمر فقط.
- **المال والشراء:** وحدة السعر والعملة والبلد وتاريخ صلاحية التقدير، تقريب الكسور وحجم العبوة والناقص الفعلي، تجميع قائمة شراء من وصفات متعددة دون عد الكمية مرتين، فصل تكلفة الاستهلاك عن ميزانية المشتريات. لا ترحيل تلقائي ولا إعادة تسعير التاريخ المؤكد.
- **الجدول والتوازن:** يوم/أسبوع/شهر وأكثر من3وجبات، تكرار ونقل وإلغاء الخطة، تغطية المغذيات والحساسية لكل فرد، ميزانية وحدود صريحة وبدائل قابلة للتفسير. المخطط ليس أكلًا مؤكدًا؛ التوازن يبقى غير محسوم مع بيانات ناقصة.
- **المسح والحفظ:** صلاحيات الكاميرا وموافقة حفظ الصور، ثقة OCR ومراجعة التكرار والكمية والسعر، باركود غير معروف وإضافة يدوية، فشل الشبكة وإعادة المحاولة دون شراء/خصم مكرر؛ عزل المستخدم وتعارض الحفظ والنسخ الاحتياطي وحذف بياناته تختبر قبل الإصدار.
- **حوكمة كل بنك:** تعريف الحقول والوحدات، مصدر ورخصة وتاريخ وإصدار وبصمة، حالة خام/مراجع/مقبول للمستخدم، فجوات وتعارضات وتصحيحات، اختبار استيراد وتغطية وتوزيع انتقائي. زيادة عدد السجلات وحدها ليست تحسنًا في دقة الحساب.

ترتيب قائمةWORK-QUEUEهو ترتيب التنفيذ الفعلي؛ جمع المنتجات مسار مساعد، وقد ينفذ بين الوحدات عند استحقاق المصدر دون تعطيل المهام الأساسية. المراحل الكبيرة تقسّم إلى وحدات ذات فحص وقبول واضحين قبل التنفيذ.


## تحديث تنفيذ 13 أكتوبر — تكامل المقاييس

اكتمل المراقب وبنك المقاييس ثم حفظ قبول المقياس وربطه بالخصم والتكلفة والتغذية. الوزن الفعلي له الأولوية، واستخدام وزن المصدر يتطلب موافقة عند التأكيد، مع حفظ علامة التقدير في النتيجة والتاريخ. أضيفت مهمة compound-revisions بأولوية25 لفصل المركبات بمقادير صريحة وإصدار جديد؛ لا تعد مكتملة. بعدها أدلة التحضير. APIs الجديدة لم توصل بالواجهة الخارجية بعد؛ راجع WORK-QUEUE للترتيب الفعلي.


## تحديث فصل المركبات والتحضير

اكتمل منطق فصل السطر المركب بإصدار جديد ومقادير صريحة ودليل مراجعة، دون تغيير الوصفات الأصلية أو نسخ روابطها. بدأت بعدها وحدة مصادر التحضير:4مراجعUSDA مفهرسة،0معاملات/تحويلات معتمدة. المهمة التالية استخراج ومراجعة أول صف مطابق وترخيصه، مع فصل المردود والجزء المأكول واحتفاظ المغذيات.


تحديث13أكتوبر:أرشيف retention الأصلي7018صفًا،9مرشحات مستخرجة ومراجعة حسابيًا،24خانة مجهولة،0تحويلات غذاء/طريقة معتمدة. بنكOFFزاد103إلى1793منتجًا عبر3صفحات سعودية؛كل الأسس غير مراجعة. التالي مطابقة وقبول طريقة التحضير،مع استمرار الصفحات المستحقة بعد تسليمGit.


## User-requested recipe research lane and data map —13 October

User explicitly requested an additional independent economical recipe agent. First bounded batch6research candidates/61ingredients/46steps with source groups/licences kept separate, research-only validation and DATA-MAP.md. Recipes are not automatically admitted into runtime. recipe-bank(priority55) continues source/version/units/family review and small regional batches without a final count; recipe-import(priority56) is the separate reviewed-to-revision/provenance/unknown-timing unit. No new automation/writer was created; existing monitor reads these tasks. Preparation evidence remains priority30; its completed category review is conditional,0runtime approvals. The direct user recipe/map request steered this unit; it did not cancel preparation work.

## تعديل أولوية المستخدم —بنك كبير ومحرك وصفات شخصية

المستخدم طلب الآن أكبر كمية عملية وتوسيع المطابخ:recipe-bank28 (2312/2428/52)،ثمrecipe-quantities29 أثناءbackoff،preparation30،recipe-import32،recipe-authoring34. لا اكتمال عددي للبنك،ولا متطلبات واجهة جديدة. مصدر429ينتظرموعده؛العمل المحلي على الوحدات/الربط يستمر. النواة اكتسبت حفظ/نقل الثقة؛مسودة من الصفر ما زالت مرحلة مستقلة. اقرأRECIPE-ENGINE.md وRECIPE-BULK.md.لا مؤقت جديد؛automation-2يقرأالقائمةالمحدثة.

## Heartbeat13:14 — completed source structure unit

Source ingredient sections and review cues are implemented/validated in research data. recipe-quantities29 continues exact line identity/explicit alternative review; recipe-bank28 respects source checkpoint. No source failure blocks independent local logic. Preparation30 and import32 remain available after this priority. No new scheduler or clinical rules.


## Heartbeat13:44 identity guard

Source batch240pages acquired;429checkpoint respected. Research identity proposal guard complete/6tests; nextcuration/authoritativefoodreader. OFF503 waits do not stop local logic. No source count completion cap.


## Heartbeat16:14: source readers, proposals and recovery

Usage became available again:0%/29% initially,21%/32% later; no reset or credit purchase tool used. Current English source category is exhausted after3796pages/3640parsed recipes. recipe-bank28 now discovers another licensed source/category/language; no final count cap. recipe-quantities29 has authoritative raw/source readers and8unreviewed proposals. Next extend identity/alternative curation, then separate runtime admission. OFF source backoff does not stop local work.

## Heartbeat16:56 — independent French source

recipe-bank28 now has French Wikibooks namespace0/prefix discovery, verified site policy and separate collection/parser/index/checkpoint. Continue due short batches; do not reset exhausted English cursor. Prefix pages are not all recipes; no unique-dish total across languages. During source backoff recipe-quantities29 remains independent. See RECIPE-FRENCH-SOURCE.md and HANDOFF§42. No new schedule or runtime/clinical assumptions.

## Local continuation after source delivery

recipe-quantities29added8cinnamon/leavening proposals;combined16/16/22/5,0runtime. Soaking/discard cases identify ingredient-fate evidence needed before nutritional admission. Source backoff did not stop local work. Continue source gates and explicit identity/alternative review;no automaticretention/clinicalrules.

Continuationafterlocalidentity:French450/625,429gate2026-10-13T17:49:47.599Z;source503/429doesnotblockrecipe-quantities29.16guardedproposalsavailable,noapprovals. Existingautomationwillreadactualcursorsandusage.

Heartbeat17:47 completed validated identity catalog with30related tests and actual2/16/16/5/22/0runtime. French source expanded to540/752;nextgate2026-10-13T18:01:42.279Z. Continue explicit alternatives/fate review and due collection; no numerical completion cap or automatic approval.

Local continuation:registered alternativebank3/24/22/9/50/1/0runtime;explicitveganunknown preserved. French621/874,gate2026-10-13T18:14:40.525Z;sourcefailures didnotstoplocalunits. Nextingredient-fate andexplicitchoice/quantity/form review,not automaticapprovals.

Completedtwoindependentlocalunits (catalogguards,explicit source alternatives),plusFrenchgrowth450→804parsedthisturn. Sourceavailablecursor,actualquota84/42beforelastguardedrequest;reserve90/recheckbeforeeachbatch. OFF503onlydelaysOFF. No task declaredgloballycomplete fromcount.

Heartbeat18:29:onebounded4requestbatch+34parsed toFrench838/1218,thenactualquota90/42ordinarytrue stopped furthercostlywork. Freshlimitrecheckbeforeanynextunit,no credits/reset;sourcecursoravailableandpreserved.


## Current checkpoint — heartbeat21:29 UTC

French inventory completed: 1489 source pages/1011 conservatively parsed recipes/7128 ingredient lines/6408 steps/128 request archives. SourceExhausted=true, no pending IDs, no listing continuation. English3796/3640 unchanged. Next licensed source discovery remains open; no source cursor reset or final bank count cap, no combined unique-dish sum.

New [ingredient-fate research](RECIPE-INGREDIENT-FATE.md) pins2source ingredient lines and6method steps; retained amounts and nutrient factors remain null,0runtime approvals.18linked tests/current source validators passed. Existing identity catalog3/24/22/9/50/1/0 unchanged. OFF2266/63 unchanged,503 gates saved. See HANDOFF§49 for exact requests, verification and next actions.


Spanish discovery now archived:3official API responses,CC BY-SA4.0 site policy,49first-prefix entries,0parsed recipes. [Source and next collector contract](RECIPE-SPANISH-SOURCE.md);HANDOFF§50. Consume archived firstlisting before continuation;no cuisine inference or exhausted-source reset.


## Spanish collector checkpoint — heartbeat21:59

[Spanish source contract](RECIPE-SPANISH-SOURCE.md) and data/recipes/bulk/es-wikibooks-recipes/index.json: 1043sourcepages/853parsed/6750ingredientlines/4981steps/85requestarchives. Parserv3/23tests/currentSHA+re-extraction+bootstrap49checks passed. Pending0,sourceExhausted=True,nextAttemptAt=None;read actual checkpoint. Research-only,0runtime/nutrition approvals;English/French/otherbanks unchanged,no combined unique-dish sum. Next:After actual quota/owner checks,discover Spanish singular Artes culinarias/Receta/ via bounded archived namespace0 nonredirect listing,using verified Spanish site policy;review scope/parser before collection. Then another licensed pool if needed. Preserve exhausted plural/English/French cursors,0runtime approvals. SeeHANDOFF§51.


## Source expansion and calculation foundation — heartbeat22:29

Current English/French/Spanishplural inventories archived,Spanishsingular1candidate verified with source-quality gaps. Ongoing recipe-bank task moves operationalpriority28→35,remainsready/open without a final record cap. Quantity29/preparation30/import32/authoring34 foundations can advance;source research continues as an economical independent lane. This prevents unrestricted discovery from permanently starving calculation/import work. Product/user decisions unchanged. Explicitone-choice backendrevisionAPI is implemented;bulk preflight/review/unknown timing and from-scratch persistence remain open. SeeHANDOFF§52–53.

## Import-draft audit checkpoint

[Source import-draft preflight](RECIPE-IMPORT-PREFLIGHT.md) now reports explicit exact-line quantity/form/choice/optional/reference/time review.29linked tests passed; English blank-template baseline3640/31774/24964,0runtime. A complete draft is not a nutrition or runtime approval. Next registered reviewed draft persistence and adapter gates; no UI/state/import changes. HANDOFF§54.

Registered source-draft continuation: [preflight/registry contract](RECIPE-IMPORT-PREFLIGHT.md);1explicit persisted blank draft/9lines/50issues/0complete/0runtime,36linkedtests passed. Exactnext: source-to-runtime adapter with required metadata/provenance and unresolved nutrition/form/retention gates. HANDOFF§55; no auto-discovery or guessed data.

## Structural adapter checkpoint

[Runtime candidate contract](RECIPE-RUNTIME-ADAPTER.md): explicit complete source drafts/metadata become CatalogRecipe-shaped candidates with full source/licence/line maps and remaining gates.44linkedNode+1actualFlutterreader/scalingpassed;analyzeclean. Transport validation rebuilds against currentauthoritativeinputs. No KitchenService import/nutritionapproval yet;next native provenance reader/immutable registration. OFF2287/64(+21/1),5banktestspassed;Saudi503gate23:49:13.371Z. HANDOFF§56.

## Native source import checkpoint

[Native import API/compatibility](NATIVE-RECIPE-IMPORT.md) now verifies exactUTF8 transport/source envelope and persists selectedreviewed roots atomically through KitchenService.importSourceRecipe. Full142Flutter+1additionalnutritionbinding/46Node/analyzeclean;no actualsourcebankpromotion/UI/usercloudwrites/automaticnutritionbindings. Quantity/import infrastructuredone;scientificcoverage remainsopen,preparation30next,privateauthoring34unblocked. OFF2378/67(+91/3),5actualbanktests;sourcegates incheckpoint. HANDOFF§58.


## Preparation implementation checkpoint —14October

Bounded category acceptance infrastructure30 complete: explicit one-method/exact-food/revision/line review and cooking acknowledgement, conservative missing data/frozen confidence. PREPARATION-ACCEPTANCE.md;full155Flutter+6sourceNode/analyzeclean. This does not close scientific factor coverage or source reuse review. Those continue under preparation-coverage51, leaving private from-scratch authoring34 as next independent core unit.


## Personal from-scratch drafts —14October2026

[PERSONAL-RECIPE-DRAFTS.md](PERSONAL-RECIPE-DRAFTS.md): owned explicit food/quantity/form/optional/scaling/estimate inputs with unknown cuisine/time/food/amount. KitchenService saves immutable reviewed versions/active pointers without a CatalogRecipe parent, exact expectedActiveKey, same-key collision protection, idempotent older retries and failed-save/850KB rollback. Typed sorted-object fingerprint survives storage map reordering. Separate ingredient/cooked previews use existing calculator. No automatic planning, stock or intake; accepted preparation scoped to another recipe cannot be copied. Full171Flutter/analyzeclean,8domain+8persistence cases. Finalization into a plannable recipe remains next under authoring34; do not invent metadata zeros or a parent. HANDOFF§60.
