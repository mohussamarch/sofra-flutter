# متابعة Codex — الفيجوال —25أكتوبر2026

## معاينة شاملة أولًا — 1 نوفمبر 2026
- طلب المستخدم إكمال المعاينة لتجربة الرحلات قبل المزيد من Flutter/APK، مع عرض كل شيء داخل موكاب جوال. لا إعادة تخطيط/بناء APK بلا حاجة؛ لا commit/push أو تعديل أصول Blender/Firebase.
- الملف القابل للاستخدام: E:/work/SOFRA/app/design-assets/ui/full-preview/index.html؛ مستقل، بدون خادم/شبكة، بكتالوج413وصفة active أصلية من707محتفظ بها. الملفات القديمة notebook-v1 لم تُستبدل.
- اليوم/البحث/المطابخ/المحفوظ/من الموجود، تفاصيل المصدر والحصص والملاحظات والنسخ الشخصية؛ مناطق الخزين والدفعات والتحويلات؛ الخطة اليومية/الفترة وتكرار الأسبوع؛ تخصيص الناقص عبر الخطة ومراجعة مشتريات مؤكدة الوصول.
- الطبخ يحفظ الخطوة والمؤقت، لا يخصم قبل تأكيد أخير، لا يتكرر الخصم، والمجهول يحتاج إقرارًا صريحًا بلا خصم مختلق؛ البواقي استهلاك/إزالة/تذكير. المدخل اليدوي ونص الطلب وصورة الريسيت المحلية وعينة صريحة يمرون بمراجعة ومنع تكرار.
- تفضيلات البيت/البلد/الحساسية والخط والحركة، مصروفات مدخلة فقط بعملة البلد، تصدير واستعادةJSON بتحقق وإعادة ضبط. المجتمع والدعوات مسودات محلية، لا نشر أو إرسال بريد.
- لا OCR أو استقبال مشاركة أو كاميرا باركود أو تسجيل/مزامنة/إشعارات نظام متصلة. لا ضمان لتحقيق ميزانية/بروتين أو ملاءمة صحية. المطبخ الاختياري مخطط2D للأبواب والتنقل والستايل، ليس رندر3D؛ باقي اختيارات الشكل محفوظة فقط.
- تحقق فعلي:12اختبار Node ناجح، syntaxcheck نظيف، check.cjs لرحلات البحث/back/حفظ/خزين/ريسيت/تكرار/وصفةشخصية/خطة/شراء/مصروف/طبخ/استكمال/مؤقت/خصم/بواقي/تفضيلات/ملف تالف.320/390/412/728 بدون تجاوزأفقي أو أخطاءJS أو طلباتHTTP؛ تقرير review/qa.json.
- capture.cjs أنتج10صور فعلية في review/showcase؛ tour.html للعرض المرئي داخل المحادثة فقط. التجربة الكاملة في index.html وليست الصور. README يوضح الحدود وإعادة البناء والتحقق.
- لم يتغير Flutter أو APK في هذه الدفعة، ولم يحدث رفعDrive. عند APK قادم: العثور على مجلد النسخ داخل Sofra(id1qRAV-M2I1LTXW2zo1tRghAbqfL3o84CH) ثم الرفع للمكان الموجود، لا إنشاء وجهة عشوائية.
- التالي مراجعة المستخدم للتجربة، ثم نقل السلوك المعتمد للتطبيق عبر KitchenService الكاتب الوحيد؛ اختبار جوال فعلي قبل ادعاءجاهزيةالإطلاق. المخزون التجريبي وبيانات المتصفح منفصلان عن حساب التطبيق.

## Flutter فعلي — 31 أكتوبر 2026
- المستخدم أجاز كود Flutter والاختبارات وAPK؛ لا كاتب runtime موازٍ ولا commit/push. هذا ينسخ قيد الفيجوال فقط لهذه الدفعة.
- lib/features/daily_home_screen.dart وhome_shell: أربعة تبويبات أصلية، حفظ حالة البحث عند الرجوع، و3D يُفتح بطلب صريح من الخزين فقط.
- recipe_stock_preview: فحص الكميات للوصفات بعد تحجيم الحصص، احترام التحويلات وتخصيص المكوّن المتكرر، ومقادير/حصص مجهولة لا تعني جاهزة؛ cache ببصمة بنيوية ثابتة تُبطل عند تغيير الخزين/الوحدات/الحصص/مراجعة الوصفة.
- cook-now ينشئ وجبة لليوم للاستكمال عبر KitchenService نفسه؛ لا خصم قبل تأكيد الطبخ. أضيف للخطة والتخطيط الشهري والمشتريات متاحون.
- تحقق جديد:22اختبار مركّز، ثم459اختبار كامل ناجح؛ analyze بلا مشكلات. سجلات E:/tmp/sofra-native-final-*.log.
- مراجعة كود مستقلة بلا موانع؛ ملاحظتان مؤجلتان: مرشح الموجود قد يستبعد التطابقات ذات المقادير غير المحسومة فقط، والطبخ المباشر يسجّل خانة الغداء حاليًا.
- Android ناجح: build/app/outputs/flutter-apk/sofra-native-20261031.apk،92,870,515bytes؛ SHA256 E137854CBE0EB1E620206E7966E886352C953DC3E8A1485AAF48B088E526AC4F. تحقق apksigner واسم الحزمة com.mohussamarch.sofra؛ توقيع الاختبار الحالي لا نشر متجر. فشل التسجيل القديم للـintegration_test زال بإعادة توليد tooling عبر build بدون --no-pub؛SDK/JDK بمسارات بيئة للعملية فقط.
- OCR/مشاركة الطلبات ومخطط البروتين لم تُنفّذ. لا تغيير Firebase أو مصادر Blender؛ لا اختبار S24 أو اعتماد بصري جديد.
- خطة التنفيذ: docs/superpowers/plans/2026-10-31-native-discovery.md؛ التالي تجربة APK على S24 بالقائمة الموثقة ثم شريحة إدخال الريسيت بمراجعة قبل الإضافة.

## تصحيح نطاق المنتج — 31 أكتوبر 2026
- المستخدم أكد تعدد الرحلات وأن اكتشاف وصفات من الموجود هو الرهان الأساسي، والتخطيط بالميزانية/البروتين وإدخال الريسيت/مشاركة مشتريات أولويات وليست تجميلًا مؤجلًا.
- موجز للمراجعة: docs/design/PRODUCT-JOURNEYS-AND-EASY-INPUT-20261031.md؛ أضفت تنبيه نسخ في LAUNCH-EXPERIENCE-20261031.md. الخريطة السابقة لا تمثل هذا التصحيح بعد.
- قراءة فقط: previewMonth يعتمد قالب اختيارات أسبوعي؛ بيانات البروتين لا تثبت وجود مولد يحقق هدف بروتين. بحث lib وpubspec لم يجد مسار OCR/استيراد مشتريات بالمشاركة؛ الباركود قائم لكنه مختلف.
- المقترح: استخراج تلقائي لمسودة ومراجعة دفعة واحدة؛ طلب لم يصل لا يصبح مخزونًا، والمكرر لا يضاف مرتين. لا اختيار مزود OCR أو إرسال بيانات أو تعديل runtime/APK. التالي مراجعة التصور ثم عقود تنفيذ الاستيراد والتخطيط. لا خادم جديد ولا commit/push.



## تجربة الإطلاق — 31 أكتوبر 2026
- المستخدم اختار الاستمرار في دفتر المطبخ الحالي لإخراج نسخة استخدام أولًا، والتطوير البصري الكبير لاحقًا.
- سلّمت docs/design/LAUNCH-EXPERIENCE-20261031.md وخريطة design-assets/ui/notebook-v1/journey-map.html؛ أربعة تبويبات، و3D اختياري من الخزين واختصار اليوم، بنفس حالة KitchenService.
- فحص جديد: html_preview بعرض728 أعاد ارتفاع894 بلا console errors؛ Edge headless تحقق من4فروع/6خطوات وعدم تجاوز العرض عند320/390/728. فشل اكتشاف قناة Edge أولًا، ونجح باستخدام مسار التثبيت الصريح.
- لا تعديل Flutter أو Firebase ولا APK جديد. اختبارات النموذج السابقة تاريخية. لا commit/push؛ التغييرات المحلية السابقة محفوظة ولم تُستبدل.
- التالي: مالك runtime ينقل الغلاف ويربط رحلة وصفة حقيقية حتى الخصم المؤكد والبواقي، ثم اختبار S24 وAPK؛ لا توسعة مودلنج قبل ذلك. لا خادم جديد لهذا التسليم، ولم تُوقف خوادم سابقة.



نسخة واحدة E:/work/SOFRA/app، والمرجع main/origin/main. Codex يملك الفيجوال والأصول، وClaude يملكFlutter والعقد والاختبارات والـAPK. لا تكتب في ملفات الطرف الآخر.

## R24 — جولة تعديلات المستخدم — 27 أكتوبر
- موعد00:30لم يُسجل كجدولة مؤكدة ولم يعمل؛ بدأ التنفيذ بطلب المستخدم الحالي بعد تجدد الحد (0%/45%،ordinary=true). لا موعد جديد أو ادعاء متابعة أثناء إغلاق الجهاز.
- عُدلت المصادر الثلاثة فقط،بلاblend1: شامفر الفريزر10.2mmمثل التلاجة،مفصلات مرئية،مفاتيح البوتجاز أمامية،نافذة فرن داخل فتحة ومثبتات يد/شريط سفلي معدن،واجهات كلاسيك أرفع،تثبيت48طرف مقبض،خشب ياباندي وكانيه اختياري،ميكروويف مجوف وباب مستقل. أجسام/رفوف18وحدة لكل من المودرن/الياباندي أضيفت؛الهندسة الأساسية للغرفة لم تتغير.
- أصول R24 جديدة ومتطابقة في realtime-r24؛ review-detail.glbبخاماتUV0منفصلة وUV1للإضاءة (25.08MBمراجعة ثقيلة). لا تخلط ملفات R23 أو تعيد UV1منUV0. مقارنة Cyclesبنفس كاميرا البيت؛شمس العارض تقرأ اتجاه/قوة/لون المصدر،وألوان التعبئة/السقف كذلك. النقل الضوئي ما زال تقريبًا،ليس مطابقًا لـCycles.
- الاختبارات: R24_GEOMETRY_AND_PACKAGE_PASSفيverification.json،3مصادر و6صورداخلRGBAبحدود/بصمات صحيحة. المتصفح اختبر فتح/قفل بابي المعدن90/75→0/0،نور الداخل4/4→0/0؛فريزر الكريمية مستقل؛ميكروويف90→0؛modern+builtin،Japandi+cane،قوة شمس الغروب23.04منالمصدر؛errors=[]. لا اختبار هاتف أو اعتماد جمالي.
- قرأت CL2C-002 ورددت C2C-009؛6صورinsideفارغة ومنورة فيinteriors/معكاميرا/sidecar. لاLEDفوقالسفرة،الموجودتحتالدواليب؛لاصورمكوناتأنتجت. تسليمClaudeالحالي docs/design/CLAUDE-R24-HANDOFF.md؛استلامه لم يُفترض.
- المعاينة http://127.0.0.1:8878/?options=r23&sourceConstants=on&detail=on ؛NodePID42680عندالإطلاق،scriptrealtime-r24/server.mjs،القديم8877محفوظ. انتهت مهامBlender. لاcommit/pushبتوجيهالمراجعة؛لاDart/test/pubspec/tool/Firebaseتغيّر.
- المتبقي: اعتماد الأشكال،آثار حواف/UVصغيرة،تقريبareaLight/نعومة الظل،مصفوفةكلالتركيبات،ضغط/تجميعالمشهدوقياسS24. لا إعادة خبز أو إعادة تعديل المصادر دون سبب جديد. تقريرالجولة R24-REVIEW-FIXES.md.

## R23 — طلب إعادة تخطيط الجودة — 26 أكتوبر
- checkpoint3: صدّرت272جزء بديل من المصدر وربطتها بعارض المراجعة (`options=r23&sourceConstants=on` مع معاملات الخرائط السابقة). واجهات3ستايلات،نوعا التلاجة/البوتجاز،3سجاد،الستائر/الزرع،LEDمستقل. اختبارBrowser للأبواب85° وLEDfalse/true نجح؛لاerrors. عيبباقٍ: carcassesبعض الوحدات خضراء مع الواجهات الأخرى. التاليتصحيح أجسامالستايلات وخاماتها ثم نعومةالظل/الأداء. تفاصيلR23-PROGRESS؛كلBakeانتهى ولاحفظmasters. Gitreadنجحبصلاحيةمحدودة؛تغييراتمحلية/untrackedبلاcommit/push. لاوكيلآخرللفيجوال.
- تحديث التنفيذ: تصحيح shadow near للشباك من.5 إلى.02م أثبت منع التسرب (9644بكسل مضاء قبل،صفر بعد). hybrid ambient=0. اكتملت خرائط4096لون/normal/roughness وbounceالثلاثة،UVمطابق والمصادر لم تتغير؛كل عمليات Blender انتهت0. راجعت الصباح/الغروب/الليل،التحسن جزئي والحواف الدقيقة/نعومة الظل والخيارات ما زالت مفتوحة. المعاينة `http://127.0.0.1:8877/?r=23&colorBake=r23&bounceBake=r23&surfaceBake=r23`؛هذه خرائط تشخيص وليست حل ذاكرة الموبايل النهائي. لا توقف عند4000توكن افتراضي؛تفاصيل الاستكمال في R23-PROGRESS.md. محلي وغير معتمد.
- بدأ التنفيذ بإذن المستخدم وبميزانية مستهدفة4000توكن للجولة: audit_scene.py/audit.json في realtime-r23. الغلاف الأساسي سليم في الفحص،والحواجز المخفية موجودة فيGLB؛3645شعاعًا هندسيًا للجهات المصمتة بلا تسرب في العينات. هذا ليس اختبار إضاءة فعليًا. المصادر الثلاثة لم تتغير. التالي عزل مسارات الضوء في العارض وفحص نافذة مفتوحة/مسدودة؛انظر docs/design/R23-PROGRESS.md. لا سب إيجنت أو رندر ثقيل بهذه الجولة.
- المستخدم رفض مستوى التقدم وطلب خطة احترافية تشمل كل البدائل والظلال في غرفة مغلقة مع السقف والحيطتين مخفيين للكاميرا فقط. الخطة قيد التنفيذ: docs/design/R23-PROFESSIONAL-KITCHEN-PLAN.md.
- ترتيب العمل التالي: جرد وغلاف الغرفة، اختبارات عزل الضوء، مرجع Cycles وخامات، استكمال البدائل، عارض جميع الخيارات، قياس الهاتف. 3DGS مؤجل خارج المسار الأساسي؛ هذا ينسخ «إعادة تدريب splats أولًا» أدناه.
- لا اكتمال بلا مصفوفة الخيارات وصور مقارنة واختبار تسرب الظل. العمل محلي حتى مراجعة المستخدم؛ لم تُعدّل مصادر Blender أو عارض R22 أثناء وضع الخطة. فحص Git الحالي فشل بوصول/work-tree؛ يعاد فحصه قبل تنفيذ الأصول ولا ادعاء نظافة.

## R22 — مراجعة محلية 3DGS / Mesh / الإضاءة الديناميكية — 26 أكتوبر
- المعاينة التفاعلية: http://127.0.0.1:8877/?r=22c ؛ تبويب المراجعة الحالي في Codex. تعتمد على بقاء خادم R22 المحلي مفتوحًا. لا commit/push بناءً على توجيه المستخدم بإبقاء المقارنة محلية حتى يراجعها.
- صفحة R22 تعرض ثلاث طرق فعلية: جدران splat مدرّبة + Mesh؛ Mesh هجين بخامات/خرائط diffuse مخبوزة مع الإضاءة والظلال الحية؛ وMesh كامل بلا lightmaps مع الشمس/الظلال/LED متغيرة. HDR reflection probes ما زالت مسبقة لكل وقت، لذا تسمية «ديناميكي» تخص ضوء المشهد القابل للتحريك ولا تعني GI/انعكاسات ديناميكية كاملة.
- تم تحديث masters الثلاثة في مكانها، sky/folliage layering، النجوم، وwarm under-cabinet LED ليلي مرتبط بحدود الوحدات العلوية. التصدير `review.glb` حجمه15,520,284بايت وبصمات مصادره في `realtime-r22/export-report.json`. Dataset:72 صورة،24 زاوية ×3 أوقات،384px،48 Cycles samples.
- تحقق: اختبارات modes الثلاثة 3/3 ناجحة، و`node --check` للعارض/السماء/مساعد الإضاءة؛ QA في المتصفح للصباح/الغروب/الليل، الكاميرات، أوضاع الإضاءة، وباب الثلاجة0–104° ثم إغلاقه. لم يُختبر هاتف حقيقي، ولا Android integration أو خيارات كل الملحقات.
- مانع مهم: تقارير PLY الحالية بصماتها تخص masters قديمة (`acd05e…`,`b21d6e…`,`ef8d41…`)، لا الصور/الموديلات الجديدة. تم تجديد captures فقط. بيئة Python3.10/PyTorch CUDA/gsplat المتوافقة غير ظاهرة من `python` الحالي (WindowsApps shim)، لذا لم أعد التدريب ولم أغيّر التقرير. أرقام التدريب القديم ليست دليلًا على جودة R22 الحالية.
- التالي: استعادة البيئة المتوافقة الموجودة مسبقًا دون تنزيل حزم، تدريب splats من جديد، مقارنة صور holdout، ثم مراجعة المستخدم. إذا تعذر ذلك، اعرض بوضوح أن 3DGS في المعاينة قديم. لا تعديل في lib/test/pubspec/tool أو عقد Claude. التفاصيل في `docs/design/R22-EXECUTION.md` و`docs/design/CONTRACT-REQUESTS.md` C2C-007.

## R20 — مقارنة الإضاءة الديناميكية والهجينة، 25 أكتوبر
- اختار المستخدم المقارنة أولًا. المعرض: http://127.0.0.1:8876/ ؛ تشغيله عبر realtime-r20/server.mjs، والمالك PID15584 وقت الإنشاء. انتهى Blender؛ مصادره الثلاثة لم تتغير، ولا مصدر رابع.
- المجلد design-assets/blender/current/realtime-r20 يحتوي نموذج مراجعة، وخامة albedo بمقاس2048، وثلاث خرائط bounce بصيغة HDR و256عينة، وثلاثة مراجع Cycles، وواجهة للباب والديكور واللون والشمس. README يشرح الإعادة والقيود؛ خطة الجولة في R20-LIGHTING-COMPARISON-PLAN.md.
- نجح R20_COMPARISON_CHECKS_PASS. سجل المتصفح يتضمن6حالات: الأوقات الثلاثة، وباب104درجة مع بقاء الفريزر مغلقًا، وإخفاء الديكور، وتعديل الشمس. لم يُختبر جهاز فعلي ولم يُعتمد الشكل. Three.js0.180.0 محلي برخصته، دون تعديل حزم التطبيق.
- نموذج المراجعة11,454,080بايت و227,742مثلثًا و608أجزاء؛ يتجاوز هدف8MB/150k. الضوء المرتد أدفأ لكنه ما زال خشنًا. لا ادعاء بمطابقة Cycles أو جاهزية الإنتاج؛ قياس CPUsubmit يخص الكمبيوتر فقط. باقي كاميرات وأبواب وخيارات التصدير الرسمي ورسومات المكونات لم تُسلّم ضمن العينة.
- الرد C2C-006 محدث بالنتائج؛ ينتظر مراجعة المستخدم ورد Claude على دعم العارض. لم تتغير lib/test/pubspec/tool أو assets/spike3d. الخام والمكتبات محلية ومستبعدة من Git؛ التسليم يشمل السكربتات والوثائق الخفيفة فقط.
## استلام سابق في 25 أكتوبر — قبل تنفيذ عينة المقارنة
- طلب المستخدم المباشر يستأنف العمل بعد طلب التوقف السابق: GLB رسمي و3إضاءات وخامات مخبوزة وتخصيص حي. خطة المراجعة docs/design/REALTIME-KITCHEN-R20.md،وإيصال CL2C-001/1–7 وC2C-006 في CONTRACT-REQUESTS. لم يصدر GLB رسمي أو bake جديد بعد.
- r19 اكتمل باستكمال Claude؛فحص Codex اليوم تحقق مستقلًا من 426بصمة SHA256 وحجم دون أخطاء:408فيديو،12مقطعًا،7,397,624بايت،partial=false. geometry/asset pass الموجودان دليل الجولة السابقة؛لم أكرر فحص Blender أو الموبايل. approved=false.
- Git المقروء HEAD=origin/main=547d01e1 لكن الشجرة غير نظيفة؛Claude يعدل assets/spike3d/kitchen.glb وlib/scene3d/kitchen_3d.dart وtool/scene3d/bake_light.py. لا overwrite/pull فوقها. لم أغير الكود أو الأدوات أو المصادر الثلاثة. لا عملية Blender/Python ظهرت وقت الفحص؛هذا لا يثبت غياب جلسة Claude النشطة.
- اقتراح hybrid: albedo وخامة مخبوزة مستقلة عن3خرائط diffuse،مع معدن وانعكاس وظلال المتغيرات في runtime. UV2 لا يعمل lightmap تلقائيًا؛نحتاج رد Claude حول دعم العارض قبل mass bake. vertex colors تجربة مؤقتة مفيدة وليست ضمان جودة.
- التالي: مراجعة المواصفة التقنية ثم عينة lightmap/PBR في العارض المتفق عليه،مع عدم إنشاء مصدر Blender رابع. جهاز S24 لم يختبر؛iPhone مرجع تكوين بصري حديث حسب المستخدم.
## تسليم r19 المكتمل
- استكمله Claude بعد توقف الجولة السابقة؛426ملفًا،408فيديو/12مقطعًا،7,397,624بايت،partial=false. فحص Codex لبصمات وحجومالملفاتكلها مرّ دونأخطاء. approved=false؛لا إعادة إخراج لازمة.
- سايدكار assets/scenes/kitchen/fridge-v2-review.json ومعاينةfridge-motion-r19؛تقاريرالهندسةوالأصولموجودة،واختبارالجوالمنفصل.

## تسليم r18 — مرجع تاريخي
- تنفيذ طلب المستخدم: من المطبخ الإيزومتري إلى واجهة أمامية ثم فتح بابي التلاجة الأساسية.132 فريمًا حقيقيًا،3 إضاءات،30 اقتراب+14 فتح لكل إضاءة،1080×2340.
- تلاجة مجوفة:3 رفوف زجاج ودرجان وإضاءة ورفوف باب. الفتح104درجة؛ المقابض والستيكرات تتبع الأبواب. المخزون غير مخبوز. حركة التلاجة الحديثة البابين ليست ضمن التسليم.
- assets/scenes/kitchen/fridge-motion-spike.json وmoves/fridge/{morning,golden,night}/. سايدكار مراجعة؛ approved=false وruntimeIntegrated=false. manifest الأساسي لم يتغير.
- 5,748,552 bytes; maximum frame 69,758 bytes; WebP quality 80–80.
- ضمن4MB مع الأساس: False؛ Claude وافق على التحميل المؤجل خارج4MB، لإضاءة واحدة وكاش محدود. كل فريم مفكوك نحو10.1MB؛ لا تفك132 فريمًا دفعة واحدة.
- FRIDGE_MOTION_PASS في verification.json داخل fridge-motion-r18:132 بصمة وأبعاد وحجوم، كاميرات ومواضع رفوف متطابقة، ونهاية الاقتراب=بداية الفتح بايتًا. geometry-verification.json للمفصلات والخلوص والمنظور، وbrowser-qa.json للمشغّل. S24 غير مختبر.
- التفاصيل في docs/design/FRIDGE-MOTION-R18.md وREADME داخل مجلد الحركة. لا تعِد الرندر المكتمل للمراجعة فقط.

## المصادر والمراجعة السابقة
- ثلاثة ملفات فقط في design-assets/blender/current: kitchen-morning.blend وkitchen-night.blend وkitchen-golden.blend. كل الخيارات موجودة، والمصادر مقفولة بالكاميرا الأصلية. SET-FRIDGE-DOORS.py داخل Text Editor؛ الحركة قابلة للإعادة عبرmotion.py وليستtimeline مخزنة.
- r17 محفوظة في49 صورة و3 تفاصيل: خشب مستقيم ومفرش وفازة، شباك أبيض، سجاد أزرق أكبر، زرع وبرطمانات زجاج، فيشة وسلك، ومقبض ياباندي مصحح. مصادرها الحالية أضيف إليها داخل التلاجةr18؛ بصماتها الجديدة في تسليمr18.
- لا.blend1 ولا مصدر رابع أو نسخ مخفية. لا تشغّل build.py القديم أو تعِد build-interior.py على المصادر المعدلة. PNG وBlender محلية ولا تُرفع.

## التنسيق وما يبقى
- القناة docs/design/CONTRACT-REQUESTS.md؛ Claude يرد بالـID في هاندوفه. استلم Codex ردودC2C-001/002 وعقد1.1. C2C-003 لتراكب الطاولة والسجادة مفتوحة. استلمت ردC2C-004 على الدفعة الجزئية، وطلبات الشفافية والأساس المطابق؛إيصال الحزمة الجديدة ينتظر رده.
- C2C-004 يطلب قراءة السايدكار، وإضافة المجلدات إلىpubspec، وقرار التحميل والكاش. أول فريم يطابق مرجعr18 المرفق؛ لا تدمجه معr14 بلا تنسيق لاستبدال الأساس.
- لم يعدل Codex كودFlutter أوFirebase. Claude أبلغ عن ربط الدفعة الجزئية في المتصفح؛لم يختبرS24، ولم يتحققCodex من ربط الحزمة الكاملة بالـAPK.
- الجماليات للمستخدم؛ لا اعتماد نيابة عنه. dustLoop لم يُسلّم. حصاد الإنتاج وخيارات التخصيص وعقد/2 لجولات لاحقة.
- المعرض http://127.0.0.1:8874/current/index.html، ورابط الحركة داخله. المصدر current/review-server.mjs؛ افحص المالك والعملية قبل تشغيل خادم ثانٍ. المحلي يحتاج الجهاز والتطبيق مفتوحين.
- استئناف03:40 نُفذ مرة وحُذفتautomation-2؛ لا جدولة جديدة تلقائيًا. التوقف عند98% أوordinary=false أو حدود مجهولة، دون شراء رصيد أوreset.




### حالة الحفظ للجولة R20
- محاولة commit/push رُفضت من المراجعة التلقائية قبل تنفيذ الأمر، بسبب توجيه إبقاء الجولة محلية حتى المراجعة. لم ينشأ commit لهذه الجولة ولم تُرفع. أزيلت ملفاتها من staging لتفادي ضمها إلى commit Claude بالخطأ. المحتوى محفوظ محليًا كاملًا؛إذن النشر سُئل عنه في بوكس مستقل.

## توجيهات26أكتوبر — بحث الجودة قبل التنفيذ
- المستخدم اختار إضاءة هجينة ورفض شكل R20،وطلب بحث تحسينها ثم سأل عن3DGS. البحث والأدلة والخطوات في docs/design/R21-QUALITY-AND-3DGS-RESEARCH.md.
- مؤكد من الكود: ACES بدلAgX المصدر،radius غير فعال معPCFSoft فيThree180،حذفNormal،تبسيط الزجاج،ومصدرAREA صارSpot وبيئةانعكاسعامة. UV/noise يحتاجان فحصًا مقاسًا؛لا ادعاء أنUVoverlap مثبت.
- 3DGS خيار لتجربة محدودة على الأجزاء الثابتة،لا تحويل تلقائي للمطبخ القابل للتخصيص. إعادة الإضاءة ممكنة بمسارات متخصصة/proxy meshes،وأداء الهاتف غير مقاس.
- محفوظ للتنفيذ: توحيد ونقل الأفياش كما بالعلامات؛خلفيةسماءكبيرةمحيطة،طبقاتزرعبعمق،شفقوليليمزجالأزرقوالنجوممعالوقت. لم تنفذ ضمن البحث. كل الجولة محلية وفق رد المستخدم،ولا commit/push.


## Codex R24b checkpoint — 27 October 2026
Claude handoff: docs/design/CLAUDE-R24-HANDOFF.md updated first. Completed shared lightmap uniforms, opt-in legacy splats, experimental disk PCF, and calibrated radiance-to-irradiance conversion (PI). Blender unit calibration mean=1; viewer syntax passes; six browser QA snapshots have no JS errors. Double-fridge doors and compartment lights pass open/close checks. Morning/night/golden reviewed; dark trim/seams and real-phone performance remain unresolved. No Blender masters, GLBs or HDRs changed in R24b; local only, no commit/push. No Claude receipt assumed.


## Codex R24c — 28 October 2026
Local review: http://127.0.0.1:8878/?review=r24c . Added Home-to-dining-corner1800ms camera and horizontally scrollable2D glass cards (illustrative content), plus portrait-size review. Camera parameters and implementation: docs/design/R24C-DINING-AND-PERFORMANCE.md.
Rendering now sleeps when idle/hidden; camera-only moves reuse shadows. Verified baseline3frames/1shadow update; closeup5/1; door-open7/2; dining11/4. Scrolling to the next card kept11/4, so no additional Three renders. These are operation counts, NOT FPS/GPU/mobile results. Half-resolution glass buffer has quarter pixel area; full comparison via glassQuality=full.
CL2C-003 acknowledged: mobile export under8MB/~150ktris and baked-only model-viewer compatibility remain OPEN. Heavy R24 review is not approved for APK. Edge seams/trim still unresolved. No Blender masters/GLB/HDR edits, no Claude code edits, no commit/push. Next: owner framing review, atlas-edge isolation and mobile export. Preview node PID42680 remains local on8878; requires running machine.

- Codex R25 mobile candidate28أكتوبر: ملف جديد design-assets/blender/current/realtime-r24/mobile-r25/kitchen-mobile.glb بحجم7,163,808bytes و147,669مثلثًا،Draco ومقاطع الأجهزة الثلاثة. فحص فك الضغط/UV/المقاطع وفتح التلاجة والفريزر بالمتصفح ناجح؛لا اختبار هاتف أو اعتماد جمالي. الإضاءة المباشرة/الليد والحواف والبدائل الخفيفة ما زالت مفتوحة. التسليم docs/design/R25-MOBILE-HANDOFF.md؛محلي بلا نشر.

## C2C-014 — 29 October: corrected dining camera; supersedes CL2C-004 camera
Exact new settings: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-camera.json
Executable reference: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-review.mjs
Position [4.35,1.4,0.75], target [0,0.9,-3.6], vertical FOV50, 1800ms smoothstep from Home. Horizontal azimuth45deg: camera/table near corner/rear wall corner share z=x-3.6. Replace the OLD32.6deg orbit and target. Coordinates use glTF Y-up metres.
Show enclosure_ceiling surface at dining arrival; hide surface when leaving for Home/closeup/outside/fridge, retaining shadow occlusion. If your loader removes enclosure meshes, retain the ceiling and clone its material for this mode. No GLB modified for this camera correction.
Fresh browser review: portrait dining transition and cards visible, Home hides cards/ceiling; node --check passes. Framing remains pending owner approval; ceiling highlight quality still needs lighting review. Local only; no commit/push. Preview8878 restarted PID45980, server.mjs in the same realtime-r24 folder. CL2C-005 read: Claude confirmed R25 loaded in app; no receipt of C2C-014 assumed. Direct-sun/LED bake, trim seams and S24 testing remain open.

## C2C-015 — Complete available-options bundle, 29 October
Start here: E:\work\SOFRA\deliveries\KITCHEN-FULL-20261029\START-HERE.md
ZIP: E:\work\SOFRA\deliveries\KITCHEN-FULL-20261029.zip
ZIP bytes: 86910706; SHA256: 839ADBF28DF9D787333529C142F1B35E5323499B0F8B468236594AEB8EFE23B3
Includes detailed base+alternatives, all runtime modules/vendor, three bounce/probe pairs, latest45degree camera, lighter BASE-only candidate, manifest and geometry audit. Run node server.mjs from bundle; http://127.0.0.1:8879/ . No prior folders needed for default review. All existing options included, not a claim that future table/curtain variants exist. Direct-sun/LED baked-only export and edge quality remain unresolved. Fresh browser smoke/geometry/syntax checks pass; temporary stalls occurred, no phone performance approval. Local only, no publish. Read CL2C-005; request receipt referencing MANIFEST.json. Preview PID45820.
