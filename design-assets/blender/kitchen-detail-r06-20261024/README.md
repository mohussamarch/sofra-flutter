# Appliance and classic-facade refinement r06 — local visual review

User found the cooker/sink too primitive and the classic option too faint. This study changes those three elements on the existing square r05 room. It does not select classic as the application's default.

## Actual geometry changes

-900mm freestanding range: exactly five burners (four outer burners plus a larger central wok burner), cast-iron caps, pan supports, three grate sections, steel/enamel hob, six controls (five gas and one oven), framed oven glass, mounted bar handle and lower drawer.
-Sink: boolean openings in countertop and cabinet-body top, genuinely recessed rounded bowl with approximately174mm depth, drain/strainer and continuous gooseneck mixer with lever/outlet. The source bowl is an open surface with shell thickness, not a raised solid block.
-Classic option:13fronts with broader65mm rails/stiles, stepped inner bead, raised center panels, clearer cream/shadow separation, brass pulls and modest upper-cabinet cornices. Deliberately simplified/cartoon furniture, still pending style review.
-Square4.2×4.2m footprint,600mm general modules, corrected camera/alignment,600mm buffer between range and fridge, completed corner, window/sink, refined sill, open shelves and6decoration anchors retained.

## Files

`kitchen-r06-classic.png`: full study. `kitchen-r06-range.png`: real Blender closeup of cooker. `kitchen-r06-sink-classic.png`: real closeup of sink/cabinet details. `.blend`: editable original source; `.glb`: experimental export. `build_details.py` builds from r05 with Blender `--background --factory-startup --python-exit-code 1 --python build_details.py -- BASE_BLEND OUTPUT_DIR`.

`verification.json` records fresh source reopening, five burners/six controls/13classicfronts, corner projection alignment, source SHA256 and GLB reimport with saved decoration anchors. Visual inspection of all three PNGs is required separately; this is not runtime performance, full visual approval or a production-ready asset validation. Generation uses user's installed Blender5.2.3LTS.

The final polish replaced overlapping individual cornices on the adjacent upper-cabinet pair with one continuous cornice to remove the black intersection seam. The full and sink/classic views were rendered again; the cooker closeup was retained because its visible geometry/lighting/framing are unchanged. A fresh ray test confirms the sink center passes through the countertop opening. GLB includes the curved mixer and grate frames as geometry.

No appliance variants/editor, animations, reward system, Flutter integration/APK, Firebase, backend, recipe bank or audio added. No public upload/commit/push while the user is reviewing. Next: review the appliance/cabinet details in selection boxes before pursuing further styles or runtime integration. Prior r01–05 stay preserved.
