# Spanish recipe source discovery

Discovery only, not a collected recipe bank or runtime importer. Official recipe manual: [Artes culinarias/Recetas](https://es.wikibooks.org/w/index.php?title=Artes_culinarias/Recetas&oldid=390018). It specifies the plural `Artes culinarias/Recetas/` path. Category search also exposed singular `Artes culinarias/Receta/`; that alternative remains unreviewed, so this prefix is not claimed to cover all Spanish recipes.

## Evidence

`data/recipes/source-discovery/es-wikibooks/` contains three immutable API response archives and `status.json`:

- `01-siteinfo.json`: Spanish language, namespace0 and current site rights policy, CC BY-SA4.0 ([official licence](https://creativecommons.org/licenses/by-sa/4.0/deed.es)). Page exceptions remain unreviewed. Preserve revision/contributor attribution, licence and modification/share-alike obligations before downstream use; no images collected.
- `02-first-prefix.json`: first49namespace0 nonredirect listing entries; API continuation preserved verbatim. This is not the total corpus or49parsed recipes.
- `03-recipe-manual.json`: manual revision390018/page28603, original wikitext/SHA and attribution metadata. No culinary recipe records created.

Each archive records request URL, retrieval date, HTTP status, exact response body and SHA256. Current verification independently recomputed all3body hashes, source manual hash, language/licence/namespace, listing entries and continuation. HTTP errors require recorded backoff and no alternate route; discovery probe completed with3requests/exit0, no failure or cooldown. The bounded one-off probe is in the coordinator's C workspace, not a production collector. No stale quota report may be reused.

## Next unit

Implement an isolated Spanish collector/parser with its own source IDs, locks, pending-page state, immutable revision archives and deterministic derived index. First consume the49already archived listing entries before advancing their saved continuation; otherwise the first batch would be skipped. Preserve underscore continuations verbatim and pending/listing isolation. Review actual manual/template/ingredient/method structures with source fixtures; do not silently reuse the French parser or invent canonical quantities, timings, cuisine, translation or nutrient links. Retain source language separately from cuisine. Source-specific parser and collector tests precede runtime promotion; none exists yet.

English and French current pools remain exhausted and unchanged; no combined unique-dish counts or final bank cap. Existing original54recipes and all runtime behavior remain unchanged.
