# Saudi retailer and delivery-platform price integrations

Research snapshot: 2026-10-14. Data: `data/prices/research/retailer-integrations-sa-20261014.json`.

## Recommendation

For a small-shop rollout, start with a cooperative retailer's POS/CSV export or a merchant-authorized Salla/Zid `products.read` connection. Those paths provide product prices and availability from a store whose owner permits the feed. Store ID and branch should be separate dimensions; keep `checkedAt`, SKU/barcode, pack size, currency, regular/sale price, availability, and the permission record with each observation.

For a store that wants to sell through HungerStation, apply through the official merchant route first. The platform's Local Shops docs describe self-service tools for smaller merchants and offer partner API or CSV-based SFTP for automating the merchant's own catalog. Its partner catalog API exposes vendor-scoped product retrieval and updates, while real-time order and outlet operations also require partner access. This is not a public all-stores/city catalog feed. The platform checks area availability during registration; the reviewed page does not publish a city list. Commission is documented but its rate is not published in the pages reviewed.

Nana Apps is a different route: a business can apply to present its own provider mini-app inside Nana, with a stated service area, pricing, and order functions after verification/review. The docs do not describe a cross-store grocery catalog reader.

Do not bulk-copy a delivery app's consumer listing into this product. HungerStation's terms prohibit copying merchant listing content for republication and warn that displayed menus may not match what a merchant actually fulfills. No public consumer catalog API was confirmed during this bounded source review; this does not prove that none exists. Never scrape hidden endpoints or use logged-in credentials outside authorized flows.

## Source-backed distinctions

- **Consumer price display:** HungerStation says catalog/price display is current when an order is placed and can change. Delivery, small-order, service, and cash-payment fees may be separate; service fees may vary with customer distance and are shown before payment. Keep those separate from product price.
- **Merchant feed:** HungerStation's Partner API overview describes real-time catalog availability/price synchronization. The catalog API has GET product/assortment retrieval and PUT price/availability updates by chain/vendor; updates are queued jobs, and the API notes catalog `quantity` is used against an existing sales buffer rather than stored as stock. Partner docs also offer SFTP CSV for shops that do not need an API.
- **Salla:** `GET /admin/v2/products` is explicitly “products related to your store,” with `products.read`. The documented response includes price/currency, taxed and pre-tax price, sale price, quantity, and availability. OAuth scopes are granted by the merchant and may be revoked. This gives authorized store data, not a public cross-city retailer list. The source does not document a freshness SLA or branch-level coverage for this endpoint.
- **Zid:** `GET /v1/products/` lists products under a `Store-Id`, using the `products.read` scope and Access-Token; examples include price, sale price, currency, quantity, and paging. It is store-scoped. The cited endpoint does not state a freshness SLA or branch model.
- **Nana:** The mini-app site asks providers to state cities and operational capacity, and describes catalog/pricing/service-area/order APIs, provider verification, and controlled rollout. Its developer guide says SDK access/credentials are supplied by Nana and the submitted app is reviewed. No feed for reading all Nana grocery listings was found in those docs.

## Files and verification

Only the assigned JSON research artifact and this agent handoff/status were edited. JSON syntax was validated with Node. Primary URLs and the facts each supports are recorded inline in the JSON. Exact commission/API fees, city coverage, retailer permission, and reuse rights remain unresolved; they require platform/merchant agreement, not inference from documentation.
