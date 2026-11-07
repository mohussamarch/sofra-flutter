import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/main.dart';

import 'persistence_test.dart' show TestStore;
import 'support/demo_flow.dart';

void main() {
  for (final scale in [1.0, 1.4]) {
    testWidgets(
      'setup: no house name, pictured choices and full lists at ${scale}x text',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = TestStore();
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SofraHome(
                store: store,
                recipes: await warmRecipes(tester),
                readAsset: await warmAssets(tester),
                showScene: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'country-saudi');
        await tapKey(tester, 'onboarding-next');
        expect(find.byKey(const ValueKey('field-house')), findsNothing);
        await tester.enterText(
          find.byKey(const ValueKey('field-name')),
          'مريم',
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'onboarding-next');

        // Table: three pictured meals.
        await tapKey(tester, 'meal-فطار');
        expect(store.data!['meals'], containsAll(['فطار', 'غداء', 'عشاء']));
        await tapKey(tester, 'onboarding-next');

        // Taste: the country's cuisines on the page, the rest in the list.
        expect(find.byKey(const ValueKey('cuisine-saudi')), findsOneWidget);
        expect(find.byKey(const ValueKey('cuisine-italian')), findsNothing);
        await tapKey(tester, 'more-cuisine');
        await tapKey(tester, 'cuisine-italian');
        await tapKey(tester, 'picker-done');
        expect(store.data!['cuisineGroups'], contains('italian'));
        await tapKey(tester, 'onboarding-next');

        // Health: two on the page, the rest and own names in the list.
        await tapKey(tester, 'health-السكري');
        await tapKey(tester, 'more-health');
        // Lower in the list: scroll it in and let the list settle first.
        await tester.ensureVisible(find.byKey(const ValueKey('health-الحمل')));
        await tester.pumpAndSettle();
        await tapKey(tester, 'health-الحمل');
        await tester.enterText(
          find.byKey(const ValueKey('field-health-search')),
          'الربو',
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'add-health');
        await tapKey(tester, 'picker-done');
        expect(
          store.data!['health'],
          unorderedEquals(['السكري', 'الحمل', 'الربو']),
        );
        await tapKey(tester, 'allergy-ألبان');
        expect(store.data!['allergies'], ['ألبان']);
        await tapKey(tester, 'onboarding-next');

        expect(find.text('أهلًا مريم!'), findsOneWidget);
        await tapKey(tester, 'onboarding-next');
        expect(store.data!['onboarded'], isTrue);
        expect(store.data!['country'], 'SA');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
