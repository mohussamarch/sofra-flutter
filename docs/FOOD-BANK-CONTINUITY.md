# استمرار تطوير بنك الغذاء

## التفويض والحدود

- طلب المستخدم في12أكتوبر2026 استمرار البحث والتطوير دون حد عددي نهائي؛ مئات آلاف المنتجات اتجاه طويل المدى وليس ادعاء تغطية حالية.
- نسخة واحدة فقط: E:\work\SOFRA\app، المرجع origin/main. لا تعديل الواجهات أو Firebase أو الأصوات أو توليد الصور ضمن هذا العمل.
- وكيل جمع واحد اقتصادي gpt-6-luna بمجهود medium وسياق مختصر مستقل؛ لا فرق وكلاء متكررة بلا حاجة. لكل دفعة handoff مفصل وملخص صغير؛ المنسق وحده يحدث STATUS/HANDOFF المشتركة.
- افحص حدود الحساب قبل الدفعة وبعد تقدم مهم. احتياط تشغيلي: إذا استهلك أي حد90% أو أكثر، أو ordinaryUsageAllowed=false، أوقف الطلبات المكلفة واحفظ الحالة. استأنف عند توفر السعة في متابعة لاحقة. لا شراء رصيد أو استخدام reset credits. إذا الحدود غير متاحة لا تعتبرها صفرًا؛ انتظر فحصًا لاحقًا قبل دفعة مكلفة.

## المتابعة الفعلية

- تحديث13أكتوبر:متابعة داخل هذه المحادثة كل30دقيقة،automationId=automation-2،اسم «تنفيذ أولويات سُفرة ومراقبة التوقف»،ACTIVEومتحقق منTOMLالمحفوظ. تجمع المراقب والمنفذ في جدول واحد؛ليست عملية جمع دائمة بينالجولات.
- العمل المحلي يحتاج الجهاز شغالًا والتطبيق مفتوحًا والنسخة متاحة؛ قد تمنع صلاحيات البيئة طلبًا، ويسجل ذلك بوضوح دون ادعاء استمرار التنفيذ.
- قبل تشغيل جديد افحص قفل الجامع وحالة Git. لا تكتب فوق عمل جارٍ أو تغييرات وكيل آخر. إن تعذر جمع مصدر بسبب backoff، انتقل إلى مصدر/فئة مستحقة؛ إن لم يوجد مصدر مستحق احفظ الموعد وانتقل لأعلى مهمة محلية متاحة منWORK-QUEUE؛لا commitوهمي ولا حلقاتانتظار.
- لا ترسل تقريرًا متكررًا إذا لم يتغير شيء مفيد. أبلغ عن تقدم مهم أو خطأ يتطلب تدخل المستخدم أو اقتراب الحد.

## كل دفعة

1. اقرأ STATUS أولًا ثم handoff المرتبط فقط؛ لا تدخل JSONL أو ردود المصدر الكاملة إلى سياق النموذج.
2. استكمل tool/food/collect-incremental.mjs من data/food/openfoodfacts/collection-state.json؛ أرشيف المصدر وبصمته أساس الاستيراد. احترم مهلة المصدر والتسلسل وbackoff؛ لا تكرر نفس503/429 في دورة سريعة.
3. أبقِ البيانات الخام والمراجعة منفصلتين؛ GTIN صالح واسم ومصدر وتاريخ ورخصة. عدم وجود معلومة ليس صفرًا أو خلوًا من الحساسية. لا تخمين أساس100g/100ml أو أسعار أو حلال أو ترتيب شهرة.
4. تحقق من المكرر والعزل وتغطية المغذيات والفئات والأسواق والبصمات. شغّل الاختبارات المرتبطة فقط عند تغير الأداة/البيانات، واكتب نتائج فعلية.
5. حدّث الملفات المشتركة وإيصال الجذر، commit/push للتغييرات المكتملة، ونظافة Git وتطابق HEAD/origin/main. لا تغير بايتات data/** بلا تحديث بصماتها.

## التوسع

- الأولوية للفجوات في مكونات الطبخ، مع تنوع السكاكر والأغذية المعلبة وباقي الفئات، والصفحات التالية والأسواق المعتمدة EG/SA.
- بنك البحث قابل للنمو؛ لا تحمل مئات آلاف السجلات في Firestore kitchen أو تضفها كلها إلى APK تلقائيًا. قارئ Flutter الحالي يحمل فهرس المنتجات في الذاكرة؛ الانتقال إلى sharding/بحث مفهرس وتوزيع انتقائي مرحلة لازمة قبل نمو كبير للنسخة المحمولة.
- المصدر المجتمعي ليس مراجعة ملصق. راجع ربط الوصفات والتحويلات وأساس القياس بجانب زيادة الأعداد. لا تعلن تغذية الوصفات مكتملة بمجرد زيادة البنك.
- تعريفات المغذيات49 موجودة في lib/domain/food_nutrition.dart. السعرات بالكيلوكالوري/الكيلوجول والتحويلات الغذائية المتمايزة لا تجمع كأنها مغذيات إضافية.

## فحص البنك الفعلي

- شغّل `$env:SOFRA_FOOD_BANK = 'E:/work/SOFRA/app/data/food/openfoodfacts'` قبل `node --test tool/food/import.test.mjs`. بدون المتغير تعمل4اختبارات عامة فقط؛ المتغير يضيف الاختبار الخامس للبنك الفعلي والبصمات والمصادر. وثّق العدد الفعلي دون خلط النوعين.


## خروج الجامع وموارد الرد

- fetchArchive يقفل جسم ردHTTPالفاشل قبل رمي خطأ المصدر؛ فشل التنظيف لا يخفيHTTPstatusالمستخدم فيbackoff. [Undici الرسمي](https://github.com/nodejs/undici#garbage-collection) يطلب استهلاك/إلغاء الجسم لتحرير الموارد.
- طباعة ملخص الجمع ليست إثبات انتهاء العملية. انتظرexit_codeوسجّل تأخر الخروج بدقة؛ لا تختلق مدة من وقت المصدر ووقت pollالمختلفين. لا تبدأ جامعًا ثانيًا بسببظهورملخصفقط.
- فحوص الأداة عند تعديلها:حددSOFRA_FOOD_BANKثمnode --test tool/food/fetch-response.test.mjs tool/food/import.test.mjs tool/food/collect-incremental.test.mjs tool/nutrition/reference-review.test.mjs. عندتغيّرالبنكفقط يكفي5اختبارات البنك الفعلي. لا تعادفحوصFlutterلبياناتOFFفقط.
- اختبارchildمحلي يؤكدالخروج الطبيعي بعدإلغاءجسم503غيرمنته؛ ليسضمانًا لكلشبكة/مصدر. راقبالتشغيلالحقيقيالقادم؛ لا تُحل المشكلةبـprocess.exitإجباري أوإلغاءbackoff.


## المنسق الجديد

- ابدأ بخطةRESEARCH-ROADMAP وسجلWORK-QUEUE وفحصحدودفعلي ثمnode tool/work/watchdog.mjs --primary <actual> --weekly <actual> --ordinary <actual>. لا تعتبرHEADقديمًا أوعدمزيادةعددالمنتجات وحدهما توقفًا؛افحصالمالك/التغييرات/الفحوص/الدليل.
- بعد60دقيقة بلا تقدم موثق لمهمةنشطة،شخّص مالكها والعملية. لا تبدأ كاتبًا ثانيًا،ولا تنسب تقدممهمةأخرىإليها. مصدرخالي/مشوه يحتاج تشخيصًا قبلالجمع؛انتهاءصفحاتمعروفةيعني مراجعةتوسع،لا اكتمالالبنك.
- المقاييس/التحضير/الحساسية/الأسعار/الأشخاص عملمحلي مستقل عنOFF؛HTTP503يؤجل طلبالمصدر فقط. لا تكررنفسالطلبأثناءbackoff. وحدةالمقاييس الجديدة وAPIفيHOUSEHOLD-MEASURES.md.
- إشعار عند تقدممهم/عائقجديديحتاجالمستخدم/توقفعليغيرمفسر/اقترابحد،وهدوءعندعدمتغيرمفيد. الجهازوCodexيلزمهماشغالين للعملالمحلي؛لا وعدباستمرارأثناءإغلاقهما.


## Safe collector CLI

- Supported: node tool/food/collect-incremental.mjs [output-directory], --help or -h. Help exits before lock/network; unknown flags/extra arguments reject before side effects. New tool/food/collector-cli.test.mjs runs real child help/invalid-flag cases in an empty temporary directory and verifies natural exit/no files. Include this test when the tool changes.
- Incident13Oct08:54Z: cheap helper's formerly unsupported --help accidentally created a separate --help bank and fetched2pages; only its newly created directory was removed, primary bank unchanged. Root added argument validation/help and tests; do not repeat the old unsupported probe. Real primary run then made1request/HTTP503/exit0; checkpoint backoff saved. Record total3requests including the mistaken2successes; do not call them primary-bank growth.

## Explicit bounded module invocation —14October2026

CLI defaults to6requests and accepts onlyoutputdir/help. Root inspected and explicitly authorized the existing exported API for a single-request helper: import {withCollectorLock,runBatch} from './tool/food/collect-incremental.mjs'; await withCollectorLock(out,()=>runBatch({out,maxRequests:1,onProgress:item=>console.log(JSON.stringify(item))})). This is not a new CLIflag or alternate sourceURL. Resolve out to selectedcheckout/data/food/openfoodfacts. Fresh actualquota commandguard≤30sec, ownlock/backoff, scoped escalation for E/Git/CIM/network, actual exit are mandatory. No unrestricted/default6call when assigned1.

Heartbeat08:16: initial helperstopped0requests rather than use unsupportedCLIflag; root explicitly authorized documentedmoduleAPI, then1actualrequest/HTTP401 Saudi/globalp11, backoff09:49:45.471Z. No retry/alternateURL/authbypass. Products/index/manifest unchanged2378/67;failure-only checkpoint is not bank growth and does not require replaying banktests. Investigate official publicaccess requirements aftergate before retry;do not request credentials/changeaccounts or evade401 automatically.

## Shared upstream access gate —14October2026

tool/food/source-access.mjs derives the latest still-active401/403 failure expiry across all market/category jobs. Both runBatch and watchdog use it. Do not switch country/category while this source access gate is active. New401/403 stops the current batch after recording its failure; restart during the gate performs no request or checkpoint rewrite. Malformed access timestamps fail closed; ordinary503 job backoff is unchanged. Expiry means eligible for a fresh controlled attempt after checking official public access, not credentials, permission or guaranteed availability. ExistingSaudi401 gate09:49:45.471Z now also protects dueEgypt. This unit made no OFF network requests or bank rebuild.

Required focused gate after these tools change: node --test tool/food/source-access.test.mjs tool/food/fetch-response.test.mjs tool/food/import.test.mjs tool/food/collect-incremental.test.mjs tool/food/collector-cli.test.mjs tool/nutrition/reference-review.test.mjs tool/work/watchdog.test.mjs with SOFRA_FOOD_BANK set to selected checkout bank.36passed. Source backoff must not suspend independent work.

## Official OFF access prerequisite — §75

https://openfoodfacts.github.io/openfoodfacts-server/api/ requires a pre-use usage form and recommends exports for collections beyond a few hundred products. Reviewed draft: docs/OFF-ACCESS-REQUEST-DRAFT.md; first page asks contact email, later fields uninspected. Not submitted; awaiting user authorization/email, no external contact or invented traffic/organisation. The documented form may be a prerequisite but is not proven to cure previous401. No route/host/auth bypass or automatic requests when access backoff expires.2378products/67archives unchanged; no collection requests this unit. Continue independent recipe/core work. Product collection stays one cheapgpt-6-luna/medium lane when access, quota and lock are actually valid.


## Current usage declaration —15October2026 / HANDOFF§84

The user supplied the contact email in reply to the explicit submission permission request. The linked official Google Form was submitted and displayed "Your response has been recorded". OFF-ACCESS-REQUEST-DRAFT.md now records exact supplied/omitted fields; private contact/proof stay outside Git. Earlier pending-email descriptions are historical. This is form receipt, not verified API access/approval or a cure for401. Preserve failure/cursor/backoff,2378products/67archives,0collectionrequests/0bankgrowth. User-contact prerequisite resolved; product-bank is ready for source-access review after fresh eligible quota, not waiting for the same email again. At actual91/61ordinarytrue no collector or source research batch was started. No product edits/media uploads/account/contract acceptance.
