import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

void main() {
  testWidgets('complete Arabic phone flow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TabkhaApp());
    await tester.pumpAndSettle();
    await exerciseDemoFlow(tester);
  });
}
