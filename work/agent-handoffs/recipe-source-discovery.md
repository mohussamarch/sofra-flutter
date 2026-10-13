# French Wikibooks source discovery

## Scope and outcome

Read-only discovery against the official French Wikibooks MediaWiki API at https://fr.wikibooks.org/w/api.php. Three sequential requests were made: two succeeded and the third returned an API error. The discovery stopped on that error, so no prefix candidates or recipe sample were fetched. No bulk recipe records were collected.

## Verified source metadata

- Site name: Wikilivres; language: `fr`.
- Namespace 0 is content namespace and reports `subpages: true`; therefore `Livre de cuisine/...` subpage titles are syntactically supported in namespace 0.
- Site-wide rights reported by siteinfo: Creative Commons Attribution-Share Alike 4.0; rights URL: https://creativecommons.org/licenses/by-sa/4.0/deed.fr.
- This is site-level metadata. No candidate page was inspected for page-specific exceptions. Do not infer the French site’s license from English Wikibooks; verify relevant page attribution and any exceptions before ingestion.

## Category result

`Catégorie:Recettes de cuisine` reports size 8: 1 direct page, 7 subcategories, 0 files. Its only direct page is `Livre de cuisine/Intersection de recettes` (page ID 46290, namespace 0). This direct category size is not a count of all recipe pages and was not used as such.

## Request log

1. Siteinfo (`general|rightsinfo|namespaces|namespacealiases`) — retrieved `2026-10-13T17:02:10.409Z`, HTTP 200, response SHA-256 `caf88a574fcddaa603a6b0bc5dbb226357638fbdaea9bfc8c904a36102fe7d7d`; archived at `data/recipes/source-discovery/fr-wikibooks/01-siteinfo.json`.
2. Category members and categoryinfo — retrieved `2026-10-13T17:03:38.979Z`, HTTP 200, response SHA-256 `3dd2cf6207d21273c52227aeb8b9a746b4c267a9d6d088d5e9566d556b07cfb3`; archived at `data/recipes/source-discovery/fr-wikibooks/02-category.json`.
3. Namespace-0 allpages prefix query for `Livre de cuisine/` — retrieved `2026-10-13T17:03:55.179Z`, HTTP 200 but API JSON error `badvalue`: `apfilterredir=non` was not recognized. Response SHA-256 `9e93b6bf7198da2ee47ed3e0caa14dc0bbdc68e55cef78a53c455cb18262ca7f`; archived at `data/recipes/source-discovery/fr-wikibooks/03-prefix-candidates.json`.

Stopped immediately on request 3 as instructed; there are no retrieved prefix candidates, sample page headings, ingredient template, or procedure list patterns to report. Recorded a 10-minute cooldown through `2026-10-13T17:13:55.179Z`; root may decide whether to resume after that gate with a corrected query and its own request budget.

## Files and validation

Archives preserve request URL, request/retrieval timestamps, HTTP status, response SHA-256, and parsed response/error. `status.json` records the stop condition and cooldown. The archive response hashes above are hashes of raw response bodies, not the archive JSON files. No runtime/license approval is implied.
