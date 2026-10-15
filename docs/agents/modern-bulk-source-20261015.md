# Modern large-source assessment —15October2026

Checkout E:\work\SOFRA\app. Scope: reconnaissance/probe only; coordinator owns existing-archive1000 batch and all shared/Git files. No archive records were reprocessed or recounted here.

Result: **no eligible scalable modern source verified within12-request cap**. New recipes collected/imported0; target1000complete distinct records not achieved. One public recipe page was inspected as a content-shape sample, without creating a recipe record or saving its body.

## Primary evidence

| Source | Observed evidence | Assessment |
|---|---|---|
| [King Arthur app](https://www.kingarthurbaking.com/app) and [publisher announcement](https://www.kingarthurbaking.com/newsroom/2025/11/18/king-arthur-baking-company-launches-new-recipe-app) | Indexed primary publisher pages claim2700+recipes | Platform-size claim only; not2700retrieved or independently enumerated recipes |
| [Recipe hub](https://www.kingarthurbaking.com/recipes) | Public HTML with category/recipe links retrieved | No public bulk/API/export documented in inspected pages |
| [Sample cheesecake](https://www.kingarthurbaking.com/recipes/maple-pecan-cheesecake-recipe) | Ingredients20bullet lines; instructions15numbered items including storage; named author; update2026-10-09; yield/time | One complete page observed;0imported. Ingredient optional groups and instruction storage item must not inflate separate recipe counts |
| [Robots](https://www.kingarthurbaking.com/robots.txt) | Declares sitemap.xml; disallows search, print/ajax-print and other paths; normal recipe slug not listed disallowed | Robots is access discovery evidence, not reuse permission |
| [Declared sitemap](https://www.kingarthurbaking.com/sitemap.xml) | Web tool could not access XML | No XML enumeration or distinct recipe-URL count; no retry/alternate-host route |
| [Current Terms](https://www.kingarthurbaking.com/policies/terms-of-use) | Primary indexed terms effective2026-04-01:§6expressly forbids scraping/crawling;§10requires written permission for reproducing/adapting/publishing content | **Do not start an automatic King Arthur collector from this assessment.** Permission/export would be needed to change this source status; no contact made |
| [Official MyPlate recipe index](https://www.myplate.gov/myplate-kitchen/recipes), [homepage](https://www.myplate.gov/) | Both direct probes timed out | Current recipe count, ingredients+method access, bulk feed, ownership/licence exceptions and English/Spanish dedup not established |
| [NAL policies](https://www.nal.usda.gov/web-policies-and-important-links), [NAL collection guidance](https://www.nal.usda.gov/programs/speccoll) | Primary source policies distinguish public-domain government information and protected third-party materials/works merely held in collections | Scope is NAL guidance; not blanket MyPlate contributor permission. No recipe-specific MyPlate rights cleared |

An unaffiliated MyPlate mirror was returned by search; its1072count, retirement story and blanket public-domain claims were excluded from accepted primary evidence. No mirror was opened or bulk acquired. One Choumicha official-domain scale query yielded no matching result; it does not establish that the source is small or exhaust Arab creators. Arab creator/YouTube priority remains open. King Arthur chiefly covers baking; broad Asian/Moroccan/Greek/Omani or other cuisine coverage was not verified.

## Exact request accounting

12underlying requests =6queries+6open/click targets across7webtoolcalls, all pre-counted before dispatch; stopped at12. Machine log records exact query strings and target URLs in source-assessment.json.

1.query MyPlate discovery (site filter was malformed; mirror claims discarded).
2.query official MyPlate copyright.
3.open official MyPlate recipe index:timeout.
4.open official MyPlate homepage:timeout.
5.query official Choumicha1000scale:no matching result.
6.query official King Arthur scale:2700+publisher claim.
7.open King Arthur recipe hub:HTML available.
8.open King Arthur robots:available.
9.open robots-declared sitemap:XML not accessible through tool.
10.click recipe link from hub:sample content available.
11.query official King Arthur terms:explicit collection restriction found.
12.query official USDA copyright/contributor policy:NAL scoped guidance found.

No guessed Drupal/WordPress/API endpoint probes, no print/search-route probe, no failed-URL retry, media/transcript/huge download, new old-book network, account/signup/payment/gate/captcha/host bypass or merchant/contact message.

## Exact requirements before a1000-record collection

For King Arthur, obtain a documented owner-provided licensed export or permission covering automated bulk access and intended reuse before implementing this route. No such permission exists here. For MyPlate, verify a current reachable official index/feed/export with recipe contents and review recipe credits/contributor exceptions first; English/Spanish language versions must share canonical recipe identity and not count twice.

Only successful records with nonempty ingredients and method count toward1000, after canonical-ID, exact/near content and language duplicate checks. Publisher total, sitemap links, partial pages, failures and metadata do not count. Preserve provenance/hash/revisions, null amounts/time/yield, ranges/alternatives and licences; keep rights/runtime/nutrition approval separate. No sound public automated bulk route was verified in this bounded assessment.

## Handoff

Owned files finalized:
- docs/agents/modern-bulk-source-20261015.md
- docs/agents/modern-bulk-source-20261015.status.md
- data/recipes/modern-bulk-source-20261015/source-assessment.json(metadata only; no recipe body bulk)

Actual worker quota at start7/17ordinarytrue; root reported latest17/18ordinarytrue at closure. Human-authorized ceiling99; no credits/reset. No further source calls after12. No code/shared files/Git or server/process changes. Root may continue its separately authorized local1000archive integration; these0new records must not be added to it.

All ownership returned. Verification: metadata JSON parses and its12 sequential request records reconcile with6queries/6open targets and claimed12cap; no code tests required for this metadata-only unit.
