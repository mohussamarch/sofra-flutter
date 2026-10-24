# Kitchen r07 — actual6×6 modules

User requested six modules along each side instead of seven. The room is now3.6×3.6m at600mm/module; floor contains6×6tiles. This changes actual geometry/layout, not merely camera framing or image scale. Plinth includes80mm border outside nominal room.

Removed one600mm base unit and its corresponding wall unit from the rear run; shifted subsequent appliance bays by600mm. Removed the extra600mm left-run unit and shifted the sink/window/rear run/shelves toward the front by600mm. Pantry remains at front left. Replaced the old pair cornice with a single-unit cornice to avoid leftover geometry.

Rear run from corner to right:600mmcorner +600mmprep +900mmrange +600mmbuffer +900mmfridge =3600mm. Left run:600mmcorner +four600mmbaseunits(including sink) +600mmpantry =3600mm. General depth600mm; refrigerator retains its explicit720mmdepth.

Five-burner cooker/oven, recessed sink/mixer, refined sill, open shelves/six decoration anchors and current classic option retained. Classic is still not approved as the default. Exact orthographic camera recentered on1.8,1.8; projected rear/front corner alignment verified. No decoration/rewards/editor/animation/runtime implementation added.

`kitchen-6x6-r07.png`: actual1400pxCycles render. `.blend`: editable source; `.glb`: experimental export. `resize_six.py`: reproduce from r06 `.blend`, arguments BASE_BLEND OUTPUT_DIRECTORY, with Blender `--python-exit-code 1`. `verification.json`: fresh source reopen, GLB reimport, five burners/six decoration anchors/corner/buffer/sink, actual tile count, dimensions and alignment. PNG must also be inspected visually.

Visual review caught the sink cabinet remaining in its old position while the sink moved. Root cause: this module has its own `cabinet_sink_600` name and was omitted from the left-module movement filter. The explicit module was added to the transform list, and six exact left-run root-position assertions plus a ray check through the moved sink countertop opening now guard this alignment. Final render must show a continuous counter, no abandoned hole or floating sink. Initial plinth dimension assignment also changed to a single full vector so sequential Blender dimension-component writes cannot reset the other axis.

All local only; no commit/push/upload until user finishes review. Previous r01–06 remain preserved. No Flutter/backend/recipe/Firebase/APK/audio changes. Next: review compact6×6 composition, continue requested design refinements.
