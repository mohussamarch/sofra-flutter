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

## Source section and review cues

`wikibooks-sections-v3` preserves nested ingredient headings as `ingredientRows[].sourceGroupPath`: original heading, cleaned title, depth and original extracted line index. Sibling/repeated root sections reset their scope. Derived recipes retain this path per ingredient via `sourceStructure`.

`source-structure-v1` records first lexical `or`, `optional/optionally`, and `to taste/as needed/as required` cues with source text offsets. These are review cues only, not asserted substitutes, selections or clinical exclusions. `or more` may be a quantity phrase: no automatic split. `alternatives/selectedAlternative/optional` stay null; absent cues do not mean required or safe. Group path null means unavailable extraction; [] means no nested heading observed. Original source revision/hash remains attached.

Actual current coverage: 4173 rows with source headings, 1806 with or cues, 737 optional cues, 838 quantity qualifiers. 11194/22394 quantity prefixes remain unreviewed candidates. Corpus 2554/2676/52;0runtime imports/nutrition approvals.48 recipe Node tests passed;7 new behavioral tests failed before implementation then passed. Source hashes and original raw prefix checked. No runtime/Flutter/UI changes.

Next: explicit review tied to recipe revision/line and ingredient identity, then choice application and unknown-aware import. Source cues never automatically exclude ingredients from nutrition or sum every alternative. Recipe-source collection continues only after its own checkpoint gate.


## Quantity parser v2 checkpoint

Current `source-prefix-v2` supports adjacent explicit units (`200g`, `250ml`) and leading decimals (`.5 cup`), with an explicit token boundary: `garlic`, `cupful`, `g3` and ratios such as `g/100g` are not accepted units. Fractions/known aliases remain supported. Every parsed/unresolved candidate now carries its parser version. No count/package inference, canonical mass, food identity or cup/spoon-system conversion is added.

On the same2676-page/2554-recipe corpus (22394 ingredient rows), v1 produced11189 candidates; v2 produces11194:7 newly parsed and2 no longer parsed under stricter token boundaries. This is transcription coverage, not nutrient coverage.48recipe tests passed:19collector/10index/9quantity/10research contract;2additional quantity tests first failed then passed. Older v1 limitation notes above are historical. No runtime/Flutter/UI changes.


## Pending request recovery and current source exhaustion

Current English Recipes category ended at3796sourcepages/3640parsedrecipes/53sourcecuisinetags,with no pending IDs/request/cursor. This ends one source pool,not the food/recipe bank. Discover additional licensed sources/categories/languages with separate checkpoints; never restart this exhausted cursor from the beginning.

The collector now separates generator continuation from `pendingRequest` page IDs/continuation/verified revisions. Pending lookups start fresh; their category callbacks use a revision retrieved in that same pending query. Resume preserves both cursors across bounded runs. Real missing content still stops with backoff and is not counted as a source record.3behavioral regressions and a3request live recovery verified the fix.

## Independent French lane

[RECIPE-FRENCH-SOURCE.md](RECIPE-FRENCH-SOURCE.md) documents the second licensed source. [French index](../data/recipes/bulk/fr-wikibooks-cuisine/index.json):112conservatively parsed recipes/139prefix pages, separate French IDs, original revisions/licence and unknown quantities/nutrition. English3796/3640/53 unchanged. Cross-language duplicate dishes remain unresolved; counts must stay separate. Continue the French checkpoint, never restart exhausted English category.
