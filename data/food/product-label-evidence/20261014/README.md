# Manufacturer product allergen evidence — 14 October 2026

Research observations from official manufacturer web pages, separate from FoodRecord approval and physical package label verification.

- Four exact Domty product variants: Bran Toast, Milk Toast, Brioche Toast, High Protein Toast with Chia Seeds.
- 13 explicit contains observations and three mayContain observations; all exact canonical mappings remain proposed. Brioche declares egg as contains; the other three pages describe possible egg traces.
- Six access records: four retrieved Domty product pages, one retrieved Juhayna dairy category page without an explicit allergen statement, one inaccessible Almarai URL attempt. Failed/absent text creates no declarations.
- The retrieved contact footers locate the manufacturers in Egypt. They do not establish a product's sale market or the label version applicable to an Egyptian or Saudi SKU. sourceMarket is null for every product and source.
- Pack quantity, GTIN, label revision, form, nutrition and market evidence are null. No prices, conversions or default nutrient zeros were supplied. Juhayna's skimmed-milk prose uses an ambiguous 200 m basis; it was not normalized into nutrition.
- Ingredient wheat does not become an additional declared allergen. Gluten and wheat remain distinct. Contains and possible cross-contact are separate; unlisted allergens remain unknown and freeFrom is empty.
- Each product keeps pageFacts, declarations, pendingLocalProductMatch and runtimeFoodRecordApproval separate. No local ID, clinical/legal currentness, redistribution or runtime approval is granted.
- Publication dates and publication scope remain unknown. retrievedAt records the completed observation capture time in UTC, not a publisher/HTTP timestamp. No full body or media was archived; archived=false, bodySha256=null and rights=unknown.
- Exact allergen excerpts plus exact product names stay within 25 words per product page. Other method notes are paraphrases. URLs/locators preserve review provenance; the offline validator cannot authenticate unarchived upstream content.

Run from E:\work\SOFRA\app:

    node tool/food/validate-product-label-evidence.mjs
    node --test tool/food/validate-product-label-evidence.test.mjs

The validator accepts this deliberately bounded reviewed source catalog and explicit statement grammar. New sources, sourced pack quantities/nutrition or verified markets require a reviewed schema/validator extension. Structural validity cannot approve an SKU match or a current physical label.
