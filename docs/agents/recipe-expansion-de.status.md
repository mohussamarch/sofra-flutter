# German Wikibooks lane status

- Active checkout: `E:\work\SOFRA\app`.
- Source: official German Wikibooks `Kochbuch/`, namespace 0; siteinfo verifies sitewide CC BY-SA 4.0. Page exceptions remain unreviewed.
- Official requests: 8 successful total across the original, continuation, and recovery batches; no failures/retries. Six response wrappers remain archived (siteinfo, three continuation pagesets, two new prefix-recovery pagesets); the two original pageset responses were lost to the filename-collision incident. Latest pre-recovery quota: 35% primary, 80% weekly, ordinary allowed.
- Current evidence set: 250 distinct fixed page revisions (100 fresh prefix recovery + preserved 150-page continuation slice); 177 parser candidates; 1,493 ingredient lines; 998 preparation steps/paragraphs; 73 source pages retained as unparsed.
- Unknowns preserved: all 1,493 canonical amount/unit/food bindings, 998 durations, servings, cuisine, and nutrition remain unknown/null; 0 runtime imports, nutrient bindings, and approved cuisines.
- Extractor and archive-safety regression passed. New recovery retrieval timestamps/hashes are explicit; overwritten original 100-page raw response bodies were unrecoverable and are not presented as original evidence. Details: `docs/agents/recipe-expansion-de.md`.
- Next continuation: `gapcontinue=Kochbuch/_Gnocchi_mit_Lauch_und_Schinken`, `continue=gapcontinue||`. Recheck quota, lock, and backoff before another request.
- Lane files: `data/recipes/source-discovery/de-wikibooks/`; tools in `tool/recipes/`. Root owns shared docs and Git integration.
