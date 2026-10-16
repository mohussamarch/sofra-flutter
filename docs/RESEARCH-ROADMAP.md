# سُفرة — أولويات البحث والمنطق والبنوك

تحديث16أكتوبر2026: توقف عند **2% متبقية**،أي استخدام **98%** لأي حد؛هذا ينسخ حدود99% و90% التاريخية أدناه. المجهول أو ordinaryUsageAllowed=false يوقف البحث المكلف؛لا credits/reset. المراقب `--quota-limit 98` بالقيم الفعلية. استكمال الجلسات في `docs/CLAUDE-RESUME.md`؛كاتب واحد فقط على نسخة E.

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

Source batch240pages acquired;429checkpoint respected. Research identity proposal guard complete/8tests; nextcuration/authoritativefoodreader. OFF503 waits do not stop local logic. No source count completion cap.


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


## Reviewed draft publication —14October2026

[PERSONAL-RECIPE-PUBLICATION.md](PERSONAL-RECIPE-PUBLICATION.md) supersedes the earlier unimplemented bridge checkpoint. PersonalRecipeFinalization owns the full draft, explicit metadata/durations/inventory IDs/review and canonical derived IDs. KitchenService.finalizePersonalRecipe publishes an authored root and exact food selections atomically from the saved active draft, with expected active recipe guard and immutable retries. Existing planning/cooking now works; no fake parent, stock/intake on publication, UI/cloud activation or automatic scientific approval. Missing metadata, unsupported estimated quantities and base precision loss reject; unknown food remains unknown. Full183Flutter/analyzeclean. Older clients do not support authored kind. HANDOFF§61.

## Latest user-directed order —14October2026

Price acquisition research nowpriority30 and recipes35 continue in parallel (one bounded economical source helper). Price research contract/tools/34observations complete; next verify a current licensed official export and fresh produce/meat coverage before provider integration. PRICE-SOURCES-EG-SA.md lists evidence and gaps. Arabic1/German177candidates from250Germanpages acquired; exact cursor and no-clobber/quota gates in RECIPE-EXPANSION-AR-DE.md. Other foundations and source banks remain as documented; no bank completed by reaching a count.

Follow-up: historical36officialEGretailintervals/June2025importedforcontracttesting,0current/liveapproval;12Nodepassed. DEcontinuedto550/375;formatbugfixedbyactualformatregression. Currentofficialfreshfeedstillonprices30;independentlicensedrecipes35continueatKochbuch/_Pesto.

## Current recipe source correction —14October2026

The latest user request replaces the previous source expansion direction: modern Arabic YouTube cooking personalities first; no further collection from recipe books/historical references/Wikibooks now. Preserve prior banks. Follow RECIPE-ACQUISITION-ARABIC-YOUTUBE.md for official source discovery, recipe/variant grouping, provenance and nutrition review. Prices remain an independent task; their sources and USDA/OFF nutrition bank scope are unchanged. Quota90/89 currently prevents new costly acquisition.

##14October — closed units and next order

Completed a bounded local curation unit(16Arabic records/4explicit preflightdrafts), modern Arabic creator unit(6website recipes/14videodiscoveries), pinned Flutter readable library(22records), and stock-aware planned purchase forecast(18tests). Source acquisition remains ongoing; no final bank completion claim. Current status is FEATURE-STATUS.md; detailed APIs RECIPE-LIBRARY.md/BACKEND-API.md. Next prioritize resolving curated recipe metadata/rights/quantity gaps and source-supported modern creator recipes; monthly budget optimizer still needs reviewed prices/people constraints. No booknetwork resurrection, UI activation or fake nutrition.

##14October — market-first source correction

Latest user priority: real retailer and delivery-app prices first; government sources are secondary, no waiting for government exports. See MARKET-PRICE-INTEGRATIONS.md, new official-source EG/SA dossiers, and offline partner-catalog-candidates.mjs (8tests). Talabat/HungerStation partner scope is own chain/vendor; Salla/Zid can read consenting merchant catalogs. No live feed or reuse permission acquired. GASTATJuly2026 workbook/100food rows saved as raw source checkpoint only; no normalized/livepricebank/currency approval. Arabiccreatorsecondbatch adds2website recipes with explicit source omissions;22bundled readable entries unchanged, nextassetintegration separate.

## Current completed bounded units — §71

After actual quota reset, completed library-to-private-calculator review and atomic provenance persistence,4additional archived Arabic records,2source-supported timer proposals and3modern official creator-website records.31selected readable records now bundled;224Flutter/12Node/creator validator pass andanalyze clean. Banks remainongoing, notdonebecause ofcounts. Next local source omissions/real food+quantity review and modern complete creator recipes; source-backed publication/rights stay separate. OFF401Egypt/global11 delays source only through16:33:18.596UTC; product count remains2378/67archives. Marketpilot still requires permitted real merchant sample. No repeated government prerequisite, no booknetwork. Current heartbeat defaultquota ceiling90; earlier99override applied only to its continuation. Full contract LIBRARY-RECIPE-CALCULATOR.md.

## §72 bounded banks and independent core unit

Completed8archived+5modernwebsite records and creatorprovenancefix;44readable records,225Flutter/17recipeNode/analyze clean. Then continued independentallergen-evidence40 with a boundedofficialsource bank:2SFDA sources,7anchoredresearchclaims,15exactmappingproposals; noEG/currentlaw/product/clinicalapproval. This unit does not close remaining allergen coverage. Next real productlabel/source/version evidence, reviewed compoundlinks and EGofficial content. A continuouslyready recipebank must not consume every workunit: keep one boundedrecipeexpansion lane and advance the next independentcore unit with distinct ownership. OFFgate/sourcefailures still do not block localcorelogic. Currentactualquota74/27ordinarytrue,default90 ceiling,no credits/reset.

## Progress and next independent units — §75

Archived local8 and modernwebsite3 added,55selected library total; source category labels30local. Manufacturer label bank4observations +strict Flutter reader built in parallel; exact-market/GTIN/physical label approval0. After this bounded bank+core integration, prioritize actual food/quantity gaps or next modern Arabic creator batch and explicit label linking/price merchant sample; do not wait for OFF. OFF official pre-use usage form draft is reviewable but needs external-submission authorization/email. Unknown form/401cause is not resolved by an expired timer. No newbooknetwork or live price claim.

## Next reviewed inputs after quantity audit — §76

Source library now63 entries/38 local cuisine-region labels. Independent core unit delivered: indexed quantity-gap report tied to the calculator source pin. Next use it for a bounded source-supported food/quantity review, then next modern creator/different-family source batch plus independent core. Continuous ready banks remain open; missing product access/merchant data does not stop these local units. No quantity or food acceptance inferred from report counters or culinary completeness.

## Task progress diagnosis repaired — §77

Continue source/logic units while actual quota permits: after §76 delivery, a bounded modern creator batch added2website records and coordinator repaired monitor task progress plus source evidence transport. Source search/index facts remain distinguished from direct/current body/video retrieval. Highest next review uses indexed source quantity/identity gaps; fresh primary access/date/channel/rights evidence still needed. No timer/attempt counted as product progress.

Watchdog now validates task.lastProgressAt and uses latest recorded own-task or matching global progress. lastAttemptAt is fallback only if neither real progress value exists; recent unrelated work or attempts cannot hide a stale owner. At60min without progress diagnose the existing owner/process before resuming/releasing. No automatic spawn/kill/queue mutation or quota/backoff change.

## Current §79 — concrete search bridge and modern source

66selected source records now include one officialManal indexedvideo-description recipe. Source-pinned ingredientfoodsearch connects library review to licensed banks with explicit query and ownedresultcontext;603of681lines havequantitygaps. Next bounded unit is actual source/food/amount/form review via that API, plus distinct moderncreator sources when quota permits. Do not resume historicalbooknetwork or wait forOFF/merchant sample. Source-request budget must count underlyingqueries/opens; last14>8overrun disclosed and sourceworkstopped. Core source-kind/URL-ID guards/dedup tested,247fullFlutter/31Node; rights/runtime/clinicalapprovals0.

## Current §80 — another bank unit and independent selection logic

Continued after§79with actual26/51ordinarytrue:4offlinearchivecurations/4newsourcecategorylabels plus explicitUSDAcandidate selection guardedbyrecipepin/ack/form/resultID/foodversion-name. Library70/13packs/48snapshots,42localsourcelabels;642of722quantitygaps.250fullFlutter/34Node/analyze5.2s. Next source/food/quantity/form reviewedinputs or distinctmoderncreatorbudgetedbatch; keepbankscontinuousandadvancecore. No newbooknetwork;OFFform/merchantaccesspending separately. No automaticclinical/rights/nutritionapproval.

## Current §81 — another bounded bank and core unit

Fresh43/53ordinary=true allowed8 offline archive curations and explicit packaged source selection. Library78/14packs/56snapshots,50 local source labels;715/797 indexed source quantity gaps. Whole package snapshot/market/barcode and scoped optional label basis are checked before using the existing packaged reader.254Flutter/33Node/analysis6.1s. Continue actual source food/quantity/form review or a pre-budgeted distinct modern/local batch; no new books/network this unit. OFF form and merchant sample remain separate prerequisites; no clinical/rights/nutrition approvals.


## Current §82

84 readable source records =62 offline archive +21 creator website +1 indexed video description;15 pinned packs/62 snapshots,51 local source cuisine/region labels. Planning54/4 and reviewed method family1 unchanged;0 new runtime/nutrition approvals. Continued after§81 at61/56 ordinarytrue. Six more offline curations and independent explicit source mass decision bridge; no network/newbook collection. Final258Flutter/27Node/analyze clean. Next reviewed food/quantity/form inputs, distinct modern Arabic creator batch with pre-counted query/open budget, then continuous bank/core. OFF pre-use contact authorization and merchant sample are separate prerequisites, not reasons to stop local core. Fresh quota before next bounded unit; preserve90 ceiling/reserve.


## Current §85

86 source records=62localarchive+21creatorwebsite+3indexedYTdescriptions;16packs/62snapshots,51local source labels. Planning54/4 unchanged. New read-only monthly explicit alternative comparison and runtime OFF contact/privacy guards;269Flutter/62Node/analyze clean. HANDOFF§85. New actual0/0ordinarytrue reading resumed after documented priorquotareserve; no reset/credits used byagent. Source budget4/8underlyingrequests and oneOFFdiagnostic only; no books. Next bounded unit: KitchenService snapshot-safe monthly advisory adapter or actual reviewed recipe quantity/food/form inputs, while distinct modern/local sources continue. Full automatic monthly menu generation remains open and should not be gated on continuous research completion merely to build core.


## Current §86

88 readable source records=62localarchive+23creatorwebsite+3indexedYTdescriptions;17packs/62snapshots,51local source labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. KitchenService snapshot-safe monthly advisory adapter implemented;282fullFlutter/36relatedNode/analyze clean. HANDOFF§86. Next independent core unit: bounded deterministic search over explicit reviewed slot candidate pools, unknown/truncated search indeterminate, no automatic application or clinical claims. Modern Arab creator acquisition remains primary; no new book network. Actual quota64/10ordinarytrue; no credits/reset used. Merchant catalog sample/user contact question pending; no outreach authorized. OFF source503 wait does not block local logic.


## Current §87

90 readable source records=64localarchive+23creatorwebsite+3indexedYTdescriptions;18packs/64snapshots,53local source category labels. Planning54/4 and naanmethodfamily1 unchanged. Bounded explicit-candidate monthly search implemented;292fullFlutter/30relatedNode/analyze clean. HANDOFF§87. Next bounded core unit: KitchenService search adapter using current/pinned explicit pool choices and existing decisions/prices/snapshotguard. Full diversity/person-target planning remains open; source collection independent. Actual84/13ordinarytrue nearing90reserve; finish current delivery, fresh usage before new costly unit. No credits/reset/newbooknetwork.


## User batch and quota correction —15October2026

User correction15October2026 supersedes all earlier90percent instructions: operational ceiling99 for both primary and weekly; unknown usage or ordinaryUsageAllowed=false still blocks costly work, no credits/reset. automation-2 updated through app tool, same30minute schedule/thread. Always pass watchdog --quota-limit 99 with actual usage. Every recipe batch target at least1000 actual recipes (nonempty ingredients AND method), goal at least10000; all cuisines, Asian cuisines included, Moroccan/Greek/Omani are examples not exclusive. Report actual accepted count, duplicates/rejections/access failures and specific reason whenever below1000. Count discovery URLs separately; no tiny2–8batch presented asmeeting1000. Separate existingarchive normalization from new acquisition, source records from distinct dishes and reviewed/plannable recipes. Modern Arab creator/video sources remain priority for acquisition, no newoldbooknetwork. Existing6056offlineprocessing remains explicitlyauthorized. Source cuisine category is evidence, never inferred from language/names or automatic planningapproval. English original text stays English until real translation/review. Bulk importer must retain original source/revision/SHA/license, unknowns and validation; no invented recipes/prices/nutrition/medicalrules. Rootalone sharedfiles/Git; independentcore continues when quota permits.


## Current §88

1090 readable source records=1064offlinearchive+23creatorwebsite+3indexedYTdescriptions;19packs/1064snapshots,71local source-category labels. Planning54/4 and reviewed naanmethodfamily1 unchanged. Native1000-record batch and snapshot-safe monthly candidate search service implemented;306fullFlutter/31relatedNode/analyze clean. HANDOFF§88. User99ceiling/min1000batch/goal10000 supersedesprior90/tinybatches; automationupdatedandwatchdog--quota-limit99. First1000offlineconversionclosed; next1000distinctsource-record conversion withbaseline/dedup, scalablemodern acquisition remainspriority, exactshortfallreasonsmandatory. Coremonthlysearchserviceclosed; fullmenu/preferences/person-target constraints remainopen. Prior4+hourinterruptioncausedusagelimit/approvalreviewfailure, notOFF503; actual1/16allowedresume, noreset/credits.


## Current §89

2090 readable source records=2064archive+23website+3indexedYTdescriptions;20packs/2064snapshots,71local source labels unchanged. Planning54/4/methodfamily1 unchanged. Second1000native conversion and explicit repeat/diversity search preferences;319fullFlutter/37Node/analyze clean. HANDOFF§89. Second exact1000 native source records+1000snapshots,8479ingredients/6936steps,0newacquisitions/translations/runtimeapprovals. Frozen19pack baseline coversall1090previous;1064prior archive identities excluded inclfirst1000,2575eligible. Indian42/Italian11,947untagged; no guessedsourcecuisine. All accepted quantity/unit/yield/timeunknown; rawtext/candidates preserved. buildBatch reusable safeone-basename outputFolder, defaultfirstpackbytesunchanged; original6+new6Nodepassed,both--checkpassafterregistration. PackSHA1d65a70f09930fd5b6e375069a6869080d424d3868f43dc55c9e1ea0c82905c7; originalpack26d6ca...unchanged. Nextmodernpublicdomainlead BasedCooking site-linkedcontentrepository; collector mustselectMarkdown/licencetextonly,pincommit/excludeallimages/media,dedupagainstcurrentlibrary andreportactualaccepted/1000shortfall. MealDB793publisherclaim alonebelow1000/freeprototype/supporterfullaccesslimitations cannotbebypassed. RecipeNLGdatacontractunverified. No1000newmodernbatchclaimed;12/12assessmentrequests2queries+10opens,0collection. See modern-bulk-alternatives-20261015 notes. User99/min1000/10000goals unchanged; independentcorepersonconstraintsremainopen.


## Current §90 —16October2026

3530 readable source records=3064 previously acquired archive conversions+440 newly acquired Based Cooking rows+23 creator websites+3 indexed video descriptions;22packs/3504 snapshots. Third exact1000 archive conversion met the native-unit target, not new acquisition. Modern source acquired440/1000, short560 due pinned source size; next lead search0/1000 with11requests, Suhtayn terms block bulk reuse without permission and its733 publisher claim is below target. Do not count discovery pages, duplicate bilingual variants or the old6056research rows as ready recipes. English3440 untranslated, local source labels71 and planning catalog54/4/methodfamily1 unchanged. Source optionality null preserved in Flutter and required caller month slots now gate bounded budget search; no full automatic menu/person/medical claim. Full current Flutter/Node/analyze and exact next work in HANDOFF§90; do not restart book network. User99% ceiling/no credits remains. Continue modern Arabic creator/video priority, broader world cuisines, actual quantity/food/rights review and live merchant sampling independent of OFF source backoff.


## Current §91 —16October2026

4530 source records=4064 existing archive conversions+440 Based Cooking+23 creator websites+3 indexed video descriptions;23 packs/4504 snapshots. Fourth offline French batch pinned1000 source records, but source-line audit found only988 with ingredient+method text free of unresolved markup, **12 short of the user's1000 fully extracted text target**. The original parser had stripped ingredient-reference names in946 rows and omitted125 ingredient lines in77; the new adapter restores only literal source parameters from pinned wikitext and flags12 unresolved rows, preserving parser and raw evidence. 7167 ingredient lines/6330 steps,0 new acquisitions/translations/runtime or nutritional approvals. Exact and semantic duplicate checks have different scopes; no claim of1000 distinct ready dishes or new approved cuisine. Source-language untranslated4440; planning54/4 unchanged. Person-target interaction now reports complete estimated subtotals as estimated and legacy null confidence as unknown, without clinical inference. Detail, hashes, check gates and next actions in HANDOFF§91 and `docs/PROGRAM-STATUS-20261016.md`. Continue modern Arab creator priority, complete extraction review, prices and independent core work; no new old-book network or OFF-blocked logic.
