# R22 — local trained 3DGS + editable Mesh execution — 26 October 2026

User asked to try the 3DGS direction and finish the previously requested visual changes. This is a review experiment only. Codex owns visual assets; Claude owns Flutter/runtime. Keep the work local until the user reviews it: no commit, push, APK integration, or production approval.

## What is ready

- [x] Updated the three existing Blender masters in place; exactly three `.blend` files remain and there are no `.blend1` backups.
- [x] Re-exported `design-assets/blender/current/realtime-r22/review.glb` from the current masters. Size: 15,520,284 bytes. `export-report.json` source hashes match all three current masters.
- [x] Captured 72 new training images: 24 views × morning/golden/night, 384×384, 48 Cycles samples. Dataset hashes match the current masters.
- [x] Updated exterior: 5 trees across three depth layers, enlarged sky dome and no plant shadow/diffuse/glossy contribution to the kitchen. Night stars are denser; golden sky was warmed. A warm under-cabinet LED is attached from exported upper-cabinet bounds and activates at night.
- [x] Local browser viewer compares three modes: trained static-wall 3DGS + editable Mesh; hybrid Mesh with baked diffuse maps and live lights/shadows; full dynamic Mesh with no lightmaps. Current time changes direct sun, editable shadows, sky, night lamp, and LED. HDR reflection probes remain precomputed per time in every mode; the full-dynamic mode is therefore a lightmap-free comparison, not a fully dynamic GI/reflection system.
- [x] Browser QA: all three modes, morning/golden/night, home/outside camera, and refrigerator door 0–104° then reset. The page initializes without visible application error. Preview: `http://127.0.0.1:8877/?r=22c`.
- [x] `node --check` passes for `viewer.mjs`, `sky.mjs`, and `lighting-mode.mjs`; `node --test design-assets/blender/current/realtime-r22/lighting-mode.test.mjs` passes 3/3 mode tests.

## Not complete / evidence limits

- [ ] **Retrain the three PLYs against the new 72-view dataset.** Existing `training-report.json` still records old master hashes (`acd05e…`, `b21d6e…`, `ef8d41…`), while current hashes are `1f1a60…`, `b2ffb8…`, `23495c…`. Its 40,000 splats, 1,800 steps, and PSNR are historical evidence only and must not be represented as training on the current masters. The previous CUDA Python environment is not available from the current `python` command (`WindowsApps` shim); do not install packages or alter the report to make it appear current.
- [ ] Check higher-resolution edge/silhouette QA, sockets and all option variants; a screenshot comparison does not establish quality approval.
- [ ] No physical S24/iPhone performance test, final mobile budget optimization, or integration into the Flutter app.

## Next action

Recover the already-installed matching Python 3.10 / PyTorch CUDA / gsplat runtime, retrain from `training/` without changing the capture protocol, verify held-out views and current source hashes, then re-open the local viewer and review all three modes. If the matching runtime is unavailable, stop at the current comparison and report the stale-model limitation; do not download/install a new stack without coordinating with the project owner.

Ruling remains provisional: 3DGS is confined to two static plaster walls; doors, floor, furniture, cabinets, and shadows remain editable Mesh. No mobile suitability is established.
