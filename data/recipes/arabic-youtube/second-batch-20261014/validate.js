const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = __dirname;
const batch = JSON.parse(fs.readFileSync(path.join(root, 'recipes.json'), 'utf8'));
const cookbook = fs.readFileSync(path.join(root, 'COOKBOOK.ar.md'), 'utf8');

assert.equal(batch.recipes.length, 2, 'Expected this bounded two-recipe batch');
assert.equal(batch.sourcePolicy.sourceKind, 'creator-website');
assert.equal(batch.sourcePolicy.youtubeDerived, false);
assert.equal(batch.sourcePolicy.sourceApproval, null);
assert.equal(batch.sourcePolicy.reuseRights, null);

for (const recipe of batch.recipes) {
  assert.equal(recipe.sourceKind, 'creator-website');
  assert.equal(recipe.sourceVideoId, null);
  assert.equal(recipe.youtubeDerived, false);
  assert.equal(recipe.sourceApproval, null);
  assert.equal(recipe.reuseRights, null);
  assert.match(recipe.sourceUrl, /^https:\/\//);
  assert.equal(recipe.evidenceUrl, recipe.sourceUrl);
  assert.ok(recipe.ingredients.length > 0);
  assert.ok(recipe.steps.length > 0);
  assert.ok(recipe.unknowns.length > 0);
  assert.equal(recipe.cuisine.status, 'source-declared-pending-human-review');
  for (const ingredient of recipe.ingredients) {
    assert.ok(ingredient.labelAr, `${recipe.recipeId}: Arabic ingredient label`);
    assert.ok(ingredient.sourceQuantityText, `${recipe.recipeId}: source quantity or explicit unspecified value`);
    assert.match(ingredient.evidenceUrl, /^https:\/\//);
    assert.ok(ingredient.amount === null || Number.isFinite(ingredient.amount));
  }
  for (const step of recipe.steps) {
    assert.ok(step.text, `${recipe.recipeId}: source-derived step summary`);
    assert.ok(step.textAr, `${recipe.recipeId}: Arabic step summary`);
    assert.match(step.evidenceUrl, /^https:\/\//);
  }
  assert.ok(cookbook.includes(recipe.title), `${recipe.recipeId}: cookbook entry`);
}

console.log(`Validated ${batch.recipes.length} complete creator-site recipe records.`);
