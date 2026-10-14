# Arabic Wikibooks recipe expansion

This isolated lane adds source discovery from official Arabic Wikibooks. It does not update the existing English, French, or Spanish banks or the runtime recipe catalog.

## Batch result — 2026-10-14

- Fresh usage read before source access: 5% short window, 76% weekly, ordinary use allowed. The 90% stop condition was not reached.
- Five sequential official API requests, all HTTP 200; no failures or retry. The requests checked siteinfo, recipe category labels and membership, a cooking category prefix, and five namespace-0 search results.
- Siteinfo reports language `ar` and CC BY-SA 4.0. Sitewide policy is recorded; page exceptions and third-party attributions remain unreviewed.
- Category `وصفات مختارة` had zero members in the captured category-member response. Prefix `طبخ` returned no category labels.
- Search returned one recipe-shaped page, `كتاب الطبخ/كعكة-1-2-3-4`, revision `227030` by `MenoBot`; the other four results were language-learning pages.
- The isolated candidate contains 8 ingredient lines and 6 concise steps. It also retains the full source wikitext, including a separate detailed method. Eight explicit quantity strings are stored only as unreviewed source transcriptions. Canonical quantities, food bindings, nutrition, servings, and all 6 step durations remain null.
- The source text explicitly calls the recipe traditional American. That wording is preserved as an unreviewed observation; `cuisine` remains null. Arabic source language is not used to infer cuisine.
- No images were fetched; the source text contains media references.

## Files

- `data/recipes/source-discovery/ar-wikibooks/`: five request archives, the isolated candidate, notes, and status.
- `tool/recipes/extract-ar-wikibooks-research.mjs`: deterministic offline extractor. It verifies the archived search response hash and expected page/revision before emitting a candidate.

`01-siteinfo.json` stores the complete parsed siteinfo response and the SHA256 of the original HTTP response body, but the original raw body bytes were not retained as a string. Archives `02`–`05` preserve their response body strings and request metadata. This archive limitation is recorded in the lane status and review notes.

## Verification and boundaries

Ran `node tool/recipes/extract-ar-wikibooks-research.mjs`. It verified the search archive body digest and exact expected page/revision and extracted 8 ingredient lines and 6 steps. Candidate SHA256 is `72468a695af9c2949bf24463e63be67cf33fdeed13fdacdfdcaf07cdb36d1744`.

The candidate is research-only. No runtime import, nutrient calculation, quantity normalization, unique-dish claim, or broad parser coverage claim was made. Existing source banks and shared handoff files were not modified. The coordinator owns shared docs, Git integration, and the final repository handoff.

## Next action

Before another source request batch, capture fresh quota evidence and inspect the source lock/backoff state. For this page, review page-level exceptions and quantity transcriptions before any normalization; retain all unknowns until that review.
