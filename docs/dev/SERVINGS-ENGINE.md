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

1. Dish kind from the recipe category (main, side, soup, drink, dessert,
   bread, salad, dip, base). A side portion is half a main one
   (`kindScale`). Bases (sauces, spice mixes, doughs) count only meat or
   fish (a bolognese sauce); otherwise they are not applicable.
2. Each non-optional measured line is mapped to a norm: canonical id
   (`idMap[id] ?? id`), exact vocabulary name or alias, otherwise a known
   vocabulary item never drives, then the deny-list, then ordered keywords
   (liver before chicken, mince before meat, bone-in before boneless).
   Generated line ids (`…-i3`, `…-ing-3`) name the recipe, so patterns
   never match on them. `refine` then corrects a category from a plain id
   by the name: "لحم بقري مفروم" with id `beef` is mince, "لحم غنم شقف" or
   bones are on the bone, drumsticks and breasts are chicken pieces. The
   amount is converted to g, ml or a count (mass, volume, cup by density,
   pieces by piece weight, with `pieceWeights` by name where the norm's is
   wrong: a whole cabbage is 1.5 kg); unknown units are skipped, never fatal.
3. Kind context: soups and drinks count only liquid; mains ignore liquid and
   tomatoes/cucumbers; desserts count flour as dessert base and milk; dips
   count starch as dip base; salads count vegetables as salad. Cream cheese,
   kunafa or phyllo pastry, biscuits, dates and chocolate (`dessertRich`,
   80 g) count only in desserts; flour or semolina in a dessert is 35 g a
   person. Eggs drive only in mains and salads, and only when there are 4 or
   more or nothing else can drive: two eggs bind, they do not feed.
4. Same-category lines are summed, then roles (protein, starch, veg, liquid,
   batch). A role drives from 0.5 people up. One role: its people. Several
   roles share the plate: sum x 0.70 (2 roles) or x 0.55 (3).
5. `servingsComputed = clamp(round(p), 1, 20)`, range `[floor(0.8p), ceil(1.2p)]`.
6. Confidence: none without a driver; low when roles that feed at least one
   person disagree by more than 2.5x, more than 40% of the measured mass is
   not understood, every driver came from piece estimates (except natural
   pieces: whole chicken, chicken pieces, shanks, fish, eggs, cans, tofu), or
   one driver feeds under 1.5; high with 2+ roles within 1.6x and 80% mapped;
   otherwise medium. A low-confidence result under 2.5 people, or any result
   above the clamp that is not high, becomes no value (`tooUncertain`): the
   app asks instead of showing "serves 1". So does any result under 1.5
   people.
7. Source check: implied per-person amount of the main driver
   (`per x p / stated`) inside its band keeps the source, and so does a
   stated value within a factor of `sourceKeepRatio` (2) of the computed
   one. Outside both, the
   computed number wins with a reason (`sourceCountsPieces`,
   `sourceInflated`, `mappingGap`, `driverAmbiguous`) only when the engine
   is high confidence; otherwise the source is kept
   (`sourceKeptLowConfidence`, `sourceKeptMediumConfidence`).

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
  it) a muted (i) opens a sheet with the basis: one driver names its amount
  and the per-person norm (`servingsInfoBasis`); several drivers are listed
  together (`servingsInfoBasisMany`), since the number combines them. The
  ingredient is named without the amount some names carry ("دجاج، رطل
  واحد" -> "دجاج"). `servingsInfoLow` shows when confidence is low, then the
  review counter (`servingsInfoAdjust`) with an apply button
  (`servingsInfoApply`). The yellow question shows
  only when no number exists. Cook now and planning follow `hasKnownYield`.

## Decisions that differ from the first spec

- Runtime never rejects a stated yield; only the library build does (see above).
- Only a high-confidence result rejects a source value.
- Agreement for confidence only counts roles feeding at least one person;
  cup conversions are not treated as low confidence (piece-only estimates are).
- Data fixes kept in portion-categories.json, not in the shared directory:
  `idMap` sends `meat` to chicken (`rawOverrides`), and the vocabulary files
  minced meat under beef (`nameOverrides`, and `refine` for lines whose id
  is a plain `beef` or `lamb`).
- Pieces counted in the steps are not parsed yet; a source that counts pieces
  is only flagged (`sourceCountsPieces`).

## Corpus run

<!-- servings-report:start (generated by tool/recipes/servings-report.mjs) -->
Corpus: **931** recipes (789 catalog, 142 candidates). The source states servings for 457; 474 have none.

The engine computes a value for **595** recipes, 260 of them without a source value. **717** recipes end up with a yield the app can scale; 214 have none, each with an explicit reason below. Median source / computed ratio: 1.11.

| final source of the number | recipes |
|---|---|
| computed, no source value | 260 |
| computed, source value rejected | 8 |
| nothing | 214 |
| plausible source value | 284 |
| source kept (engine low confidence) | 11 |
| source kept (engine medium confidence) | 32 |
| source only (engine found no driver) | 122 |

| confidence | recipes |
|---|---|
| high | 89 |
| low | 96 |
| medium | 410 |
| none | 336 |

| computed people | recipes |
|---|---|
| 2 | 66 |
| 3 | 147 |
| 4 | 113 |
| 5 | 90 |
| 6 | 53 |
| 7 | 45 |
| 8 | 21 |
| 9-20 | 60 |

| reason a source value was rejected | recipes |
|---|---|
| sourceInflated | 8 |

| reason there is no computed value | recipes |
|---|---|
| driverTooSmall | 46 |
| noDriverIngredient | 40 |
| noMeasuredDriver | 160 |
| notApplicable | 15 |
| tooUncertain | 75 |

| largest mismatches | source | computed | reason | drivers |
|---|---|---|---|---|
| eg-mesaqaa-bel-lahma | 12 | 4 | sourceInflated | mince:beef=454g, vegMain:eggplant=750g |
| eg-mesaqaa-bel-lahma | 12 | 4 | sourceInflated | mince:beef=454g, vegMain:eggplant=750g |
| bc650-fish-curry | 5 | 2 | sourceInflated | fish:bc650-fish-curry-ing-12=400g, vegMain:bc650-fish-curry-ing-8=250g |
| bc-tajine | 12 | 5 | sourceInflated | chickenBoneless:bc-tajine-ing-1=454g, eggsMain:bc-tajine-ing-6=8count, potatoMain:bc-tajine-ing-3=200g |
| fiw650-51916 | 6 | 3 | sourceInflated | mince:fiw650-51916-i0=454g, vegMain:fiw650-51916-i9=150g |
| lg-galayet-bandora-lahma | 4 | 2 | sourceInflated | meatBoneless:beef=300g, potatoMain:potato=200g |
| fi650-56111 | 6 | 3 | sourceInflated | couscous:fi650-56111-i13=270g, potatoMain:fi650-56111-i7=200g, vegMain:fi650-56111-i10=300g |
| lg-galayet-bandora-lahma | 4 | 2 | sourceInflated | meatBoneless:beef=300g, potatoMain:potato=200g |
<!-- servings-report:end -->

Duplicate ids in the corpus (for example `eg-ghorayeba`, `lv-shish-barak`,
`eg-mesaqaa-bel-lahma`) appear twice in the mismatch list.
