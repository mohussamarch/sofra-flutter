# Closed-room morning/night lighting r08

User requested two renders with the kitchen treated as enclosed, and no lighting sources except the window or ceiling. Morning should feel like golden hour, entering through the window and reaching toward the refrigerator. Same6×6module3.6msquare kitchen/camera/appliance/classic-option geometry retained.

## Actual lighting setup

The previously missing front/right walls and ceiling are present, opaque to shadow/diffuse/glossy rays. They are invisible **only to the render camera** to preserve the cutaway view; this is not an open-room studio rig. Original studio area light and original sun removed. Non-camera world/background strength is zero. A camera-only gray backdrop and a camera-only window-view card do not illuminate the room.

-`morning_golden`: one warm directional sun and one soft daylight area emitter outside the same window aperture, representing direct sun plus diffuse sky entering that opening. No ceiling light, ambient HDRI, interior fill, LED or hood lamp. Ray cast starts outside a clear pane and verifies direct path to the actual fridge door. Initial test accidentally sampled the wooden mullion and was corrected to sample clear glass/opening. Warm color/angle are art-directed for this scene; no claim about a real date/location/solar time.
-`night_ceiling`: one warm downward-facing area emitter just below the ceiling fixture. No sun/window emitter/ambient moon/HDRI/LED/hood lamp. Fixture is camera-hidden along with the ceiling; room enclosure remains physically active.

Same camera, composition and exposure0 for both; Blender5.2.3LTS,Cycles96samples,1400×1400,denoising,10total/6diffusebounces. `render_lighting.py` builds both from r07source with arguments BASE_BLEND OUTPUT_DIRECTORY and `--python-exit-code 1`. Each lighting mode has its own editable `.blend` and actual PNG. `verification.json` records active sources, enclosure/camera/world constraints, actual solar ray hit, source SHA256, saved-source reopens and equal cameras. PNGs require visual inspection as well.

Final morning refinement: direct sun4.5strength,warmRGB(1,.55,.24),direction(1,.235,-.36);window daylight40W. Initial daylight was too cool/soft and was replaced, retaining the completed night source/render(180W ceiling). Fresh ray checks hit fridge door at≈(3.272,2.799,.725) and floor near fridge at≈(3.164,2.274,.014). `check_saved.py` reopens both final sources and verifies exact allowed lights, opaque enclosure visibility to shadow/bounce rays, zero world illumination and36tiles; records source/PNG hashes. Both final PNGs visually inspected. No volumetric beam or atmospheric fog was added: visible patches/shadows come from actual light on geometry.

No runtime renderer or GLB lighting compatibility claim: area-light/visibility behavior must be rebuilt and tested for the eventual app renderer. No APK/backend/recipes/Firebase/audio changes, no native time-of-day feature. No style/default choice inferred. Keep all results local, no commit/push/upload while user reviews.

Next: user compares actual morning/night mood and chooses lighting adjustments through selection boxes.
