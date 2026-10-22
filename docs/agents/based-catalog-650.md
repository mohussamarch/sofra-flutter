# Based catalog 650 curation — agent handoff

## Scope and baseline

- Active checkout: `E:\work\SOFRA\app`, base commit `533891c1` as assigned by coordinator. Only this agent's recipe folder and two agent notes were edited.
- Source pack: `data/recipes/curated-local/based-cooking-20261015`, pinned at `9d4a31a040eedd61e4fb608cb0c114ff9a7c4dd2`.
- Structural eligibility: 440 saved snapshots passed the pack parser's ingredient-and-method acceptance. This is a source-shape count, not culinary/runtime approval.
- After 16 exact title overlaps, 4 held candidates, and 4 explicit external attribution/source-cue pages (disjoint union 24), 416 remain before semantic-dedup review. Moroccan/Omani tags were not found; no national cuisine was inferred.

## Completed chunks

- `data/recipes/catalog-650-20261021/based/chunk-001.json` and `.provenance.json`: 25 candidate recipes and pinned source evidence. Root reviewed/froze this chunk.
- `data/recipes/catalog-650-20261021/based/chunk-002.json` and `.provenance.json`: 25 Arabic candidates, with main-dish priority. Includes Indonesian duck, goulash, Irish stew, chicken tacos/tikka/curries, cochinita pibil, paella, biriyani, mapo tofu, paneer, carnitas, jambalaya, Yibin noodles, roast chicken, and others.
- `data/recipes/catalog-650-20261021/based/chunk-003.json` and `.provenance.json`: 25 Arabic candidates, mostly full main dishes, with source-compared methods and indexed ingredient crosswalks. Eight additional drafts were attached to the pinned snapshots and merged into this chunk.
- `data/recipes/catalog-650-20261021/based/chunk-004.json` and `.provenance.json`: 25 additional Arabic candidates spanning full mains and substantive soups; includes Philippine chicken dishes, Flemish carbonade, Finnish salmon soup, Maltese aljotta, Portuguese stone soup, and others.
- `data/recipes/catalog-650-20261021/based/chunk-005.json` and `.provenance.json`: 25 additional candidates emphasizing chicken and pork mains, substantial soups, salads, and curries from the remaining pinned source pool.
- `data/recipes/catalog-650-20261021/based/chunk-006.json` and `.provenance.json`: 25 additional candidates, including European and North American mains, Thai soup/curry, lentil dishes, salads, and useful cooking basics.
- `data/recipes/catalog-650-20261021/based/chunk-007.json` and `.provenance.json`: 25 additional Arabic candidates, including Swiss Älplermagronen, Dutch pea soup, Dominican spaghetti, Filipino squash, Greek pastitsio, Peruvian ceviche, Galician octopus, and other full meals.
- `data/recipes/catalog-650-20261021/based/chunk-008.json` and `.provenance.json`: 25 additional Arabic candidates with main dishes, soups, pasta, and breakfast recipes. Candidates with method/ingredient-list mismatches were held and replaced before freezing.
- `data/recipes/catalog-650-20261021/based/chunk-009.json` and `.provenance.json`: 25 further Arabic candidates spanning mains, soups, stews, salads, breakfast, snacks, and baked items; source section headings and an equipment line are explicitly unmapped in the crosswalk.
- `data/recipes/catalog-650-20261021/based/chunk-010.json` and `.provenance.json`: 25 additional candidates focused on pasta, taco filling, breads, breakfast, snacks, and baked goods, with methods translated against the pinned source snapshots.
- `manifest.json` tracks 250 serialized candidate rows across the first ten chunks; coordinator may hold semantic duplicates at integration.

## Chunk-002 verification

- 25 recipes and 25 provenance rows; unique recipe and ingredient IDs.
- Every row carries `metadataPolicy: source-unknowns-v1`; every serialized note contains actual source URL, pinned revision, and source snapshot SHA-256.
- Measured amount rows have `display: null` so computed scaled quantities render correctly; null amounts use `scale: false`; per-step durations remain null.
- Source URLs/revision/hash, full original raw source text, source ingredient lines, explicit indexed crosswalks, source methods, author, and rights evidence are carried in the sidecar.
- A few source quantities or linked-line differences remain intentionally represented as raw source facts and null quantities; root should review mapped source equivalents before shared integration. `seasoning:` in the chicken taco ingredient block is a section heading, not a food ingredient.
- No exact-title duplicates with the current 65 catalog were selected. Semantic duplicates remain subject to coordinator review.

## Rights and limits

- Excluded: couscous (explicit credit/link to another publisher), Japanese noodle soup (says inspired by other recipes), kettle chips (explicit external recipe credit/link), Tuscan pork roast (explicit adaptation credit/link).
- The four held items remain excluded: chicken satay, butter chicken masala, ardei umpluti, Yorkshire pudding.
- No application tests or runtime import were run. Source quantities, methods, cuisine claims, metadata, and time/yield conflicts were preserved conservatively; candidates are not cooking-validated and carry no nutrition or medical claims.
- Chunk-008 validation found 25 recipe/provenance rows, 214 ingredient crosswalk rows, and zero structural mismatches. Every source index/text, ingredient ID, accepted amount/unit/scale state, metadata policy, step-duration unknown, notes URL/revision/SHA, source path, raw snapshot, and rights evidence was checked. Explicit source prep/cook/yield metadata was retained only where a scalar was supported; ranged or non-serving yields remain null and are stated in notes.
- Chunk-009 validation found 25 recipe/provenance rows and 188 ingredient crosswalk rows with zero structural mismatches; source index/text and linked quantities, source paths, raw snapshots, rights evidence, URL/revision/SHA notes, policy, and measured display behavior were checked. Exact source-title scan against chunks 001–008 found no duplicate title.
- Chunk-010 validation found 25 recipe/provenance rows and 172 ingredient crosswalk rows with zero structural mismatches; source index/text and linked quantities, source paths, raw snapshots, rights evidence, URL/revision/SHA notes, policy, and measured display behavior were checked. Exact source-title scan against chunks 001–009 found no duplicate title.
- The current `CatalogRecipe` parser requires numeric servings/times/durations; per coordinator direction this candidate bank preserves nulls for the separate backend reader to support.

## Next action

- Chunks 003–010 are frozen for coordinator review. Coordinator owns shared index/STATUS/HANDOFF and Git. This worker did not commit or touch them.
