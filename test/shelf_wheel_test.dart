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

  testWidgets('shelves narrow by category and by name', (tester) async {
    ShelfItem item(String id, String label, String group) => ShelfItem(
      id: id,
      art: const Text('🥕'),
      label: label,
      amount: '1',
      group: group,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShelfWheel(
            title: 'التلاجة',
            items: [
              item('carrot', 'جزر', 'خضار'),
              item('tomato', 'طماطم', 'خضار'),
              item('milk', 'لبن', 'ألبان'),
              item('leftover-x', 'كشري', 'بواقي'),
            ],
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    Finder shelf(String id) => find.byKey(ValueKey('shelf-item-$id'));
    await tester.tap(find.byKey(const ValueKey('shelves-group-خضار')));
    await tester.pump();
    expect(shelf('carrot'), findsOneWidget);
    expect(shelf('milk'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('shelves-group-all')));
    await tester.tap(find.byKey(const ValueKey('shelves-search')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('shelves-query')), 'كشرى');
    await tester.pump();
    expect(shelf('leftover-x'), findsOneWidget, reason: 'ى and ي match');
    expect(shelf('carrot'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('shelves-query')), 'زيت');
    await tester.pump();
    expect(find.text('مفيش حاجة بالاسم ده هنا.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
