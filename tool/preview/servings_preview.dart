// Screenshot preview of the app: no kitchen scene, onboarding skipped.
//
//   flutter build web -t tool/preview/servings_preview.dart //     --dart-define=SOFRA_PREVIEW=true -o build/preview
//   then open index.html?recipe=<id> (served over http).
import 'package:flutter/material.dart';
import 'package:tabkha_demo/main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TabkhaApp(showScene: false));
}
