# r14 — Default kitchen correction and option review library

Actual Blender5.2.3LTS renders. Local review only. **45renders = default +14optional views, each in morning/night/golden light.** Neither palette/options nor harvesting/app integration have been approved. `index.html` is a standalone gallery with relative images; `REVIEW.md` links to originals. Canonical directory: E:/work/SOFRA/app/design-assets/blender/kitchen-options-r14-20261024/.

## Default corrections

- Dissolved coplanar wall grid edges; removed wall/base weighted-normal modifiers, retained angle-only bevel and explicit flat main faces. Fresh evaluated large-face shading-normal error0degrees in all three saved sources; manifold walls. Initial r13max.54degrees included small bevel faces, not evidence of broken wall polygons. Remaining physical shadows still need the user's visual review; no unsupported claim that every sloping shadow was a polygon defect.
- Countertops no longer split every600mm: one genuine L slab with a boolean sink opening and one separate right buffer slab, preserving the necessary freestanding cooker gap. Matching low stone upstands added. Built-in option has a continuous L surround and true sink/hob cutouts.
- Round brass finials at both curtain-rod ends. Three outlet plates repositioned according to marked areas; left plate has about155mmclearance to window frame, verified above100mm. Decorative authoring only, not wiring validation.
- Open metal hood duct shortened to upper-cabinet top2.33m. Top shelf herb removed from default. Prior square3.9m/600mmmodule/camera/soft materials/lower handle/stickers remain.

## Options

1. Diagonal corner microwave facing camera XY.
2. Generic1.10mwide modern side-by-side satin steel fridge, no brand/logo; reserved bay retained.
3. Three stronger pastel finishes: coral,blue,lilac,with subtle painted grain.
4. Optional trailing plants on two shelves and pantry top.
5. Warm gingham(default),blue gingham,white office-style slatted blind,or no curtain/rod.
6. Three original vintage-style rugs: dark red triangles/diamonds,teal diamonds,ochre floral;50fringe strands each across two ends. Preview caught coplanar motif overlap;raised motif/center layers and rerendered all9rug images before delivery.
7. Flush four-ring black hob with integrated oven beneath inside matching cabinet.
8. Small720mm square wood table with exactly3chairs.

Each option is rendered independently. All cross-product combinations, door swings, navigation/ergonomic clearance, layer occlusion and runtime performance remain unvalidated. They are optional assets; default is unchanged by rendering an alternative.

## Three lighting states

- Morning: soft16energy sun,7degreeangle,RGB1,.78,.48;180Wwindowdaylight;volume.012.
- Night: accepted centered200WSPOT/100degreecone/.8edgeblend/.24mradius,RGB1,.87,.68;noLED.
- Golden sunrise/sunset art state: sun24/RGB1,.48,.12/direction1,.245,-.40;window90Wwarmfill;volume.032;strongerFogGlow.30 and subtle glints. Art-directed, no astronomical timing claim. Exterior sky/garden remain camera-only and do not obstruct/illuminate the room.

The user requests automatic selection from phone time later. **Clock logic is not implemented.** Exact fixed-time vs sunrise/sunset calculation, golden-window duration, timezone/location policy and transition behavior need selection boxes after visual approval. No device location permission requested.

## Sources, checks and review

- `base-geometry.blend`: repaired geometry before options.
- `options-library.blend`: all optional groups,hidden by default in viewport and render.
- `base-morning.blend`,`base-night.blend`,`base-golden.blend`: three editable default scenes,optional groups hidden. Render output paths are portable relative `//renders/` paths; no final source writes into C staging.
- Builders: common.py,build_base.py,build_options.py,modes.py,render_options.py. repair_rugs.py records the pre-delivery repair;prepare_sources.py cleans default viewport/group manifest. Rebuild normally uses the corrected builders directly.
- `render-manifest.json`: all45filenames,mode/variant/resolution/samples/SHA256. `verification.json`:45hashes checked,3source reopens,wall normals/manifold,sink opening,hood top,finials,upstands,outlet clearance,outdoor light isolation and14option selectors.
- Final base1400px512samples morning/golden,192night;options900px160samples. Cycles RTX4070OptiX in memory only. All45views inspected in the local gallery, with final rug repair reviewed.9browser screenshots document family/mode boards; gallery controls/images tested in Edge. Browser full-page CDP capture timed out; native viewport captures succeeded.
- Local loopback preview only: http://127.0.0.1:8874/ ; process command `node E:/work/SOFRA/app/design-assets/blender/kitchen-options-r14-20261024/review-server.mjs`. Device/app must stay open for local preview. No public hosting. Server binds only127.0.0.1 and serves this artifact folder.

No commit,push,upload,GLB/atlas/sprite harvesting,APK/Flutter/backend/Firebase/audio change. No Flutter tests needed/run. Next: user reviews corrected default + options in3lights,then approves before harvesting/runtime planning. Previous published DELIVERY remains historical; current local receipt BLENDER-DELIVERY-20261024.json.
