# بنك الوصفات بالجملة

نسخة العمل `E:\work\SOFRA\app`. طلب المستخدم أكبر كمية عملية الآن وتوسيع المطابخ، مع تجهيز محرك وصفات شخصية. هذا مسار بحث وجمع مستمر؛ لا حد عددي يعتبر البنك مكتملًا.

## الملفات وعلاقاتها

| الملف داخل `data/recipes/bulk/wikibooks-cookbook/` | المعنى |
|---|---|
| `source-pages.jsonl` | مراجعات صفحات المصدر: النص الأصلي wikitext، الصفحة والإصدار والرابط الثابت والتاريخ وبصمة النص؛ أصول قابلة لإعادة الاستخراج دون إعادة تنزيل |
| `category-observations.jsonl` | مشاهدات تصنيفات API المتتابعة؛ لا تُفقد بقية تصنيفات نفس الصفحة عند تعدد ردود المصدر |
| `checkpoint.json` | continuation وpendingIDs والقفل المنفصل وأخطاء المصدر وموعد المحاولة القادمة؛ عدد طلبات الدفعة منفصل عن التراكمي |
| `manifest.json` | أعداد الجامع ومصدره ورخصته وحدود الدفعات؛ عدد parseable هنا يصف الاستخراج وقت التنزيل، وقد يختلف عن فهرس إعادة الاستخراج الأحدث |
| `index.json` | آخر إصدار لكل صفحة، فهرس البحث وتصنيفات المطابخ والمصدر والبصمات؛ مرجع الأعداد الأحدث بعد إعادة الاستخراج |
| `parsed-recipes.jsonl` | وصفات أعيد استخراجها محليًا من المصدر الثابت؛ parserVersion وsourceSha256 وربط واضح بالأصل، مع مقادير/وحدات/تغذية غير محسومة تبقىnull |

`sourceRevisionRecords` يعد الإصدارات، و`distinctSourcePages` يعد الصفحات الفريدة، و`parseableRecipePages` يعد الصفحات التي استُخرجت لها مكونات وخطوات. تحديث إصدار الصفحة لا يُعد وصفة جديدة. استخراج خطوات لا يضمن اكتمال كل التفاصيل أو مراجعة جودة الوصفة.

## المصدر والترخيص والتصنيف

- المصدر APIويكي كتب الرسمي `https://en.wikibooks.org/w/api.php`، `Category:Recipes` وCookbook namespace102. حُفظت سياسة الترخيص CC BY-SA4.0/GFDL والإسناد وإشعار التعديل. استثناءات كل صفحة لم تُراجع؛ لا صور أو ملفات ميديا نُسخت.
- لكل وصفة رابط `oldid` وبصمة SHA256 للنص الراجع من API؛ البصمة تخصwikitext،لاHTMLالموسع أو صور المصدر. القوالب المتضمنة قد تحتاج معالجة مستقلة.
- تصنيف المطبخ يأتي من عنوان تصنيف مصدر معروف مطابق بالضبط، عبر API أو تصنيف مكتوب صراحة فيwikitext. لم نستنتج البلد من اسم الطبق، ولا نتعامل مع «سهل/مقلي/نباتي» كمطابخ. لا ادعاء أصالة أو صلاحية صحية/حلال بمجرد التصنيف.
- أسماء المصدر الأصلية محفوظة؛ الترجمة العربية للوصفات ليست مكتملة. المطابخ الجديدة تستخدم معرفات مفتوحة في بنك البحث، دون تغيير دفتر الوصفات الأصلي ذي54وصفة أو الواجهة.
- أول طلب محتوى فشل بإعدادrvlimitغيرمتوافق معgenerator؛ الإعادة الفورية رفضتها المراجعة التلقائية. استؤنف نفس المصدر بعد انتهاء انتظار10دقائق موثق،مع تصحيح الإعداد وفحوص offline؛لم يُستخدم مسار بديل لتجاوز الرفض.

## تشغيل مضبوط

```powershell
node --test tool/recipes/collect-wikibooks.test.mjs tool/recipes/build-bulk-index.test.mjs
node tool/recipes/collect-wikibooks.mjs --limit 500 --resume
node tool/recipes/build-bulk-index.mjs
```

افحص الحدود والقفل و`nextAttemptAt` أولًا. حتى10طلبات متتابعة/دفعة،وحتى50صفحة للطلب،وفاصل2ثانية على الأقل. `--limit` سقف صفحات جديدة لهذه الدفعة وليس سقفًا للبنك كله. APIقد يحتاج صفحات متابعة إضافية للتصنيفات،لذلك لا نستنتج عدد وصفات من سقف500.

عند أي فشل يحفظ الجامع checkpoint ويتوقف؛ الانتظار على الأقل10دقائق وأطول إذاحدد`Retry-After` ذلك. الرد الفاشل يُغلق،والقفل يُزال فيfinally. الإعادة بعد انتهاء الانتظار فقط؛ استأنف عمل الفهرسة/المنطق المحلي أثناء الانتظار. اختبارات الاستكمال ومنع التكرار والتصنيفات المتتابعة وRetry-Afterوفصل الصفحات/الإصدارات موجودة؛تعافي آخر سطر مقطوع أوcheckpointتالف يظل يحتاج مراجعة،ولا تُحذف مصادر تلقائيًا لإصلاحه.

## تحقق البنك الفعلي

أداة الفهرسة تتحقق لكل صف من هوية الصفحة والإصدار والرابط الثابت وبصمة النص والرخصة وشكل البيانات،وتبني آخر إصدار وتصنيفاته. ترفض ربط غذاء أو تغذية غير مراجعة. الفهرس يحفظ بصمات ملفات المصدر والمشاهدات والاستخراج المشتق. لا تُقرأ البيانات الضخمة داخل سياق النموذج.

مكونات وخطوات المصدر محفوظة؛الكميات والوحدات العددية وعدد الحصص وأوقات الخطوات لا تُخمن. حتىبيانات العدد الموجودة كنص مصدر لا تتحول إلى وزن طبق. محلل مرشحات الكميات الصريحة مدمج؛ التالي مجموعات واختيارات ومرادفات وهوية غذاء،ثم مراجعة وتحويل إلىإصدارات runtime. لا مقارنة تلقائية بين الطبق وحساب الأشخاص قبل هذا الربط.

مراجعات المصدر المجتمعي لا تُعلن كحقائق غذائية معتمدة.0وصفات جديدة فيruntimeمن هذا البنك حتىالآن. تفاصيل محرك التخصيص: [RECIPE-ENGINE.md](RECIPE-ENGINE.md)،الخريطة:[DATA-MAP.md](DATA-MAP.md)،عقد المرشحات:[RECIPE-BANK.md](RECIPE-BANK.md).


## Source quantity candidates — implemented

`tool/recipes/parse-ingredient-quantity.mjs` parses explicit source prefixes into `ingredients[].quantityCandidate`, separately from canonical `amount/unit/foodBinding` which remain null. Version `source-prefix-v1` currently yields 10227 candidates out of 20277 ingredient rows; 10050 remain unresolved. This is transcription coverage, not reviewed nutrition coverage.

Positive decimals, simple/mixed/common Unicode fractions and explicit g/kg/ml/l/cup/tsp/tbsp aliases are supported. Ranges, approximate amounts, packaging/counts, decimal commas and unknown units remain unresolved. Cup/spoon volume systems remain unspecified; no volume-to-mass conversion. Adjacent `200g`, leading `.5 cup`, alternatives/groups and ingredient identity still need further parsing/review. Unknowns are never filled with zero.

Each result preserves original text, remaining text, parser version, unreviewed status and source revision/hash through its recipe. Future user input may bypass source parsing and provide explicit reviewed food and quantity inputs to the calculator. The corpus itself is still outside the shipping catalogue; no automatic nutrient estimates from recipe names.

Actual checks: 7 quantity tests and 7 index tests passed within 41 recipe Node tests. Added spoon-system regression failed first, then passed after preserving ambiguity. Integration test proves parsed `1 cup` does not overwrite canonical amount or create a food binding. Raw source files remain immutable.
