# R24 — 27 October 2026

User-authorized implementation after the review collection pause. Earlier00:30 restart was not actually scheduled; do not claim it ran. Sources: exactly kitchen-morning/golden/night.blend in design-assets/blender/current. Local review only; no commit/push. Codex visuals only.

Acceptance targets:
- Match freezer bevel to fridge; visible physical fixed/rotating hinge hardware on both cream doors.
- Range knobs face forward, with indicator marks; oven handle mounts connect; window recessed into a real aperture; bottom strip is shared appliance metal.
- Classic fronts use one slab with shallow frame/inset instead of stacked thick panels.
- Japandi handles have actual stems/rosettes; oak grain clearer; optional cane example.
- Cream and double fridge controls open/close their actual selected doors; interior lights follow independent door states, including night.
- Read CL2C-002: empty,lit frontal fridge RGBA with requested camera metadata; microwave has separate door pivot/clip; identify table light honestly. Ingredient illustration proposal only, no mass production.
- Re-export changed geometry/material maps together. Old R23 UVs cannot be reused after topology changes. Compare runtime with same source camera and Cycles reference; production quality/mobile gates remain open until demonstrated.

Workflow: read-only geometry diagnosis → update three masters once → geometry checks → new R24 exports/bakes → runtime interaction tests and visual comparison → update Codex handoff/STATUS/Claude handoff/receipt. No old build.py requiring deleted sources.

## Implemented and checked
- Three masters updated,geometry-only stage left room/wall/floor geometry unchanged. Source pipeline then corrected microwave rail local transforms and built its cavity;added18shared cabinet bodies/shelves ×2style variants. Exactly3masters,0blend1. No further source writes during baking.
- verification.json:R24_GEOMETRY_AND_PACKAGE_PASS. Sixforward knobs;matched10.2mmfridge/freezer bevel;4physical hinge pins;oven center ray hits glass in real frame opening;bottom strip metal;microwave cavity and parent hinge;6RGBAinterior backgrounds/bounds/hash checks.
- New base GLB,matching three indirect maps and probes,three Cycles reference renders. Samehome camera position/target/42degree FOV as local runtime. Reference-only camera portal avoids showing exterior trees above cutaway walls;this is a presentation mask,not removal of the light-blocking enclosure.
- Material-page experiment:6procedural materials repacked separately onUV0,1024maps8bit;globalUV1lightmap data unchanged by hash. review-detail.glb25,079,892bytes. Single shared-atlas baseline26,220,908bytes retained for comparison. Detail normal strength restored to1 for those pages;legacy supplemental atlas retains.35. No claim of mobile memory acceptance.
- R23 golden sunlight mismatch fixed:reads source power/matrix/color rather than hardcoded10.7 and arbitrary rotatingdirection. Sourcegold23.04;morning15.36. Window fill still approximates an area light;full Cycles equivalence not achieved.
- Runtime door controls select actual cream/double device. Browser tested doubleopen90/75degrees,close0/0,lights4/4→0/0;creamfreezer85degrees lights only freezer;microwave90→0. All recorded errors=[]. Independent under-cabinet LED retained. Newfrontcamera button facilitates interior review.
- Browser visually reviewed Japandi/oak/cane,complete modern bodies with builtin,sourcegolden light. Updated Claude handoff and C2C-009;actual receiver acknowledgment pending.
- Final source color calibration also reads the window-area and ceiling lamp linear colors from Blender reports (old runtime hex constants differed);window shadow far limited to its12mrange. Area-light shape/intensity still approximated. A shadow-off diagnostic showed dynamic shadowing contributes to dark trim;some baked/normal edge artifacts also persist. No blanket claim that all dark seams disappeared.
- Frontal night test exposed horizontal shadow acne on double-fridge liner. Same-camera A/B with only interior spotlight bias0→-.001 removed stripes. Final window/ceiling depthbias-.00015,source sun colors/direction still matched. This is a shadow-map precision correction,not a claim of full light-transport parity.

## Remaining
Art acceptance,softer/more faithful area-light transport,source/runtime visual parity,full compatibility matrix and S24performance/texture compression remain open. Existing3DGS mismatch persists and is not the primary path. No ingredients drawn,no table pendant fabricated,no Flutter integration/noAPK/no Firebase/no commit/push.

## Local preview
http://127.0.0.1:8878/?options=r23&sourceConstants=on&detail=on . ServerPID42680 at startup,checkoutE:/work/SOFRA/app,script realtime-r24/server.mjs;inspect live owner before stopping. Port8877 historical review remains intact. Live app/computer required;no new automation scheduled by this run. The previous00:30 scheduling was never confirmed and did not run;this round began on the user's explicit request.


## Codex R24b checkpoint — 27 October 2026
Claude handoff: docs/design/CLAUDE-R24-HANDOFF.md updated first. Completed shared lightmap uniforms, opt-in legacy splats, experimental disk PCF, and calibrated radiance-to-irradiance conversion (PI). Blender unit calibration mean=1; viewer syntax passes; six browser QA snapshots have no JS errors. Double-fridge doors and compartment lights pass open/close checks. Morning/night/golden reviewed; dark trim/seams and real-phone performance remain unresolved. No Blender masters, GLBs or HDRs changed in R24b; local only, no commit/push. No Claude receipt assumed.

