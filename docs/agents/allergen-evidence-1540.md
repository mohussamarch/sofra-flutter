# allergen-evidence-1540 — full handoff

## Ownership and base

- Selected checkout: E:\work\SOFRA\app, root-reported main base a9a4ccc.
- Owned only data/food/allergen-evidence/20261014/**, tool/food/validate-allergen-evidence.mjs, tool/food/validate-allergen-evidence.test.mjs, and this handoff/status pair.
- Scope: bounded official EG/SA allergen vocabulary/declaration evidence; root integrates shared docs, queue and Git.
- Ownership returned to root on completion. No shared file, runtime source, UI, Firebase, billing, APK, audio or image changes.

## Actual work

- Read STATUS first, AGENTS and relevant prior allergen handoff; inspected only canonicalAllergenId, AllergenStatus and foodAllergenStatus sections needed for the contract.
- Actual tool quota before research: 65% primary / 26% weekly, ordinaryUsageAllowed=true. Rechecked 68/26 before follow-up source reads; final 75/27 true. No purchase/reset.
- New data: data/food/allergen-evidence/20261014/official-evidence.json and README.md.
- 4 source access records, 2 retrieved SFDA pages/documents, 2 unavailable attempts, 7 paraphrased facts, 15 exact vocabulary proposals, 4 declaration status boundary entries, 2 jurisdiction coverage records.
- No products classified; all 15 proposal productStatus values unknown, runtimeApproved=false, status=proposed.
- 14 groups map to existing exact canonical IDs only as proposals. Wheat remains specific and separate from gluten; nuts/peanuts and crustaceans/molluscs remain separate. No family/member expansion.
- Saudi source wording distinguishes actual ingredient declaration from possible cross-contact; precautionary disclosure does not replace ingredient disclosure.
- EG vocabulary/declaration/current law/free-from requirements remain unknown; no US/EU/SA extrapolation.
- Licence unknown for all sources, archived=false and bodySha256=null. No full source body/media downloads or large copyright copy.

## Official source access

1. SFDA Arabic 2019 menu notice:
   https://www.sfda.gov.sa/ar/news/الإفصاح-عن-مسببات-حساسية-الطعام-اعتباراً-من-1-أكتوبر-2019
   Retrieved text supports 14 groups and historical out-of-home/menu disclosure scope. Display date 2019-09-01 differs from body dateline 2019-09-03; retained explicitly. Announced start date 2019-10-01, not present-law certification.
2. SFDA Arabic guide:
   https://sfda.gov.sa/sites/default/files/2019-11/دليل%20مسببات%20الحساسية.pdf
   Read relevant extracted pages 8, 10 and 12 (1-based PDF pages), including wheat example, declaration wording/cross-contact and packaged ingredient-list context. Actual publication date unverified/null. Screenshot requests for pages 8/9 timed out; no visual verification claimed. No retries.
3. https://www.nfsa.gov.eg/ returned web fetch 404; domain-restricted allergen search produced no accessible specific evidence. Recorded unavailable, no claims.
4. https://www.sfda.gov.sa/en/faq/what-are-requirements-food-labeling timed out. Recorded unavailable; no reliance on search snippet and no retry.

## Verification actually run

- node --test E:\work\SOFRA\app\tool\food\validate-allergen-evidence.test.mjs: 12 passed, 0 failed.
- node E:\work\SOFRA\app\tool\food\validate-allergen-evidence.mjs: exit 0; sources=4, retrievedSources=2, claims=7, mappingProposals=15, runtimeApprovals=0.
- Tests initially failed with ERR_MODULE_NOT_FOUND before validator creation, then passed against actual implementation.
- Negative cases cover unknown/absence, cross-jurisdiction misuse, unavailable/missing source/anchor, duplicates, spoof official host/authority/credentials, wheat/gluten separation, nut/shellfish group separation, no product status promotion/free-from inference, null unarchived hashes/licence, clinical/legal/runtime approvals, unknown fields and invalid date chronology.
- No Flutter/analyze/full suite run: no runtime code changed. No Git commit/push performed; root owns final integration.

## Limits and exact next action

- This unit is locally validated research evidence, not operational allergen coverage or completion of all allergen work.
- Unarchived sources cannot be independently authenticated by the offline validator. It checks a bounded reviewed vocabulary table and source/jurisdiction/research boundaries, not legal correctness.
- Historical menu guidance does not establish current packaged-label obligations; free-from criteria and Egypt guidance unknown. Sulphite thresholds were deliberately not adopted.
- Root: review and integrate the 6 owned files, record partial evidence completion for allergen-evidence40 (do not mark product/runtime coverage complete), update common handoff/queue, commit/push and final receipt.
- Next research: obtain an accessible specific NFSA/Egypt official allergen declaration reference and current applicable Saudi packaged-label text in a new bounded source unit after fresh quota. Preserve all unknowns until actual evidence/review.
- Any future alias promotion requires explicit reviewed runtime change/tests and product/version/market declarations; this bank grants none.
- No user decision changes. No server operation performed; root retains preview ownership.
