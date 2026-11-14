# R23 — checkpoint 2 — 26 October 2026

## Checkpoint3: source materials and real option export
- Closing quota95% primary/44% weekly, ordinary=true; stopping heavy work before authorized98% ceiling. Browser review preserved; screenshot C:/Users/atgs0/Documents/Codex/r23-options-review.png. Next action is cabinet carcass style materials, not redoing completed bakes. No automatic restart scheduled.
- Latest quota during work primary90%, weekly43%, ordinary=true. No agents; all local.
- `audit_materials.py` reads90 source materials plus object tags; most base colors are constants. `sourceConstants=on` restores source linear PBR constants instead of sampling tiny atlas islands. Browser recorded749 color,989 roughness,744 normal,989 metallic material-instance restorations (not unique material counts). Procedural inputs retain maps. Fridge/range handles visibly cleaner.
- `export_options.py` exported272 existing option meshes with color/normal/roughness baking and unchanged master hashes: plants76,double fridge64,blind21,builtin21,rugs7/8/12,modern24,Japandi39. Supplemental GLB is local review only. First export lost hidden empty hinges; revealing source empties before export fixed it. GLB now contains both named double-door hinges.
- `r23-options.mjs` adds live controls. Browser exercised classic/modern/Japandi fronts,standard/double fridge,standard/builtin range,all3rugs,gingham/blind/none,plants; double doors opened to85degrees. Combined variants visibly align. LED toggle was checked against runtime QA: false→true at22:00,2fixtures,errors=[]. Microwave toggle present; full combination matrix not tested.
- Review URL: `http://127.0.0.1:8877/?r=23&colorBake=r23&bounceBake=r23&surfaceBake=r23&sourceConstants=on&options=r23`.
- Important remaining defect: modern/Japandi fronts switch, but some cabinet carcasses retain classic green material. Do not call complete cabinet styles finished. Palette/curtain color variants,alternative table,soft shadows,UV quality,mobile memory/draw-call optimization remain open. Current full loaded scene361048triangles; displayed draw counts vary with selections and are above mobile goal. No S24 test/production acceptance.
- Syntax checks passed for viewer/options. Blender jobs exited0. Scoped elevated Git read now succeeds; work is locally modified/untracked and remains unpublished by user request. Do not touch .claude or other-owner changes.

Runtime work is underway. User explicitly corrected stopping at an assistant-selected 4,000-token target: conserve tokens, continue execution. Latest quota: primary8%, weekly30%, ordinary=true. Local only, no commits/push or Claude-owned code changes.

## Verified direct-light regression
`realtime-r22/r23-light-audit.html` and `.mjs` isolate lights on 17,066 visible interior floor pixels (tile_* meshes, excluding exterior plinth). Open versus fully sealed window, no environment/lightmap/emission:
- Sun sealed: 0 lit pixels; open:1547. Missing-enclosure negative control:377.
- Window fill with original shadow near=.5m:9644 pixels lit both open and sealed (leak).
- Corrected near=.02m: open5474, sealed0. All diagnostic assertions passed.
- Ambient-only sealed lights all17066 pixels; global ambient bypasses walls by design.
Applied near=.02 to preview; hybrid ambient now zero to avoid duplicate/unoccluded bounce. LED lights moved below cabinets, cast shadows with near=.01; night visual verification outstanding. This does not prove complete GI/reflection/option correctness.

## Material seam investigation
Normal-map and mipmap disabling did not remove black borders. Neutralizing albedo removed chair borders; cabinet borders persisted, so a single normal-map tweak is insufficient.
`realtime-r23/rebake_color.py` baked4096 color with16px EXTEND margins, no source saves; source hashes unchanged. Runtime query `?r=23&colorBake=r23&normal=off` visibly improves chairs and fridge handles. Not final aesthetic acceptance. Original R22 maps remain intact.
`rebake_bounce.py` completed all three4096/16px EXTEND maps. UV SHA256 matched the original report in every mode; sources unchanged; process exited0. Morning37.21s, golden49.05s, night38.3s. Viewed morning/golden/night in browser: reduced black window/fridge borders; some cabinet trim artifacts remain. LED effect visible at night; lamp shadows still sharper than desired. No visual acceptance or phone performance claim.
`rebake_surface.py` completed matching4096 normal/roughness maps, UV/source checks passed and exit0. Runtime diagnostic flags select the new maps without replacing original R22 files. Full experiment: `http://127.0.0.1:8877/?r=23&colorBake=r23&bounceBake=r23&surfaceBake=r23`. 4K maps are diagnostic, NOT the mobile memory-budget solution; compressed/per-material production export outstanding.

Remaining work: fix undersized UV islands/material partitioning rather than merely increasing every atlas; tune soft lamp/LED shadows, foliage/window view, then export complete option groups. All requested options, mobile performance and final aesthetic gates remain open. No bake process left running after this checkpoint.

## Earlier geometry evidence

Budget requested by user: target 4,000 assistant tokens per round, economical focused work; not an account billing cap. Quota at start: primary11%, weekly14%, ordinaryUsageAllowed=true. No agents/downloads/training or new render in this round.

Implemented `design-assets/blender/current/realtime-r23/audit_scene.py` and ran it in Blender5.2.3 against all three masters. Result in `audit.json` includes source SHA256, architecture bounds/ray visibility, evaluated-mesh topology, option-group object counts and R22 GLB shadow-only nodes. The script never saves a Blender source.

Findings:
- Exactly three masters, no blend1; source hashes unchanged by audit.
- Main wall meshes and enclosure ceiling/front/right have zero boundary/non-manifold edges, planar faces, no smoothing modifiers; camera=false on the hidden enclosure pieces, shadow/diffuse/glossy=true, hideRender=false.
- The three hidden enclosure pieces are present in R22 GLB with reviewShadowOnly; absence of these objects is NOT the diagnosed problem.
- 1,215 sampled axis rays per source toward the five opaque room sides, 3,645 total: zero misses. Window-facing direction intentionally excluded. This proves sampled geometric coverage only, NOT runtime shadow correctness, window sealing, indirect light or reflection correctness.
- Existing option counts inventoried; visual completeness and compatibility matrix still outstanding.

Next bounded unit: implement and run R23 runtime diagnostic that isolates direct sun, ambient/IBL, window fill and LED. Render open-window versus temporary blocked-window and sun-off controls using the same camera. Verify invisible enclosure contributes to shadow maps. Correct only the demonstrated leak; preserve R22 review until new output is verifiable. Then test indirect/reflection passes and curtain shadows. Do not rebuild currently sound walls without contrary geometric evidence.

Git status remains unavailable: both normal and explicit --git-dir/--work-tree status return “must be run in a work tree”. No config edits, commits or push; do not claim clean or synchronized repository. Read-only source inspection and new owned R23 diagnostics do not overwrite Claude's files.

Filesystem sandbox initially blocked audit.json. A scoped write grant for realtime-r23 allowed the final audit to complete. Final Blender run completed; no background render/training left running by this unit.
