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
3. Cooked or boiled grain and legumes ("أرز مطهو", "حمص مسلوق", "cooked
   rice", not "غير مطبوخ") are counted against cooked norms (`riceCooked`
   250 g, `pastaCooked` 300 g, `grainCooked` 250 g; cooked or canned
   legumes as `legumeCanned`). Rice wine, sake and mirin never drive; a
   line only "for dusting" never drives (the main flour "with more for
   dusting" still does). Fish named as such wins over "لحم" in the name
   ("سمك أبيض اللحم"); mixed or frozen vegetables, peas and green fava are
   vegetables, not dry legumes. A piece named small weighs 0.7 of the norm.
4. Kind context: drinks count only liquid. A soup is one bowl: liquid
   (350 ml), vegetables or canned beans (150 g), dry legumes (60 g), dry
   starch (60 g) or meat (120 g) each give a bowl count, and the largest
   alone is the number. Mains ignore liquid and tomatoes/cucumbers;
   desserts count flour as dessert base and milk; dips count starch as dip
   base; salads count vegetables as salad. Cream cheese, kunafa or phyllo
   pastry, biscuits, dates, chocolate (`dessertRich`, 80 g) and oats count
   only in desserts; semolina counts as flour in a bread and nowhere else
   outside desserts. Eggs drive only in mains and salads, and only when
   there are 4 or more or nothing else can drive.
5. Same-category lines are summed, then roles (protein, starch, veg, liquid,
   batch). A role drives from 0.5 people up. Several roles share the plate
   (sum x 0.70 for two, x 0.55 for three), but the number is the best of
   the largest one, two or three roles, so a small extra role never lowers
   it: adding food never lowers the count (tested over the catalog). The
   drivers shown are the roles that set it.
6. A line that would drive but has no usable amount ("أفخاذ دجاج" with no
   weight) is unmeasured. When its role ranks above every measured driver
   (the chicken is unweighed, only the potatoes are), there is no value
   (`unmeasuredDriver`): the app asks. Another unmeasured driving role makes
   the result low; an unmeasured line in a measured role keeps it from high.
   Lines "for serving" or "to taste" do not count.
7. `servingsComputed = clamp(round(p), 1, 20)`, range `[floor(0.8p), ceil(1.2p)]`.
   Confidence: none without a driver; low when roles that feed at least
   one person disagree by more than 2.5x, more than 40% of the measured
   mass is not understood, every driver came from piece estimates (except
   natural pieces), one driver feeds under 1.5, or a driving role has no
   amount; high only with 2+ roles that each feed at least one person,
   within 1.6x, 80% mapped and nothing unmeasured in them; otherwise
   medium. No value (`tooUncertain`) under 1.5 people, a low result under
   2.5, a result above the clamp that is not high, and, without a source to
   check it, more than 8 (low), 12 (medium) or 16 (high) people; desserts
   are cut into pieces, so 14, 16 and 20.
8. Source check: implied per-person amount of the main driver
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

The engine computes a value for **577** recipes, 237 of them without a source value. **694** recipes end up with a yield the app can scale; 237 have none, each with an explicit reason below. Median source / computed ratio: 1.1.

| final source of the number | recipes |
|---|---|
| computed, no source value | 237 |
| computed, source value rejected | 4 |
| nothing | 237 |
| plausible source value | 296 |
| source kept (engine low confidence) | 5 |
| source kept (engine medium confidence) | 35 |
| source only (engine found no driver) | 117 |

| confidence | recipes |
|---|---|
| high | 65 |
| low | 72 |
| medium | 440 |
| none | 354 |

| computed people | recipes |
|---|---|
| 2 | 58 |
| 3 | 138 |
| 4 | 119 |
| 5 | 77 |
| 6 | 58 |
| 7 | 55 |
| 8 | 20 |
| 9-20 | 52 |

| reason a source value was rejected | recipes |
|---|---|
| sourceInflated | 4 |

| reason there is no computed value | recipes |
|---|---|
| driverTooSmall | 40 |
| noDriverIngredient | 40 |
| noMeasuredDriver | 144 |
| notApplicable | 15 |
| tooUncertain | 87 |
| unmeasuredDriver | 28 |

| largest mismatches | source | computed | reason | drivers |
|---|---|---|---|---|
| eg-mesaqaa-bel-lahma | 12 | 4 | sourceInflated | mince:beef=454g, vegMain:eggplant=525g |
| eg-mesaqaa-bel-lahma | 12 | 4 | sourceInflated | mince:beef=454g, vegMain:eggplant=525g |
| bc650-fish-curry | 5 | 2 | sourceInflated | fish:bc650-fish-curry-ing-12=400g, vegMain:bc650-fish-curry-ing-8=250g |
| fi650-56111 | 6 | 3 | sourceInflated | couscous:fi650-56111-i13=270g, potatoMain:fi650-56111-i7=200g, vegMain:fi650-56111-i10=300g |
<!-- servings-report:end -->

Duplicate ids in the corpus (for example `eg-ghorayeba`, `lv-shish-barak`,
`eg-mesaqaa-bel-lahma`) appear twice in the mismatch list.
