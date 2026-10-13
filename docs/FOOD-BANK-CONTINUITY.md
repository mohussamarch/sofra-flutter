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
