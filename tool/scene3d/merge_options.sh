#!/usr/bin/env sh
# Builds assets/spike3d/r24/kitchen.glb: Codex's R25 mobile kitchen (Draco)
# plus the R24 options library (cabinet styles, double fridge, built-in range,
# rugs, blind, plants, cane), its 2048 texture pages cut to 1024.
# The options carry no TEXCOORD_1, so the app keeps the bounce lightmap off
# them (probe light only). Run from the app folder.
set -e
R24=design-assets/blender/current/realtime-r24
OUT=${TMPDIR:-/tmp}/sofra-merge
T="npx -y @gltf-transform/cli@4"
mkdir -p "$OUT"
$T resize "$R24/r23-options.glb" "$OUT/options-1k.glb" --width 1024 --height 1024
# Merging into a Draco file writes the whole result with Draco.
$T merge "$R24/mobile-r25/kitchen-mobile.glb" "$OUT/options-1k.glb" \
  assets/spike3d/r24/kitchen.glb --merge-scenes
