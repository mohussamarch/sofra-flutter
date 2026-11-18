import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/features/onboarding_screen.dart';
import 'package:tabkha_demo/features/profile_screen.dart';

void main() {
  testWidgets('shows only chosen values; the rest are added from the menu', (
    tester,
  ) async {
    var selected = {'بيض', 'كزبرة'};
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PickedGroup(
                id: 'avoid',
                title: 'حساسية الأكل',
                empty: 'لا توجد حساسية',
                options: setupAvoid,
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('avoid-بيض')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('avoid-كزبرة')),
      findsOneWidget,
      reason: 'a value typed during setup still shows',
    );
    expect(find.text('سمسم'), findsNothing, reason: 'not chosen, not shown');

    await tester.tap(find.byKey(const ValueKey('avoid-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('avoid-pick-بيض')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('avoid-pick-سمسم')));
    await tester.pumpAndSettle();
    expect(selected, {'بيض', 'كزبرة', 'سمسم'});

    await tester.tap(find.byKey(const ValueKey('avoid-بيض')));
    await tester.pumpAndSettle();
    expect(selected, {'كزبرة', 'سمسم'});

    await tester.tap(find.byKey(const ValueKey('avoid-كزبرة')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avoid-سمسم')));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد حساسية'), findsOneWidget);
  });
}
