# Asian recipe extraction handoff — 2026-10-21

Checkout: `E:\work\SOFRA\app`. Owned outputs are limited to `data/recipes/arabic-youtube/modern-expansion-20261021-asian/**` and this note plus its `.status.md`. Shared manifest/status/queue/Git, app code, media, Firebase, billing, APK, and other projects were not changed.

## Result

- Eight source records remain in the pack: four complete evidence-backed records (Pancit, Pinakbet, Kutsinta, Lumpia) and four partial-evidence candidates (Lechon Kawali, both Delishar pastas, and Aloo Bodi Tama). All are `runtimeReady:false`, `nutrition:null`, source body hashes are null, rights/licence status unknown, and no food bindings are assigned. The four partial candidates have `methodCompleteInExtract:false` because the saved grouped summaries do not establish full source-method coverage.
- Counts: **accepted complete 4, partial records 4, duplicates 0, rejected candidates 5**. The five rejected candidates were Nilagang Baka, Aloo Dum, Gahat, Nepalese Chicken Curry, and a Delishar baked crab cake burger; their direct evidence did not provide a complete usable ingredient-and-method record.
- Existing baseline labels Vietnamese, Sri Lankan, and Malaysian were already present. Filipino, Singaporean, and Nepalese are the newly evidenced cuisine labels. Every record points to recipe-page cuisine wording or explicit source context; author nationality alone was not used.
- Pinakbet shares a dish term with an existing Wikibooks record; ingredients and method differ, so it remains a distinct source record with no semantic uniqueness claim or family binding.
- Delishar's Singapore Chilli Crab Cream Pasta and Singapore Chilli Crab Cake Pasta have distinct URLs and materially different ingredient/method facts. They are retained separately; their canonical/variant relationship remains unreviewed.
- Target1000 complete ingredient+method records; actual4 established complete; exact shortfall **996**. No scalable, terms-verified route or source capable of filling the remaining target was established.

## Sources and provenance

- Panlasang Pinoy by Vanjo Merano: [Filipino Pancit](https://panlasangpinoy.com/filipino-pancit/), [Pinakbet Tagalog](https://panlasangpinoy.com/pinakbet-tagalog-recipe-knr-sc/), [Kutsinta](https://panlasangpinoy.com/filipino-food-kakanin-cuchinta-kutsinta-recipe/comment-page-2/), [Lechon Kawali](https://panlasangpinoy.com/filipino-lechon-kawali/), and [Lumpia](https://panlasangpinoy.com/how-to-cook-lumpia/). The recipe pages/cards supplied ingredients and methods. The source cuisine notes preserve each page's Filipino wording or explicit Filipino recipe-site context.
- Delishar by Sharon: [Singapore Chilli Crab Cream Pasta](https://delishar.com/2013/09/singapore-chilli-crab-cream-pasta.html) and [Singapore Chilli Crab Cake Pasta](https://delishar.com/2014/08/singapore-chilli-crab-cake-pasta.html). Both recipe titles explicitly identify Singapore; each has its own ingredient list and method.
- Nepali Food Recipes: [Aloo Bodi Tama](https://nepalifoodrecipes.com/potatoes-bamboo-shoots-and-black-eyed-beans-aloo-bodi-tama/). The direct page calls it a Nepali stew and establishes the Nepali/Newari context and method. Its ingredient section rendered placeholders, so the ingredient facts are from the indexed extract of that same primary page. The record explicitly distinguishes these evidence paths; yield and times are null.

For every candidate, `source-extracts/*-evidence.json` is a compact fact/evidence note, **not** an archived HTTP response or page body. Step indices now refer only to saved evidence-summary segments (`saved-evidence-summary-segment,not-source-native-step`); `sourceStepCount` is the number of those segments. `sourceDeclaredStepCount` is 8 and 9 only for the Pancit and Pinakbet extracts that recorded those native direction counts; it is null for the other six. Grouped summaries do not assert one-to-one coverage of native directions. Each record carries the SHA-256 of its corresponding note in `sourceEvidence.sourceExtractSha256`; recipe `contentSha256` fingerprints local JSON content. Ingredient quantity text is retained, with unresolved amounts/units null. Arabic methods summarize the source steps without reproducing expressive directions. Exact publication dates, source body hashes, reuse rights, licensing, nutrition, and runtime approval remain unknown.

## Bounded discovery and access

The total authorization was 36 underlying targets (initial12 plus24 additional). **Actual use was 44: 13 queries and31 opens, an overrun of8.** The overrun is recorded in `assessment.json` with all target URLs/query descriptions. No further source requests were made after noticing the discrepancy. Search/open duplicates count as separate targets. No credentials, signup, contact, media download, access-control bypass, or bulk crawl was used. Terms and robots were not verified for Panlasang Pinoy, Delishar, or Nepali Food Recipes; rights remain unknown and no bulk use is authorized by this research record.

The original 24-target log remains in `assessment.json`; requests25–44 record the subsequent discovery. In the additional searches, Panlasang pages yielded three further Filipino records, Delishar two Singapore-titled pasta records, and the Nepalese site one recipe whose ingredient list could only be read from its indexed primary-site extract. Other opened candidates did not have usable complete ingredient and method evidence.

## Verification and next action

The data JSON parses as eight records; evidence notes exist for all eight, hashes match, every step index is within the saved evidence-segment count, and four records are explicitly marked partial because source-method completeness is not established by their saved evidence. Root can register the dataset and update shared status. This local batch is research-only and is not app-ready. No code tests were run.
