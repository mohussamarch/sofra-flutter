
# مصادر أسعار الغذاء — مصر والسعودية

14 أكتوبر 2026. البحث في نسخة E:\work\SOFRA\app، بلا تغيير واجهات أو Firebase. هذا تسليم بيانات وأدوات بحث؛ **0 أسعار مقبولة في runtime، ولا متوسط وطني محسوب**.

## النتيجة المحفوظة

| السوق | مشاهدات البحث المحتفظ بها | طبيعتها |
|---|---:|---|
| مصر |30|5 أسعار تجزئة Carrefour في سياق المعادي/القاهرة، و25 سعر غذاء معلن لمبادرة وزارة التموين |
| السعودية |4|Danube في سياق الشاطئ/جدة؛ اثنان غير متاحين، والآخران يعرضان زر شراء دون تأكيد مخزون فعلي |
| الإجمالي |34|فهرس بحث موحد، جميعه غير مقبول للاستخدام التشغيلي |
| Open Prices، منفصل |4 نتائج بعملة EGP و3 بعملة SAR|نتيجة استعلام العملة وليست عدد منتجات أو تغطية مؤكدة للبلد |

المسارات: data/prices/research/egypt-sources.json (8 ملفات مصدر وصفية/30 مشاهدة)، saudi-sources.json (7 مصادر/5 مشاهدات؛ واحدة snippet مستبعدة من الفهرس)، observations.json (34). Open Prices له probe.json وردان أصليان في open-prices/ ورخصته منفصلة.

تواريخ الرصد لا تعني أن الأسعار سارية اليوم. الأسعار المصرية الحكومية منشورة 23 سبتمبر وبدء المبادرة المعلن 25 سبتمبر 2026؛ انتهاء العرض والمخزون الحالي مجهولان. أسعار المتاجر قد تأتي من صفحات مخبأة، وتاريخ السعر الفعلي غير معلوم. لا نستنتج شهرة المنتج أو انتشار السعر من نتيجة بحث.

## من أين نجلب كل نوع؟

| الاستخدام | مصر | السعودية | القرار العملي |
|---|---|---|---|
| مرجع إحصائي عام |CAPMAS|GASTAT Average Prices of Goods and Services|الأفضل للمرجع الشهري عند التحقق من أحدث جدول ووحدته وتاريخه ورخصته؛ ليس سعر فرع أو عرض |
| سلع مصنعة وباركود وعبوات |Carrefour وSeoudi وموردون متعاقدون|Danube وLulu وPanda وOthaim وCarrefour|نطلب feed/API أو تصريح إعادة استخدام؛ لا نفترض أن ظهور الصفحة يبيح التجميع التجاري |
| خضار وفاكهة طازجة |سوق العبور/قطاع الشؤون الاقتصادية/agriprice|المتاجر + مرجع GASTAT|العبور جملة، لا نخلطه بتجزئة المستخدم؛ نحتاج الصنف والدرجة والمنطقة ووحدة البيع |
| لحوم ودواجن وأسماك |إعلانات الوزارة والمتاجر ثم موردون موثقون|المتاجر والمرجع الإحصائي ثم موردون|نفصل النوع والقطعة والعظم والطازج/المجمد والمنشأ؛ تغطية الطازج والأسماك غير منجزة |
| ما دفعه المستخدم |سعر يدخل يدويًا أو فاتورة يراجعها|نفس المنطق|أفضل دليل على مشترياته الفعلية؛ لا نشر أو رفع فواتير تلقائيًا |
| مصادر مجتمعية |Open Prices|Open Prices|مساعد منخفض التغطية حاليًا، ODbL، لا يصلح وحده كمرجع البلد |

مصادر أولية:
- [وزارة التموين: إعلان المبادرة](https://www.msit.gov.eg/?p=7509):25 بندًا غذائيًا؛ استبعدنا5 بنود تنظيف.
- [GASTAT: منهج ومعلومات متوسط الأسعار](https://www.stats.gov.sa/en/w/apgs)، [قائمة الإصدارات](https://www.stats.gov.sa/en/statistics-tabs?category=121662&delta=4&tab=436312). ظهر إصدار يوليو2026/نشر13أغسطس؛ لم نثبت أنه أحدث إصدار متاح اليوم، ولا ملف XLSX مباشر قابل للاستيراد.
- [Danube شروط الاستخدام](https://api.danube.sa/en/pages/terms-and-conditions): مشاركة بيانات الموقع/التطبيق مع أطراف أخرى تتطلب إذنًا. Lulu يقيد الاستخدام الشخصي غير التجاري دون موافقة مكتوبة. بقية الرخص/التغذيات غير مثبتة.
- [Carrefour مصر: عبوة لبن1لتر](https://www.carrefouregypt.com/mafegy/en/juhayna-full-cream-milk-1l/p/12721): مثال صفحة منتج مع وزن/سعة، وليس مرجعًا وطنيًا.
- [Open Prices بيانات وAPI وترخيص](https://github.com/openfoodfacts/open-prices/blob/main/docs/guides/data.md)، [استعلامات الأسعار](https://openfoodfacts.github.io/documentation/docs/Open-prices/prices/prices_list/). استعلامان HTTP200 محفوظان، آخر عينة EGP بتاريخ2024-12-24 وعينة SAR بتاريخ2026-08-09؛ لا اعتماد للسعر أو هوية الباركود أو وزن العبوة.

CAPMAS ظهر ببيانات وصفية قديمة2017، دون جدول أسعار حديث مؤكد. العبور timeout، وجداول الزراعة/IDSC غير متحققة. نشرة الوزارة التاريخية PDF فشلت في التحميل؛ لم نخترع صفوفًا منها. تفاصيل كل تجربة ومصدر في البنكين وهاند أوف الوكيلين.

## العقد البرمجي الذي بُني

tool/prices/price-observations.mjs وbuild-research-index.mjs، بحث فقط، غير موصول بحالة KitchenService أو MarketPrice.

السجل يحفظ: id، البلد/العملة، نوع المصدر (retail/wholesale/statistical/initiative/community)، المبلغ، العبوة المعلنة، الرابط، تاريخ الرصد، تاريخ السعر إن عُرف، الفرع/المدينة/هوية الصنف، الإتاحة، العرض ومدته، حالة الإذن والمراجعة. الفهرس يحفظ مراجع وبصمات ملفات المصدر. المصدران يحتفظان كذلك بضريبة/شحن/عضوية/شكل الغذاء عندما يذكرها المصدر؛ المجهول null. ترقية السجل للتطبيق تحتاج توسيع هذه الحقول في العقد التشغيلي ومراجعتها، وليست منجزة هنا.

- g→kg وml→l حساب فقط من العبوة المعلنة. لا كثافة مخمّنة، ولا تحويل حبة/مكعب إلى جرامات.
- المقارنة تشترط نفس البلد والعملة والمدينة والصنف والوحدة، وretail فقط؛ لا خلط مبادرة أو جملة أو إحصاء مع تجزئة.
- أحدث دليل للمتجر يُختار قبل فحص أهلية السعر: معلومة أحدث عن نفاد المخزون لا تعيد سعرًا قديمًا. تعارض أحدث سجلين يرفض؛ ترتيب الملفات لا يحسمه.
- لا تقدير من سعر مجهول التاريخ، أو عرض مجهول/منتهي/مستقبلي، أو إذن/مراجعة غير مقبولين. النطاق وعدد المتاجر يظهران مع أي تقدير تجريبي.
- جميع السجلات الحالية itemKey/storeKey غير معتمدين؛0eligible،0runtimeReady. الأداة لا تدّعي مصادقة المصدر أو الموافقة القانونية.

الفحوص الفعلية:9 Node نجحت، تشمل إعادة بناء الفهرس نفسه والتحقق من5 بصمات مقاطع أسعار مصرية وردّي Open Prices. بصمة المقطع لا تساوي أرشيف صفحة كاملة؛ الأسعار الحكومية المنقولة لا تحمل بصمة جسم HTTP. لا نحول عدم الأرشفة إلى دليل وهمي.

## التنفيذ التالي حسب الأولوية

1. استيراد جدول رسمي حديث قابل لإعادة الاستخدام لكل بلد، مع فترة السعر والسلعة والوحدة والمصدر. اختبر اختلاف الجملة والتجزئة والمرجع الشهري.
2. حسم إذن/feed من متجر أو مورد بكل بلد، ثم عينة حديثة لمدينة/فرع واضحين تشمل خضارًا ولحمًا طازجًا وأسماكًا. لا استخراج hidden API أو تجاوز شروط.
3. مراجعة هوية المنتج/العبوة/الشكل/الباركود وربط ingredientID أو productID صريحًا؛ المراجعة لا تعتمد على الاسم وحده.
4. توصيل مزود الأسعار الموافق عليه بالخدمة مع أولوية سعر المستخدم، وإبقاء المرجع والتاريخ وعدد المشاهدات واضحين.
5. اختبارات فشل المصدر/السعر القديم/العملة/الضريبة/الوزن المتغير والعروض؛ عدم تعديل عمليات شراء أو طبخ مؤكدة.

اقتراح تشغيل بعد الحصول على الإذن: تجزئة يومية، طازج حسب المتاح اليومي، إحصاءات شهرية عند الإصدار. هذه سياسة مقترحة وليست API أو خدمة مجدولة مفعّلة.

قرارات المال ثابتة: الميزانية للمشتريات الجديدة فقط، اختيار شراء جديد صريح، الاستهلاك منفصل، سعر المستخدم قبل المتوسط، تنبيه تجاوز مع بدائل دون تبديل تلقائي، الماضي المؤكد ثابت، لا ترحيل شهري تلقائي.

## Official historical table import —14October2026 follow-up

A separate36-row interval bank is now saved in data/prices/research/official/msit-2025-06-ranges.json, from page15 of the official MSIT June2025 bulletin. Includes4pulses/3poultry/6meat/4fish/9source-vegetable/10fruit rows, all explicitly EGP/kg. It retains minima/maxima and month2025-06; no invented midpoint, day price, store, food identity, current availability or nationwide average. These36 do not join the34point-quote/initiative research index.

Source PDF: https://msit.gov.eg/wp-content/uploads/2025/07/%D9%86%D8%B4%D8%B1%D8%A9-%D9%8A%D9%88%D9%86%D9%8A%D9%88-2025-1.pdf . Webreader contentlimit blocked26,752,665bytes; one normal publicHTTP download succeeded. Raw PDF retained only at E:\work\SOFRA\source-cache\prices\msit-june-2025.pdf (outsideGit; rights unknown), SHA256069f385c424dcf2d6595064b3b0300d57c3ad9e289bd10f46ded0e040bbee209. Metadata in samecache; source metadata/page/hash also in trackedbank. Clone alone has extractedfacts, not the copyrightedPDF. PDF rendering available via bundledpypdfium2; pypdf text had corruptfontmapping and was not trusted for numbers.

Second independent visual review compared all36rows and corrected2transcriptions: source abbreviation «ف. رومى» remains unresolved (not strawberries/canonicalpepper); fig range35–45 not30–45. Mackerel160–200 and lemon15–40 verified against image, not conflicting old search snippets. Transcription check does not approve rights/freshness/foodbinding.

tool/prices/official-price-ranges.mjs validates this exact scoped table and preserves owned copies; selection requires an explicit historical month and matching EG/EGP. Rejects reverse/zero/unknown bounds, wrongunit/source/month, invented midpoint/date or runtimeflag.3newNodecases plusprior9 all12passed. No XLSX/currentliveprovider implemented; runtime0/reuseapprovalfalse.

Follow-up sourceaccess evidence: official/source-followup-2026-10-14.json. GASTAT publicsearch/export discovery returnedinaccessible/502, noexportvalues. Egyptagriculture https://agri.gov.eg/databases/83 opened with separatewholesale(Obour)/representativeretail/min/max/mean/dateheaders but no numericrows. No privateendpoint/login/termsbypass or guessed currentprices. Next still current reusable official export +permitted fresh retailerfeed, supported by the tested historicalrange contract.

##14October — market-first source correction

Latest user priority: real retailer and delivery-app prices first; government sources are secondary, no waiting for government exports. See MARKET-PRICE-INTEGRATIONS.md, new official-source EG/SA dossiers, and offline partner-catalog-candidates.mjs (8tests). Talabat/HungerStation partner scope is own chain/vendor; Salla/Zid can read consenting merchant catalogs. No live feed or reuse permission acquired. GASTATJuly2026 workbook/100food rows saved as raw source checkpoint only; no normalized/livepricebank/currency approval. Arabiccreatorsecondbatch adds2website recipes with explicit source omissions;22bundled readable entries unchanged, nextassetintegration separate.
