# R20 lighting comparison implementation plan
Goal: compare fully dynamic direct/IBL lighting against hybrid direct lighting plus baked static diffuse bounce in the same interactive review scene.
Spec: docs/design/REALTIME-KITCHEN-R20.md; user selected comparison first,25 October.
Execution: Codex inline in sole checkout,owned design-assets only. No product code/dependencies or source .blend saves.

- [x] Export actual classic kitchen with mandatory table/microwave. Bake procedural albedo into one2048atlas,keep PBR response. Export review.glb with pivots/extras,camera and architectural shadow blockers.
- [x] Bake only indirect diffuse bounce for three source light configurations;use one identical UV mapping. Moving/optional furniture and curtains excluded from static bounce;their direct shadows remain realtime. This intentionally tests an approximation,not complete GI.
- [x] Serve two matching Three.js viewports,shared camera/time/exposure/materials/direct lights/IBL. Left dynamic has no irradiance atlas;right hybrid adds diffuse atlas. All other settings identical.
- [x] Provide3lights,door motion,table/curtain toggle,live cabinet tint,and light direction control to reveal stale indirect contribution. Label desktop timing honestly;no device-performance claim.
- [x] Check all3source hashes unchanged,three UV hashes identical,atlas and GLB present,door pivots independent,local modules served. Browser screenshots in three modes,door closed/open and décor toggle;capture console errors and render stats.
- [x] Record limitations/results and deliver comparison link;no mass bake or final engine selection.

Rulings: current model-viewer trial is untouched. Use separate local review renderer to exercise lightmaps directly rather than rely on private model-viewer internals. Dynamic means conventional realtime direct+environment lighting,not hardware raytraced multi-bounce GI. No new worktree because user mandates sole E checkout. Review-only temporary geometry may exceed final mobile budget;measure and disclose.

