# تقسيم ملكية الشغل — 24 أكتوبر 2026

## User authorization — 31 October 2026

The user explicitly authorized Codex to implement Flutter, tests and APK builds as well as visual work. This supersedes the visual-only Codex prohibition below for the current delivery. Work only in E:/work/SOFRA/app; preserve existing changes and the single KitchenService state writer. Do not run a concurrent runtime writer.

| | Codex (إنت) | Claude |
|---|---|---|
| الدور | كل الفيجوال: Blender، الرندرات، الطبقات والماسكات، تصميم الشاشات (شكل، ألوان، خطوط، مكونات بصرية)، الحركة كتصميم | كل الكود: Flutter، ربط الواجهات بـ`KitchenService`، عارض المشهد التفاعلي، الحركة كتنفيذ، الاختبارات، الـAPK |
| الفولدرات اللي بتكتب فيها | `design-assets/**`، `assets/scenes/**` (الصور والـmanifest بس)، `docs/design/**` | `lib/**`، `test/**`، `integration_test/**`، `pubspec.yaml`، `tool/**`، `docs/SCENE-CONTRACT.md`، `docs/dev/**` |
| ممنوع تلمسه | `lib/`، `test/`، `pubspec.yaml`، أي كود Dart | `design-assets/`، ملفات `.blend`، سكربتات Blender |

- Claude يكتب عقد المشهد `docs/SCENE-CONTRACT.md`. Codex يملأ الصور والـmanifest وفق العقد، ويطلب تغييره في `docs/design/CONTRACT-REQUESTS.md` فقط.
- بيانات spike-r14 مؤقتة للاختبار، ولا تنشئ عقد المشهد النهائي قبل أن يكتبه Claude.
- GitHub main هو المرجع. كل طرف يسحب قبل البدء ويحفظ ويرفع شغله قبل انتقال الملكية، ولا يكتب فوق تغييرات الطرف الآخر غير المرفوعة.
- متابعة Codex في `docs/handoff/codex.md`، ومتابعة Claude في `docs/handoff/claude.md`. STATUS ملخص مشترك أقل من 40 سطر، ويعدل كل طرف سطوره فقط.
- ملفات Blender والرندرات الخام تبقى محلية على E. لا رفع أو نسخ احتياطي خارجي دون إذن المستخدم. الحزمة التقنية النهائية الخفيفة هي استثناء مصرح به في assets/scenes.
- الأسئلة في بوكسات اختيار. لا Firebase أو فوترة أو مشروع آخر ضمن هذا التسليم.
