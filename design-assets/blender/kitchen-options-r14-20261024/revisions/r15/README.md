# r15 — local Blender review

Open `index.html` through the local review server (`http://127.0.0.1:8874/revisions/r15/index.html`). Original renders and editable `.blend` scenes are grouped by variant and lighting mode. `DECISIONS.md` records user choices and research references. No publishing or application integration has been authorized for this art review.

## Reproduction

- Blender5.2.3 LTS, Cycles OptiX RTX4070. Base final1400px256samples; alternatives1100px160samples. Persistent Blender preferences are not saved.
- `refine_base.py` builds the new room/sky/material baseline from the archived r14 `options-library.blend`, using archived `modes.py`, plus local `appearance.py`.
- `render_variants.py` finalizes the900mm grate top/short feet, three-drawer cabinet, vintage furniture and enlarged rugs; renders base, modern, Japandi, fridge, microwave, built-in, furniture, three rugs in three lights. It regenerates `variant-manifest.json` for its30images.
- `render_remaining.py` then appends12renders for hanging plants and curtain variants against the corrected base. These are NOT exports of isolated runtime layers.
- `check_saved.py` reopens selected saved scenes, validates key geometry/options and all42render hashes. See `saved-checks.json` for actual final checks.
- All scene output paths use `//renders/`. C staging files are not a second product repository. The canonical local review lives under E:/work/SOFRA/app/design-assets/blender/kitchen-options-r14-20261024/revisions/r15/.

## Wall investigation

Three controlled r15 diagnostics changed one component each: hide enclosure, hide interior volume, hide sun. Only disabling volume removed the triangular patches with closed enclosure retained. New simple quad wall meshes alone did not remove them. Replacing the bevel-bearing/coincident-boundary volume box with a plain cube inset10mm from room surfaces removed the patches in the inspected render while preserving scattering. This establishes the old volume object's involvement; the separate roles of its bevel versus coincident boundary were not individually isolated. Do not claim a specific Blender engine defect or that all marks were caused by wall polygon normals.

The left/window wall is a fresh16-quad closed ring, rear wall a fresh6-quad box, flat normals, no inherited mesh/modifiers. They touch at the room corner without overlapping volumes. The air volume measures3.88×3.88×2.68m, has no bevel or weighted-normal modifiers, and is hidden in night mode. Closed-room shadow walls/ceiling remain in the scene, with world irradiance0.

## Remaining review and integration

- User approval for every option and light mode is pending. Color swatches are research-backed proposals, not approved product palettes or guaranteed audience preferences.
- Cabinet styles share the600mm layout and three-drawer buffer. Japandi was explicitly selected by user. Lilac was rejected and removed from the active gallery.
- Character-derived fridge stickers are a future feature; the three sample stickers are generic examples.
- Follow `LAYER-EXPORT-PLAN.md` after approval: aligned transparent parts, occlusion masks and shadow contributions, controlled compatible combinations. No atlas/GLB/harvest/Flutter clock selector or APK was built here.
- `DELIVERY.json` outside this directory remains the historical published-code receipt; the local art receipt is E:/work/SOFRA/BLENDER-DELIVERY-20261024.json. No commit/push/upload during review.
