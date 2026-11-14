# R25 mobile candidate — 28 October 2026

Actual NEW file for Claude to test:
`E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\mobile-r25\kitchen-mobile.glb`

- 7,163,808 bytes (7.16MB),147,669triangles, versus source25,079,892bytes/296,834mesh triangles.
- Draco required. Base color maximum768px; normal maximum512px.705meshes retain2UV channels. This reduces file/triangle cost, not proven phone FPS or draw-call cost.
- Preserved hinge names r18_fridge_hinge,r18_freezer_hinge,r24_microwave_hinge. Clips fridge_open,freezer_open,microwave_open; glTF end rotations verified negative100degrees aroundY. Use clips OR manual hinge control, never both simultaneously.
- Source only had microwave_open; new fridge/freezer clips were added to this candidate, not to source .blend masters.
- Invisible ceiling/front/right enclosure meshes remain with reviewShadowOnly metadata. They must block light in a runtime-shadow renderer and be hidden from the visible surface pass. In model-viewer without shadow-only handling, hide them from display; then this asset alone does NOT recreate their occlusion. Exterior plants/sky are separate and omitted here.
- This is BASE kitchen, not the complete alternative-options library. r23-options.glb remains separate/heavy. Do not claim all options have a mobile export.
- Existing bounce-HDRs remain external and indirect-only. Direct-sun/LED baking and dark trim/seams are still OPEN. This does not fix model-viewer's lighting compatibility automatically.
- Verification: Draco roundtrip import passed; requirednodes/clips/UVs/textures/size/triangle checks passed. verification.json and export-report.json in the same directory. No phone test or visual approval yet. No APK replacement/publish performed by Codex.
- decoded-qa.glb in same directory is ONLY an uncompressed decoder output for local browser inspection; do NOT ship it. Review: http://127.0.0.1:8878/?mobile=qa&options=none . Browser test here does not prove model-viewer's Draco decoder compatibility.
- Build: export_mobile.py; check: verify_mobile.py in parent directory. No .blend file written; only3masters retained. Original review-detail.glb hash unchanged.
SHA256: 227e2be77635aeb437f003586116a0e458fabee2180ed12d7265a758e32aa8fd


Browser QA on decoded output: fridge75/freezer0 at09:30; fridge0/freezer70 at22:00;errors=[];visual spot-check completed. Original Draco payload imported by Blender successfully. Actual phone/renderer Draco loading not tested.
