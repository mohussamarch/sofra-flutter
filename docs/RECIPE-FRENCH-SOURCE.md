# French recipe research source

The independent source is [French Wikibooks](https://fr.wikibooks.org/wiki/Livre_de_cuisine), namespace0, prefix `Livre de cuisine/`. Official siteinfo reports French and [CC BY-SA4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.fr). Metadata and the unsuccessful initial prefix probe are archived in `data/recipes/source-discovery/fr-wikibooks/`. Page exceptions remain unreviewed. No images are collected.

## Collection and storage

`tool/recipes/collect-wikibooks-fr.mjs` discovers50nonredirect prefix pages per listing request, then retrieves at most20revisions per request. Each invocation has at most10sequential requests, at least2seconds between successful requests, and a10minute minimum failure backoff (longer Retry-After wins). Discovery cooldown is resolved from the application root, independently of output directory.

```powershell
node tool/recipes/collect-wikibooks-fr.mjs --requests 10
node tool/recipes/collect-wikibooks-fr.mjs --requests 10 --resume
```

Default data directory: `data/recipes/bulk/fr-wikibooks-cuisine/`:

| File | Purpose |
| --- | --- |
| checkpoint.json | Separate listing cursor, pending page IDs/titles, source cooldown and bounded-run counters |
| requests/ | Request URL, retrieval date, HTTP status, exact response body and SHA256; cumulative request number prevents archive overwrite |
| source-pages.jsonl | Immutable page revisions with permalink, author, raw wikitext/hash, licence and conservative extraction |
| parsed-recipes.jsonl | Derived research recipes, rebuilt from validated raw revisions |
| index.json / manifest.json | Latest revision per page, distinct page/recipe/ingredient/step counts and raw/derived byte hashes |
| recovery/ | Preserved torn final append evidence before repair; not an approved source record |

The lock refuses a second collector. Listing continuation never enters revision requests. Pending IDs advance only after all requested revisions are verified and appended. Append-before-checkpoint replay deduplicates revisions. An invalid unterminated final line may be archived and refetched only while its request is pending; middle corruption or a lost checkpoint stops for investigation. Complete prefix records are validated before repair. Keep collector/indexer stopped during downstream validation; local hashes do not independently authenticate the upstream source.

## Meaning of the data

Prefix pages include indexes, techniques and ingredients. Only pages with both recognized ingredient and method lists count as extracted recipes; others remain searchable source pages. Parser `fr-sections-v1` recognizes conservative French headings and list items, retaining source group paths. Unlisted headings, prose methods, templates and other source structures can remain unparsed. Counts describe extraction coverage, not culinary quality or complete recipe coverage.

- Source language stays `fr`; `nameAr=null`. French language does not establish French cuisine. Literal categories remain source metadata, with no inferred cuisine or translated tags.
- Canonical quantities/units, servings, food bindings, step durations, cuisine and nutrition stay null. No guessed grams, automatic identity matching, clinical advice or runtime admission.
- Parsed IDs use `fr-wikibooks:<pageid>`; raw IDs use `fr-wikibooks-<pageid>-r<revision>`, separate from the English source. English reader/identity proposals are unchanged and do not accept French records yet.
- Cross-language or dish-family duplicates have not been resolved. Do not sum source counts as unique dishes.
- Attribution, change notice and applicable share-alike obligations travel with each revision. Page-specific exceptions and recipe content still need review before use.

Next: continue due prefix batches without resetting the cursor; inspect a bounded sample of unparsed source structures, add evidenced parser fixtures, then develop source-specific quantities and explicit food-identity review. Runtime promotion remains a separate tested step.

## First live batch

139sourcepages/112parsed/637ingredientlines/567steps;12rootrequests including2local/source failures. Initial API continuation uses underscores; preserve it verbatim, normalize only for validation. Archived listing was recovered offline after the old guard failure,without clearing its gate. Last429gate17:35:52.878Z;9pendingIDs remain.16French tests/101related tests passed. Source requests/derived hashes and English preservation verified; no runtime/nutrition approvals.

## Due collection continuation

After the independent local identity unit,source resumed only at its next gate. Current:625sourcepages/450parsed/2862ingredientlines/2591steps,53rootAPIrequests/archives. Latest429gate2026-10-13T17:49:47.599Z;9pendingIDs remain,sourcepoolnotexhausted. OriginalEnglish untouched;no cross-languageunique-dishsum,0runtime/nutrition approvals. Actualcurrentraw/derived/requesthashes and deterministicre-extraction verified;collector/parser codeunchanged.

Heartbeat17:47 actual:752pages/540parsed/3557ingredientlines/3210steps,65rootrequests.2boundedbatches+90parsed,then429gate2026-10-13T18:01:42.279Z;28pendingIDs. Raw/derived/currentrequesthashes/re-extraction verified;all canonical amounts/units/nutritionnull,0runtime. Fullhelperhandoff:french-heartbeat-1747.md.

Later dueunit:874pages/621parsed/4090ingredientlines/3794steps;gate2026-10-13T18:14:40.525Z,49pendingIDs. All540prior recipes at5a60180 unchangedbyrecordId;rawprefix preserved. Derivedsortedfile isnot append-only,so byteprefixchanges arenot rowdrift. Corrected category/arraymetric error inHANDOFF§46;no sourcecontentchanged.

Final17:47turnsnapshot:1169pages/804parsed/5554ingredientlines/5133steps,100requests,pending0,sourceExhausted=False,gateNone. Sourcecurrentlyavailable;nextbatchrequiresfreshquota. Approval/fail-closedUTCguardincident documentedHANDOFF§47;no source requestonrejections/guardfailure. Originaldata/choices/nutritionstillunapproved.
