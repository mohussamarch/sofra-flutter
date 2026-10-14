# Manufacturer web label observations — §75

Asset: `data/food/product-label-evidence/20261014/manufacturer-evidence.json`.
Reader: `lib/data/product_label_evidence_repository.dart`; `ProductLabelEvidenceRepository().all()`, `.search(query)`, `.byProposedAllergen(id, includeMayContain: true)`.

The bounded bank holds4Domty website observations: Bran/Milk/Brioche/High Protein Toast.6official source attempts,5readable (Juhayna category has no explicit statement),1failed Almarai attempt.13contains and3mayContain declarations. Not a physical label check. No complete source-body archive; body hashes/licence/market/GTIN/pack/version/form/nutrition remain unknown. Egypt contact address is context only.

Byte SHA1428c31beb18be0c8800b111f9f0ce0e79f84afe994961b8ca16cd90639b6f67 is checked before fatalUTF8/JSON. The reader requires exact nested schema, registered source identity, date/source/evidence links and declaration status/term matching. Returns immutable typed lists and deep-owned copied product/source/batch context. Failed async or synchronous loading retries after cache clears in one place. Source vocab maps are proposed only; wheat is not inferred from gluten, absence is unknown, freeFrom is empty. No FoodRecord, KitchenService write, health warning or runtime/clinical/legal/rights approval.

Node validator11tests and Flutter reader8tests cover original-byte drift, malformedUTF8, explicit status, source link/unknown schema/promotion rejection, ownership, cache and failed-read retry. Review found permissive extra fields and synchronous failed-cache retention; both reproduced before repair.

Next: independently verify exact target-market physical SKU/GTIN/version and permitted reuse, match a local food explicitly, retain distinction between manufacturer statement and approved current label. Extend via a new reviewed schema/batch and pin, never by name inference or weakened validation. See docs/agents/product-label-evidence-2000.md and HANDOFF§75.
