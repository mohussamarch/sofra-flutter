# Kitchen r14 render review plan — 24 October 2026

Goal: repair the default Blender kitchen and create reviewable optional assets under morning/night/golden sunset lighting. Keep local. No runtime harvesting/integration until user approves all renders.

- [x] Diagnose wall/floor shading with actual mesh and evaluated normals; planarize wall faces, remove unnecessary normal modifiers, verify no coplanar overlaps.
- [x] Baseline: continuous countertop runs with retained sink opening and stone upstands; three outlet positions clear of window; round rod finials; hood duct top matches upper-cabinet top; remove upper herb pot.
- [x] Three editable base lighting scenes; retain accepted night distribution. Golden sunset adds window/metal glints, haze and subtle bloom.
- [x] Independent option previews: corner microwave facing camera; wider modern double-door steel fridge; three pop pastel cabinet palettes; hanging plants; two gingham colors (default warm + blue), white office blind and no curtain; three vintage fringed rugs; built-in hob/oven; small square wood table with three chairs.
- [x] Render each option separately in all three light states with fixed camera. Do not imply all cross-product combinations fit or have been approved.
- [x] Verify source reopening, planar normals, countertop continuity/sink cutout, outlet clearances, duct height, option/mode counts, exterior light isolation, expected files/hashes; inspect all final renders.
- [x] Local artifact gallery/manifest/README; update shared and external STATUS/HANDOFF/QUEUE/CLAUDE and local art receipt. No commit/push/upload.

Deferred: final chosen palette/options, exact phone-clock/sunrise/sunset thresholds, GLB/atlas/occlusion/compositing export, interactive runtime and device performance. The user's base scene remains default; optional renders do not select replacements.
