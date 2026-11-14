# Native discovery implementation plan — 31 October 2026

Goal: deliver the first real Flutter slice of PRODUCT-JOURNEYS-AND-EASY-INPUT-20261031.md, using existing persisted state and cooking confirmation.
User explicitly authorized Codex to own Flutter, tests and APK on this turn, superseding the earlier visual-only restriction. Execute inline in E:/work/SOFRA/app; no parallel runtime writer, branch, commit or push.

1. Add failing navigation tests: four primary destinations, repeated selection stays put, 3D only on explicit entry, from-stock entry and Android back.
2. Add failing stock-preview tests: insufficient amount, duplicate ingredient allocation, units, unknown quantities/yield, optional-only recipes and personal yield.
3. Add native home and direct recipes/stock/plan pages using SofraController/KitchenService only. Keep monthly plan and shopping visible. Preserve account/community/style access.
4. Replace name-only filter with a quantity-aware summary and truthful labels. Invalidate cached previews when inventory/rules/yield/servings change. Preserve all-recipes exploration.
5. Add direct-cooking action through the existing planned-meal lifecycle and explicit consumption confirmation. Disable repeat submission while starting.
6. Update existing navigation test helpers for the intentional four-tab contract. Run focused tests, full Flutter tests, analyzer and Android build attempt; report actual outcome, never historical passing counts.

Receipt OCR, inbound sharing and protein-constrained planning are separate implementation slices, not represented as shipped by this change. Existing budget planning remains accessible. Do not change Firebase or invent food data.

## Verification — 31 October 2026

- Implemented all six scoped steps in the real Flutter application, not the HTML prototype.
- Focused navigation, persistence, stock discovery, demo and monthly planning tests: 22 passed.
- Fresh full Flutter suite: 459 passed, zero failures (sofra-native-final-all-tests.log).
- Fresh flutter analyze: no issues (sofra-native-final-analyze.log).
- Fixed the red regression for unstable cache identity using structural inventory/unit-rule hashes.
- Android tools exist at C:/Users/atgs0/Android/sdk and C:/Users/atgs0/Android/jdk/jdk-17.0.20.1+1 but were absent from process environment; local build succeeded with process-only ANDROID_HOME/JAVA_HOME and regenerated platform tooling. See E:/tmp/sofra-native-regenerated-apk.log.
- Delivery APK: build/app/outputs/flutter-apk/sofra-native-20261031.apk, 92,870,515 bytes; SHA256 E137854CBE0EB1E620206E7966E886352C953DC3E8A1485AAF48B088E526AC4F. apksigner verify exit0; aapt confirms com.mohussamarch.sofra v0.1.0(1). Existing debug signing remains test-only.
- No commit, push, Firebase changes, real-device test or visual approval.

## Review and device acceptance

Read-only independent code review found no blocking issues. Known limitations: from-stock candidates with only unresolved/unmeasured stock matches are currently omitted rather than shown as uncertain; direct-cooking records currently use the lunch slot. Neither limitation changes the conservative readiness rule or bypasses consumption confirmation.

Android release initially failed because an old GeneratedPluginRegistrant.java still referenced the dev-only integration_test plugin, which release Gradle correctly excluded. Regenerating platform tooling by building without --no-pub removed that stale reference; do not hand-edit generated Java or add test plugins as production dependencies.

Manual phone acceptance remains required:
1. Open today, add actual stock, then discover from stock for the household serving count.
2. Change an amount/unit and confirm suggestions and readiness refresh.
3. Search all recipes, enter a recipe, press Android back and confirm the query survives.
4. Cook now, leave/resume via today, and verify inventory changes only after explicit confirmation.
5. Open monthly planning/shopping and the optional 3D kitchen from stock; check Android back, RTL, enlarged text and responsiveness on the S24.

Local build environment (PowerShell, process only):
```powershell
$env:ANDROID_HOME = 'C:/Users/atgs0/Android/sdk'
$env:JAVA_HOME = 'C:/Users/atgs0/Android/jdk/jdk-17.0.20.1+1'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
& 'C:/Users/atgs0/Documents/Codex/2026-10-09/cooking-app-flutter/work/flutter_sdk/bin/flutter.bat' --no-version-check build apk --release --target-platform android-arm64 --dart-define-from-file=config/firebase.android.json
```
