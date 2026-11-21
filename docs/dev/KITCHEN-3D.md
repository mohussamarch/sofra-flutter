# The 3D kitchen viewer

Since 21 November 2026 the kitchen is drawn by the app's own three.js page, not
by `model-viewer`. One page runs everywhere: in a WebView on the phone, in an
iframe on the web, and on its own in a desktop browser for trials.

## Files

| Path | What it is |
|---|---|
| `assets/scene3d/index.html`, `kitchen.js` | The viewer page and all of its logic. |
| `assets/scene3d/vendor/` | three.js r180 (MIT) and the Draco glTF decoder (Apache-2.0), copied by `tool/scene3d/vendor_three.mjs`. Bundled, so the kitchen opens with no network. |
| `assets/spike3d/r24/` | The model (`kitchen.glb`: Codex's R25 mobile kitchen plus the options library, Draco) and the light files: `bounce-*.png` (lightmaps on UV1) and `probe-*.hdr` (reflections), one per time of day. |
| `lib/scene3d/kitchen_3d.dart` | `Kitchen3D` widget and `Kitchen3DController`. |
| `lib/scene3d/viewer_host*.dart` | Where the page runs: WebView (`_io`) or iframe (`_web`). |
| `lib/scene3d/asset_server_io.dart` | Loopback server on the phone that serves the two asset folders to the WebView. |
| `tool/scene3d/serve.mjs`, `drive.mjs` | Local server and the headless-Edge driver used for screenshots. |

## Lighting

The hybrid the owner chose (26 October): the room's bounce light is baked in
Cycles into lightmaps; the sun, the window's sky light, the ceiling lamp, the
under-cabinet LEDs and the fridge lamps are live and cast shadow maps.

- Two lightmaps are mixed while the hour turns. Baked surfaces take no diffuse
  light from the probe (it would count the bounce twice).
- Light powers, colours and directions are the Blender masters' own, read from
  Codex's `export-report.json` (R24).
- One fixed set of lights is always in the scene. A light that is off has zero
  power, so shaders never rebuild; its shadow map is simply not redrawn.
- The ceiling and the two near walls always block light and are never drawn
  (the owner's closed room, cut away for the camera). Codex's C2C-014 asks for
  the ceiling to show in the table shot; that waits for a ceiling that lights
  well and for the owner's word.
- The floor joints and the cut faces of the far walls are covered by thin
  planes lit by the room (`dressCuts`): in the closed room they bake black.
- Baked surfaces never get less than a small floor of bounce light
  (`BOUNCE_FLOOR`): grooves, joints and corners against the hidden walls bake
  pure black in the coarse lightmap and read as ink outlines otherwise.
- The shader edits are text patches of three r180's chunks. `kitchen.js`
  refuses to start on another revision or if a patch finds no match.

## Drawing

The model arrives as 1,065 meshes, one draw call each. At load, meshes that
never move and share a material and option tags are merged (`mergeStatics`):
about 150 draw calls per frame instead of about 740, pixel for pixel the same
picture. Doors and what hangs on them, glass, and the hidden walls stay
separate. `?unmerged=1` on the standalone page turns it off for comparison.

On demand: a frame is drawn only while the camera, a door or the light moves.
A shadow map redraws only for a light that has power, and only when what it
sees changed (a door swing redraws the big room maps every second frame).
After a camera move the viewer reports frame pacing (`t: 'perf'`); after two
slow moves running (median over 24 ms) it lowers its pixel ratio one step,
down to 1.5.

Quality tiers (`?q=desk|phone`, picked from the device by default): they share
shadow settings; the phone tier draws glass without refraction (which would
draw the room twice).

**Numbers on a real phone:** hold a finger on the kitchen for three seconds
(long enough not to happen by accident; a normal slow press still taps). A small box
shows draw calls, triangles, pixel ratio, frame time of the last camera move,
start-up time split into load / shaders / first frame, the graphics chip and
its texture units, and the view size. Hold again to hide it. If the page
could not start, the error state shows the page's own reason in small print.

The view never ends on a hard line against the page: the overview and the
appliance shots fade in an oval, the table shot fades at the frame. The mask
changes halfway through a camera move.

## Messages

Host to page, any subset, as JSON through `window.sofraKitchen(msg)` (WebView)
or `postMessage({sofraKitchenCmd: json})` (iframe):

```
{shot: 'home'|'fridge'|'freezer'|'microwave'|'table',
 weights: {morning, golden, night} | null,   // null: follow the clock
 look: {style, fridge, range, rug, curtain, plants, cane, led, cabinet: [r,g,b] linear},
 vignette: bool, calm: bool,                 // calm: fades, no travel
 pick: [x, y],                               // 0..1 across the view
 hud: bool}                                  // the numbers box
```

Page to host: `{t:'hello'}` when it can listen, `{t:'ready', ms, ...}` after the
first frame, `{t:'tap', p:[x,y,z]}` (Blender metres, z up) for a pick that hit,
`{t:'perf', median, p95, draws, triangles, pixelRatio, tier}`, `{t:'warn'}`
for a script error the room survives, `{t:'error'}` when it could not start.

The widget sends its whole state on every change and again on `hello` and
`ready`, so nothing sent early is lost. Touches never reach the page: Flutter's
`GestureDetector` asks the page what a tap hit, and the app maps the point to a
zone (`_zones` in `today_screen.dart`).

## Trying it

```
node tool/scene3d/serve.mjs assets 8912
http://127.0.0.1:8912/scene3d/index.html?hud=1&bg=FCF8F0
```

In the console: `sofraKitchen({shot:'fridge', weights:{night:1}})`,
`sofraDebug()`. Screenshots: `node tool/scene3d/drive.mjs <url> <outDir> <script.json> [w] [h]`.

## Open (next rounds)

- Never run on the S24 Ultra. If the WebView's renderer
  process dies (memory), `webview_flutter` has no hook and Android closes the
  app: watch for that on the device.
- The reflection probe switches at the midpoint of a change of hour; it is
  not blended like the lightmaps.
- Option parts (other cabinet styles, double fridge, built-in range, rugs,
  blind, plants) have no lightmap UVs: probe light and live lights only.
- The lightmaps are 8-bit, 2048: crevices are lifted by `BOUNCE_FLOOR` rather
  than baked right. A rebake with padding belongs to the lighting round.
- The fridge shelves' backdrop (`assets/scenes/kitchen/fridge-interior-r24`)
  is a still that no longer matches the live fridge behind it.
- The garden outside the window is not in the mobile model; the sky is a shader.
- Look, from the two review passes of round 1: cabinet door grooves are still
  dark by day (lifted, not rebaked); a green-yellow sheen on the fridge side
  at golden hour (the 8-bit golden lightmap may clip); night is one pool of
  light with dark furniture (the lamp is at 44 instead of the master's 53);
  rug fringe reads as a barcode from the overview; the overview is centred in
  the whole view although the today card covers its lower part.
- To watch on the phone: sparkle or a thin wrong line at the edge of the
  window light, the lamp's cone and the fridge lamps (the shadow slope uses
  screen derivatives inside a per-pixel condition); grain on cloth and
  plaster at night.
- The table shot cannot be reached in the app today: 3D opens from the stock
  tab in kitchen mode only. Whether the kitchen returns to the home tab is
  the owner's call.
