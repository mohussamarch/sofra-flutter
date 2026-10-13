# سجل التسليم — سُفرة

هذا سجل للتغييرات والقرارات المهمة. البداية من STATUS.md، ثم القسم المتعلق بالمهمة فقط.

## 1. خط الأساس البرمجي

- Flutter مثبت محليًا في مجلد العمل، والمشروع داخل outputs/tabkha_flutter.
- lib/main.dart: تدفق الإعداد والتبويبات والتفاعل الحالي.
- lib/domain: نماذج المكونات والوصفات وحساب الحصص والعجز والاستهلاك.
- lib/ui/design.dart وlib/ui/illustrations.dart: المكونات المشتركة والرسومات الحالية.
- بيانات تجريبية، حالة داخل الذاكرة، ولا توجد تبعيات Firebase في pubspec.yaml وقت المراجعة.
- التحقق السابق: flutter analyze، و7 اختبارات، وبناء ويب ناجحة. تدفق محاكي iOS نجح على GitHub Actions.
- رابط التحقق السابق: https://github.com/mohussamarch/sofra-flutter/actions/runs/38049382511
- حدود الدليل: الاختبارات تخص النسخة الحالية، ولا تثبت تنفيذ الميزات الجديدة أو التشغيل على جوال المستخدم.

## 2. النطاق والقرارات

- خطة المنتج مقبولة مبدئيًا، والأفكار الإضافية تؤجل حتى إنجاز نطاقها الحالي.
- المطلوب: مطبخي إيزوميتريك وإضاءة الوقت، تلاجة وفريزر ودواليب، وحدات شراء واقعية، أفراد وشخصيات وسفرة وسجل، ثم التخصيص والمسح والفواتير.
- اعتراض واجب المعالجة: الزر الحالي يشبه دولينجو أكثر مما يريده المستخدم؛ يلزم اتجاه أصلي.
- توثيق تفاصيل المنتج والأسئلة المفتوحة في ../../sofra-product-design-plan.md؛ لا تنسخ الوثيقة هنا.
- المستخدم طلب خطة قبل التنفيذ. إنشاء هذه الوثائق لا يغير حالة تنفيذ الميزات.

## 3. الجوال وFirebase — 10 أكتوبر 2026

- المستخدم أكد Samsung Galaxy S24 Ultra؛ مسار APK مباشر مناسب للتجربة الأصلية، ولا حاجة لمسار TestFlight له.
- لا يوجد APK جديد مبني أو تم تثبيته على جهازه حتى الآن.
- للمستخدم مشروع Firebase مختلف ولم ينشئ مشروعًا لسُفرة. عرض إتاحة الحساب/الصلاحية، ولم تُنشأ جلسة دخول أو تُمنح صلاحية متحققة بعد.
- التوصية: نفس حساب Google مع مشروع مستقل لسُفرة، لحفظ بيانات التطبيقين وإعداداتهما منفصلة.
- البداية المخططة: Authentication بالبريد وكلمة مرور، Firestore للحفظ، وHosting عند الحاجة لرابط معاينة.
- الخطة المجانية مناسبة مبدئيًا للتجربة ضمن الحصص. لا تفعيل للفوترة أو استخدام SMS أو خدمة مدفوعة بالافتراض.
- المطلوب التالي: تحديد مشروع سُفرة وتسجيل الدخول بالطريقة المتاحة، دون طلب كلمة مرور أو أسرار في الدردشة.

## 4. نظام التسليم وتقليل الاستهلاك — 10 أكتوبر 2026

- طلب المستخدم أن يحفظ الوكلاء تفاصيل العمل في ملف تسليم، وملخصًا صغيرًا يمنع إعادة قراءة كل شيء.
- أنشئ AGENTS.md في مساحة العمل والمستودع، وdocs/STATUS.md، وهذا الملف.
- STATUS محدود بأقل من 50 سطرًا. HANDOFF يحتوي القرارات والتغييرات ونتائج الفحص والمشكلات والخطوة التالية، دون سجلات خام.
- عند وجود وكلاء: لكل واحد ملفات محددة، ويسلم تفاصيل عمله؛ المنسق يحدث الملخص المشترك لتجنب التعارض.
- لم تُشغل فحوص التطبيق لهذه الإضافة التوثيقية، ولم يُعدل الكود أو Firebase.

## 5. الحساب والحفظ وAndroid — 11 أكتوبر 2026

- المستخدم أذن بالتنفيذ ثم أنشأ مشروع sofra-c03a1 وأرسل رابطه.
- CLI مسجل مسبقًا؛ استُخدم هذا الاتصال دون تصدير بيانات اعتماده. لوحة Firebase كانت عالقة في التحميل؛ حُل العائق في القسم 7.
- أضيف Android بمعرف com.mohussamarch.sofra، وWeb. ملفات config تحتوي إعدادات العميل العامة فقط.
- Firestore: قاعدة (default)، Standard، europe-west3، freeTier=true. لم يُربط حساب فوترة.
- Authentication كان غير مهيأ؛ حُل عبر Get started في القسم 7. لا تستخدم initializeAuth العامة لأنها تتطلب مشروعًا مفعل الفوترة وفق التوثيق.
- lib/data/state_store.dart: حفظ محلي، حفظ سحابي بمعاملات ومراجعة رقم النسخة، وطابور كتابة متسلسل.
- lib/ui/session_gate.dart: تحميل بيانات المستخدم أو الحفظ المحلي، دخول/تسجيل/استعادة كلمة مرور، وحالات خطأ.
- lib/main.dart: حفظ الحالة المهمة واسترجاعها، عرض خطأ الحفظ ومنع الخروج أثناء كتابة معلقة أو فاشلة.
- test/persistence_test.dart: عودة البيانات بعد إعادة الفتح، إعادة المحاولة بعد فشل الحفظ، وترتيب الكتابة وعدم تغير النسخة أثناء الانتظار. الثلاثة نجحت؛ flutter analyze نظيف.
- اختبار استرجاع البيانات احتاج ضبط SnackBarTheme في إطار الاختبار؛ تم الإصلاح وإعادة الاختبار.
- قواعد Firestore تعزل كل حساب وتفرض تسلسل revision؛ اختبار Emulator نجح في CI ونُشرت القواعد.
- CI يبني ARM64 APK ويرفعه كأثر. فحص iOS أصبح يدويًا اختياريًا؛ لا ندعي اختبار هذه الدفعة عليه بعد.
- أدوات الإعداد الإدارية في tool/rules/setup-firebase.cjs، تعمل على sofra-c03a1 فقط وتستخدم جلسة CLI دون طباعة الاعتمادات.
- الدفعة دُفعت في f6d5785؛ CI 38113824888 نجح: التحليل و10 اختبارات وبناء الويب وAndroid وقواعد Firestore. iOS لم يعمل لهذه الدفعة.
- tool/rules/live-smoke.mjs يفحص حسابين مؤقتين وكتابة/استرجاع البيانات وعزل الحسابات ورفض نسخة قديمة، مع تنظيف بيانات الاختبار. نجح فعليًا في القسم 7.

## 6. تسليم APK وGoogle Drive — 11 أكتوبر 2026

- المستخدم طلب مجلد Sofra داخل WORK على Google Drive لنسخ التجارب. استخدمه لكل تسليم لاحق، مع الاحتفاظ بالنسخ السابقة وتسمية واضحة.
- WORK: 1cT047i5RJqOvVavWwDMnLDdAhfRupme9؛ Sofra: 1qRAV-M2I1LTXW2zo1tRghAbqfL3o84CH.
- رابط المجلد: https://drive.google.com/drive/folders/1qRAV-M2I1LTXW2zo1tRghAbqfL3o84CH
- رُفع Sofra-v0.1.0-build1-2026-10-11-f6d5785-arm64.apk وتحقق وجوده بقراءة محتويات المجلد؛ الحجم 19613057 بايت.
- رابط النسخة: https://drive.google.com/file/d/1OlprXHw2sG6LhpvBe7gggN2IFUrLcQZ7/view
- المصدر: GitHub run https://github.com/mohussamarch/sofra-flutter/actions/runs/38113824888، artifact sofra-samsung-apk.
- النسخة المحلية: ../../sofra-s24-ultra.apk. SHA256: 06E9742F4AEBB98F4DC7424B914C9E5595636FE1BDFC1ACB5B745DA1DAE32332.
- فُحصت بنية ZIP ووجود AndroidManifest.xml ومكتبتي libapp.so وlibflutter.so للـARM64. البناء نجاح، لكن التثبيت على Samsung الفعلي لم يُتحقق بعد.
- توقيع اختبار؛ CI يحتفظ بمفتاح debug عبر cache. إصدار متجر أو تحديثات طويلة المدى تحتاج مفتاح توقيع دائم.
- إرشادات الجوال: ../../تجربة-سفرة-على-سامسونج.md. واجهة الدخول فُحصت بصريًا محليًا؛ تهيئة Auth اكتملت في القسم 7.
- Hosting رفض APK لأن Spark يمنع الملفات التنفيذية؛ حُذف ملف APK فقط من build/web/downloads، مع إبقاء النسخ المحلية وDrive. لا تغيّر الفوترة.
- نشر الويب وحده نجح: https://sofra-c03a1.web.app . خدمة تسجيل الحساب جاهزة بعد القسم 7.

## 7. اكتمال تفعيل Firebase — 12 أكتوبر 2026 بتوقيت الرياض

- المستخدم فتح صفحة Authentication؛ هذه المرة حمّلت الواجهة. ضُغط Get started لمشروع sofra-c03a1 فقط، ثم node setup-firebase.cjs auth-enable.
- النتيجة المتحققة: email.enabled=true، passwordRequired=true، subtype=FIREBASE_AUTH. الواجهة أظهرت Email/Password Enabled وSpark بدون تكلفة شهرية. لم تُفعل الفوترة.
- node live-smoke.mjs انتهى exit 0: إنشاء حسابين تجريبيين، تسجيل دخول، حفظ rice=500 واسترجاعه من الخادم، منع حساب آخر من القراءة، ومنع كتابة revision قديمة. تحذير PERMISSION_DENIED أثناء اختبار الرفض متوقع.
- حُذفت الوثيقة وحسابا الاختبار المؤقتان في finally بنجاح؛ لم تُقرأ أو تُعدل بيانات مستخدمين آخرين.
- دليل الواجهة: ../../setup/firebase-auth-enabled.png. فحص الخلفية استخدم Firebase JS SDK؛ لا تدّع اختبار APK على Samsung فعليًا.
- لا تغييرات في كود التطبيق أو إعدادات العميل؛ APK الموجود على Drive ومعاينة Hosting يعملان بالإعداد الجديد دون إعادة بناء أو إعادة رفع.
- أضيف .firebase/ إلى .gitignore لاستبعاد كاش النشر المحلي. حُدث STATUS ودليل الجوال.
- التالي: تجربة المستخدم للنسخة الحالية: إنشاء حساب، إعداد البيت والمخزون، انتظار الحفظ، إغلاق وفتح التطبيق ثم خروج ودخول. عالج أي مشكلة فعلية قبل الانتقال لدفعة التصميم التالية.

## 8. أول تصور بصري وصوتي — 12 أكتوبر 2026

- المستخدم أكد تثبيت APK وإنشاء حساب تجريبي بنفسه، ثم طلب نموذجًا كاملًا للمراجعة وأجاز الصور المبدئية أولًا للتوفير، مع التفكير في Sound Design.
- الدفعة الحالية صور أولًا: ../../sofra-concept-v1/concept-board.png تعرض أفراد البيت، المطبخ الإيزوميتريك، التلاجة المفتوحة والسفرة المخططة. أداة image_gen المدمجة؛ النص الكامل في IMAGE-PROMPT.txt. الصورة مرجع فني وليست واجهات منفذة أو Auto Layout متحققًا.
- استُفيد من مرجع دروس الواجهات: المسار أولًا، تخطي/رجوع، المسافات والتناسق وتقليل الزينة ورد الفعل الواضح. صورة السفرة الحالية تحتاج زاوية أعلى وإظهار المقاعد في التنفيذ، والمطبخ قد يحتاج تبسيط الزينة لتوضيح مناطق اللمس.
- وفق طلب Astra السابق للتصميم، أُسندت مهمة مستقلة واحدة لـAstra: soundboard.html وSOUND-HANDOFF.md فقط. لا تكرار لقراءة المشروع أو تعديل Flutter.
- لوحة عربية مستقلة بستة أصوات تركيبية أصلية: الثلاجة، مكوّن، درج، طبق، فرحة، تنبيه. تحكم بالمستوى والكتم والتسلسل؛ لا تشغيل تلقائي أو موارد خارجية. ليست أصوات foley نهائية.
- README داخل مجلد التصور يحدد مسارات النموذج الكامل وسياسة الصوت والقرار التالي؛ لا حاجة لإعادة قراءة خطة المنتج كلها.
- تحقق: فحص بنية JS/HTML نجح بواسطة Astra. فتحها المنسق في IAB وشغّل التسلسل ثم كتم وألغى الكتم؛ الحالة المرئية تغيّرت كما ينبغي، وسجل المتصفح خال من أخطاء JS. لا يدّعي هذا تقييمًا سمعيًا بشريًا أو اختبار الصوت على الهاتف.
- دليل الواجهة: ../../sofra-concept-v1/soundboard-preview.png. خادم work/serve_concept.cjs على http://127.0.0.1:8766/ . احتاج التشغيل خارج العزل ليصل إليه المتصفح؛ لا تشغّل خادمًا ثانيًا على المنفذ نفسه.
- قرار التوقف للمراجعة: المستخدم أجاز الصور أولًا؛ التالي ضبط اتجاه الرسم والأصوات حسب رأيه ثم النموذج المتجاوب الكامل، قبل نقل التصميم إلى APK.

## 9. تنفيذ النموذج بعد تصحيح الاتجاه — 12 أكتوبر 2026

- المستخدم رفض تعقيد الرسوم ثم منع توليد صور إضافية وأكد المطبخ الإيزومتريك والشخصيات الفلات المتحركة، وألغى عينات الأصوات. الموسيقى ممنوعة نهائيًا. تُقدّم هذه القيود على التصور السابق.
- أُنجز النموذج بالكود في ../../sofra-concept-v1/index.html وprototype.css وprototype.js؛ التفاصيل المركزة في PROTOTYPE-HANDOFF.md داخل المجلد نفسه. لا تعد قراءة السجل كله.
- رابط محلي http://127.0.0.1:8766/؛ المصدر الدائم design-preview/ داخل المستودع مع serve.cjs، وwork/serve_concept.cjs بالمساحة الرئيسية يحيله إليه. عدّل المصدر الدائم مستقبلًا؛ outputs/sofra-concept-v1 يحتفظ بنسخة التسليم والصور التاريخية. راجع عملية المنفذ قبل إعادة تشغيله.
- رحلة إعداد البيت والأفراد، التخصيص والطرحة، مطبخ إيزومتريك وشباك يسار وإضاءة الوقت، مناطق تخزين وأرفف ورموز وكميات وبواقي، وصفات وحصص، سفرة ومقاعد قابلة للتبديل وتفاعل المفضلة، تأكيد طبخ وسجل، وتقليل الحركة.
- الحفظ محلي فقط بمفتاح مستقل. حسابات المستخدم وFirestore وAPK وHosting لم تتغير؛ لا تدّع أن التصميم نُقل إلى تطبيقه المثبت.
- الأصوات أُلغيت: لا استيراد audio.js في الصفحة ولا AudioContext، ولوحة الصوت الحالية تعرض إلغاء التجارب. لا تَعُد لتشغيل عينات الأرشيف.
- محاولة Astra لبناء النموذج تعثرت بحد الاستخدام؛ المنسق أكمله. لا تُنسب له كتابة النموذج.
- تحقق Node وبراوزر Edge مستقل: الإعداد والتخصيص ومحتوى العبوة والبواقي وتبديل الكرسي الفارغ والحفظ، والتخطيط دون خصم والتأكيد مرة واحدة والسجل والرجوع وإضاءة الليل، على 412 و360؛ لا أخطاء JS. لقطات واجهات فعلية محفوظة بالمجلد.
- التالي: ملاحظات المستخدم ثم نقل الاتجاه إلى Flutter تدريجيًا. السكان والفواتير وموديلات الأجهزة المتعددة والسحب مؤجلة، والتبديل بالضغط والتخصيص بالألوان يعملان.

## 10. صباح واكتشاف الأجهزة وستة رفوف وتسليم SOFRA — 12 أكتوبر 2026

- طلب المستخدم بداية صباحية وشعاع ضوء وتفاصيل إضافية، إزالة أسماء الأجهزة من المشهد والاكتشاف بالضغط، حركة دخول، وستة رفوف على الأقل بخانات صغيرة. وطلب حفظ المشروع كاملًا داخل مجلد work/Sofra الذي يحتوي صورتين مرجعيتين وهاند أوف كامل.
- عُثر على المجلد E:\work\SOFRA. روجعت الصورتان Screenshot 2026-10-10 211534.png وScreenshot 2026-10-12 013310.png. يحتوي أيضًا دفتر recipes مستقلًا؛ لا تحذف أو تستبدل الموجود.
- design-preview/prototype.js: كل جلسة متصفح جديدة تبدأ صباحًا، مع بقاء اختيار العصر والليل داخل الجلسة. تفاصيل أصلية بالكود: منظر شباك، شعاع وبقعة ضوء، بلاط وسجادة، أدوات وحلة ولوح تقطيع وفوطة ومقابض ومغناطيس. أسماء الأجهزة أزيلت من الرسم مع إبقاء تسميات قارئ الشاشة.
- حركة الدخول تركز على القطعة المضغوطة، تفتحها ثم تقرّب وتنتقل إلى المنظور الأمامي. قفل الضغط المكرر أثناء الانتقال؛ احترام تقليل الحركة والنظام.
- ستة رفوف مكونات على الأقل، أربع خانات صغيرة لكل رف؛ الخانة الفارغة تضيف مكوّنًا في المكان الحالي. تُزاد الرفوف تلقائيًا بعد 24 مكوّنًا فلا يختفي المخزون. رف البواقي مستقل. الأرفف قابلة للتمرير وتبقى الكميات نصية.
- design-preview/check.cjs يحفظ لقطات فعلية في design-preview/screenshots، ويعمل عبر Playwright مع Edge مستقل. فحص syntax نجح؛ رحلة الإعداد والحفظ والتخطيط والخصم والمقاعد والبواقي نجحت، ومعها بدء صباح بعد إعادة الفتح وعدم وجود أسماء SVG، حركة التركيز والدخول، 6×4 خانات، عرض 31 مكوّنًا وطبق بواقي، وعدم امتداد أفقي 412/360. أخطاء JS: صفر.
- نسخة تسليم كاملة من المستودع وتاريخه داخل E:\work\SOFRA\app، والخطط وAPK التجريبي السابق داخل E:\work\SOFRA\deliverables، مع HANDOFF.md كامل وSTATUS.md صغير بالمجلد الرئيسي. دون كاش البناء أو SDK؛ تستعاد التبعيات بالأوامر الموضحة. الوصفات والصور الأصلية في الجذر محفوظة كما هي.
- Flutter وFirebase وHosting وAPK لم تتغير. لا موسيقى ولا مؤثرات ولا توليد صور. دفتر 54 وصفة لم يُدمج بعد؛ النموذج لا يزال يعرض 3 وصفات مثال.
- التالي: مراجعة المستخدم للمشهد المعدل؛ ثم نقل المطبخ والأرفف والشخصيات تدريجيًا إلى Flutter، مع الخدمات الحالية، وبناء APK جديد في دفعة الدمج.

## قالب أي تسليم لاحق

- الهدف والنطاق:
- الملفات والتغييرات:
- القرار وسببه:
- الفحص الذي نُفذ فعلًا ونتيجته:
- ما لم يُنفذ أو ما يزال معطلًا:
- الخطوة التالية المحددة:

## 11. اعتماد بروتوكول التسليم ونسخة واحدة — 12 أكتوبر 2026

- الهدف: تثبيت تعليمات المستخدم التسع للتسليم بين الوكلاء. نسخة العمل الوحيدة المختارة E:\work\SOFRA\app؛ المرجع GitHub origin/main. نسخة Codex بقيت دون تعديل على 123534db3618d3b247331f2c6bdd01a9516415e6 وتحتاج fast-forward من GitHub إذا اختيرت لاحقًا للعمل.
- الملفات المتغيرة: AGENTS.md وdocs/STATUS.md وdocs/HANDOFF.md فقط داخل Git. ملفات التسليم الخارجية STATUS.md وHANDOFF.md وDELIVERY.json تُحدّث بعد commit وpush لتسجل hash التسليم الفعلي.
- القرارات وأسبابها: اعتماد E لأنها مجلد التسليم الذي حدده المستخدم، وإبقاء نسخة واحدة للتحرير لمنع تباعد النسخ. نُقل خادم المعاينة من نسخة Codex إلى E مع الحفاظ على المنفذ نفسه؛ أُوقف PID 37752 بعد التحقق من أنه خادمنا القديم.
- الفحوص المنفذة في هذه الدفعة: fetch origin main، وتحقق HEAD وorigin/main ونظافة الشجرتين عند البداية، وفحص node --check للنموذج ناجح، وفحص HTTP 200 على المعاينة من نسخة E. git diff --check يُنفذ قبل commit، ونظافة Git وتطابق HEAD وorigin/main تُثبت في إيصال التسليم الخارجي بعد push.
- نتائج فحص التفاعل والرفوف والحفظ في القسم 10 تاريخية، لم تُعَد في دفعة التوثيق؛ لا تعديل في مصدر التطبيق أو التصميم.
- المشاكل المفتوحة: لا مشكلة تشغيل جديدة. ما زال نقل التصميم إلى Flutter ودمج دفتر الوصفات والباركود والفواتير مؤجلًا حسب النطاق السابق. لا شغل غير مكتمل ولا branch عمل منفصل لهذه الدفعة.
- APK: لم يُبن ملف جديد ولم يُرفع ملف جديد ولم تُجر تجربة هاتف جديدة. بيانات النسخة السابقة واختبار المستخدم وDrive في القسمين 6 و7 وإيصال التسليم الخارجي.
- Firebase: لم يحدث أي تغيير في القواعد أو الدخول أو البيانات أو Hosting أو Billing بهذه الدفعة. المشروع الوحيد المصرح به sofra-c03a1.
- قرارات المستخدم: لم تتغير؛ بلا موسيقى أو أصوات أو توليد صور، المطبخ إيزومتريك صباحًا والتلاجة أمامية بنقطة تلاشي وستة رفوف على الأقل، والخصم بعد التأكيد مرة واحدة.
- الخطوة التالية بالضبط: استقبال ملاحظات المستخدم على المعاينة الحالية؛ ثم نقل التصميم المعتمد إلى Flutter تدريجيًا مع خدمات الحساب والحفظ الحالية وبناء APK جديد. لا تنفذ إعادة بناء أو نشرًا ضمن دفعة التوثيق.

### آخر بيانات التسليم

- آخر commit للتنفيذ المرئي وقاعدة دفعة التوثيق: 123534db3618d3b247331f2c6bdd01a9516415e6.
- آخر commit النهائي للتسليم بعد push: يُسجل بالـhash الكامل في E:\work\SOFRA\HANDOFF.md (آخر قسم) وDELIVERY.json؛ يعرض git rev-parse HEAD القيمة نفسها. لا يمكن لملف متتبع أن يسجل hash الـcommit الذي يحتويه دون تغيير ذلك الـhash.
- السيرفر: شغال على 127.0.0.1:8766، PID 31004، المصدر E:\work\SOFRA\app\design-preview\serve.cjs. أمر التشغيل: node E:\work\SOFRA\app\design-preview\serve.cjs. أُبقي للمراجعة، ولم يُغلق.

## 12. مراجعة واعتماد دفتر وصفات المستخدم — 12 أكتوبر 2026

- المستخدم شارك imports للفهرس وscaleRecipe وstepSchedule/createTimer/tickTimer. روجع المصدر الموجود بالفعل في E:\work\SOFRA\recipes بدل إعادة إنشائه. نسخة العمل للمشروع E:\work\SOFRA\app فقط؛ المرجع origin/main.
- أُدخلت نسخة من ملفات الدفتر الستة عشر إلى recipes/ داخل Git، مع اختبار rounding-regressions.mjs جديد، ودليل docs/RECIPE-INTEGRATION.md. الأصل خارج Git بقي دون تغيير، وتحقق ذلك بـSHA256 لجميع ملفاته وقت النسخ.
- قبل التصحيح نجحت اختبارات المستخدم لكن تجربة مستقلة كشفت تقريبًا خاطئًا: 0.25 كوب→0.5، و8 أكواب→10، و1.25 لتر→1.5. السبب مشاركة وحدات الكوب واللتر قاعدة تقريب الجرام. صُحح recipes/src/scale.ts بحفظ الكسور للكوب واللتر والكيلو حتى ثلاث خانات. بقيت قواعد الحبات وscale:false وحسب الرغبة كما هي.
- حُدث اختبار ذاتي واختبار تكامل كانا يثبتان الخطأ القديم (11.25 كوب→10)، وأضيفت حالات مستقلة للتصغير والتكبير وكسور السوائل والكيلو. package.json يشغلها ضمن npm run check؛ README يوضح النسخة المعتمدة وNode 24.20.0 المتحقق منه والحدود.
- الفحوص الفعلية: npm run check على الأصل نجح؛ فحوص النسخة المصححة نجحت: 54 وصفة،605 مكونات،375 خطوة،15 اختبارًا ذاتيًا،216 تغيير حصص،54 مؤقّتًا، واختبارات منع تكرار التقريب. ظهرت 74 ملاحظة عرض غير فاشلة عن كسور عشرية مقصودة. git diff --check قبل commit؛ التطابق مع origin/main ونظافة الشجرة بعد push موثقان في الإيصال الخارجي.
- المشاكل والحدود: الوصفات لم تُربط بشاشة النموذج أو Flutter بعد. TypeScript يحتاج بناء للمتصفح ومحولا إلى Dart للتطبيق. التحويل بين الأكواب/الحزم والوزن يتطلب تعريفًا حسب المكوّن؛ لا تخمين. الأوقات تقديرات، وجدول الخطوات متتابع، والمؤقّت يحسب الحالة ولا يشغل تنبيهًا أو خدمة خلفية بذاته.
- التالي بالضبط: استعمال الفهرس والوصفات وواجهات الحساب الموجودة عند ربط شاشة الوصفات، مع معرفات مكونات ومراجعة الوحدات، ثم اختبار عدم الخصم عند التخطيط والخصم مرة واحدة بعد التأكيد.
- لا APK جديد، ولا تغيير Firebase أو Hosting أو Billing أو قرارات الموسيقى والأصوات والصور وشكل المطبخ والتلاجة والخصم. لا شغل غير مكتمل لهذه الدفعة؛ الربط المستقبلي معلن كخطوة لاحقة.

### آخر بيانات التسليم

- قاعدة دفعة الوصفات: 0c72a132596d4d551fd313d34a88c97da71c963a. آخر hash نهائي بعد push في E:\work\SOFRA\HANDOFF.md وDELIVERY.json ويطابق git rev-parse HEAD.
- السيرفر: شغال 127.0.0.1:8766، PID 31004، المصدر E:\work\SOFRA\app\design-preview\serve.cjs. لم يُغلق، ولم تتغير واجهة المعاينة بهذه الدفعة.

## 13. تدقيق وإكمال طبقة المنطق دون إعادة تصميم — 12 أكتوبر 2026

- المستخدم طلب معرفة نواقص الكود وبناء الوظائف، مع ترك التصميم البصري لمكان آخر. نسخة العمل الوحيدة E:\work\SOFRA\app، وقاعدة هذه الدفعة 98570b65c5a187044fd14818388fb9b5b7d42add. نسخة Codex غير نشطة ولم تُعدّل.
- النواقص المثبتة قبل العمل: دفتر54 وصفة TypeScript غير متاح في Dart، محرك consume القديم يقبل خصمًا جزئيًا ويتعامل مع تقدير قديم، والاحتياجات المكررة تستطيع الاعتماد على نفس المخزون؛ لا سجل تأكيد ثابت أو طبقة مستقلة للتقويم/المؤقّت/الوحدات/العبوات/الميزانية/الأسعار حسب البلد.
- الملفات الجديدة: lib/domain/recipe_catalog.dart وkitchen_core.dart وmarket_profile.dart وcooking_timer.dart؛lib/data/recipe_repository.dart وkitchen_service.dart؛test/backend_test.dart وtest/fixtures/recipe-parity.json؛tool/recipes/export-dart-fixtures.mjs؛docs/BACKEND-API.md وMONEY-RULES.md.
- ملفات الربط والتصحيح: pubspec.yaml يضمّن recipes/data؛recipe_engine.dart يرفض النقص والتقدير القديم ويجمع المكررات؛main.dart يحفظ البلد وسجل الطبخ ويحمي ضغط التأكيد؛اختبارات engine/persistence/demo flow حُدثت لمنافذ التنقل الجديدة. لم تُضف تبعية أو خدمة مدفوعة.
- RecipeRepository يحمّل الفهرس وملفات المطابخ كسولًا من الأصول مع كاش وإعادة محاولة،وبحث عربي وفلاتر. CatalogRecipe/scaling/schedule مطابق للمكتبة المصححة؛أُثبت المقادير والنصوص والمدد في216 حالة حقيقية عبر golden مولّد من TypeScript.
- KitchenService يستخدم StateStore الموجود،بامتداد kitchen.version=1 داخل الجذر schema=1،ويحتفظ بالمفاتيح القديمة،ويرحل المخزون القديم فقط بوحدات صريحة. الحفظ متسلسل،ولا ينشر الحالة إلا بعد نجاحه. اختبار rollback/retry نجح. لا تشغيل كاتبين قديم/جديد على الحالة نفسها؛الواجهة الخارجية تستعمله مالكًا واحدًا.
- مخزون بدفعات وكمية مجهولة،عبوات ذات محتوى صريح، وتحويل جرام/كيلو ومل/لتر فقط أو UnitRule لمكوّن محدد. تخصيص أفراد ومقاعد ثابتة وبواقي وحصص، وخطط بتاريخ ووجبة وحصص،ونطاق يوم/أسبوع/شهر (الأسبوع الاثنين)،دون خصم عند التخطيط.
- تأكيد الطبخ يستخرج المقادير،ويتطلب إقرارًا بالمكونات غير المقاسة أو كميات صريحة،ويعيد تقييم المخزون،ويحفظ المخزون والخطة والسجل في عملية واحدة. operationId ثابت يعيد النتيجة نفسها بعد التزامن/إعادة الفتح؛طبخ خطة مكتملة بعملية جديدة مرفوض. السعر المجهول يظل null مع قائمة،والسجل المؤكد لا يتغير عند تعديل الأسعار.
- مؤقّت serializable بمرجع ساعة حقيقي: الخلفية لا تضيع الوقت،وقف/استئناف،والخطوة صفرية الوقت انتظار يدوي. لا صوت أو خدمة OS أو إشعارات أضيفت. أسعار منفصلة للبلد،وسعر المستخدم قبل المتوسط،وشراء جديد منفصل عن الاستهلاك وميزانيات فترة دون ترحيل.
- التحقق الفعلي النهائي: flutter analyze --no-pub نجح بلا ملاحظات؛flutter test test --no-pub نجح23 اختبارًا؛flutter build web --dart-define-from-file=config/firebase.web.json --no-pub نجح مع Wasm dry run. المقارنة مع TypeScript216 حالة ناجحة. npm run check للمكتبة الأصلية تاريخي في القسم12؛هذه الدفعة لم تغيّر TypeScript.
- المشاكل المفتوحة/الحدود: لا عطل برمجي معروف في الفحوص المنفذة. المصدر الجديد جاهز للواجهة الخارجية؛شاشات الوصفات الحالية ما زالت demo ولم يُربط بها كتالوج بصري جديد. مصادر الأسعار الفعلية،البيانات الغذائية ومحرك البدائل/خطة من الميزانية والباركود والفواتير لم تبدأ. لا يدّعي الكود توازنًا غذائيًا أو أمانًا طبيًا من بيانات ناقصة.
- Firebase: لا تعديل قواعد أو Auth أو Hosting أو بيانات فعلية أو Billing. اختبارات الطبقة الجديدة استخدمت MemoryStore والأصول المحلية،ولم تشغّل live Firebase smoke مجددًا. المشروع الوحيد المصرح به sofra-c03a1.
- APK: لم يُبن أو يُرفع APK جديد بهذه الدفعة؛بناء الويب محلي ولم يُنشر. نسخةAPK السابقةf6d5785 وSHA ومكانها وDrive وتجربة المستخدم في§6–7 وإيصال الجذر.

## 14. توجيهات المستخدم الوظيفية والقرارات المالية الستة

- المستخدم استثنى من منع تصميم الواجهات تصحيحات محددة: ذكر لا يرتدي طرحة،النوع قبل خيار الطرحة وترتيب الأشخاص/المقاعد ثابت،صياغة عامة تناسب شخصًا واحدًا،اختيار مصر/السعودية مبكرًا للصياغة والعملة والأسعار،حذف بيتي من الشريط وإتاحته داخل مطبخي/النهارده،وتقويم أسفل النهارده بثلاث وجبات أو أكثر واليوم/الأسبوع/الشهر.
- prototype.js ينفذ التصحيحات ويحفظها بمفتاح النموذج المستقل؛شراء جديد اختياري يسجل المبلغ والبلد والعملة،أما الموجود من قبل فلا. تقويم النموذج يحفظ خطط مؤرخة مع وجبات إضافية دون خصم أو شراء. main.dart أصلح التنقل إلى4 تبويبات،واختيار البلد والصياغة العامة،ولا يعيد تسمية السعر التجريبي المصري سعرًا سعوديًا؛السعودي غير المعروف ظاهر كغير محدد. lib/data/demo_data.dart صيغته أصبحت عامة،ولا تعديل على الرسوم.
- القرارات التي أجاب عنها المستخدم: الميزانية للمشتريات الجديدة فقط والمستهلك منفصل؛السعر الذي يضعه المستخدم قبل المتوسط؛تجاوز الميزانية تنبيه+بدائل بلا تعديل آلي؛إضافة المكوّن فيها اختيار شراء جديد؛تعديل السعر يؤثر القادم فقط والسجلات المؤكدة ثابتة؛كل شهر ميزانية جديدة بلا ترحيل. تفصيل السيناريوهات والنطاق المؤجل في MONEY-RULES.md.
- ملفات فحص النموذج: check.cjs وcheck-functional.cjs؛نجح التدفق القديم والأرفف والحفظ والخصم،والجديد للذكر والطرحة والشخص الواحد والبلد والعملة وأربع تبويبات وبيتي والتقويم بثلاثة عروض ووجبات إضافية والشراء الاختياري والحفظ. عرضا412/360 دون تجاوز أفقي،وأخطاء JS صفر. لقطات المشاهد القديمة في screenshots حُدثت بالفحص،وليست توليد صور.
- تغييرات قرارات المستخدم الصريحة: لم يعد بيتي تبويبًا سفليًا؛التصميم البصري سيُنفذ خارجيًا،والعمل الحالي منطق مع الاستثناءات الوظيفية أعلاه. بقية القرارات ثابتة:لا موسيقى أو أصوات أو توليد صور،مطبخ إيزومتريك صباحي وتلاجة أمامية one-point،والخصم بعد التأكيد مرة واحدة.
- الخطوة التالية بالضبط: فريق/مكان التصميم يقرأ BACKEND-API.md ويربط الواجهة الجديدة بمالك الحالة KitchenService وRecipeRepository. ثم تُجهز بيانات الأسعار والتغذية قبل تشغيل محرك اقتراحات أو الحكم على التوازن. لا تعِد بناء الحسابات ولا تُنشئ واجهات إضافية تلقائيًا.

### آخر بيانات التسليم

- آخر commit قبل دفعة المنطق: 98570b65c5a187044fd14818388fb9b5b7d42add. hash التسليم النهائي بعد push في E:\work\SOFRA\HANDOFF.md وDELIVERY.json؛ويطابق git rev-parse HEAD.
- لا شغل متروك بلا commit ولا branch غير مكتمل في هذا التسليم؛المراحل المؤجلة أعلاه لم تبدأ.
- سيرفر المعاينة ما زال شغالًا127.0.0.1:8766،PID 31004،المصدر E:\work\SOFRA\app\design-preview\serve.cjs. تشغيله node E:\work\SOFRA\app\design-preview\serve.cjs؛لم يُغلق.


## 15. الغذاء والأشخاص وبنك المصادر — 12 أكتوبر2026

### النطاق والملفات

- المستخدم فوّض نواة الغذاء وربط الأشخاص والأرقام والتفاعل ووكلاء لبنك المنتجات. نسخة E وحدها؛ base: bb1034d3b6056cdccde7f1c2f298368ef71e8d25. ثلاثة وكلاء بملكية مستقلة؛ تقاريرهم في work/agent-handoffs/، والملخص هنا.
- جديد: lib/domain/food_nutrition.dart وperson_nutrition.dart وrecipe_nutrition.dart؛ lib/data/food_repository.dart؛ اختبارات food_nutrition/person_nutrition/nutrition_integration؛ data/usda وdata/food؛ tool/usda وtool/food؛ docs/FOOD-DATA-ARCHITECTURE.md وPRODUCT-DATA.md.
- حُدث KitchenService وpubspec.yaml والوثائق. لا واجهات أو dependencies جديدة. نسخة Codex لم تُعدّل.

### القرارات وأسبابها

- 49 معرّف مغذٍ بوحدات وتعريفات منفصلة؛ الكربوهيدرات العامة/byDifference/available وRAE/DFE لا تُخلط. قياس وحالة وجزء مأكول وكثافة وحبة واحتفاظ بمصدر، مع نواقص لكل مغذٍ ووزن ناتج مطلوب لـper100g.
- USDA: 8156 مرجعًا، Foundation363 صالحًا+SRLegacy7793؛32null عُزلت. CC0،32shard وقاموس مغذيات وبصمات. الوحدة التالفة�g لا تُصحح بالتخمين؛ الخام محفوظ. ليست بيانات توفر محلي أو شهادة حلال.
- OFF: 687GTINصالحًا مسمى/20فئة؛ EG320/SA374/مشترك7؛510مغذيات/461ماكروز/329مكونات/179حساسية/108ماركة ناقصة.27أرشيفًا،15طلب503 بلاretry،75occurrence معزولة و92مكررة. ODbL/DbCL مفصولتان عنUSDA والكود؛ التفاصيل والبصمات بالـmanifest وPRODUCT-DATA. لا صور أو أسعار أو مفاتيح.
- أساسOFF100g/100ml مجهول حتى دليل الملصق. مراجعة الأساس لا تصلح تعارض جدول التغذية، وبيانات المجتمع تقديرية. الماركة الناقصة تحتاج مراجعة قبلFoodRecord محدد. عدم بيان الحساسية لا يعني الخلو.
-54وصفة/605سطرًا/145ingredientId بقائمة مراجعة، لكن0ربط مؤكد جاهز. الربط recipeId+line لأن نفسID قد يصف نيئًا/مطبوخًا/بدائل. لا تدعي تغذية مكتملة لجميع الوصفات.
- الأشخاص بنفسmemberId، وحساسية بمصدر وشدة وسياسةcrossContact، وأهداف صريحة بمصدر وفترة ومراجعة. لا احتياج طبي من العمر/الجنس/الصورة أو نص صحي. مرادفات الحساسية صريحة، والقمح والجلوتين منفصلان.
- حصص بالجرام أو نسبة دفعة صريحة؛ المخطط منفصل عن المأكول، وبواقي وهدر وتصحيحات بلا محو التاريخ. لا حصص متساوية أو معاملات أعمار مفترضة. تقسيم مغذيات دفعة متجانسة تقدير؛ الطبق غير المتجانس يفصل عند الحاجة.
- تفاعلات الحساسية/المجهول/الاحتفال والأهداف أحداث للواجهة. الأهداف تحتاج اكتمال تسجيل اليوم والبيانات. لا صوت أو رسوم أو علاج أضيفت.
- kitchen.nutrition.version1 يحفظprofiles/selections/ledger داخلschema1؛ البنك الكبير محلي. تأكيد الطبخ يجمد التغذية والدفعة والمخزون والسعر في حفظ واحد بلا أكل تلقائي. تصحيح بواقي واستهلاك يحفظان معًا عبرrecordNutritionEvents.
- فشل الحفظ لا ينشر الحالة، وحماية850KB تطلب أرشفة مستقبلية دون حذف التاريخ. لا كاتب ثانٍ مع الواجهة القديمة. الحساسية النصية القديمة تحتاج مراجعة منظمة لا تخمينًا.

### التحقق والحدود

- فحوص نهائية فعلية: Flutter51passed؛ analyzeNoissues؛ OFF5passed بإعدادSOFRA_FOOD_BANK؛ تدقيق هويات وقيم وبصمات8156مرجعًا وقائمة54/605؛ بناءwebبالإعدادات الحالية ناجح. محاولات أولى كشفتageمطلوبًا واسم مرجع رز غير مطابق وأصلحا، وحُلتbraceinfos.
- Playwright لم يُعد لعدم تغيير الواجهات؛ نتائجه السابقة تاريخية. لاAPKجديد/Hosting/Drive/اختبار جهاز بهذه الدفعة. APKالسابق كما في§6–7 وإيصال الجذر. لاFirebase/Auth/قواعد/حسابات/فوترة تغيرت.
- المفتوح: اعتماد الملصقات والمقادير وربط الوصفات، الأسعار الحقيقية وoptimizer وscan/OCR، أرشفةFirestore، عارض3D. هذه مراحل تالية معلنة؛ النواة والبنك منفذان.
- قرار تغيّر بطلب المستخدم: الغذاء انتقل من مؤجل إلى تنفيذ نواة وبنك. بقية القرارات محفوظة، ومنها الأصوات الملغاة والموسيقى وتوليد الصور والخصم بعد التأكيد.

## 16. ملف مستقل لسيشنBlender

- طلب المستخدم ملفًا كاملًا لسيشن جديدة تصمم المطبخ والسفرة3Dكرتونية بإضاءة غير واقعية. docs/BLENDER-DESIGN-BRIEF.md جاهز، وله نسخة في E:\work\SOFRA\BLENDER-DESIGN-BRIEF.md.
- استُخدمتdesign-handoff لتنظيم المتطلبات والحالات والتصدير والقبول. الملف يشملprompt، مطبخ إيزومتريك صباح وشباك يسار وشعاع، دخول تلاجةone-point وستة رفوف وخانات وبواقي/overflow، سفرة بيضاء بمنظور مركزي وأقلها3كراسي وشخص واحد صالح، شخصيات فلات وحركات وطرحة للأنثى فقط، وتخصيص أجهزة/ألوان/LED.
- يتضمنhotspots/pivots وكاميرات وclips وmanifest وGLB وخامات وتراخيص، ودعم الشاشات ومراحلblockout ورندرBlenderفعلي وقبول. لا صور أو موديلات وُلدت هنا ولا سيشن جديدة أُنشئت تلقائيًا.
- عارضFlutter3D لم يُحسم؛ اختبار أصل صغير علىS24Ultra مطلوب. حدود الأداء مقترحات غير مختبرة. المصمم لا يعدل الخلفية/Git/Firebase افتراضيًا ولا يرسم النصوص والكميات داخل الموديل.
- التالي بالضبط: إرفاق الملف بالسيشن الجديدة لبدءblockout والكاميرات ورندر فعلي. لمسار الغذاء، واجهة المراجعة تربطKitchenService وتراجع سطور البشاميل الفعلية أولًا وفقFOOD-DATA-ARCHITECTURE قبل تقرير مكتمل.

### آخر بيانات التسليم الحالي

- basecommit: bb1034d3b6056cdccde7f1c2f298368ef71e8d25. commitالنهائي بعدpush في E:\work\SOFRA\HANDOFF.md وDELIVERY.json، ويطابقHEAD وorigin/main. لاbranchغيرمكتمل أو تعديلات متروكة.
- السيرفر شغال127.0.0.1:8766، PID31004، node.exe من E:\work\SOFRA\app\design-preview\serve.cjs؛ لم يُغلق. إعادة التشغيل: node E:\work\SOFRA\app\design-preview\serve.cjs.

- تدقيق تسليم المصادر: .gitattributes يحفظ بايتات data/** دون تحويل سطور؛ hashes مصدر الوصفات تطبّعCRLFإلىLF لتعمل بين الأجهزة. تم فحص بصمات ملفات البيانات داخلGitindex نفسه مقابلmanifest، فلا يفسدهاcheckoutعلىويندوز.

## 17. استمرار اقتصادي لبنك الغذاء — 2026-10-12T23:37:07.626441+03:00

- تفويض المستخدم: لا توقف تطوير البنك عند عدد معين؛ وكيل اقتصادي وحفظ handoff مفصل وملخص صغير. هذا طلب جديد صريح، وبقية القرارات محفوظة.
- ملفات: AGENTS.md، docs/FOOD-BANK-CONTINUITY.md، docs/PRODUCT-DATA.md، tool/food/collect-incremental.mjs وملفات فحصه، tool/food/import.mjs، data/food/openfoodfacts/collection-state.json، work/agent-handoffs/food-bank-growth.md، test/nutrition_integration_test.dart، STATUS/HANDOFF. الملفات الفعلية النهائية فيcommit.
- الجامع يستكمل الفئة/السوق/الصفحة، يستفيد من الأرشيف المحفوظ ويحفظ الفشل وbackoff والقفل والوتيرة؛ المصدر لا يضمن التوافر. أضيف 29 منتجًا فأصبح البنك 716، مصر349/السعودية378/مشترك11، و28 أرشيفًا؛ الدفعة6 طلبات، نجاح1 وخطأ503 عدد5، مع حفظ backoff.
- القرار التشغيلي: احتياط10%من كل حد استخدام، فحص قبل الدفعة وبعد تقدم مهم، لا reset credits أو شراء رصيد؛ الحد90%اختيار احترازي للوكيل لا نسبة فرضها المستخدم.
- متابعة داخل المحادثة automation-2 «تطوير بنك غذاء سُفرة» ACTIVE كل ساعة؛ الجهاز والتطبيق والنسخة المحلية يجب أن تتاح. ليست خدمة جمع تعمل بين الجولات. النموذج المفوضgpt-6-luna/medium بسياق مختصر؛ لا اختلاق ضمان أرخص سعر رقمي.
- اختبار ربطOFF يقرأ العدد منmanifest مع شرط عدم الفراغ وعدم تكرارGTIN، حتى لا يفشل نمو مشروع للبنك بسبب687ثابتًا.
- تحقق فعلي بهذه الدفعة: Flutter integration: 5 passed؛ Node: 12 passed، تشمل 7 للجامع و5 للبنك مع فحص الهوية والبصمات؛ node --check ناجح نتائج51اختبار/analyze/web السابقة تاريخية ولم تُعد كاملة هنا. لا تغيير وظائف الواجهات يستلزم فحص المتصفح.
- المفتوح: تعطل المصدر المسجل، مراجعة أساس100g/100ml والملصقات، ربط605سطور الوصفات. لا نمو معدود أو جودة معتمدة من مجرد طلب ناجح. قبل مئات آلاف المنتجات بالنسخة المحمولة نحتاجبحثًا مفهرسًا/sharding وتوزيعًا انتقائيًا؛ البنك ليس مستندFirestore.
- لا Firebase/Auth/قواعد/فوترة أوHosting أوAPKجديد أوDrive، لا أصوات أو توليدصور أو تعديل تصميم. APKالسابقf6d5785 لم يُبنَ أو يُجرَّب بهذه الدفعة.
- الخطوة التالية بالضبط: في المتابعة التالية افحص الحدود ثم شغّل الجامع للفئات/الصفحات المستحقة، مع عدم تكرار الأخطاء داخلbackoff؛ سجلdeltaوالمراجعة الفعلية، حدّث التسليم وcommit/push بعد تغيير مفيد.

### آخر بيانات تسليم البنك

- نسخة العمل الوحيدة E:\work\SOFRA\app؛ basecommit e981a05fef22fd8b02262c6b56067546915bbdf7. آخرhashنهائي بعدpush في E:\work\SOFRA\HANDOFF.md وDELIVERY.json؛ لاhashذاتي داخلcommit.
- السيرفر باقٍ127.0.0.1:8766،PID31004،node.exe من E:\work\SOFRA\app\design-preview\serve.cjs؛ فُحص مالكه ولم يُغلق. إعادة التشغيل node E:\work\SOFRA\app\design-preview\serve.cjs.

## 18. قرار ملخص التغذية — 12 أكتوبر2026

- العرض الأساسي 5 قيم فقط بالترتيب: السعرات kcal، البروتين، السكريات الكلية، الألياف، الدهون الكلية مرة واحدة. تظل49خانة غذائية محفوظة للمستقبل؛ لا عرض مستقل لأنواع الدهون أو الكربوهيدرات أو الصوديوم في الملخص الأساسي. المجهول لا يصبح صفرًا.
- التنفيذ: const primaryDisplayNutrients في lib/domain/food_nutrition.dart؛ وثّق في FOOD-DATA-ARCHITECTURE وAGENTS وSTATUS. الواجهة تُبنى خارجيًا ولم تتغير؛ حفظ النواة والحسابات لم يتغير.
- سبب القرار: اختيار المستخدم الصريح لتبسيط الملخص مع الاحتفاظ بالتفاصيل الصحية لاحقًا. يحل محل اقتراح عرض10قيم سابقًا.
- التحقق: dart analyze lib/domain/food_nutrition.dart؛ النتيجة تثبت في إيصال الجذر بعد التشغيل. لم تُعد اختبارات البنك/التكامل السابقة لأن التغيير قائمةconstوتوثيق فقط.
- التالي: سيشن الواجهة تستخدم القائمة المختصرة، والمتابعة الاقتصادية تستكمل البنك وفق§17. لا تعديلFirebase أوAPK أوDrive أوأصوات/صور.
- basecommit da8ec10c5572faee0cf05e009ab546c355bf1a85؛ آخرhashنهائي في E:\work\SOFRA\HANDOFF.md وDELIVERY.json بعدpush.
- السيرفر باقٍ127.0.0.1:8766،PID31004،node.exe،المصدرE:\work\SOFRA\app\design-preview\serve.cjs؛ لم يُغلق.

## 19. استئناف الجمع وتوضيح التقدم — 2026-10-12T23:57:05.842916+03:00

- المستخدم طلب المتبقي وسبب الوقفة؛ أوضحنا أن الوكلاء أنهوا دفعاتهم، والمتابعة كل ساعة وليست خدمة متواصلة. الاستخدام63%قصير/52%أسبوعي عند البدء؛ ليس سبب الوقفة. مصدرOFFكان يعيد503.
- استؤنف جمع محدود بثلاثة طلبات بواسطةgpt-6-luna؛ الملفات الفعلية فيdata/food وwork/agent-handoffs/food-bank-growth.md. 3 طلبات ناجحة، أضيف61 منتجًا فأصبح البنك777؛ مصر366/السعودية422/مشترك11،31 أرشيفًا؛ البيانات غير مراجعة.
- تحقق فعلي: اختبارات سلامة البنك5 نجحت لدى وكيل الجمع، تشمل البصمات والهوية والقيم المصدرية؛ لا تغيير للأداة لا إعادة فحوص Flutter الكاملة أو بناء جديد؛ الأداة والواجهة لم يتغيرا.
- المفتوح وترتيب العمل: مراجعة وربط سطور البشاميل ثم بقيةالوصفات، ربط النتائج/الأشخاص بالواجهة الخارجية، scan/OCR، محرك اقتراح ميزانية/توازن، دمجBlender ثمAPKاختبار. اكتمال بنك المنتجات ليس شرطًا لبدء ربط الوصفات؛0ربط مُراجع حاليًا.
- لا تغيير قرار مستخدم، Firebase/قواعد/فوترة/Hosting أوAPK/Drive أوتصميم/صوت/صور. العرض5قيم والحفظ49والخصم بعد تأكيد الطبخ محفوظة.
- التالي بالضبط: يواصل جامعالبنك منcollection-state.json فيالمتابعة؛ يبدأ مسارربطالبشاميل بمقاديرها وحالةالمكونات الصريحة، ولا يعتمد علىمطابقةأسماء تلقائية.
- نسخة واحدة E:\work\SOFRA\app؛ base1a6bac2923b54075e6b56d40ebe17da0bf1bde8e. آخرcommitنهائي في إيصال E:\work\SOFRA\DELIVERY.json وHANDOFF.md بعدpush.
- السيرفر باقٍ127.0.0.1:8766،PID31004،node.exe،المصدرE:\work\SOFRA\app\design-preview\serve.cjs؛ لم يُغلق بهذه الدفعة.

## 20. Immutable recipe revisions and resumed bank

Objective: implement the agreed recipe-family/variant/personal-recipe logic without UI design. Sole checkout E:\work\SOFRA\app; base b22187b5ded813f0f3165c460bdf1313121b0dc0.

Changed: lib/domain/recipe_variants.dart (new immutable book, validation and fingerprint); recipe_catalog.dart full serializers; kitchen_core.dart pinned plan references; recipe_nutrition.dart revision-bound selections and line choices; lib/data/kitchen_service.dart registration/planning/preview/atomic frozen cooking; test/recipe_variants_test.dart11 meaningful tests; docs/RECIPE-VARIANTS.md plus API/architecture/product/status/AGENTS updates. data/food/openfoodfacts/** and work/agent-handoffs/food-bank-growth.md contain25new sourced GTINs and checkpoint/backoff.

Decisions: full snapshots avoid live inheritance; parents stay within family; new revisions affect future plans only; identical retries never roll back active content. Nutrition cannot leak across versions; old unversioned selections stay stored but require re-review. Repeated IDs use independent line choices/measurements, including stock and nutrition. Empty selected recipe is rejected, rollback preserves stock/plan. No automatically authored variants or medical mappings. User decisions on design/audio/images/inventory/finance unchanged.

Review: nutrition_core completed a focused read-only audit, found repeated-ID measurements/optional choices ambiguous. Coordinator implemented line-specific APIs and tested both omission and repeated-row allocation. This was API logic work; no Blender character modelling/animation was performed.

Checks actually run: flutter test --reporter expanded61passed (after fixing an initially incorrect empty-recipe test assumption); flutter analyze no issues; food collector reports node --test tool/food/import.test.mjs5passed including all shipped hashes/source values. After the final unknown-unit guard,11recipe tests passed and focused Dart analysis passed; confirmation rejects unsupported actual measurement units with rollback rather than silently reusing a stored reviewed weight. Full54recipe JSON roundtrips and216existing scaling parity cases included. Git diff --check and clean HEAD=origin/main verified at final receipt. No web/APK rebuild or device test this delivery; no Hosting/Drive/Firebase/Auth/rules/billing changes.

Bank:802products, EG391/SA422/shared11,32archives,84quarantine,122duplicates,587nutrition,529core macros,667brands; all802bases unreviewed. Egypt condiments succeeded; Saudi flour/pulses503 persisted with backoff. Source licenses/provenance intact. All49nutrients retained; approved primary5 unchanged.

Disk: E reached0free during writing recipe_nutrition.dart; restored file from GitHEAD then reapplied own changes, followed by full tests/analyze. Removed only own regenerable build output. Ignored build and .dart_tool now junction to C:\Users\atgs0\Documents\Codex\2026-10-09\cooking-app-flutter\work\sofra-generated-cache; source remains solelyE. User freed space; latest E free roughly47GiB. Inspect junction target before future cleanup.

Open:0verified bindings across605recipe lines; labels/basis require review; real recipe variants not populated. UI must use recipeForMeal and exact revision bindings.850KBguard remains, archival/scan/budget optimizer/medical targets/external Blender work incomplete. Exact next action: source-review bechamel lines/forms/units, bind a pinned revision, then external UI integration; collector resumes due checkpoint jobs within quota/backoff policy.

Final commit hash: recorded after push in E:\work\SOFRA\HANDOFF.md and DELIVERY.json (avoids self-referential hash). Server remains127.0.0.1:8766 PID31004 node.exe, source E:\work\SOFRA\app\design-preview\serve.cjs; restart `node E:\work\SOFRA\app\design-preview\serve.cjs`.

## 21. Hourly food-bank batch — 13 October2026 Riyadh

- Sole checkout E:\work\SOFRA\app, base f65ace68289fd4454eae2f676f17d0e0946a09ce. Quota checked before collection86%5h/55%weekly, ordinary allowed; after useful growth88%/56%. One gpt-6-luna medium agent with independent short context; one3request batch. No further costly batch this turn to leave delivery capacity before90%reserve boundary; next heartbeat rechecks quota. No credit purchase/reset.
- Successful requests: Saudi condiments p1, Egypt beverages p1, Saudi beverages p2,100source occurrences each;0new failures, existing failures/backoff retained. Bank802→1035 (+233), EG391→453 (+62),SA422→593 (+171),shared11;32→35archives. Condiments59→140,beverages124→278,dairy171→183; groups overlap.
- Quality:106quarantine,167duplicate occurrences,757with nutrients,685core macros,484ingredients,844brands,244declared allergens; all1035bases unreviewed/unknown. Licenses/source dates/raw responses/hash manifests preserved.0reviewed recipe bindings and49stored/5primary nutrients unchanged.
- Files: data/food/openfoodfacts/**; work/agent-handoffs/bank-heartbeat-0133.md and .status.md; docs/STATUS/HANDOFF/PRODUCT-DATA/FOOD-DATA-ARCHITECTURE/FOOD-BANK-CONTINUITY. No tool/source/UI/Firebase/audio/image changes. No APK,Hosting,Drive or device test.
- Actual checks: agent ran4generic Node tests; coordinator noticed SOFRA_FOOD_BANK missing, reran with E:/work/SOFRA/app/data/food/openfoodfacts:5passed including shipped bank archive/hash/source equality,0skipped. Continuity guide now mandates that environment variable. No Flutter rerun because source unchanged; previous61/11/analyze evidence remains historical. git diff --check and final clean/push equality recorded in external receipt.
- Exact next action: resume checkpoint Saudi frozen page1 after fresh quota/lock/backoff check. No completion claim; market/label quality and cooking-category gaps remain.
- Final commit: E:\work\SOFRA\HANDOFF.md and DELIVERY.json after push. Server retained127.0.0.1:8766 PID31004,node.exe,E:\work\SOFRA\app\design-preview\serve.cjs; restart node E:\work\SOFRA\app\design-preview\serve.cjs. User decisions unchanged; no Firebase/billing modifications.


## 22. Reviewed recipe reference integration and continued bank —13October2026

Objective: continue actual backend research/implementation economically, without UI design. Sole checkout E:\work\SOFRA\app; base27b2a6b50f30691a4e0148a90139b210c982879f. Main remains the user-authorized delivery branch; inactive C app unchanged. C staging/scripts/generated cache only. Plan/ledger docs/superpowers/plans/2026-10-13-recipe-reference-integration.md.

Changes: new lib/data/recipe_reference_repository.dart (typed identity proposals, exact full snapshot checks, explicit generic acceptance/food choices, blocked compounds, source description/version checks); lib/data/kitchen_service.dart (atomic apply, preserve user choices, no publication on save failure/changed plan, distinct input estimate); lib/domain/recipe_nutrition.dart (reference acceptance provenance and IngredientNutritionEstimate wrapper); pubspec.yaml (nutrition asset). New data/nutrition/recipe-reference-review.json has197 entries/53recipes/36USDAreferences,153single recommendations/44choices, all10bechamel lines. It contains0 confirmed full nutrition bindings; no actual user defaults were installed. References maintain CC0 separately from OFF ODbL/DbCL.

New tool/nutrition/validate-reference-review.mjs and reference-review.test.mjs check canonical-LF whole recipe/index hashes, exact line ID/name/quantity/unit/optional state, source USDA ID/version/name/100g edible basis, candidate form and compound blocking. stamp_reference_review.dart calls the read-only guard before writing runtime fingerprints. The initial validation exposed raw-CRLF versus canonical-LF index hashes; verified both hashes and aligned the implementation with the curator's canonical-LF evidence without changing USDA bytes. New test/recipe_reference_integration_test.dart9 meaningful scenarios include all197 snapshots, actual bechamel choices/gaps, stale data/duplicates, explicit acceptance, blocked compounds, rollback/preservation/reload, changed plan and mutable choices.

Decisions/reasons: ingredient-input composition is useful without pretending it is cooked food. Wrapper has whole/perPortion/gaps and explicit basis/estimated flag, no MealBatch/cooked-per100g export; quantity form preserved. Prepared preview/cooking retain unknown retention/conversions; no universal factor1 or guess of medium-onion/cup/spoon mass. No automatic intake or stock changes from preview. The compound salt+pepper row remains blocked: components are not alternatives. Butter/ghee allocation, actual milk/meat/pasta/cheese type, Roumy identity and household measures require explicit evidence. Existing bindings survive unless replacement explicitly requested; accepted source review identity/evidence persists per exact revision/line. Legacy unpinned plans must be saved/pinned before application. Full snapshot matching prevents propagation into edited variants.

Independent read-only reviewer reference_integration_review found P1blind restamping and P2mutable choices across await. Both fixed with source gate and copying choices at service/repository entry. Regression reproduced choice mutation failure then passed; stale hash/quantity/source/compound negative tests pass. No other actionable atomicity/history/form issues reported. Reviewer did not run tests; coordinator ran gates. using-superpowers/writing-plans/executing-plans/TDD/verification/review workflows applied; existing approved architecture and explicit continue authorize inline work, and user one-checkout rule takes precedence over creating a worktree.

Actual final checks: full flutter test --reporter expanded --no-pub71passed on final formatted source; flutter analyze --no-pub no issues after fixing10style findings; combined Node8passed/0skipped with SOFRA_FOOD_BANK set (actual bank5 plus review guard3); guarded dart run tool/nutrition/stamp_reference_review.dart197stamped. All54recipes and216scaling parity cases remain covered in full suite. New feature missing-method/adapter tests were run red first, then green. git diff --check and final clean/remote equality recorded in external receipt after commit. No web/APK build, native device/Drive/Hosting test or Firebase/Auth/rules/billing change.

Bank:1035→1344 (+309), EG453→624 (+171),SA593→731 (+138),shared11;35→43source archives,184quarantine,248duplicate occurrences,981nutrition,887core macros,551ingredient text,1036brands,273declared allergen tags; all1344bases unknown/unreviewed. One gpt-6-luna medium collector continued short sequential batches while jobs due and quota allowed. Cumulative24requests,8success/16HTTP503failures with backoff retained. Source success occurrences: EGglobalp3/p4/p5 each100, SAchocolatep1=51, EGoilsp1=7, SAcondimentsp2=9, EGbabyp1=1, SAbeveragesp3=100. No due jobs at last release01:37:46Z; next retry SAsweetsp1 01:43:39.331Z; source backoff, not a completed bank. Prior bounded stop was revoked while useful work remained; collection then continued until all jobs unavailable. Quota naturally reset before session0%/57%; latest checked26%/61%, ordinary allowed. No credit purchase/reset. data/food/openfoodfacts/** + collector handoff/status changed; research curator handoff/status records source evidence; never read large bank records into a model for calculation.

Open:408catalogue lines without proposals; generic identity review is not measured quantity/product/clinical verification. Bechamel full values remain unknown until identities, compound quantities, edible weights and preparation evidence resolved. Future external UI adoption, label basis review/scan, selective product delivery/sharding,850KBhistory archival, budget optimizer/medical evidence and Blender remain incomplete. Exact next action: review actual bechamel input weights/conversions, split seasoning into a new full revision and bind explicitly, source method-specific preparation evidence; collector resumes due persisted jobs under quota/backoff policy. All user decisions unchanged (primary5/storage49, finance, stock only confirmed cooking, cancelled sounds/no music/no images, approved kitchen/fridge/characters).

Final commit hash: E:\work\SOFRA\HANDOFF.md and DELIVERY.json after push, avoiding self-reference in tracked docs. No unfinished branch planned. Server remains127.0.0.1:8766 PID31004 node.exe, command/source E:\work\SOFRA\app\design-preview\serve.cjs, inspected this delivery; restart `node E:\work\SOFRA\app\design-preview\serve.cjs`.


## 23. Hourly bank continuation —2026-10-13T01:44Z

- Sole checkout E:\work\SOFRA\app; base dc5973b271bc6bee1046ce511a70355690de1479; main reference. Quota31%5h/61%weekly ordinary allowed before dispatch. One independent short-context gpt-6-luna medium collector; only OFF data and its dedicated handoff/status owned by collector, shared docs by coordinator.
- Actual source outcomes: 6requests, 3success/3failures. Saudi snacks p1=58, dairy p2=100 and flour p1=14 source occurrences succeeded; sweets p1, pulses p1 and dairy p3 returned HTTP503. No jobs due at release; lock absent; quota32%5h/62%weekly ordinary allowed. Shared market count remains11. Requests respect lock, persisted backoff and pagination; no fabricated empty categories, values or market claims. No arbitrary bank-complete threshold.
- Bank1344→1483 (+139); EG624/SA870/shared11;43→46archives. Quality:189quarantine,276duplicates,1084nutrition,983core,627ingredients,1144brands,324declared allergens; all1483bases remain unknown/unreviewed. Source licenses/date/URLs/archive hashes preserved; manifest authoritative.
- Files:data/food/openfoodfacts/**, work/agent-handoffs/bank-heartbeat-0444.md/.status.md, shared STATUS/HANDOFF and relevant product/architecture counts. No application code or recipe review artifact changed.197identity proposals and0fully verified nutrition bindings unchanged. No UI/audio/images/Firebase/Auth/rules/billing/APK/Hosting/Drive/device changes; all user decisions preserved.
- Checks actually run: Node5passed with SOFRA_FOOD_BANK including shipped archive/hash/source equality. Historicaldc5973b gates71Flutter/analyze clean/3review-source tests are not rerun for bank-only changes. git diff --check and clean HEAD=origin/main/live GitHub verification recorded in external receipt after push.
- Next exact continuation: 2026-10-13T01:52:17.253Z / saudi-arabia/beverages / 4. Recheck quota/lock and due cursor jobs; do not repeat during backoff. Collector handoff contains full bounded batch log; no requests left running at release.
- Final commit hash:E:\work\SOFRA\HANDOFF.md and DELIVERY.json after push. Server remains127.0.0.1:8766 PID31004 node.exe E:\work\SOFRA\app\design-preview\serve.cjs, retained; final receipt records process check; restart node E:\work\SOFRA\app\design-preview\serve.cjs.
