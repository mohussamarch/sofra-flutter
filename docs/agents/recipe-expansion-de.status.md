# German Wikibooks lane status

- Active checkout: `E:\work\SOFRA\app`.
- Source: official German Wikibooks `Kochbuch/`, namespace 0; siteinfo verifies sitewide CC BY-SA 4.0. Page exceptions remain unreviewed.
- Official requests: 20 successful total. Eighteen response wrappers are archived (siteinfo + fifteen continuation pagesets + two new prefix-recovery pagesets); two original pageset bodies were lost in the documented filename-collision incident. An additional local collector invocation failed before HTTP (0 requests, no backoff); fixed before successful continuation batches.
- Current evidence: 850 distinct fixed page revisions; 544 parser candidates; 4,635 ingredient lines; 3,136 preparation steps/paragraphs; 306 source pages retained as unparsed.
- Unknowns preserved: all canonical amounts/units/food bindings, 3,136 durations, servings, cuisine, and nutrition remain unknown/null; 0 runtime imports, nutrient bindings, and approved cuisines.
- Latest bounded batch: 3/3 official HTTP 200 requests. Quota at start: 86% primary, 88% weekly, ordinary allowed. Extractor, response/sidecar hash and unique-ID integrity checks, and null invariants passed.
- Next continuation: `gapcontinue=Kochbuch/_Vegetarisches_Schnitzel_Hawaii`, `continue=gapcontinue||`. Recheck quota, lock, and backoff before another request.
- Lane files: `data/recipes/source-discovery/de-wikibooks/`; tools in `tool/recipes/`. Root owns shared docs and Git integration.
