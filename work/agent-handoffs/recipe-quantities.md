# Source quantity candidate parser handoff

## Purpose

Added a small offline parser for candidate quantities transcribed from recipe ingredient lines. It returns source-text evidence and a conservative status; it does not produce runtime-ready quantities or ingredient identities.

## API and result

Import `parseIngredientQuantity` from `tool/recipes/parse-ingredient-quantity.mjs` and pass the original ingredient line. The result preserves `sourceText`, includes `status`, candidate `amount` and canonical source `unit` only when both are unambiguous, and keeps `quantityText`, `unitText`, `remainingText`, `reason`, and `reviewStatus`. Parsed candidates have `canonicalAmount`, `canonicalUnit`, and `foodBinding` set to null.

Recognized canonical units are `g`, `kg`, `ml`, `l`, `cup`, `tbsp`, and `tsp`, for explicit English unit names/aliases. It parses positive integers/decimals, simple and mixed fractions, and common Unicode fractions. Cup amounts are flagged with `cup-volume-system-unspecified`; no mass/volume conversions are performed.

Ranges, approximation terms, zero/negative values, zero denominators, decimal commas, counts, unknown units, package descriptions, and lines without a known explicit unit remain unresolved. Original wording is retained; no first-number fallback is used for ambiguous package/count lines. Non-string input throws `TypeError`.

## Verification

- `node --test tool/recipes/parse-ingredient-quantity.test.mjs`: 6/6 passed.
- Tests cover unit aliases, decimal/fraction/Unicode parsing, cup system uncertainty, ambiguous and malformed quantities, unknown/count/package units, and source preservation/no canonical binding.
- No network calls. No source bank, app runtime, collector, shared docs, or Git changes.

## Integration constraint

The parent task may attach this object as `ingredient.quantityCandidate`, while canonical amount/unit and food binding remain null pending review. Do not use this candidate parser to scale recipes, calculate inventory, infer conversions, nutrition, or food identity. Each candidate remains `unreviewed-source-transcription`.


## Source quantity candidates — implemented

`tool/recipes/parse-ingredient-quantity.mjs` parses explicit source prefixes into `ingredients[].quantityCandidate`, separately from canonical `amount/unit/foodBinding` which remain null. Version `source-prefix-v1` currently yields 10227 candidates out of 20277 ingredient rows; 10050 remain unresolved. This is transcription coverage, not reviewed nutrition coverage.

Positive decimals, simple/mixed/common Unicode fractions and explicit g/kg/ml/l/cup/tsp/tbsp aliases are supported. Ranges, approximate amounts, packaging/counts, decimal commas and unknown units remain unresolved. Cup/spoon volume systems remain unspecified; no volume-to-mass conversion. Adjacent `200g`, leading `.5 cup`, alternatives/groups and ingredient identity still need further parsing/review. Unknowns are never filled with zero.

Each result preserves original text, remaining text, parser version, unreviewed status and source revision/hash through its recipe. Future user input may bypass source parsing and provide explicit reviewed food and quantity inputs to the calculator. The corpus itself is still outside the shipping catalogue; no automatic nutrient estimates from recipe names.

Actual checks: 7 quantity tests and 7 index tests passed within 41 recipe Node tests. Added spoon-system regression failed first, then passed after preserving ambiguity. Integration test proves parsed `1 cup` does not overwrite canonical amount or create a food binding. Raw source files remain immutable.
