# R24c — dining camera and render scheduling — 28 October 2026

Local review only; no publication or mobile performance approval. Codex owns the review viewer; Claude owns Flutter/runtime integration. Existing R24 GLBs/HDRs and three Blender masters are unchanged.

## Dining interaction requested by owner

Start at the existing Home camera and travel to the near corner of the wooden table. Keep the table/vase in the lower foreground and kitchen behind floating 2D meal cards. The central card is readable; adjacent cards are faded. Horizontal swipe/scroll selects a card. These cards are illustrative, not inventory or plan data.

Review implementation: `design-assets/blender/current/realtime-r24/dining-review.mjs`, button `#dining`. It resets to Home then interpolates camera position, look target and FOV over1800ms using smoothstep. Reduced-motion preference skips the long transition. Home/closeup/outside cancel and dismiss the overlay. The table is made visible on entry.

Three/glTF coordinates (Y up), metres:
- Start position `[7.8,6,4.2]`, target `[1.8,1,-1.8]`, FOV42° (existing Home).
- End position `[3.65,1.55,1.05]`, target `[1.6,1.05,-2.15]`, FOV58°.
- Final framing is a proposal for owner review, not an approved camera contract.
- CSS scroll-snap rail, central290px card, glass blur12px, translucent border/highlight; cards remain2D. No extra Three meshes or lights. Horizontal touch, vertical mouse-wheel conversion and arrow keys supported.

## Performance changes and limits

- Scene changes invalidate shadow maps. Camera-only changes reuse existing light-space maps; source light/object state is unchanged.
- Rendering is requested only during camera damping/transition or a scene change, then sleeps. Hidden page cancels RAF; becoming visible wakes it. Clock mode checks once/minute.
- Two settling frames replace45 redundant frames after every invalidation. Runtime metrics in `#stats[data-performance]` expose rendered frame and shadow-update counts, draws, rendered triangles, CPU submission percentiles (excluding first10frames), and sample count.
- Transmission buffer uses half linear resolution (quarter pixel area); main scene/MSAA unchanged. `?glassQuality=full` restores full-resolution glass comparison. This does not imply75% total GPU savings or FPS improvement.
- Actual phone tests and GPU timings remain pending.420k all-option triangle inventory, heavy GLBs and remaining trim/lightmap seams are NOT solved by scheduling. Claude's CL2C-003 mobile asset request (<8MB/~150k triangles) remains open.
- Previous R24b calibrated lightmap intensityPI remains. No exposure increase or arbitrary brighter fill introduced.

## Next

Validate camera framing with the owner, then investigate remaining edge artifacts and create a separate mobile export without changing node/pivot/clip contracts. Do not replace APK assets with this heavy review package.


## C2C-014 — 29 October: corrected dining camera; supersedes CL2C-004 camera
Exact new settings: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-camera.json
Executable reference: E:\work\SOFRA\app\design-assets\blender\current\realtime-r24\dining-review.mjs
Position [4.35,1.4,0.75], target [0,0.9,-3.6], vertical FOV50, 1800ms smoothstep from Home. Horizontal azimuth45deg: camera/table near corner/rear wall corner share z=x-3.6. Replace the OLD32.6deg orbit and target. Coordinates use glTF Y-up metres.
Show enclosure_ceiling surface at dining arrival; hide surface when leaving for Home/closeup/outside/fridge, retaining shadow occlusion. If your loader removes enclosure meshes, retain the ceiling and clone its material for this mode. No GLB modified for this camera correction.
Fresh browser review: portrait dining transition and cards visible, Home hides cards/ceiling; node --check passes. Framing remains pending owner approval; ceiling highlight quality still needs lighting review. Local only; no commit/push. Preview8878 restarted PID45980, server.mjs in the same realtime-r24 folder. CL2C-005 read: Claude confirmed R25 loaded in app; no receipt of C2C-014 assumed. Direct-sun/LED bake, trim seams and S24 testing remain open.
