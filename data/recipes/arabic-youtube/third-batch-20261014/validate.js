'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const batchPath = path.join(__dirname, 'recipes.json');
const batch = JSON.parse(fs.readFileSync(batchPath, 'utf8').replace(/^\uFEFF/, ''));
const prior = [
  path.join(root, '2026-10-first-batch.json'),
  path.join(root, 'second-batch-20261014', 'recipes.json'),
].map((p) => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '')));
const ids = new Set(prior.flatMap((b) => b.recipes.map((r) => r.recipeId)));
const errors = [];
if (batch.recipes.length !== 3) errors.push(`expected 3 recipes; got ${batch.recipes.length}`);
for (const [n, r] of batch.recipes.entries()) {
  const at = `recipes[${n}]`;
  if (!r.recipeId || ids.has(r.recipeId)) errors.push(`${at}: missing or non-unique recipeId ${r.recipeId}`);
  ids.add(r.recipeId);
  if (r.sourceKind !== 'creator-website' || r.sourceVideoId !== null || r.youtubeDerived !== false) errors.push(`${at}: website provenance mismatch`);
  if (!r.sourceUrl?.startsWith('https://choumicha.ma/') || r.evidenceUrl !== r.sourceUrl) errors.push(`${at}: missing official source URL`);
  if (r.sourceApproval !== null || r.reuseRights !== null) errors.push(`${at}: approval/rights must remain unknown`);
  if (r.cuisine?.status !== 'source-declared-pending-human-review' || !r.cuisine.evidenceUrl || !r.cuisine.evidence) errors.push(`${at}: cuisine source evidence/review status missing`);
  if (!Array.isArray(r.ingredients) || !r.ingredients.length || !Array.isArray(r.steps) || !r.steps.length) errors.push(`${at}: ingredients or method missing`);
  for (const [i, x] of (r.ingredients || []).entries()) {
    if (!x.label || !x.labelAr || !x.sourceQuantityText || x.amount === undefined || x.unit === undefined || x.evidenceUrl !== r.sourceUrl) errors.push(`${at}.ingredients[${i}]: incomplete bilingual source-backed fact`);
    if (x.amount === null && x.unit !== null) errors.push(`${at}.ingredients[${i}]: unknown amount must have null unit`);
  }
  for (const [i, s] of (r.steps || []).entries()) if (!s.text || !s.textAr || s.evidenceUrl !== r.sourceUrl) errors.push(`${at}.steps[${i}]: incomplete bilingual source-backed method`);
  if (!Array.isArray(r.unknowns) || !r.unknowns.length) errors.push(`${at}: source unknowns not documented`);
}
if (batch.sourcePolicy.sourceApproval !== null || batch.sourcePolicy.reuseRights !== null || batch.sourcePolicy.httpBodyHash !== null) errors.push('source policy must not invent approvals, rights, or body hash');
const cookbook = fs.readFileSync(path.join(__dirname, 'COOKBOOK.ar.md'), 'utf8');
for (const r of batch.recipes) if (!cookbook.includes(r.sourceUrl)) errors.push(`cookbook missing source ${r.recipeId}`);
if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
else console.log(`OK: ${batch.recipes.length} website recipes; ${batch.recipes.reduce((s,r)=>s+r.ingredients.length,0)} ingredients and ${batch.recipes.reduce((s,r)=>s+r.steps.length,0)} steps; all source-linked, bilingual, pending review; unique IDs against prior 8.`);
