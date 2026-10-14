
# توسعة بنك الوصفات العربي والألماني

14 أكتوبر2026؛ المصدران مستقلان خارج Flutter assets وshipping recipes.

| المسار | المصدر/النتيجة | المكونات/الخطوات | الحالة |
|---|---|---|---|
| العربي |5طلبات رسمية ناجحة، مرشح واحد كتاب الطبخ/كعكة-1-2-3-4 rev227030|8سطور/6خطوات|مرشح بحث؛0runtime |
| الألماني |250مراجعة صفحة محفوظة؛177مرشحًا؛73صفحة غير محللة|1493سطرًا/998خطوة أو فقرة|0ربط غذاء/تغذية/مطبخ معتمد |

هذه سجلات مصادر وليست أطباقًا فريدة عبر اللغات. اللغة ليست المطبخ، والسطر الخام ليس كمية معيارية معتمدة. الكميات/الوحدات القياسية والحصص والأزمنة غير المحسومة تبقى null. لا نضيف صفرًا لإرضاء نموذج التطبيق.

المسارات: data/recipes/source-discovery/ar-wikibooks/ وde-wikibooks/، والأداتان extract-ar-wikibooks-research.mjs وextract-de-wikibooks-research.mjs. يعاد اشتقاق JSON/JSONL من المراجعة الأصلية مع المصدر/التاريخ/المؤلف/بصمة النص؛ بصمة محلية ليست توقيعًا من المصدر. CC BY-SA4.0 العام محفوظ؛ استثناءات كل صفحة لم تُراجع. يلزم لاحقًا قارئ مسجل ومراجعات كمية/ترخيص/تعليمات/غذاء قبل importSourceRecipe؛ القارئ التشغيلي الحالي للبحث الإنجليزي فقط، ولا ترقية جماعية تلقائية.

## حادثة الأرشيف وإصلاحها

جامع الألماني اختار تسلسلًا خاطئًا بسبب wildcard فأبدل جسمي رد أصليين لأول100صفحة. هذان الجسمان فُقدا ولم ندّع استعادتهما. حُفظت150صفحة الاستكمال، وأجري طلبان جديدان مستقلان لأول100صفحة مع وقت وبصمات جديدين. المجموعة الحالية250 مراجعة فريدة. إجمالي8طلبات ناجحة،6أرشيفات رد باقية (سياسة المصدر+5مجموعات صفحات). لا نسمي طلبات الاستعادة أرشيفًا أصليًا.

أداة الكتابة الآن CreateNew ومنع التصادم قبل الشبكة وتسمية تدعم100+، قفل خاص بالمسار وفحص CommandLine للكاتب، لا يحجب سيرفر المعاينة. حارس حدود حديث قبل كل طلب، false/مجهول/90%/أقدم من30ثانية يرفض؛ لا شراء رصيد أوreset. المصدر له backoff ولا إعادة طلب فوري. دليل الاستخدام ملف JSON خارج Git: checkedAt،primary،weekly،ordinaryUsageAllowed، من قراءة أداة حقيقية؛ لا تستعمل قيم الاختبار للبحث.

تشغيل لاحق من E:\work\SOFRA\app:
pwsh -NoProfile -File tool/recipes/fetch-de-wikibooks-next-batch.ps1 -UsageGatePath <fresh-actual-usage.json>
ثم node tool/recipes/extract-de-wikibooks-research.mjs بعد خروج الجامع؛ لا مصدر وكاتب اشتقاق متزامنان.

التالي: gapcontinue=Kochbuch/_Gnocchi_mit_Lauch_und_Schinken، continue=gapcontinue||. اقرأ checkpoint والقفل وافحص الحدود أولًا؛لا تعيد بداية الفهرس. حتى3طلبات متتابعة/2ثوان pacing؛قد تنتهي صلاحية دليل الحدود أثناء الدفعة فيقف دون HTTP أو backoff زائف. أسماء أجسام الردود وأرشيفات الفشل محجوزة أيضًا في التسلسل؛ يتجاوزها رقم الأرشيف التالي مع الاحتفاظ بالمؤشر وبوابة الانتظار، ولا يحذفها.

الفحوص: إعادة استخراج عربية وألمانية تطابق البصمات دون اختلاف. فحص PS محلي نجح لمنع استبدال بايتات قائمة والتسلسل101 و8أدلة حدود غير صالحة؛ لا شبكة أثناء الفحص. العربي01-siteinfo احتفظ JSON محللًا وبصمة الجسم دون الجسم نفسه؛02–05 أجسام محفوظة. لا ندّعي إثبات جسم غير موجود.

## Continued acquisition and actual sequence-format fix

A real collector invocation failed before HTTP: Measure-Object.Maximum producedDouble; D2integerformat refusedit. Numericcomparison-only earlier tests missedthetype. Root added actual '{0:D2}-pages' regression:RED withsameerror; integer(long)output fixedit/GREEN. Outer local errors now local-error-stop rather than misleadingrunning, withnullHTTPstatus andnobackoff;sourcecursorpreserved. ScopedCIM requires approvedescalatedshell inthisenvironment; sandboxdenial was not bypassed.

Subsequent successful boundedbatches retained existingarchives andnowgive550fixedpages/375candidates/3287ingredients/2146steps;175unparsed,12retainedwrappers. Previous250/177countsabove are historical checkpoints. Currentcursor:Kochbuch/_Pesto,continue=gapcontinue||. Actualrequestcounts/exacttimestamps/hashes andzero-requestlocalfailure in docs/agents/recipe-expansion-de.md/.status.md. Allcanonicalquantities/time/food/nutrition/cuisineunreviewed,0runtime. Root independent deterministicregeneration andPSsafety/format checks passed. Nooverwrite/reset/backoffbypass.
