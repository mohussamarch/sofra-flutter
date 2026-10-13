# Research identity proposals

`first-review.json` contains8unreviewed source-line identity interpretations,14candidate references and separate source/food evidence. No identities, quantities or nutrition are approved or written to runtime. Preserve Wikibooks attribution/version/licence/change notices and USDA CC0evidence separately. Do not merge candidate source records.

Validate with `node tool/recipes/validate-identity-bank.mjs` after collection/indexing has exited. Changed source recipes or food snapshots require explicit re-review, not regeneration of targets to hide drift. Proposal source text is an attributed adaptation; original source licence exceptions still need review. This file is outside Flutter assets and is not user profile data.

Original Wikibooks contributors are attributed through each permanent source-version URL in recipeSources. Source text policy: [Wikibooks copyrights](https://en.wikibooks.org/wiki/Wikibooks:Copyrights). Structured adaptations retain the applicable [CC BY-SA4.0 notice](https://creativecommons.org/licenses/by-sa/4.0/); individual source-page exceptions still require review before redistribution. USDA source evidence is CC0-1.0 and remains separate.

## Second explicit review batch

`spices-leavening-review.json` adds8unreviewed proposals:4ground-cinnamon and4baking-soda lines,8additional recipes/8references/2USDA records. Across the two banks:16distinct targets/16recipes/22references/5foods;0accepted or runtime-ready. No cross-dataset nutrition merge. Validate separately:

```powershell
node tool/recipes/validate-identity-bank.mjs data/recipes/identity-proposals/spices-leavening-review.json
```

Source methods for HummusI and MushyPeas soak with baking soda then rinse/drain. Retained amount and sodium remain unknown; no all-or-none consumption/retention assumption. Cinnamon species/brand remains unreviewed. Even explicit source grams need separate edible-quantity/preparation acceptance. These are research issues only,not automatic nutrition or changed cooking behavior.

## Catalog inventory

`catalog.json` explicitly registers the two research banks with raw byte hashes and guarded aggregate counts. Run `node tool/recipes/validate-identity-catalog.mjs` after English collection/indexing stops. It validates current source/food evidence and rejects repeated recipe-line targets across banks. Shared foods are loaded once, not merged. Only listed files are included; new bank registration is explicit. Report2/16/16/5/22/0runtime does not approve any identity or nutrition.
