# Library-only recipes

Recipes here are published only to the online library
(https://sofra-library.web.app, `tool/recipes/publish-library.mjs`). They are
**not** app assets: `pubspec.yaml` bundles `recipes/data/` (the offline seed)
and never this folder, and `test/library_only_recipes_test.dart` fails if the
bundled seed grows.

| File | What |
|---|---|
| `youtube.json` | Active creators' video recipes (published). Each keeps `creatorId`, `video{...}`, `source`, `steps[].videoStartSec`. |
| `youtube-held.json` | The review queue: candidates as converted, with the reasons they are held. Not published. |
| `youtube-report.json` | Counts of the last import and the dropped candidates with reasons. |
| `youtube-plan.json` | The audit's decisions (21 November 2026) the importer applies. |
| `creators.json` | The creators (`yt:<channelId>`), published as `creators.json`. |
| `dishes.json` | The catalog's dish groups plus the library's (`tool/recipes/build-dishes.mjs`), published instead of `recipes/data/dishes.json`. |

Refresh after new candidate batches, then publish:

```bash
node tool/recipes/import-youtube.mjs ../app/data/recipes   # folder with candidates-youtube-*
node tool/recipes/build-dishes.mjs
node tool/recipes/publish-library.mjs && firebase deploy --only hosting:library --project sofra-c03a1
```

Batches converted after the audit are counted as "not audited yet" and left
out until `youtube-plan.json` covers them. Cuisine is never inferred: a
recipe whose source states none waits in the held queue.
