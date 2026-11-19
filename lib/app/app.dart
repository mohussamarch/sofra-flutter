import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../l10n/l10n.dart';
import 'look.dart';
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
  Widget build(BuildContext context) => ValueListenableBuilder<SofraLook>(
    // The language picks the locale (system widgets, reading direction);
    // the rest of the look is applied by LookRoot below.
    valueListenable: SofraLook.notifier,
    builder: (context, look, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: sofraTheme(),
      locale: look.language.locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.delegates,
      builder: (context, child) => LookRoot(
        child: Directionality(
          textDirection: look.language.direction,
          child: PhoneFrame(child: child!),
        ),
      ),
      home: persistent
          ? SessionGate(
              builder: (store, data, signOut, links) => SofraHome(
                key: ObjectKey(store),
                store: store,
                initialData: data,
                signOut: signOut,
                community: links?.community,
                reopen: links?.reopen,
                communityPreview: links?.preview ?? false,
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
    ),
  );
}
