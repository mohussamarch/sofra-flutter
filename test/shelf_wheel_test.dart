import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/features/shelf_wheel.dart';

void main() {
  testWidgets('shelf wheel holds three items a shelf and edits on tap', (
    tester,
  ) async {
    final tapped = <String>[];
    ShelfItem item(String id) => ShelfItem(
      id: id,
      art: const Text('🍅'),
      label: id,
      amount: '1 حبة',
      onTap: () => tapped.add(id),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShelfWheel(
            title: 'التلاجة',
            items: [
              for (final id in ['a', 'b', 'c', 'd']) item(id),
              const ShelfItem(
                id: 'leftover-x',
                art: CoveredDish(variant: 1),
                label: 'كشري',
                amount: '2 حصة',
              ),
            ],
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('shelf-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-item-a')), findsOneWidget);
    // Taps land on the wheel, which picks the item under the finger.
    await tester.tap(
      find.byKey(const ValueKey('shelf-item-a')),
      warnIfMissed: false,
    );
    expect(tapped, ['a']);
    expect(tester.takeException(), isNull);
  });
}
