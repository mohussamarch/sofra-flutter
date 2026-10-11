# الحالة المختصرة — سُفرة

آخر تحديث: 11 أكتوبر 2026.

- المرحلة: المستخدم أذن بالتنفيذ؛ الدفعة الحالية الحساب والحفظ وAPK.
- الجهاز الفعلي: Samsung Galaxy S24 Ultra؛ الأولوية لنسخة Android APK.
- الموجود: نموذج Flutter عربي، إعداد أولي، مخزون، وصفات، تخطيط وطبخ.
- أضيفت واجهة دخول بالبريد، حفظ محلي/سحابي، كشف تعارض النسخ، وإعادة محاولة الحفظ.
- المشاهد الإيزوميتريك الجديدة خارج هذه الدفعة ولم تُنفذ.
- آخر تحقق برمجي سابق: التحليل و7 اختبارات وبناء ويب ناجحة؛ اختبار iOS على GitHub ناجح.
- آخر تحقق جديد: التحليل و10 اختبارات وبناء الويب وAndroid واختبار قواعد Firestore نجحت في CI 38113824888.
- Firebase: sofra-c03a1 أنشأه المستخدم؛ اتصال CLI متاح، وسُجل Android والويب.
- أُنشئت قاعدة Standard بمنطقة europe-west3، ونتيجة API تؤكد freeTier=true.
- Authentication يحتاج Get started من المستخدم بسبب تعطل لوحة Firebase في المتصفح المدمج.
- إعدادات التطبيقين محفوظة في config/firebase.android.json وconfig/firebase.web.json.
- المنجز الآن: قواعد AGENTS وملفا STATUS وHANDOFF للتسليم وتقليل القراءة المتكررة.
- قواعد Firestore نُشرت. APK مبني من f6d5785، ولم يُختبر على جوال المستخدم بعد.
- نسخ APK تُرفع إلى Google Drive داخل WORK/Sofra، باسم يتضمن الإصدار والتاريخ ومعرف الكود.
- مجلد النسخ: https://drive.google.com/drive/folders/1qRAV-M2I1LTXW2zo1tRghAbqfL3o84CH
- النسخة الحالية: v0.1.0+1، ARM64، حوالي 20 MB؛ تفاصيل التنزيل في HANDOFF §6.
- التالي: Get started في Authentication، ثم auth-enable واختبار live-smoke.mjs؛ لا تدّع نجاح الحسابات الفعلية قبله.
- Firebase Spark رفض استضافة APK؛ التنزيل عبر Drive. نُشرت معاينة الويب: https://sofra-c03a1.web.app
- التفاصيل: راجع العناوين المناسبة في HANDOFF.md فقط.
- خطة المنتج: ../../sofra-product-design-plan.md
- خطة التنفيذ: ../../sofra-execution-plan.md
