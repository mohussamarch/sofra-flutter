import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/recipe_repository.dart';

export 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Recipes from the online library kept on the phone; the bundled ones are
  // the first-run and offline seed.
  runApp(TabkhaApp(persistent: true, recipes: RecipeRepository.online()));
}
