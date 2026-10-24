import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../ui/design.dart';
import '../ui/session_gate.dart';
import 'home_shell.dart';

export 'home_shell.dart' show SofraHome;

class TabkhaApp extends StatelessWidget {
  const TabkhaApp({
    super.key,
    this.persistent = false,
    this.recipes,
    this.readAsset,
  });
  final bool persistent;
  final RecipeRepository? recipes;
  final Future<String> Function(String path)? readAsset;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'سفرة',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: Sofra.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Sofra.green,
        primary: Sofra.green,
        onPrimary: Colors.white,
        surface: Sofra.cream,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Sofra.ink, fontSize: 15, height: 1.45),
        bodyLarge: TextStyle(color: Sofra.ink, fontSize: 16, height: 1.45),
        titleLarge: TextStyle(color: Sofra.ink, fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: Sofra.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.line, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Sofra.green, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Sofra.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: persistent
        ? SessionGate(
            builder: (store, data, signOut) => SofraHome(
              key: ObjectKey(store),
              store: store,
              initialData: data,
              signOut: signOut,
              recipes: recipes,
              readAsset: readAsset,
            ),
          )
        : SofraHome(recipes: recipes, readAsset: readAsset),
  );
}
