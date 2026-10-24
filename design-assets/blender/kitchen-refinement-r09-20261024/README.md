# Sofra r09 — quieter night, visible morning beam and geometry corrections

User requested: softer/slightly warmer night; visible morning beam angled to just reach the fridge end and floor; properly seated cast-iron grates; hood underside aligned to wall-cabinet underside; straight shelves with no window-wallLreturn; slightly smaller window and removable/changeable curtain. Current6×6module3.6m square and camera retained. Local review only.

## Geometry

-Three rebuilt cast grate assemblies have solid rectangular-ring frames, supported fingers/center bridges and12contact feet. Feet meet the hob, frame and fingers intersect structurally. Existing five burners retained.
-Hood head underside aligned to actual cabinet underside1.61m. Duct extended to retain its top height. Covering hood with an upper cabinet remains a future option, not built here.
-Three straight600mm shelves extend to the left wall; allLreturn boards removed. Six decor anchors retained and repositioned onto straight boards. No actual earning/reward/editor functionality.
-Window aperture shrunk from1.5×1.3m to1.2×1.1m, still centered over sink. Surrounding wall pieces rebuilt; thin sill retained.
-Original pleated linen side curtains, rod and rings under independent `curtain_root_optional`. Curtains left open so daylight passes. The root is an authoring structure for future removal/replacement; app toggle is not implemented.

## Lighting

Closed front/right walls and roof remain camera-hidden only, opaque to other rays. No environment/studio/LED/hood sources. Night: ceiling-only60W instead of180W, slightly warmerRGB(1,.85,.67), softer600mm disk. Morning: sun10.5 with warmRGB(1,.58,.27), direction(1,.245,-.36),30Wdiffuse daylight through the smaller window; actual indoor VolumeScatter density.040,anisotropy.15 to show the shaft. No extra beam lamp or painted overlay. Actual rays checked through clear pane to near the far fridge-door edge/handle and the floor in front. Art direction, no solar date/location calculation.

`build_geometry.py` runs from r07source and saves `kitchen-r09-geometry.blend` plus geometry-verification.json. `render_lighting.py` uses that geometry file and produces morning/night `.blend`/PNG and verification.json. `check_saved.py` checks final saved lighting files. All commands use Blender `--background --factory-startup --python-exit-code 1 --python SCRIPT -- BASE_BLEND OUTPUT_DIR` (checker takes OUTPUT_DIR only).

`render_detail.py` makes `stove-hood-detail.png` from the final night source, showing grate feet and hood/cabinet alignment with closer framing. It does not save over either full-composition source. Geometry-only intermediate retains the input's temporary lighting; the two final morning/night sources are the closed-room lighting deliverables. Draft preview folders/logs are not part of delivery.

User-installedBlender5.2.3LTS. DetectedRTX4070OptiX used in-memory with CPUfallback; no global preferences/driver installation changed. Actual1400pxCycles renders: morning512samples to smooth volume noise, night96samples, same camera/exposure. Morning beam required an additional800pxpreview and adjustments to direct-sun/scatter balance before final high-quality render; draft files are not deliverables. Inspect both finalPNGs; structural/ray/light checks do not establish visual approval, runtime performance or production-ready asset variants. Area lights/volumetric effects need separate renderer evaluation before app integration. No APK/backend/recipes/Firebase/audio changes. No commit/push/upload until review complete.
