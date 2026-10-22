# Foodista world cuisine candidate curation

Scope: cached selection sources in the allowed non-Asian, non-Moroccan cuisine pool. Candidate records are review artifacts; they are not operational or kitchen-tested recipes.

## Frozen chunks

- `chunk-001.json`: 20 candidates (prior batch).
- `chunk-002.json` and `chunk-002.review.json`: 20 candidates starting at the requested cursor `modern-bulk:foodista:58411`.
- `chunk-003.json` and `chunk-003.review.json`: 20 additional candidates; next selection cursor `modern-bulk:foodista:52028` (selection index 172).

Review sidecars preserve source IDs, URLs, cached source file paths, source and verified snapshot SHA-256, CC BY 3.0 declaration, raw source ingredient lines, full extracted method, cuisine title evidence, and known unknowns. Recipe notes include source URL and snapshot SHA-256. Numeric quantities and source unit wording were translated where clear; omitted, vague, alternate, or non-scalable quantities retain explicit notes/nulls. Unknown servings and times remain null. Source sequence is preserved inside a single ordered step per extracted method, with step duration null and `passive=false`.

## Holds

Excluded from these chunks: Russian Pierogi (55991; source method extraction truncated), Hungarian Beef Goulash with Potato Dumplings (57696; method terminates mid-assembly), Italian Sprinkle Cookies (51974; glaze method extraction truncated), Swedish Visiting Cake (58035; mangled ingredient quantities), Black Russian Cake (54996; title is cocktail-derived), French Toast-title rows without French cuisine evidence, and rows outside the assigned cuisine scope.

## Review state

Source and translation crosswalk recorded for 40 chunk 002/003 candidates. Root review pending. No runtime readiness, culinary approval, nutrition review, or kitchen testing is claimed.

- chunk-004.json: 20 additional records frozen; chunk-005.json: 20 further records frozen with source hash crosswalk.
- Chunk 005 attribution notes were restored for all records. British Apple Crumble omits source section headings and heat instruction from ingredients and includes the 3 tbsp water stated in the method; the source's ambiguous optional sugar remains unparsed.
- Chunk 006 generation did not produce a file because the crosswalk script had a PowerShell syntax error; no completion is claimed for it.

- chunk-006.json: 20 additional Arabic candidates frozen with 20 exact cached-source crosswalks and snapshot hashes. Schema-shape check: 20 unique recipe IDs and no missing note strings, step fields, or ingredient IDs.
- Several candidates have descriptive or unknown cuisine where the source title is not sufficient to establish national origin. They remain subject to root semantic/cuisine review; none is operationally approved.
