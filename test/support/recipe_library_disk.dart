import 'dart:io';

import 'package:tabkha_demo/data/recipe_library_assets.dart';
import 'package:tabkha_demo/data/recipe_library_repository.dart';

/// The pinned recipe library read from disk. It is not bundled into the app
/// (nothing in the UI reads it yet), so tests cannot load it from assets.
RecipeLibraryRepository bundledRecipeLibrary() => RecipeLibraryRepository(
  expectedManifestSha256: recipeLibraryManifestSha256,
  read: (path) => File(path).readAsString(),
);
