# Kitchen r05 — window sill refinement and open corner shelves

User requested a cleaner, less protruding window sill and open shelves filling the upper-cabinet corner beside the window wall. User also requested future optional display items/plants, including items users can earn. No earning rules or reward system have been designed or implemented.

## Changed

- Sill reduced from260mm overall depth/65mm thickness to100mm overall depth/25mm thickness,75mm projection into the room, gently rounded edges. Shorter lateral overhang, aligned to window frame. This corrects the protruding ledge rather than hiding it with decor.
- Three floating L-shaped open shelf levels fill the corner between the back-wall upper units and the window wall. Six independent boards parented to `open_corner_shelves_root`. Shelves stay at least60mm clear of window aperture and outside the adjacent upper-cabinet bay.
- Six named empty decoration anchors, two per shelf level, exported with the model; suggested200×200×270mm item envelopes are provisional authoring limits, not finalized fit logic. Shelves remain empty for this layout review.
- Existing square4.2×4.2m room,600mm general modules, exact orthographic camera alignment, appliances, sink/window relationship and pantry location unchanged. No cabinet style selected.

## Deliverables and checks

`kitchen-r05.png`: full actual Blender render. `kitchen-r05-detail.png`: actual second Blender render with temporary closer framing; clean saved source retains original full camera.

`sofra-kitchen-r05.blend`: editable source. `sofra-kitchen-r05.glb`: experimental export. `refine_shelves.py`: reproducible from r04 `.blend`; arguments BASE_BLEND OUTPUT_DIRECTORY, run Blender with `--python-exit-code 1`. `manifest.json`: dimensions, source SHA256 and decoration anchor metadata. `verification.json`: source reopening, actualGLB reimport/mesh count and anchor preservation, sill dimensions/window clearance and retained projected corner alignment. PNGs require visual inspection too. Blender5.2.3LTS;1400pxCycles.

No actual plants, earnable-item library, rewards, app customization, animation, Flutter integration, APK, source recipes, backend, Firebase or audio added. No public upload/commit/push: user requested local review. Previous revisions remain preserved. Next: user reviews sill/shelf proportions before further detail/variant/interaction work. Future decoration and earning mechanics must be designed separately, not inferred from these anchors.
