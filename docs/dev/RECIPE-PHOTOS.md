# Recipe photo library — contract (Claude, 26 Oct 2026)

## 1. Catalog dish photos (bundled, works now)

- Folder: `assets/recipe-photos/` (registered in `pubspec.yaml`).
- Manifest: `assets/recipe-photos/manifest.json`

```json
{
  "version": 1,
  "photos": {
    "eg-koshari": [
      {"file": "eg-koshari.webp", "width": 1200, "height": 900,
       "credit": "اسم المصوّر أو الجهة", "licence": "CC BY 4.0",
       "source": "https://..."}
    ]
  }
}
```

- The key is the recipe ID from `recipes/data/index.json`.
- `file` must be lowercase `[a-z0-9-]` plus an optional `-2` suffix, ending in `.webp`, `.jpg` or `.png`.
- `credit` and `licence` are required. A photo without a known licence is rejected when the manifest loads.
- Preferred size: 1200×900 (4:3) WebP, under 150 KB each. The detail screen crops to 4:3.
- The recipe screen shows the first photo, with its credit, in place of the drawn dish.
- A recipe with no entry keeps the drawing. A photo of another dish is never substituted.
- Code: `lib/data/recipe_photo_library.dart` and `SofraController.photosOf`.
- Photo generation stays off (standing user decision). Photos come from the user, from a real shoot, or from openly licensed sources.

## 2. Community photos (slot ready, uploads off)

- Every `communityRecipes/{id}` document has a `photos` list of `{path, by, width?, height?, caption?}`.
- `path` follows `photos/{uid}/{file}`. The model is `PhotoRef` in `lib/domain/community.dart`.
- `firestore.rules` currently allows only an empty list. Uploads open with one rules change once a store is approved.
- Store options (decision pending with the user):
  - **Firebase Storage:** new buckets now need the Blaze plan, which means billing. Not allowed without the user's approval.
  - **Small compressed images inside Firestore documents** (about 200 KB, under the 1 MB document limit): stays on the free tier, but eats into its 1 GiB of storage.
  - **An outside image service:** needs the user's permission and a privacy review.
EOF
cd /e/work/SOFRA/app && echo ok