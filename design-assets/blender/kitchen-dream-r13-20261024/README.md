# r13 — Soft dreamy golden kitchen / cotton gingham / lived-in details

Actual Blender5.2.3LTS review study from r12; local only. Not final visual approval, runtime, APK or performance validation.

## Geometry and material changes

- Diagnosed edge steps: prior base4.06m was smaller than outer wall envelope4.14m; separate wall boxes had mismatched corner extents. Rebuilt the two visible walls as one closed manifold L mesh with actual window opening and shared corner,12mmsoftbevel. Base4.14m now matches outer wall bounds;3.9msquare interior and600mm modules retained. Existing camera-only closed-room front/right/ceiling retained.
- Open-top hood duct is a true10mmmetal shell with a rim and inner walls, no top cap. Ray test through center hits the hood below atz<1.75m. Naturally shaded duct interior is not a painted black top.
- Muted faded teal painted wood; gentle broad procedural vertical grain with.5mmbumpdistance/.07strength, moderate color variation. Unified across cabinets/pantry/uppers/shelves. No realistic scratch textures.
- Curtain has only24mmfold-depthrange, no wind-billow offset. Broad planar top gathers into ties and short straight cotton tails. Procedural6cmgingham checks,cream/warmrusset weave,25percenttranslucent shader for sunlight through cotton. Independent optional root preserved.
- Three modeled decorative outlet plates with holes; no wiring or electrical installation claim. Original heart/star magnets and generic three-line note on refrigerator. Prior raised lower handle,thin metal hob/5burners/accessories preserved.

## Morning

Sun direction(1,.24,-.54),energy24,warmRGB1,.54,.16,7degreeart-directedsoftness. Window diffuse180W/RGB1,.88,.72. Real sun paths reach floor/cooker/lower-fridge region; exact ray hits in verification.json. Bounded volume.022density, subtle highlight FogGlow plus seven camera-only dust glints. No extra studio/HDRI/LED source. Artist-directed dreaminess, not astronomical or physical sun-angle simulation.

Blue sky and modeled outdoor foliage are camera-only, with shadow/diffuse/glossy/transmission/volumevisibility disabled. They cannot obstruct sunlight or alter interior GI. Sky card is behind foliage and positioned to the fixed isometric camera aperture; no outside scene assets were downloaded. Night foliage hidden and sky dark.

## Night

User accepted r12 distribution, asked slightly stronger. Same centered100degreeSPOT/.8edgeblend,160→200W(+25percent),shadowradius.16→.24m for gentler shadows. Same warmRGB1,.87,.68/exposure0. No undercabinetLED. Wattage is an artistic Blender setting,not a bulb recommendation.

## Files/checks

`refine.py`, `check_saved.py`, `morning-r13.blend/png`, `night-r13.blend/png`, `verification.json`, thisREADME. Final1400px Cycles/OptiX512morning/192night. Fresh source reopening checks:manifoldwalls/exactbase,enclosure,lights,cottonfolddepth,3outlets,12gratefeet,realopenductray,outsidevisibility,correctedmagnet/leafscales,corneralignment and hashes. Final images visually inspected before delivery. Preview caught a stale transform when parenting scaled props;fixed with view-layer update and final size assertions,not shipped.

Local only,no commit/push/upload. No Flutter/backend/Firebase/recipe/audio changes or fresh Flutter gate claimed. No preview server started/stopped. Next:user reviews warm soft morning/night,curtain,color and outdoor view. Runtime/customization/LED remain future.
