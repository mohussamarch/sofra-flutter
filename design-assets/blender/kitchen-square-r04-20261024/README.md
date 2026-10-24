# Square kitchen alignment r04 — local review

The user clarified that the rear wall junction must appear directly above the imagined near/front floor corner, and explicitly confirmed a square kitchen footprint. The previous4.2×3.6m rectangular floor was the reason these corners failed to align despite an equal-axis camera. The earlier camera proof addressed projected axis lengths, not diagonal corner alignment; that was insufficient for the intended composition.

## Corrected

- Square4.2×4.2m footprint: seven600mm modules along each direction. Dimensions are an art composition, not a user's real-room measurement.
- Orthographic camera retains equal XYZ offset(8,-8,8) and azimuth45°; target at square center(2.1,2.1,1.1).
- Rear run and sink/window shifted by600mm. Added600mm left-run module to fill the extension. Right-end fridge,600mm buffer before cooker, corner unit, sink under window and pantry clear of the window retained.
- Previous style comparison remains exploratory. No style default has been selected; r04 uses the neutral base to review geometry first.

## Review files

`square-kitchen-r04.png`: clean Blender render.

`square-kitchen-r04-alignment.png`: same scene with an orange vertical guide and endpoint rings drawn/rendered in Blender. This demonstrates the rear and front corner positions. The review guide is not in the clean `.blend` orGLB.

`sofra-square-kitchen-r04.blend` and `.glb`: source and experimental export. `build_alignment.py`: reproducible correction from r02 source, arguments BASE_BLEND OUTPUT_DIRECTORY. Blender5.2.3LTS; actual1400pxCycles renders. `verification.json`: square dimensions, numeric projected corner coordinates, pixel alignment error, clean source reopened and actualGLB reimported with required roots and matching mesh counts. PNGs require visual inspection too.

No runtime renderer integration, customization editor, animation, APK, recipes, nutrition, Firebase or audio changed. All local, no commit/push/upload by explicit user request. Next: visual approval of the square composition through selection boxes before detailed variants/styles. Prior r01-r03 remain preserved for comparison.
