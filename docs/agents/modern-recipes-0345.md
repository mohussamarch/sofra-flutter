# Eighth modern Arabic creator source attempt

Date: 2026-10-15. The task allowed one recipe source attempt, with a strict maximum of four underlying requests. The live quota was checked immediately before source access: primary 80%, weekly 59%, ordinary usage allowed. The task’s 85% stop threshold was not reached.

The selected library did not contain `https://www.youtube.com/watch?v=FmpmSDkknD0`. Video-to-creator attribution comes from a prior search result (`turn178youtube0` in this task history), which returned this exact URL and displayed title `لأول مرة الشيف منال العالم مع اخواتها لتحضير وصفة رائعة` with the byline `Manal Alalem (Verified)`. That result, not the channel record alone, is the evidence linking this video to the creator. The separate channel identity record is `data/recipes/arabic-youtube/2026-10-first-batch.json`, `creators[0]`: it links the verified `@manalalalem` channel to the official site with high confidence.

One direct open was attempted. It failed to fetch the YouTube page. The attempt record therefore sets `identityStatus=video-attribution-observed-in-prior-search-result; direct-page-content-unavailable`: the creator attribution is supported, but direct description access failed. The prior search result also exposed an ingredient list and publish date (2022-07-28) but no method; it is incomplete and was not promoted as a recipe. Reuse rights remain unknown. No recipe was accepted or fabricated. No media or transcript was accessed.

Verification: `node --test tool/recipes/creator-eighth-validation.test.mjs` — 2 passed, 0 failed. The test confirms the failed source remains a blocker and that no recipe record was created.

Exact next action: retry only if a later authorized unit provides a fresh source-access allowance and a reason to revisit this video. Until then, record no YouTube recipe from this attempt.
