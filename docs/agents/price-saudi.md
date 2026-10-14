# Saudi price source research — 14 October 2026

Selected checkout: E:\work\SOFRA\app. Base: c9b1f24c82be7a96065fe5c8f6b69cb474d63560. Owner: price_saudi_sources; coordinator owns shared handoff/Git.

## Objective and files

Audit seven primary source organizations for Saudi food prices with acquisition rights and provenance. Added data/prices/research/saudi-sources.json (schemaVersion1, researchOnly) and these two owned handoff files. No implementation or shared-document edits.

## Verified outcome

Five observations: four verified full-page research quotes, one snippet-only lead excluded from usable counts. All four pages show Al Shati, Jeddah; SAR is established by [Danube terms](https://api.danube.sa/en/pages/terms-and-conditions). Retrieval batch began2026-10-14T07:41:41Z; retailer price dates remain unknown.

| Product | Display amount | Basis | Page availability | Tool-reported crawl |
|---|---:|---|---|---|
| [Tomato](https://danube.sa/en/products/tomato-kg-2) | SAR6.95 | 1kg weight basis | Add To Cart control | last week |
| [Heinz ketchup](https://danube.sa/en/products/heinz-tomato-ketchup-squeez-342g) | SAR14.99 | 342g listed item | Out of Stock | 2 months ago |
| [Almarai full fat fresh milk](https://danube.sa/en/products/almarai-fresh-milk-full-fat-1ltr) | SAR7.00 | 1L listed item | Add To Cart control | yesterday |
| [Al-Watania frozen chicken](https://danube.sa/en/products/al_watania_poultry_chicken_800g) | SAR19.75 | 800g listed item | Unavailable | 4 months ago |

Four categories: produce, packaged groceries, dairy and poultry. Two purchase controls do not prove current stock. Unavailable products cannot support purchase suggestions. Zero statistical values, runtime prices or approved retailer bulk feeds. VAT, price effective dates, membership requirement, shipping amount and explicit pack counts remain null. No barcodes inferred.

## Sources and acquisition decision

- [GASTAT publication list](https://www.stats.gov.sa/en/search-publication?category=publication&delta=40&q=%D8%A7%D9%84%D8%A3%D8%B3%D8%B9%D8%A7%D8%B1) displays July2026 APGS, release2026-08-13 and XLSX filename APGSTables-Jul2026-AR-EN (1).xlsx. Latest item on the cached retrieved list is not proof of newest live release. Direct [report](https://www.stats.gov.sa/en/w/average-prices-of-goods-and-services-july-2026-1) returned502; export URL/download remain unverified.
- [GASTAT reuse policy](https://www.stats.gov.sa/en/use-policy) indexed official result permits commercial reuse with attribution/change notices and exceptions; direct opens502. Rights/applicability stay unverified pending direct review. Official methodology4.0 indexed update12/02/2026 states fixed specifications/units and thirteen-region coverage.
- [DataSaudi](https://datasaudi.sa/en) opens with August2026 CPI. Absolute commodity-price dataset/export/API not identified; CPI is not SAR food pricing.
- [LuLu Saudi terms](https://gcc.luluhypermarket.com/en-sa/termsAndConditions-sa/) open: personal noncommercial access conditions, written permission for other reuse. Displayed date2019-05-08; product retrieves loading shell, no price.
- [PandaClick terms](https://s.panda.sa/app_terms/) open: guide prices, fulfilment-store delivery-day prices, variable-weight adjustments, VAT where applicable and additional delivery/collection charges. Panda product access minimal shell; no quote/reuse licence.
- Danube terms require explicit permission for third-party use/sharing; online/store prices can differ and fees are additional. These observations are research-only, blocked from automated reuse.
- [Othaim offers](https://www.othaimmarkets.com/en/offers) redirects to Arabic offers. No dated brochure price/validity/branch verified.
- [Carrefour Saudi terms](https://www.carrefourksa.com/mafsau/en/helpcenter/topics/223-get-started?articleId=4385) open and verify KSA operation; home open failed, no quote. VAT/feed/reuse evidence unknown.

Best next acquisition: verify GASTAT policy/report when access recovers, newest release and actual XLSX URL. Archive original bytes/hash and retain commodity code/specification/unit/period/geography/currency/VAT definition/attribution. Review explicit inventory mapping. Keep monthly statistics separate from store quotes; never average incomparable sources. Retail feeds require owner permission/documentation before collection. User-entered actual purchase prices remain a practical fallback.

## Verification and limits

Focused JSON parse, seven unique sources/five observations, four full-page verified quotes/four categories, two unavailable records; all runtime acceptance false. Normalized prices null. Main gaps: meat/fish, statistical export rows, retail VAT/date/membership context, order-confirmed availability and authorized bulk APIs. Search-only policy and lead explicitly marked. No large scraping, workaround, login/cart/purchase, UI/Firebase/APK or Git mutation.

Last fresh quota13%short/77%weekly, ordinarytrue at2026-10-14 07:41:41UTC; stop new batches at>=90%/unknown/ordinaryfalse. No further source requests needed for this audit.

## Exact next action

Coordinator integrates this research-only bank and licence/freshness/availability/normalization/explicit-acceptance gates, then commits/pushes and records receipt. Later authorized checkpoint retries GASTAT. Preview process/server untouched; no process inspection/restart by this agent.
