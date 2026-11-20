# Online recipe library

Recipes reach the app from a separate Firebase Hosting site on `sofra-c03a1`
(target `library`, site `sofra-library`), so new or corrected recipes arrive
without an app-store update. The web app site (target `app`, site
`sofra-c03a1`) keeps its exact previous config.

## Adding recipes (owner)

1. Add or edit recipes in `recipes/data` with the existing importer/tools.
2. Publish and deploy, one command from the repository root:

```bash
node tool/recipes/publish-library.mjs && firebase deploy --only hosting:library --project sofra-c03a1
```

Phones pick the new library up at the next launch or recipes-tab visit after
6 hours, or at once with «تحديث الآن» in Settings → «الوصفات على جهازك».
Never deploy plain `--only hosting`: that would also redeploy the web app.

### Deployed (2026-11-21)

Site `sofra-library` was created on sofra-c03a1 and is live at
https://sofra-library.web.app/ (the app's default `SOFRA_LIBRARY_URL`); the
Firestore rules with `savedRecipes` are released. First live version
`8ebced9c976c…` (495 active recipes, 789 bodies).

### Safety built into the publisher and the app

- The publisher runs the app's own catalog checks (15 primary groups plus
  other, group counts, held rows outside groups, listing ingredient lines) and
  refuses to write a library the app would reject.
- `--out` refuses the repository root, the recipe data, or a non-empty folder
  that is not an earlier library build.
- Body files of the previous build stay one more version, so a phone still on
  the old catalog can open recipes; the app also retries a 404 after taking
  the new catalog. Publish from the same `build/library` folder each time.
- The app checks at most every 6 hours, waits 30 minutes after a failed check,
  and does not download a rejected version again until a new one is published.

## What is published (`build/library/`, gitignored)

| File | Cache | Content |
|---|---|---|
| `manifest.json` | no-cache | `schema`, `version` (hash of the files map), `generatedAt`, `recipeCount`, `files` (`index.json`, `dishes.json` → `sha256`, `size`), `bodies` (`count`, `size`) |
| `index.json` | no-cache | every catalog row plus `body` (sha256 of its body file), for active rows `ingredients` (`id`, `name`, `amount`, `unit`, `scale`, `optional`), and optional `thumbnail` / `photos[]` image references |
| `dishes.json` | no-cache | dish groups |
| `r/<sha256>.json` | 1 year, immutable | one full recipe each, content addressed |
| `img/**` (later) | 30 days | images, see below |

The output is deterministic; `generatedAt` changes only when the content does
(or pass `--generated-at` / `SOURCE_DATE_EPOCH`). CORS is open (`*`) so the web
build can read it. `node --test tool/recipes/publish-library.test.mjs` checks
the publisher. Firebase Hosting serves JSON gzip/brotli compressed: today the
index is about 0.94 MB raw, all bodies about 4.9 MB raw.

## App side

- `lib/data/online_recipe_library.dart` (`OnlineRecipeLibrary`): memory → device
  (shared_preferences: app storage on Android, localStorage on web) → network
  (`--dart-define=SOFRA_LIBRARY_URL=…`, default `https://sofra-library.web.app/`)
  → the bundled recipes as seed. Every file is checked against its sha256
  before use; a new catalog is written under its hash and only then pointed to
  by the stored manifest (atomic swap). A failed or partial download changes
  nothing.
- `RecipeRepository.online()` (used by `main.dart`) falls back to the bundled
  recipes (`recipes/data` assets) for first run and offline. Removing those
  assets later shrinks the APK by about 5 MB raw (0.64 MB compressed) but
  leaves first-run-offline users with no catalog.
- Kept on the phone: the catalog index (listing, search, filters, stock
  matching use it alone), plus full recipes one by one, only once opened,
  cooked, planned or saved. Bodies are capped at `maxBodyBytes` (30 MB on
  Android, 1.5 MB on web); past it the least recently used opened recipes are
  evicted. Saved ones are pinned (never evicted) and also copied to the
  account (`users/{uid}/savedRecipes/{id}` or `kitchens/{id}/savedRecipes/{id}`,
  outside the 850KB state document), so a new phone restores them and they
  survive the library dropping them (they then list only under «محفوظة»).
- A full device store (web localStorage quota) first gives up opened recipes;
  a recipe still opens from memory, and a new catalog that does not fit leaves
  the old one in place. At about 2000 recipes the index alone nears 3 MB, so
  the web build should then move the library store to IndexedDB.
- Checked at launch and when opening the recipes tab, at most every 6 hours,
  never blocking a screen; a recipe neither on the device, reachable nor
  bundled shows a short error with retry.

## Images (later)

Each recipe will get a thumbnail and several step photos; at ~2000 recipes
that is about 100 MB. The Spark plan allows about 10 GB hosting storage and
**about 360 MB of hosting transfer per day**, so images must never be fetched
in bulk:

- The index stays text only. A row may carry `thumbnail` (one reference) and
  `photos` (step photos), each an `https://` URL or a path under `img/` on the
  library site; the publisher (`imageFields`) and the app
  (`RecipeRepository.thumbnailOf` / `photosOf`) reject anything else and the
  app drops a bad reference rather than the catalog. The fields can sit on the
  index row or on the recipe in `recipes/data`; the row wins.
- Files: compressed WebP, thumbnails about 320 px wide (~15–25 KB), step
  photos about 1080 px (~60–120 KB). Name them by content hash
  (`img/<sha256>.webp`) so the 30-day cache never shows a stale image; the
  publisher would copy them from a source folder into `build/library/img/`.
- Thumbnail: loaded lazily, only while its card is on screen (list builders
  already build cards on demand), through the platform image cache, not the
  library store.
- Step photos: loaded only once the recipe is opened. A saved recipe may
  later pin its photos too; they would count against a separate image cap.

Tests: `test/online_recipe_library_test.dart` (manifest diff, sha256
rejection, offline cache/seed fallback, size cap and LRU, full store, image
references, dropped recipes), `test/saved_recipes_library_test.dart` (pinning,
account copy restore, settings counts), `test/online_recipe_library_http_test.dart`
(real publisher output over real HTTP on localhost), `tool/rules/rules.test.mjs`
(saved recipe rules; needs the Firestore emulator and JDK 21+).
