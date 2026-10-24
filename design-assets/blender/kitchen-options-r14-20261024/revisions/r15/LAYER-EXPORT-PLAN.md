# Modular pre-render direction — pending visual approval

The existing r14 PNGs are full-scene review renders, NOT exported runtime layers. r15 changes only the default scene. Do not label old options as updated r15.

After the user finishes edits and approves all three lighting modes:

- Fix camera, resolution, orthographic scale, color management and canvas origin for every export.
- Export a shared room base for each mode, with optional/replacement objects removed from that base. Preserve true masks for occupied areas.
- Export each appliance/decor variant with transparent RGBA, a separate contact/cast-shadow contribution and required foreground holdout/occlusion masks. Shadows are contributions relative to the same base, not black polygons baked over a complete scene.
- Define slots and exclusivity: refrigerator, freestanding versus built-in cooker/counter, curtain/blind/none, rugs, furniture, plants. Dependencies select the matching counter mask for a built-in stove.
- Cabinet paint changes need replacement surfaces/masks or a separately approved tint pipeline; multiplying a flattened whole-scene image cannot reproduce wood color faithfully.
- Three lighting families per exported option; time selection later chooses a family, not a live Blender render. Exact phone-time boundaries remain unchosen.
- Cross-object shadow/reflection interactions are not generally reproduced by independent 2D layers. Restrict supported combinations and reserve local paired patches for nearby dependent slots, rather than pre-rendering every full-scene combination. Validate actual composited results before claiming readiness.
- Verify matching pixel alignment, no seams/halos, occlusion behind fridge/table/shelves, contact shadows, all three light modes and target phone memory/texture sizes.

No export, harvest, atlas, Flutter integration or phone-clock logic is implemented in this revision. User explicitly requests those only after render approvals. No upload/commit/push.
