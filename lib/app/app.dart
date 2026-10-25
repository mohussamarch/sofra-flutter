import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../ui/design.dart';
import '../ui/session_gate.dart';
import 'home_shell.dart';
import '../ui/phone_frame.dart';

export 'home_shell.dart' show SofraHome;

class TabkhaApp extends StatelessWidget {
  const TabkhaApp({
    super.key,
    this.persistent = false,
    this.recipes,
    this.readAsset,
    this.showScene = true,
  });
  final bool persistent;
  final RecipeRepository? recipes;
  final Future<String> Function(String path)? readAsset;
  final bool showScene;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'سفرة',
    theme: _theme,
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: PhoneFrame(child: child!),
    ),
    home: persistent
        ? SessionGate(
            builder: (store, data, signOut) => SofraHome(
              key: ObjectKey(store),
              store: store,
              initialData: data,
              signOut: signOut,
              recipes: recipes,
              readAsset: readAsset,
              showScene: showScene,
            ),
          )
        : SofraHome(
            recipes: recipes,
            readAsset: readAsset,
            showScene: showScene,
          ),
  );
}

final _field = OutlineInputBorder(
  borderRadius: BorderRadius.circular(Sofra.r16),
  borderSide: BorderSide.none,
);

final _theme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Tajawal',
  scaffoldBackgroundColor: Sofra.cream,
  splashFactory: InkSparkle.splashFactory,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Sofra.green,
    primary: Sofra.green,
    onPrimary: Colors.white,
    secondary: Sofra.orange,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    hintStyle: const TextStyle(color: Sofra.muted),
    border: _field,
    enabledBorder: _field,
    focusedBorder: _field.copyWith(
      borderSide: const BorderSide(color: Sofra.sage, width: 1.5),
    ),
    errorBorder: _field.copyWith(
      borderSide: const BorderSide(color: Sofra.orange, width: 1.5),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: Sofra.mint,
    side: BorderSide.none,
    labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: Sofra.ink),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r12),
    ),
    showCheckmark: false,
    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Sofra.cream,
    showDragHandle: true,
    dragHandleColor: Sofra.line,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Sofra.r28)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Sofra.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r28),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Sofra.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Sofra.r16),
    ),
  ),
);
