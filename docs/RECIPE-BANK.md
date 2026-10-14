# بنك الوصفات البحثي وربطه بالتطبيق

نسخة العمل الوحيدة `E:\work\SOFRA\app`. طلب المستخدم جمع وصفات بوكيل مستقل وتسجيلها بصيغة قابلة للربط. ينفذ هذا الجزء جمعًا محدودًا وفحصًا غير معدّل للبيانات وخريطة ربط؛ لا يضيف وصفات غير مراجعة إلى دفتر المستخدم.

## صيغة الإصدار1

الملف `data/recipes/research-candidates.json` يحوي `schemaVersion:1` و`sources` و`recipes`. لكل مصدر هوية وURL وعنوان وناشر ورخصة و`retrievedAt` فعلي. `licenseStatus` هو `unknown` أو `unverified-primary-source` أو `verified-license`؛ الأخير يحتاج رابط `licenseEvidenceUrl` لمراجعة الدليل، ولا يعني أن الفاحص أصدر حكمًا قانونيًا. الرخصة تخص مصدر الوصفات نفسه؛ لا تُورّث CC0 من بنك USDA الغذائي. يظل محتوى المصادر المختلفة منسوبًا لكل مصدر؛ لا يصبح الملف المجمّع كله CC0.

| الحقل | المعنى |
|---|---|
| `id/sourceId/sourceRecipeId/sourceUrl` | هوية مرشح محلية مع هوية الوصفة الأصلية ورابطها ومصدرها؛ لا تصادم مع كتالوج التطبيق |
| `name/nameAr` | الاسم المنشور مطلوب؛ الترجمة العربية اختيارية ولا تغير هوية المصدر |
| `recordVersion/sourceRevision` | إصدار مرشح البحث مثبت، وإصدار المصدر عند معرفته؛ `null` عندما لا تتوفر نسخة مصدر ثابتة. يزداد إصدار المرشح عند تعديل المحتوى لاحقًا |
| `familyId/variantId` | اقتراح عائلة وطريقة منفصل عن تصنيف runtime؛ لا دمج آلي لمجرد تشابه الاسم |
| `reviewStatus` | `research-only` فقط في هذا البنك؛ صحة الصيغة لا تعني صحة الوصفة أو قبولها |
| `servings` | عدد حصص موجب صحيح منشور أو `null`؛ وزن الناتج وعدد الحصص مفهومان منفصلان |
| `ingredients[].id` | معرف سطر فريد داخل المرشح، وليس معرف غذاء أو مخزون معتمدًا |
| `name/sourceText/amount/unit` | اسم ونص الكمية الأصلي، ثم قيمة عددية ووحدتها إذا كانت معلومة؛ النطاقات والتقديرات تحفظ في النص وكمية غير محسومة تظل `null` |
| `ingredients[].foodBinding` | `null` حتى مراجعة هوية الغذاء وإصداره وحالته وقياسه؛ لا اختيار USDA بالاسم تلقائيًا |
| `steps[].n/text/durationMinutes` | خطوات مرتبة بصياغة عربية مختصرة أصلية، المدة المنشورة أو `null`؛ لا نقل مطوّل للنصوص المحمية ولا اختراع وقت |
| `nutrition` | `null`؛ الحساب لاحقًا من سطور الغذاء المراجعة. أرقام تغذية منشورة، إن جُمعت مستقبلًا، تحفظ كملاحظة مصدر منفصلة ولا تُخلط بالنتيجة المحسوبة |
| `gaps` | نواقص الهوية/الوحدة/الحالة/المقادير/الزمن/الترخيص وغيرها؛ ليست علامة اكتمال |

إذا أُرشف مصدر تحت `research/recipes/` يلزم SHA256 فعلي للبايتات؛ بدون أرشيف يبقى hash غائبًا أو null. فحص CLI يتحقق من بايتات الأرشيف عند وجوده. `contentSha256` الناتج لكل مرشح بصمة لمحتوى JSON بمفاتيح مرتبة؛ **ليس بصمة صفحة المصدر ولا دليلًا على صحة معلوماتها**.

## فحص البنك

```powershell
node tool/recipes/validate-research.mjs
node --test tool/recipes/validate-research.test.mjs
```

الفحص يرفض تصادم المعرفات، المصدر المفقود، المقادير غير الصالحة، تسلسل خطوات معيب، ربط الغذاء أو التغذية غير المراجع، وادعاء الجاهزية. يعرض عدد الوصفات والسطور والخطوات والمجهول والبصمات دون تعديل أي ملف. لا يثبت صحة الترخيص أو جودة الوصفة ولا يغني عن مراجعة المحتوى.

## الربط بعد المراجعة — الخطوة التالية المحددة

1. راجع ترخيص الوصفة ونسبها ومصدرها؛ احفظ أصل النص وإصداره خارج صياغة العرض، وحالة المراجعة وتاريخها. لا تُستنتج ملكية حكومية من نطاق الموقع فقط؛ افحص أي إسناد لطرف ثالث.
2. اختر `RecipeFamily` و`variantId` جديدًا بعد مراجعة العلاقة بالأطباق الموجودة؛ ثبت مراجعة تربط `candidateId/contentSha256/sourceId` بالإصدار. **حفظ provenance من بنك البحث إلى إصدار runtime لم ينفذ بعد**، فلا تتجاهل هذا الرابط عند بناء المستورد.
3. حوّل المقادير إلى `CatalogIngredient` مع معرف المكون المشترك المناسب والوحدة الأصلية/المراجعة. الكمية المجهولة `amount:null/scale:false`، لا وزن حبة أو كوب مفترض. راجع البدائل والمركبات والاختياري كسطور مستقلة عند الحاجة.
4. `CatalogRecipe` الحالي يتطلب `servings/prepTime/cookTime/totalTime/difficulty/cuisine/category/description` ومددًا رقمية للخطوات. بنك البحث يسمح بالمجهول؛ لا تمرر `null` أو تحوّله0 لإرضاء النموذج. أكمل من مصدر أو ابن دعمًا صريحًا للأوقات المجهولة قبل الترقية، وراجع سياسة زمن الخطوات بدل افتراض تضاعف زمن الفرن.
5. أنشئ `RecipeRevision` كاملًا عبر `KitchenService.saveRecipeFamily/saveRecipeRevision`؛ تغيير الوصفة يصبح إصدارًا جديدًا. لا تعِد كتابة الأصل ولا تُورّث روابط تغذية إصدار سابق.
6. لكل سطر، أنشئ اختيارًا صريحًا `RecipeFoodSelection(recipeId, recipeRevisionKey, line, food, amountForm, preparedForm, ...)`. أكمل القياسات والتحضير والجزء المأكول من أدلة منفصلة. اجعل المعامل المفقود مجهولًا.
7. التخطيط يثبت الإصدار وعدد الحصص. التأكيد فقط يخصم المخزون مرة واحدة ويجمد التكلفة والتغذية؛ إسناد الحصص للأشخاص إجراء صريح لاحق. الأسعار والأسواق والحساسية تأتي من بنوك/ملفاتها، لا من وصفة مبهمة.

المستورد وقبول المراجعة وسجل provenance وتوسيع الأوقات المجهولة وحدة لاحقة قابلة للاختبار. هذه الدفعة تحافظ على54 وصفة أصلية و0 روابط تغذية كاملة معتمدة؛ لا تعد إضافة مرشحات بحثية اكتمالًا للتغذية أو تغييرًا في APK.

الخريطة العامة: [DATA-MAP.md](DATA-MAP.md). تفاصيل الكود الحالي: [RECIPE-VARIANTS.md](RECIPE-VARIANTS.md)، [RECIPE-REFERENCES.md](RECIPE-REFERENCES.md)، [FOOD-DATA-ARCHITECTURE.md](FOOD-DATA-ARCHITECTURE.md).

## الدفعة الأولى —13 أكتوبر2026

- 6 مرشحات من مجموعتي مصدر،61 سطر مكونات و46 خطوة. منها كشري ووصفة شطة خليجية؛ ليست المجموعة كلها وصفات مصرية/سعودية، ولا ادعاء أنها الأكثر انتشارًا.
- 4 وصفات من أرشيف MyPlate مستقل؛ نسبتها الأصلية تضم USDA وجهات ولاية/جامعة وNIH. ادعاء الأرشيف بالملك العام لا يُعمم على كل صاحب عمل، وتظل مراجعة المصدر الأولي والترخيص مفتوحة.
- وصفتان من Wikibooks مع إسناد ورابط ترخيص CC BY-SA4.0 وإشعار صياغة عربية وتكييف. للكشري رابط إصدار ثابت؛ نسخة المصدر الدقيقة للشطة ما زالت مجهولة.
- 6 كميات مجهولة،و46 مدة خطوة مجهولة في الحقل العددي،وعدد حصص وصفة واحدة مجهول. الأوقات المنشورة داخل النص/الملاحظة لا تتحول إلى مدة إجمالية بالتخمين.
- 0 وصفات جاهزة للاستيراد و0 روابط غذاء مقبولة لهذه الدفعة. لم تُضف إلى `recipes/data/index.json` أو أصول Flutter أو واجهة الهاتف.

## Arabic and German expansion —14October2026

Independent research lanes added: AR1candidate/8lines/6steps; DE250sourcepages/177candidates/1493lines/998steps. No accepted quantities/nutrition/runtime/cuisines. See RECIPE-EXPANSION-AR-DE.md for exact cursor, raw response loss/recovery truth, licence exceptions and offline checks. Existing EN/FR/ES banks unchanged; do not sum as distinct dishes.

ContinuedDEsource:550fixedpages/375candidates/3287ingredientlines/2146steps;0runtime. Exactcursor/checks/provenance in RECIPE-EXPANSION-AR-DE.md; old250/177 checkpointabovehistorical.

Latest DE-language source snapshot: 700 source revisions / 481 records under review / 4121 ingredient lines / 2784 preparation lines. Source language ≠ cuisine, records under review ≠ ready unique dishes. Exact cursor and source evidence in DEindex/agenthandoff;0runtime approvals.

Latest German-language inventory: 850 fixed source pages / 544 records under review / 4635 ingredient lines / 3136 preparation lines; under review, not a distinct-dish total or ready recipes. Runtime approvals remain0. HANDOFF§65 and DEindex/checkpoint retain next cursor.

## Current source policy supersedes older continuation instructions

Use RECIPE-ACQUISITION-ARABIC-YOUTUBE.md. User stopped further recipe-book/reference collection and prioritizes modern Arab cooking personalities on YouTube. Old DE/EN/FR/ES cursors retained as historical checkpoints; do not resume them now.54catalogue recipes/4cuisines;6056researchrecords beforededup,0shared verifiedmulti-methoddishgroups,0YouTubesource candidates sofar. No new acquisition at90primary/89weekly.

## Current reviewed output —14October2026

RECIPE-LIBRARY.md supersedes old zero-output counts:16locally curated Arabic records fromexisting6056,6official creator-website records,22readable bundled library entries,0automatic planning/nutrition approvals. Local4fullyspecified/10needsreview/2notcookable,11source-supported geographic/cuisine labels,1reviewed distinct-method naan family.14video discoveries/4partialvideo recipes/0completeYouTube-derived. Full/small handoffs for all3workers underdocs/agents. No newbookcollection; original54/4planning unchanged.

## Current output supersedes earlier counts — §71

31readable Flutter records/5packs/20snapshots:20local Arabic curations (8fullyspecified culinary/10needsreview/2notcookable) and11official creator-website recipes.13local source cuisine/region labels, not13approved national cuisines;1reviewed distinct-method naan family.14videos/4partialvideo descriptions/0completeYouTube-derived. Added4existing-archive records and3Choumicha website records; no newbook acquisition. Source rights/food/nutrition/planning approvals remain0. Library-to-private-calculator review/persistence now implemented, not automatic nutritional coverage: LIBRARY-RECIPE-CALCULATOR.md. Local source-supported timer proposals reduce4older preflight drafts60→58issues; do not call native-ready. Full/small owned handoffs underdocs/agents/*1500*; coordinator consolidated§71.

## §72 current totals

44selectedreadable records,7packs/28snapshots:local28(10fullyspecifiedculinary/16needsreview/2notcookable) plus16creatorwebsite. New8local fromexistingarchive add9exactsourcecategorylabels;combinedlocal22cuisine/regionlabels,not22approvednationalcuisines. New5Manalwebsite recipes have81ingredientlines/15conciseArabicsteps; allsource-serving/cuisineunknowns preserved.14existingvideo discoveries/4partialdescriptions/0completeYouTube-derived;2newfailedvideo fetches notpromoted/disguised.1reviewed distinct-methodnaanfamily unchanged. No globaldedup/automaticnutrition/planning/rightsapproval or newbooknetwork. Full/small archivehandoffs underdocs/agents/curated-third-1530*.
