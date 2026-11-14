# Codex → Claude Code — R23 — 26 October 2026

**Superseded by docs/design/CLAUDE-R24-HANDOFF.md on27October.** R24 changes source geometry,door routing,interior lighting,style bodies and material UVs. Do not reuse R23 mesh/lightmap combinations with R24 files.

## Update: checkpoint3
Local review now includes actual exported option meshes and independent double-fridge hinges. URL: http://127.0.0.1:8877/?r=23&colorBake=r23&bounceBake=r23&surfaceBake=r23&sourceConstants=on&options=r23 . See R23-PROGRESS.md checkpoint3. Do not integrate yet: some cabinet carcasses retain classic material under modern/Japandi fronts,full option/lighting matrix and mobile optimization remain open. Source constants should stay PBR constants when inputs are unlinked; avoid baking constant metal/enamel colors into tiny UV islands. `material-audit.json` is source provenance,not a production contract. LEDs now have an independent review toggle; runtime QA verified active false/true at night. Git read works with scoped permissions; prior work-tree failure was not evidence of a broken repository. No commits/push performed.

## Scope and ownership
Single checkout: E:/work/SOFRA/app. Read docs/STATUS.md, docs/OWNERSHIP.md and your own handoff first. Codex owns design-assets; Claude owns Flutter/runtime. This is an intermediate technical handoff, not final scene or aesthetic acceptance. Keep changes local: owner requested no commit/push until review. Do not modify Blender masters or rerun Codex bake jobs.

## Verified fix to port to the actual runtime
The window fill light is very close to the wall. A shadow-camera near plane of0.5m skipped that wall, allowing light into a sealed room. In Three.js preview, setting `windowLight.shadow.camera.near = 0.02` and updating its projection matrix fixed the regression. Use equivalent units/settings in your runtime; do not copy blindly if light position or engine differs.

Evidence: design-assets/blender/current/realtime-r22/r23-light-audit.html and r23-light-audit.mjs. Same camera, neutral materials, no lightmaps/environment/emission,17066 visible interior floor pixels:
- Original fill:9644 lit pixels both with window open and sealed.
- Fixed fill:5474 open,0 sealed.
- Sun:1547 open,0 sealed; removing hidden enclosure produces377 lit pixels (negative control).
- Global ambient illuminates all17066 sealed pixels. In hybrid mode disable global ambient diffuse when baked indirect already supplies it. Keep specular reflection support separate. This test does not certify full GI or reflections.

Hidden ceiling/front/right walls must remain occluders, only invisible to the viewing camera. They already exist in the GLB and sources; do not remove them or rebuild walls merely to mask lighting artifacts. Geometry audit: realtime-r23/audit.json,3645 sampled opaque-side rays,zero misses.

## LED prototype (review, not final quality)
In preview, LED point lights were moved below cabinet bounds (minY-.025m) and enabled for shadows, near=.01m. Night view shows illumination under cabinets. Final softness/intensity and mobile cost are unresolved; point-light cubemap shadows can be expensive. Do not treat current pixel-map sizes as a mobile recommendation.

## Texture experiment — do NOT ship as production assets
Preview:
http://127.0.0.1:8877/?r=23&colorBake=r23&bounceBake=r23&surfaceBake=r23

Local scripts/results in design-assets/blender/current/realtime-r23:
- rebake_color.py / color-bake-report.json
- rebake_bounce.py / export-report.json
- rebake_surface.py / surface-bake-report.json

4096 atlases,16px EXTEND margins; color,normal,roughness and three indirect maps. All bake jobs exited0. Bounce and surface UV hash matches existing R22 mesh: b24825ad726fba3f382a7e0a5366e29960819a8b49234aa5a5274281de9c1111. Three Blender master hashes unchanged. No fourth master created.

Visible improvement: reduced black borders on chairs,window and fridge. Cabinet trim artifacts and overall quality still below target. These large atlases are diagnostic; mobile texture memory/compression and per-material packing remain unresolved. Original R22 maps were retained. Do not copy the experimental maps into APK or call the scene production-ready. No S24 device test performed.

## What Claude can work on independently
1. Port and test the near-plane correction and hybrid ambient separation in the actual runtime, respecting your current implementation.
2. Preserve independent option/door nodes and camera-hidden occluders in runtime loading. Do not assume current R22 export contains every requested option.
3. Prepare GPU texture-memory/draw-call measurements on S24; desktop CPU-submit figures are not phone GPU performance.
4. Record findings under your handoff and respond to C2C-008 in docs/design/CONTRACT-REQUESTS.md using the established coordination workflow. No receipt has been assumed.

## Codex remaining work
UV/material partitioning for thin surfaces, better shadow softness and window foliage, complete option exports (styles/appliances/rugs/curtains), quality comparisons and production optimization. 3DGS is deferred; existing PLYs are older than current sources and must not be treated as the final path.

Detailed progress: docs/design/R23-PROGRESS.md. Plan: docs/design/R23-PROFESSIONAL-KITCHEN-PLAN.md. Git work-tree inspection previously failed; no claim of clean/synchronized HEAD and no publish performed.
