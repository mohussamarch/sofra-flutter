
## C2C-015 — Complete available-options bundle, 29 October
Start here: E:\work\SOFRA\deliveries\KITCHEN-FULL-20261029\START-HERE.md
ZIP: E:\work\SOFRA\deliveries\KITCHEN-FULL-20261029.zip
ZIP bytes: 86910706; SHA256: 839ADBF28DF9D787333529C142F1B35E5323499B0F8B468236594AEB8EFE23B3
Includes detailed base+alternatives, all runtime modules/vendor, three bounce/probe pairs, latest45degree camera, lighter BASE-only candidate, manifest and geometry audit. Run node server.mjs from bundle; http://127.0.0.1:8879/ . No prior folders needed for default review. All existing options included, not a claim that future table/curtain variants exist. Direct-sun/LED baked-only export and edge quality remain unresolved. Fresh browser smoke/geometry/syntax checks pass; temporary stalls occurred, no phone performance approval. Local only, no publish. Read CL2C-005; request receipt referencing MANIFEST.json. Preview PID45820.

## C2C-014 — 29 October: corrected dining camera; supersedes CL2C-004 camera
Exact new settings: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-camera.json
Executable reference: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-review.mjs
Position [4.35,1.4,0.75], target [0,0.9,-3.6], vertical FOV50, 1800ms smoothstep from Home. Horizontal azimuth45deg: camera/table near corner/rear wall corner share z=x-3.6. Replace the OLD32.6deg orbit and target. Coordinates use glTF Y-up metres.
Show enclosure_ceiling surface at dining arrival; hide surface when leaving for Home/closeup/outside/fridge, retaining shadow occlusion. If your loader removes enclosure meshes, retain the ceiling and clone its material for this mode. No GLB modified for this camera correction.
Fresh browser review: portrait dining transition and cards visible, Home hides cards/ceiling; node --check passes. Framing remains pending owner approval; ceiling highlight quality still needs lighting review. Local only; no commit/push. Preview8878 restarted PID45980, server.mjs in the same realtime-r24 folder. CL2C-005 read: Claude confirmed R25 loaded in app; no receipt of C2C-014 assumed. Direct-sun/LED bake, trim seams and S24 testing remain open.

# Codex → Claude Code — current R24c — 28 October 2026

## NEW FILE — R25 mobile candidate
Read E:\work\SOFRA\app\docs\design\R25-MOBILE-HANDOFF.md first. Actual new GLB: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\mobile-r25\kitchen-mobile.glb . 7.16MB/147,669triangles, Draco, all3clips; local test candidate, not final visual approval. This supersedes the earlier 'no new GLB' statement for R24c only. Lighting/edge/options limits remain documented.


## ابدأ هنا — الملفات الحالية R24c — 28 أكتوبر 2026

**الجديد كود معاينة، وليس GLB جديدًا.** نسخ review-detail.glb وحده لن ينقل الشمس أو الظلال أو مصابيح التلاجة أو حركة السفرة أو جدولة الرسم.

| المطلوب | الملف الفعلي | طريقة الاستفادة |
|---|---|---|
| الإضاءة الهجينة، مزج lightmaps، معامل PI، نور الحجرات، الرسم عند الطلب | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\viewer.mjs` | مرجع تنفيذ Three؛ ينقل Claude المنطق المتوافق إلى عارضه، وليس أصلًا يحمّله model-viewer تلقائيًا. |
| حركة السفرة والكروت | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-review.mjs` | الكاميرا في destination؛ 1800ms smoothstep من Home. كروت DOM توضيحية؛ كروت التطبيق يملكها Claude. |
| فلتر الظلال | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\soft-shadow-filter.mjs` | تعديل ShaderChunk لإصدار Three المحلي؛ ليس ميزة مضمنة داخل GLB. لا تنقله إلى model-viewer دون توافق صريح. |
| الموديل ذو الخامات التفصيلية — قديم من R24، لم يتغير في R24c | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\review-detail.glb` | 25,079,892bytes؛ UV0 للخامة وUV1 للإضاءة. تجربة ثقيلة وليست نسخة الموبايل المطلوبة. |
| اختيارات الموديل | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\r23-options.glb` | ملف إضافي مستقل؛ ليس كل البدائل داخل review-detail.glb. |
| خرائط الإضاءة والانعكاس | `E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\bounce-{morning,golden,night}.hdr` و`probe-{morning,golden,night}.hdr` | ملفات منفصلة يربطها العارض. الـbounce إضاءة غير مباشرة فقط، وليس شمسًا وظلالًا مباشرة مكتملة. |
| وصف الكاميرا والأداء | `E:\work\SOFRA\app\docs\design\R24C-DINING-AND-PERFORMANCE.md` | الإحداثيات، الاختبارات الفعلية والقيود. |
| فهرس تحقق كامل | `E:\work\SOFRA\app\docs\design\R24-CURRENT-FILES.json` | المسارات المطلقة والأحجام وSHA256؛ قارنه بما نُسخ إلى التطبيق. |

المعاينة: http://127.0.0.1:8878/?review=r24c . المصدر المحلي كاملًا في المجلد أعلاه، لكن نقل HTML/DOM إلى Flutter ليس نسخًا مباشرًا.

**إيصال فعلي:** قرأ Codex رد CL2C-004 الذي يؤكد استلام Claude لتحديثات R24b/R24c ونقل كاميرا السفرة. لا حاجة لإعادة تنفيذ الكاميرا. لم يفحص Codex دمج التطبيق في هذه الجولة. طلب الموبايل CL2C-003، وحل الإضاءة المباشرة لـmodel-viewer، ما زالا مفتوحين. لا يوجد ملف موبايل جديد جاهز أُخفي مساره.

---

## Historical checkpoint — R24b
User requested this handoff first, then continued visual work. Codex still owns and is editing the R24 review viewer; do not concurrently edit design-assets. The GLBs, HDRs and three Blender masters are unchanged from R24. You can inspect the assets and continue your own Flutter adapter against the node/UV contracts below; do not treat this as final visual approval or permission to publish.

- `viewer.mjs`: all baked materials now share the current secondary-lightmap/mix/enabled uniforms. Previously `onBeforeCompile` initialized new shaders to morning/mix0, which could reset a material's lighting when its shader was rebuilt. Browser checks so far cover morning,16:12 blend,golden,dynamic→hybrid and night with no reported JS errors; final double-door open/close and compartment-light regression passed; see r24b-browser-qa.json.
- `soft-shadow-filter.mjs`: experimental deterministic32-tap disk PCF, sun radius6texels, window/ceiling7. Compare `?shadowFilter=grid` for the original17-tap grid/radii4/4/5. This is filtering, not PCSS or true area-light transport; subtle visual change, not Cycles parity. Phone cost not measured.
- Legacy Spark/PLY training is no longer loaded on the default hybrid route. Historical mode requires `?legacySplats=on`; stale training has not been refreshed. Do not include that path in the production viewer.
- Zero-intensity review lights are hidden, restored when active. Morning reports2active lights. No draw-count or FPS improvement has been demonstrated; do not claim a speedup. Cold shader compilation contaminates the current CPU average.
- Close-up normal-off comparison did not remove dark cabinet edges. Bounce-off removes the room's indirect fill; the remaining seam cause is not conclusively isolated. Do not delete normal maps or increase exposure as a blanket fix.
- Resolved the earlier browser timeout: double-fridge open angles75/90 degrees, both compartment lights4; closed angles0/0, both lights0. Current browser QA has6 snapshots and no reported JS errors.

- Radiometric correction: Cycles diffuse bake is outgoing white-Lambert radiance; Three lightMap is irradiance, followed by BRDF_Lambert=1/PI. Isolated Blender calibration produced exactly1 for unit-white world; correct lightMapIntensity is PI. Implemented in viewer; ?bounceUnits=legacy restores1 for comparison. Do not multiply the HDR asset again. Source/HDR files unchanged. Morning/night/golden browser checks pass without JS errors; screenshots show improved fill but dark trim/seams and mobile optimization remain unresolved.

Next Codex action: isolate remaining trim/seam sampling versus geometry and evaluate disk filter cost on a real phone. No source rebake launched. Local only, no commit/push, no external upload.

Read docs/STATUS.md and docs/OWNERSHIP.md first. Sole checkout E:/work/SOFRA/app. This handoff supersedes R23 asset pointers; local review, approved=false, no commit/push authorized. Codex has not modified your lib/test/pubspec/tool/SCENE-CONTRACT files. Coordination reply C2C-009 acknowledges CL2C-002; no receipt from you assumed.

## Actual output
Root: design-assets/blender/current/realtime-r24. Exactly three existing Blender masters were edited in place, no blend1 or fourth master. Source edits are recorded by source-fixes.json,microwave-fix.json,style-carcasses.json; final source SHA256 in verification.json and export-report.json. Render/bake jobs finish before delivery; do not restart old build.py.

Local preview: http://127.0.0.1:8878/?options=r23&sourceConstants=on&detail=on
Short entry http://127.0.0.1:8878/ now defaults to those same review settings;explicit query is retained for reproducibility.
Server command: node design-assets/blender/current/realtime-r24/server.mjs . Port8878, original process42680 at startup; inspect live owner before stopping/replacing. Port8877 remains historicalR23. The query name options=r23 is retained for the local control module, not an asset revision claim.

Review assets (heavy, not APK production):
- review.glb:26,220,908bytes,baseline mesh and original shared-atlas comparison.
- review-detail.glb:25,079,892bytes,six separate1024 material pages,UV0 material/UV1 global lighting.
- r23-options.glb:12,284,132bytes,supplemental appliances,rugs,styles,blinds,plants,cane. Each part carries option_group/cabinet_style.
- bounce-{morning,golden,night}.hdr,probe-{morning,golden,night}.hdr,reference-{morning,golden,night}.png.
- material-pages.json proves UV1 identical to the global bake. Retain TEXCOORD_1; do not clone UV0 over it. Base color sRGB; normal/roughness Non-Color. Data/color pages saved by Blender as8bit with Raw/Standard transforms respectively.

## Geometry fixes
Freezer bevel matches fridge10.2mm; four physical cream hinge pins with fixed/rotating leaves;6range knobs face forward; inset oven glass within four-sided aperture; cylindrical handle mounts and metal bottom strip. Classic frames/insets shallow, one main slab. Japandi handles have connected stems/rosettes; oak grain enhanced; optional real woven cane on upper fronts. Bodies/shelves now have modern/Japandi material variants too. Microwave hollow with independent hinge/door. These are model edits, not screenshot paint.

Visibility must combine selections: cabinet_style AND option_group. In particular a built-in cabinet body must be both selected style and builtin range. Cane requires Japandi plus cane toggle. This avoids revealing all builtin/style bodies on top of each other.

## Door state and lighting
The two original top sliders in R23 always changed the cream hinges even when the double fridge was selected; R24 routes them to the selected device. Node IDs:
- Cream fridge:r18_fridge_hinge;cream freezer:r18_freezer_hinge. Runtime rotationY negative.
- Double freezer(left):r19_double_left_hinge,negativeY;double fridge(right):r19_double_right_hinge,positiveY.
- Microwave:r24_microwave_hinge;microwave_open animation exists in both baseline/detail GLBs. Source30frames,close by reverse playback or a single transform owner. Do not simultaneously run animation and manually overwrite the same rotation.

Runtime lights in local preview: r24_{default,double}_{fridge,freezer}_interior_light. Spotlights follow selected model and independent hinge angle;off atclosed,ramp~2–20degrees. Prototype intensity4,near.01m,512shadowmaps:these are preview values,not device-tested production settings. Anchors:r18_fridge_inner_light_strip and .001; r19_fridge_light_diffuser;r19_freezer_light_diffuser. Lights are created in viewer.mjs,not KHR_lights inside GLB.

Close frontal review found horizontal self-shadow acne on double-fridge liner. Changing only interior-light shadow.bias from0 to-.001 removed stripes in the same view. Window/ceiling bias now-.00015;sun retains-.0001. These normalized values depend on shadow-camera ranges,not universal constants. Test depth bias on device with actual units/maps and retain wall occlusion;do not fix acne by removing the enclosure or disabling shadows globally.

## CL2C-002 interior background delivery
interiors/interiors-review.json lists6actual768×1024RGBA PNGs:cream/double × morning/golden/night. No shelves or open doors baked;fixed compartment divider retained;inside lights on. Exact requested target/orbit40degree camera configured. Normalized interiorBounds use top-left origin and include left/right/top/bottom;SHA256 per file. They are review backgrounds,not registered assets/manifest entries. Validate layout against ShelfWheel before integration. All6images passed hash,RGBA corner transparency and normalized-bound checks.

No dedicated LED above the table exists. Under-cabinet LEDs are not table lights;ceiling_fixture_disk is the general ceiling fixture. Keep the current table UI glow until a specific table fixture is agreed. Ingredient-art proposal only in C2C-009;no mass illustration run occurred.

## Lighting fidelity finding
R23 golden sun was a hardcoded10.7 with arbitrary orbital direction;source is23.04 with different orientation/color. R24 reads sun power,color and matrix basis from export-report.json for day/golden and blends anchors. Atmorning source15.36/color[1,.78,.48];golden23.04/[1,.48,.12]. Window area fill is still approximated by a spotlight;runtime is not identical to Cycles GI. Hybrid ambient remains0 and window shadow near=.02. These are separately verified from final aesthetic acceptance.

## Verification and limits
verification.json:R24_GEOMETRY_AND_PACKAGE_PASS across3sources;center oven ray hitsglass,6knob normals forward,freezer bevel matched,4hinge pins,microwave hollow/separate,6interior images valid. Source/bake UV hashes match. Browser proof/remaining status in R24-REVIEW-FIXES.md.

No phone test,no final performance acceptance,no production texture budget pass. Full loaded review scene420036triangles;draw counts depend on current options and shadow passes. Material/lighting quality still needs art review and performance work. Existing3DGS is older than sources and remains outside the primary path. Do not ship these heavy atlases/meshes as finished assets.


## Codex R24c — 28 October 2026
Local review: http://127.0.0.1:8878/?review=r24c . Added Home-to-dining-corner1800ms camera and horizontally scrollable2D glass cards (illustrative content), plus portrait-size review. Camera parameters and implementation: docs/design/R24C-DINING-AND-PERFORMANCE.md.
Rendering now sleeps when idle/hidden; camera-only moves reuse shadows. Verified baseline3frames/1shadow update; closeup5/1; door-open7/2; dining11/4. Scrolling to the next card kept11/4, so no additional Three renders. These are operation counts, NOT FPS/GPU/mobile results. Half-resolution glass buffer has quarter pixel area; full comparison via glassQuality=full.
CL2C-003 acknowledged: mobile export under8MB/~150ktris and baked-only model-viewer compatibility remain OPEN. Heavy R24 review is not approved for APK. Edge seams/trim still unresolved. No Blender masters/GLB/HDR edits, no Claude code edits, no commit/push. Next: owner framing review, atlas-edge isolation and mobile export. Preview node PID42680 remains local on8878; requires running machine.




