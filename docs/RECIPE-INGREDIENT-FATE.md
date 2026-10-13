# Ingredient fate research

This research contract records evidence that an added ingredient may have a different fate from the final edible dish. It does not approve identities, quantities, retention factors, nutrient calculations or runtime imports.

## Current files

- `data/recipes/ingredient-fate/soaking-review.json`: two unreviewed baking-soda observations for Hummus I and Mushy Peas, with six exact method-step references.
- `tool/recipes/validate-ingredient-fate.mjs`: strict validation against the existing authoritative English recipe reader.
- `tool/recipes/validate-ingredient-fate.test.mjs`: seven behavioral tests, including changed source/steps, numerical retention, injected approvals, provenance and duplicates.

```powershell
node tool/recipes/validate-ingredient-fate.mjs
node --test tool/recipes/validate-ingredient-fate.test.mjs tool/recipes/review-target.test.mjs tool/recipes/recipe-review-reader.test.mjs
```

## Contract

Each observation pins the existing exact `reviewTarget`: source revision and SHA, parser versions, ingredient line identity/text and full derived recipe fingerprint. `methodSteps` holds ordered zero-based indices, source step numbers and exact text. Source attribution, licence and modification notice must match every observed recipe, with no missing or duplicate provenance.

`retainedIngredientFraction` and `nutrientRetention` must both be null. They describe different questions: how much ingredient remains, and what happens to each nutrient. Zero, one, guessed coefficients and embedded approval/selection fields are rejected. `requiresReview` stays true; both statuses explicitly remain unreviewed. The validator always reports zero runtime-ready observations. Interpretation is a research annotation, not an automatically proven scientific conclusion.

The Hummus source includes soaking, rinsing, pouring water out and optional reservation of some cooking water. The Mushy Peas source includes soaking and draining before new water. Neither establishes retained baking soda or sodium. The original ingredient quantities are not silently reduced or treated as fully consumed.

## Future calculation boundary

Added quantities used for stock/cost, edible retained ingredients and nutrient-specific transformations require separate explicit evidence before future engine integration. This bank changes no current runtime rule: confirmed cooking still owns stock deductions and frozen history. It does not introduce an automatic waste deduction, clinical rule, food substitution, universal nutrient multiplier or all-or-none retention assumption.

Wikibooks attribution/change notices and CC BY-SA obligations travel with each observation. Page-specific exceptions remain unreviewed. Current hashes and re-extraction establish local consistency, not independent source authenticity. The CLI rejects an existing English collector lock; keep collector/indexer stopped during validation. The point-in-time lock check is not a transaction. French records require their own reviewed reader integration.

Next: review explicit choices and quantity/form decisions alongside these anchors, then design a separate reviewed runtime admission step. Never promote source observations by filling unknowns with zero or refreshing stale targets automatically.
