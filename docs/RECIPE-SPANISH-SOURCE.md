# Spanish recipe source discovery

This document preserves initial discovery evidence and the implemented research collector contract. Runtime import remains separate. Official recipe manual: [Artes culinarias/Recetas](https://es.wikibooks.org/w/index.php?title=Artes_culinarias/Recetas&oldid=390018). It specifies the plural `Artes culinarias/Recetas/` path. Category search also exposed singular `Artes culinarias/Receta/`; that alternative remains unreviewed, so this prefix is not claimed to cover all Spanish recipes.

## Evidence

`data/recipes/source-discovery/es-wikibooks/` contains three immutable API response archives and `status.json`:

- `01-siteinfo.json`: Spanish language, namespace0 and current site rights policy, CC BY-SA4.0 ([official licence](https://creativecommons.org/licenses/by-sa/4.0/deed.es)). Page exceptions remain unreviewed. Preserve revision/contributor attribution, licence and modification/share-alike obligations before downstream use; no images collected.
- `02-first-prefix.json`: first49namespace0 nonredirect listing entries; API continuation preserved verbatim. This is not the total corpus or49parsed recipes.
- `03-recipe-manual.json`: manual revision390018/page28603, original wikitext/SHA and attribution metadata. No culinary recipe records created.

Each archive records request URL, retrieval date, HTTP status, exact response body and SHA256. Current verification independently recomputed all3body hashes, source manual hash, language/licence/namespace, listing entries and continuation. HTTP errors require recorded backoff and no alternate route; discovery probe completed with3requests/exit0, no failure or cooldown. The bounded one-off probe is in the coordinator's C workspace, not a production collector. No stale quota report may be reused.

## Initial implementation plan — completed below

Implement an isolated Spanish collector/parser with its own source IDs, locks, pending-page state, immutable revision archives and deterministic derived index. First consume the49already archived listing entries before advancing their saved continuation; otherwise the first batch would be skipped. Preserve underscore continuations verbatim and pending/listing isolation. Review actual manual/template/ingredient/method structures with source fixtures; do not silently reuse the French parser or invent canonical quantities, timings, cuisine, translation or nutrient links. Retain source language separately from cuisine. Source-specific parser/collector and23tests are now implemented below;runtime promotion is still unimplemented.

English and French current pools remain exhausted and unchanged; no combined unique-dish counts or final bank cap. Existing original54recipes and all runtime behavior remain unchanged.


## Spanish collector checkpoint — heartbeat21:59

[Spanish source contract](RECIPE-SPANISH-SOURCE.md) and data/recipes/bulk/es-wikibooks-recipes/index.json: 1043sourcepages/853parsed/6750ingredientlines/4981steps/85requestarchives. Parserv3/23tests/currentSHA+re-extraction+bootstrap49checks passed. Pending0,sourceExhausted=True,nextAttemptAt=None;read actual checkpoint. Research-only,0runtime/nutrition approvals;English/French/otherbanks unchanged,no combined unique-dish sum. Next:After actual quota/owner checks,discover Spanish singular Artes culinarias/Receta/ via bounded archived namespace0 nonredirect listing,using verified Spanish site policy;review scope/parser before collection. Then another licensed pool if needed. Preserve exhausted plural/English/French cursors,0runtime approvals. SeeHANDOFF§51.


## Implemented CLI and source contract

```powershell
node tool/recipes/collect-wikibooks-es.mjs --requests 10
node tool/recipes/collect-wikibooks-es.mjs --requests 10 --resume
node --test tool/recipes/collect-wikibooks-es.test.mjs
```

The first command is only for a new bank; normal continuation always uses --resume. --out selects an isolated data path; default discovery/policy evidence remains app-root based. No --help or unknown option makes a request. Collection max10requests per invocation,20revision pages per request,2second successful pacing,own collector.lock and min10minute/Retry-After backoff. Inspect owner before treating a lock as stale. Check actual quota before every new batch.

Current parser v3 accepts Spanish ingredient/method headings and literal documented Datos de receta ingredient/procedimiento lists. It preserves singleline unresolved templates without expanding them. Multiline unresolved templates/ambiguous mixed layouts/code or unclosed hidden spans remain raw/unparsed to avoid false rows. Not all Spanish recipe structures are supported; unparsed pages are not discarded. Original raw parser versions remain immutable; derived recipes record the current version and are deterministically rebuilt. Source language/category labels are not culinary review,canonical quantities or nutrition.

The archived49firstlisting IDs were verified present in the actual raw bank before later continuation. Their discovery requests are separate from collector request counters. Current local hashes/index re-extraction/lock checks do not independently authenticate upstream content or establish an atomic transaction;stop collector/indexer during downstream review. English identity/fate readers do not accept Spanish records yet. Recipe-from-scratch persistence/runtime promotion remains separate.
