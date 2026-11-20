# Servings engine

Owner directive: the app decides how many people a recipe feeds from its own
portion norms. A yield stated by the source only confirms the number when it
exists; when it is missing the app does not need it. Anchor: one person's dry
pasta is about 200 g.

## Files

| file | role |
|---|---|
| `data/ingredients/portion-norms.json` | per-person norms (amount, plausible band, cup and piece weights, role), units, rules and thresholds |
| `data/ingredients/portion-categories.json` | ingredient -> norm mapping: canonical ids, name and raw-id overrides, deny-list, ordered keywords, dish kinds, driver priority |
| `lib/domain/servings_engine.dart` | the engine, pure Dart (no I/O) |
| `lib/domain/servings_tables.g.dart` | the tables compiled in (generated, do not edit) |
| `tool/recipes/servings-engine.mjs` | node mirror of the engine; `--emit-dart` writes the tables, `--check` fails when stale |
| `tool/recipes/servings-report.mjs` | runs the corpus, writes `data/recipes/servings-report.json`, `test/fixtures/servings-parity.json` and the stats below |
| `tool/recipes/publish-library.mjs` | writes the four fields on every published index row and recipe body |
| `tool/recipes/import-candidates.mjs` | a candidate without servings imports when engine confidence is at least medium |

After changing a table: `node tool/recipes/servings-engine.mjs --emit-dart && node tool/recipes/servings-report.mjs`.

## Algorithm

1. Dish kind from the recipe category (main, soup, drink, dessert, bread,
   salad, dip, base). Bases (sauces, spice mixes, doughs) are not applicable.
2. Each non-optional measured line is mapped to a norm: canonical id
   (`idMap[id] ?? id`), exact vocabulary name or alias, otherwise a known
   vocabulary item never drives, then the deny-list, then ordered keywords
   (liver before chicken, mince before meat, bone-in before boneless). The
   amount is converted to g, ml or a count (mass, volume, cup by density,
   pieces by piece weight); unknown units are skipped, never fatal.
3. Kind context: soups and drinks count only liquid; mains ignore liquid and
   tomatoes/cucumbers; desserts count flour as dessert base and milk; dips
   count starch as dip base; salads count vegetables as salad; eggs drive
   only without another protein.
4. Same-category lines are summed, then roles (protein, starch, veg, liquid,
   batch). A role drives from 0.5 people up. One role: its people. Several
   roles share the plate: sum x 0.70 (2 roles) or x 0.55 (3).
5. `servingsComputed = clamp(round(p), 1, 20)`, range `[floor(0.8p), ceil(1.2p)]`.
6. Confidence: none without a driver; low when roles that feed at least one
   person disagree by more than 2.5x, more than 40% of the measured mass is
   not understood, every driver came from piece estimates (except natural
   pieces: whole chicken, chicken pieces, shanks, fish, eggs, cans, tofu), or
   one driver feeds under 1.5; high with 2+ roles within 1.6x and 80% mapped;
   otherwise medium.
7. Source check: implied per-person amount of the main driver
   (`per x p / stated`) inside its band keeps the source. Outside it, the
   computed number wins with a reason (`sourceCountsPieces`,
   `sourceInflated`, `mappingGap`, `driverAmbiguous`), except when the engine
   is low confidence (`sourceKeptLowConfidence`, source kept).

## In the app

- `CatalogRecipe.servings` stays the source value. `effectiveServings`:
  stated value, unless the library build stored a rejection
  (`servingsBasis.source == computed`); without a stated value, the engine's
  number (stored fields, or computed on the device for recipes published
  before the fields and for the user's own). A stated value is never
  overridden at runtime, so reviewed yields and personal recipes keep theirs.
- `hasKnownYield`, `forServings`, `ScaledCatalogRecipe`, `canPlanMonth`
  (`SofraController.rowServings`), the stock preview and sharing use it.
- The four fields survive `toJson`, so planned and cooked revisions scale the
  same way the detail screen showed. A user yield review strips them.
- Recipe detail: a "serves N" tag; when the app computed it (or the user set
  it) a muted (i) opens a sheet with one basis line
  (`servingsInfoBasis`), `servingsInfoLow` when confidence is low, and the
  existing review counter (`servingsInfoAdjust`). The yellow question shows
  only when no number exists. Cook now and planning follow `hasKnownYield`.

## Decisions that differ from the first spec

- Runtime never rejects a stated yield; only the library build does (see above).
- A low-confidence result does not reject a source value.
- Agreement for confidence only counts roles feeding at least one person;
  cup conversions are not treated as low confidence (piece-only estimates are).
- Data fixes kept in portion-categories.json, not in the shared directory:
  `idMap` sends `meat` to chicken (`rawOverrides`), and the vocabulary files
  minced meat under beef (`nameOverrides`).
- Pieces counted in the steps are not parsed yet; a source that counts pieces
  is only flagged (`sourceCountsPieces`).

## Corpus run

<!-- servings-report:start (generated by tool/recipes/servings-report.mjs) -->
Corpus: **931** recipes (789 catalog, 142 candidates). The source states servings for 457; 474 have none.

The engine computes a value for **668** recipes, 292 of them without a source value. **749** recipes end up with a yield the app can scale; 182 have none, each with an explicit reason below. Median source / computed ratio: 1.25.

| final source of the number | recipes |
|---|---|
| computed, no source value | 292 |
| computed, source value rejected | 86 |
| nothing | 182 |
| plausible source value | 243 |
| source kept (engine low confidence) | 47 |
| source only (engine found no driver) | 81 |

| confidence | recipes |
|---|---|
| high | 102 |
| low | 159 |
| medium | 407 |
| none | 263 |

| computed people | recipes |
|---|---|
| 1 | 69 |
| 2 | 100 |
| 3 | 144 |
| 4 | 133 |
| 5 | 85 |
| 6 | 39 |
| 7 | 40 |
| 8 | 13 |
| 9-20 | 45 |

| reason a source value was rejected | recipes |
|---|---|
| driverAmbiguous | 16 |
| sourceCountsPieces | 5 |
| sourceInflated | 65 |

| reason there is no computed value | recipes |
|---|---|
| driverTooSmall | 49 |
| noDriverIngredient | 42 |
| noMeasuredDriver | 156 |
| notApplicable | 16 |

| largest mismatches | source | computed | reason | drivers |
|---|---|---|---|---|
| bc650-ukrainian-vareniki | 45 | 2 | sourceInflated | vegMain:bc650-ukrainian-vareniki-ing-8=525g |
| eg-ghorayeba | 35 | 4 | sourceCountsPieces | dessertBase:flour=250g |
| eg-ghorayeba | 35 | 4 | sourceCountsPieces | dessertBase:flour=250g |
| fiw650-50500 | 16 | 2 | sourceInflated | eggsMain:fiw650-50500-i11=3count, legumeCanned:fiw650-50500-i4=400g |
| bc-tajine | 12 | 2 | sourceInflated | chickenBoneless:bc-tajine-ing-1=454g, potatoMain:bc-tajine-ing-3=200g |
| eg-mesaqaa-bel-lahma | 12 | 3 | sourceInflated | meatBoneless:beef=454g, vegMain:eggplant=600g |
| lv-shish-barak | 8 | 2 | sourceInflated | mince:ground-beef=350g |
| fi650-51917 | 4 | 1 | sourceInflated | eggsMain:fi650-51917-i8=1count, vegMain:fi650-51917-i12=150g |
| eg-mesaqaa-bel-lahma | 12 | 3 | sourceInflated | meatBoneless:beef=454g, vegMain:eggplant=600g |
| lv-shish-barak | 8 | 2 | sourceInflated | mince:ground-beef=350g |
| bc650-damper | 15 | 5 | sourceCountsPieces | flourBread:bc650-damper-ing-1=500g |
| fiw650-52212 | 6 | 2 | sourceInflated | soupLiquid:fiw650-52212-i1=720ml |
<!-- servings-report:end -->

Duplicate ids in the corpus (for example `eg-ghorayeba`, `lv-shish-barak`,
`eg-mesaqaa-bel-lahma`) appear twice in the mismatch list.
