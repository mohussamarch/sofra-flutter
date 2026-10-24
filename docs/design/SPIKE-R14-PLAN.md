# Visual ownership and r14 performance spike implementation plan

> Execution: Codex implements inline per the user's explicit file request. Claude owns application code. No delegated agents.

**Goal:** Publish clean ownership/docs and a small, reproducible 2.5D test package from frozen r14 for S24 Ultra, without publishing Blender/raw sources or approving artwork.

**Architecture:** Keep Blender sources on E. Native Blender exports same-camera bases, masks, a cropped door sequence and closeup. Pillow encodes WebP85 and checks pixel dimensions/palette/hashes. `scene.json` is provisional technical metadata until Claude authors SCENE-CONTRACT.md.

**Tools:** Blender5.2.3/Cycles OptiX, bundled Python/Pillow, Git.

- [x] Read complete user request, inspect status/owners and pull origin/main with ff-only. Save four existing doc changes in commit a97aa6db.
- [ ] Add ignore rules; archive the exact HANDOFF bytes; create short owner handoffs, readable STATUS/RESUME, OWNERSHIP and updated AGENTS. Do not edit Dart/tests/pubspec/tool or Claude contract.
- [ ] Export frozen r14 bases1440square with identical camera, IDs, window/beam masks,16cropped door frames0..100degrees, detailed fridge closeup and camera/hotspot/pivot metadata. Preserve source hashes. Curtain separation and optional light groups can be explicitly deferred with reason; do not mislabel full scenes as layers.
- [ ] Validate all assets/dimensions/camera/palette/sequence/pivots/decoding/size budget and inspect representative images. Package only lightweight final assets; no .blend/raw exports in Git.
- [ ] Commit/push permitted files, verify HEAD=origin/main and empty status, update external receipts/mirrors, return exact requested confirmation and wait for Claude's contract. No r15 polishing while user supplies comments.
