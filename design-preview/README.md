# Sofra interactive design preview

Run `node design-preview/serve.cjs` from the repository root, then open http://127.0.0.1:8766/ . This is the canonical source for future design edits.

Arabic RTL, responsive, original code-drawn SVG isometric kitchen and flat animated characters. Includes onboarding, family customization, fridge/freezer/pantry shelves, explicit purchase units, leftovers, recipe planning, seat swapping, cooking confirmation and history. Data stays in this browser under `sofra.design.prototype.v1`; this preview does not access Firebase or the installed app's data.

No generated images are used by the prototype. No audio or music. User requested cancellation of the draft sound effects.

See `PROTOTYPE-HANDOFF.md` for implementation scope and verified user flows. Historical concepts and browser screenshots remain in `../../sofra-concept-v1` in the workspace.

Latest: morning on every new session, sunlight from the left window, detailed isometric kitchen with unlabelled interactive appliances, focused opening/zoom motion, and at least six four-slot shelves plus leftovers. Additional rows preserve all stock. No sounds.

Verification: `node --check design-preview/prototype.js`; with Playwright installed and Microsoft Edge available, run `node design-preview/check.cjs` while the server runs. It uses isolated browser contexts and writes actual screenshots to `design-preview/screenshots/`. Set `NODE_PATH` to an existing Playwright installation if necessary. No Firebase data is accessed.
