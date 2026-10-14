# product-label-evidence-2000 — full handoff

## Ownership and base

- Active checkout: E:\work\SOFRA\app, branch main; root-reported starting base fc7912e. The assignment's app/main notation meant checkout/branch, not a subdirectory; root clarified before any edit.
- Owned only data/food/product-label-evidence/20261014/**, tool/food/validate-product-label-evidence.mjs, tool/food/validate-product-label-evidence.test.mjs, and this handoff/status pair.
- Root owns shared docs, queue, Flutter reader/assets/pins, Git commit/push and outside-Git delivery receipt. Ownership of all six files returned to root at handoff.
- Read STATUS first, AGENTS, HANDOFF§72 allergen subsection, previous allergen helper handoff/README, and relevant canonicalAllergenId/AllergenDeclaration/FoodRecord snippets. Existing runtime/source banks/shared docs were not edited.

## Evidence actually retrieved

Six bounded web tool calls (search/open/click batches), primary manufacturer pages only used for claims. No repeat failure, login, media/body download or source gate bypass.

1. [Domty Bran Toast](https://domty.org/product/bran-toast/): heading line 21 and dedicated allergen statement inside Ingredients accordion line 24. Contains gluten, soy and milk; possible egg traces.
2. [Domty Milk Toast](https://domty.org/product/milk-toast/): same anchored page sections. Contains gluten, soy and milk; possible egg traces.
3. [Domty Brioche Toast](https://domty.org/product/brioche-toast/): same sections. Contains gluten, soy, milk/products and egg; no precautionary declaration observed. The absent precautionary sentence is not an absence claim.
4. [Domty High Protein Toast with Chia Seeds](https://domty.org/product/high-protein-toast-with-chia-seeds/): same sections. Contains gluten, soy and milk/products; possible egg traces.
5. [Juhayna dairy category](https://www.juhayna.com/brands-category/juhayna-dairy/): readable product prose/pack options, no explicit allergen statement in retrieved text. No product declaration imported. Skimmed-milk quantity wording is ambiguous; nutrition not imported.
6. Almarai full-fat-fresh-milk URL attempt recorded in bank: web internal error/inaccessible. The attempted URL is not confirmed as an existing product page. No facts accepted and no retry. Restricted search did not reveal an accessible explicit Almarai statement or a suitable Maggi/Nestlé/Americana/Halwani product statement.

Four exact product names/variants, 13 contains and three mayContain observations, zero freeFrom claims, zero verified market/pack/version/GTIN matches, zero runtime approvals. Domty's footer identifies an Egypt contact address only; it is stored as contactCountryContext, not as sourceMarket. This is useful Egypt-manufacturer source evidence with applicability to EG/SA SKUs still unknown, not four certified Egyptian labels or Saudi coverage.

## Data and validator

- Bank: data/food/product-label-evidence/20261014/manufacturer-evidence.json; concise limits/commands in adjacent README.md.
- Top level: schemaVersion=1, batchId, scope=research-only-manufacturer-web-declarations, capturedAt, approvals, sources, products.
- Product sections: pageFacts, declarations, pendingLocalProductMatch, runtimeFoodRecordApproval, unknowns. All local identity review/runtime approval values remain pending/null/false.
- Exact proposed mappings only: Gluten→gluten, Soy→soy, Milk/Milk and Milk Products→milk, Eggs→egg. Ingredient wheat was not promoted; no family/member expansion or alias/runtime change.
- packQuantity/labelVersion/gtin/form/sourceMarket/sourceMarketEvidence/nutrition all null. No invented prices, quantities, units, transformations or zero-filled49 profile.
- Publication date/scope unknown; retrievedAt is completed observation capture UTC. Rights unknown, archived=false/bodySha256=null. No body authentication or redistribution permission claimed.
- The reviewed source catalog and bounded explicit statement grammar reject unknown fields, spoofed URL/authority/access, unsupported/mislinked declarations, duplicate IDs/status claims, quantity/market guesses, false absence/freeFrom, ingredient-based mapping, local ID/runtime/clinical/current-law promotion, archive/hash/rights fabrication, chronology and excerpt budgets.
- Offline validation checks local consistency, not truth of unarchived upstream text. Root can pin exact bank SHA for the separately owned read-only Flutter reader.

## Verification actually run

- First test invocation failed import because validator did not exist. A minimal empty stub then ran all11 tests with11 expected assertion failures.
- First implementation reproduced a greedy regex bug: the trace sentence became part of contains text. Exact standalone reproduction demonstrated boundary error and corrected sentence grammar; no source facts were changed.
- node --test tool/food/validate-product-label-evidence.test.mjs: 11 passed, 0 failed.
- node tool/food/validate-product-label-evidence.mjs: exit0, sources6/retrieved5/products4/contains13/mayContain3/verifiedMarketProducts0/runtimeApprovals0.
- Actual bank SHA256: 1428c31beb18be0c8800b111f9f0ce0e79f84afe994961b8ca16cd90639b6f67. This is the local bank file hash, not a source body hash.
- No Flutter/analyze/full suite run by this helper: no runtime Dart was owned or changed. No Git mutation/commit/push performed.
- Actual own quota before new source batch: primary3%/weekly31%, ordinary allowed. Final observed20:08:59UTC:23%/35%, ordinary allowed. No credits purchased or reset used; default90 guard preserved.

## Limits and exact next action

Root: review the six owned files; complete the separately owned read-only Flutter repository and source-bank pins/tests; update shared queue/STATUS/HANDOFF with partial allergen evidence progress; commit/push and write receipt. Do not mark EG/SA market label coverage or runtime/clinical/current-law approval complete.

Next source unit after fresh quota: obtain a readable exact market/pack/version label or manufacturer SKU sheet for one candidate; preserve the web observation and add separate reviewed evidence, then explicitly match the local product. For Saudi coverage, obtain an accessible official manufacturer product declaration with stated Saudi applicability. New sourced quantities/markets/nutrition need a reviewed schema extension; they cannot be filled from brand origin or ingredient absence.

No UI/Firebase/billing/APK/audio/image/user-decision/server changes. No preview process inspection or operation performed; root retains existing preview ownership and must include its actual state in final delivery.
