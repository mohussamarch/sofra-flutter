# r11 — Cozy cartoon color and perimeter study

Local review proposal in actual Blender 5.2.3 LTS, based on r10. Not a selected final palette or app runtime feature.

## User corrections

- Room expands from 3.6m square to 3.9m square: 300mm strip beyond each open end (right and front). Existing six 600mm cabinet modules per run stay unchanged; 36 full floor tiles plus 13 border pieces. Refrigerator bay can accommodate a future 1200mm-wide variant, but the current 900mm fridge remains. Door clearances and actual future appliances still need validation.
- Moved real enclosing walls outward with the floor; this separates them from the appliance sides. Improved indirect window daylight reveals the sides instead of the former nearly black occlusion. Natural soft form shading remains.
- Removed all four projecting upper cornice pieces and the cutting board. Upper-cabinet bodies/shelves preserved.
- New independent optional curtain pair: upper curved gathered silhouette, narrow tieback, straight lower drop. Existing rod/rings retained and redistributed. No in-app toggle implemented.
- Sage lower cabinets/pantry, vanilla uppers/counters, warm honey floor, muted peach curtains, brass pulls. Softer large appliance edges; hood has separate satin steel material (metallic .8, roughness .3). This is a first colored cartoon study.
- Morning sun stays energy16; steeper vector (1,.12,-.68) moves the real window patch onto the floor near the cooker. Window diffuse daylight180W; exposure+.4; volume density .018. No studio/HDRI/LED lights. Artist-directed, not geolocation/solar-time simulation.
- New night uses the same geometry/palette: ceiling light60→8W, warm RGB(1,.90,.78), broad1m disk, no daylight/sun/volume. Future under-cabinet LEDs deliberately absent, as requested. Night exposure0; morning+.4. A15W preliminary night was still too bright on the floor and was replaced.

## Files and verification

`build_cozy.py` recreates both final scenes; preview mode is optional. Final sources: `cozy-morning-r11.blend`, `cozy-night-r11.blend`; matching PNGs; `verification.json` records actual rays, source hashes and reopened-source checks. Final Cycles morning512/night192 samples at1400px using RTX4070 OptiX in memory only.

Both saved sources reopened: exact source lights, opaque camera-only enclosure, no cornices/board, two curtain panels and ties,36tiles+13border pieces, hood/upper undersides aligned. Real window rays hit floor near cooker; equal-axis orthographic corner alignment retained. Final morning and night images visually inspected before delivery. No GLB, APK, app/backend/Firebase changes or new Flutter gate claimed. No preview server started/stopped. Local only: no commit, push or upload. User approval pending.
