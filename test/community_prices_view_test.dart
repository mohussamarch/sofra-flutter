import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/data/community_backend.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/domain/community.dart';
import 'package:tabkha_demo/features/community_prices.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

class _Store implements StateStore {
  Map<String, dynamic>? data;
  @override
  String get label => 'محفوظ للاختبار';
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> save(Map<String, dynamic> value) async => data = value;
}

/// A community whose area reads or price shares can be made to fail.
class _FlakyCommunity extends MemoryCommunity {
  _FlakyCommunity(super.server, super.uid);
  bool failReads = false, failShares = false;

  @override
  Future<List<PriceReport>> areaReports(String country, String area) async {
    if (failReads) throw StateError('unavailable');
    return super.areaReports(country, area);
  }

  @override
  Future<void> reportPrice(PriceReport report) async {
    if (failShares) throw StateError('unavailable');
    return super.reportPrice(report);
  }
}

const _area = 'الزمالك، القاهرة';

Future<void> _seed(MemoryServer server, List<double> amounts) async {
  var i = 0;
  for (final amount in amounts) {
    final uid = 'u${i++}';
    await MemoryCommunity(server, uid).reportPrice(
      PriceReport(
        uid: uid,
        country: 'EG',
        area: _area,
        ingredientId: 'tomato',
        quantity: 1,
        unit: 'kg',
        amount: amount,
        paidOn: DateTime.now(),
      ),
    );
  }
}

Future<void> _openPrices(
  WidgetTester tester,
  CommunityBackend community,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: SofraHome(
        store: _Store(),
        recipes: await warmRecipes(tester),
        readAsset: await warmAssets(tester),
        showScene: false,
        reminders: SilentReminders(),
        community: community,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await completeOnboarding(tester);
  await openCorner(tester, 'community');
  await tapKey(tester, 'community-prices');
}

Future<void> _chooseArea(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('price-area')), 'الزمالك');
  await tester.pumpAndSettle();
  await tapKey(tester, 'place-$_area');
  await tapKey(tester, 'price-group-خضار');
}

Finder _inCell(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  setUpAll(() => AreaPricesView.live = false);

  test('prices show as plain Latin decimals, never fraction signs', () {
    expect(priceText(25), '25');
    expect(priceText(12.5), '12.5');
    expect(priceText(7.10), '7.1');
    expect(priceText(50 / 3), '16.67');
    expect(priceText(12.999), '13');
    expect(parsePrice(priceText(12.5)), 12.5);
  });

  testWidgets('an area price opens prefilled and saves only on confirm', (
    tester,
  ) async {
    final server = MemoryServer();
    await _seed(server, [10, 15]);
    await _openPrices(tester, MemoryCommunity(server, 'bob'));
    await _chooseArea(tester);
    expect(_inCell('area-price-tomato', '12.5'), findsOneWidget);
    expect(_inCell('my-price-tomato', '12.5'), findsNothing);

    await tapKey(tester, 'area-price-tomato');
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('price-input')),
    );
    expect(field.controller!.text, '12.5');
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(_inCell('my-price-tomato', '12.5'), findsNothing);

    await tapKey(tester, 'area-price-tomato');
    await tapKey(tester, 'price-save');
    expect(_inCell('my-price-tomato', '12.5'), findsOneWidget);

    // An existing decimal price reopens as typed and saves unchanged.
    await tapKey(tester, 'my-price-tomato');
    await tapKey(tester, 'price-save');
    expect(find.byKey(const ValueKey('price-input')), findsNothing);
    expect(_inCell('my-price-tomato', '12.5'), findsOneWidget);
  });

  testWidgets('sharing refreshes the area price on screen', (tester) async {
    final server = MemoryServer();
    await _seed(server, [20, 30]);
    await _openPrices(tester, MemoryCommunity(server, 'bob'));
    await _chooseArea(tester);
    expect(_inCell('area-price-tomato', '25'), findsOneWidget);
    await tapKey(tester, 'my-price-tomato');
    await tester.enterText(find.byKey(const ValueKey('price-input')), '22');
    await tapKey(tester, 'price-share');
    await tapKey(tester, 'price-save');
    // 20, 22 and 30: the new median.
    expect(_inCell('area-price-tomato', '22'), findsOneWidget);
    expect(find.text('حُفظ سعرك وشاركته مع منطقتك'), findsOneWidget);
  });

  testWidgets('a failed share keeps the saved price and says so', (
    tester,
  ) async {
    final server = MemoryServer();
    final community = _FlakyCommunity(server, 'bob');
    await _openPrices(tester, community);
    await _chooseArea(tester);
    community.failShares = true;
    await tapKey(tester, 'my-price-tomato');
    await tester.enterText(find.byKey(const ValueKey('price-input')), '18');
    await tapKey(tester, 'price-share');
    await tapKey(tester, 'price-save');
    expect(find.text('حُفظ سعرك، وتعذّرت مشاركته.'), findsOneWidget);
    expect(_inCell('my-price-tomato', '18'), findsOneWidget);
    expect(server.prices, isEmpty);
  });

  testWidgets('failed area prices keep own prices and offer a retry', (
    tester,
  ) async {
    final server = MemoryServer();
    await _seed(server, [20, 30]);
    final community = _FlakyCommunity(server, 'bob')..failReads = true;
    await _openPrices(tester, community);
    await _chooseArea(tester);
    expect(find.text('تعذّر جلب أسعار المنطقة.'), findsOneWidget);
    for (final (category, _, _) in priceGroups) {
      expect(
        find.byKey(ValueKey('price-group-$category')),
        findsOneWidget,
        reason: category,
      );
    }
    expect(find.byKey(const ValueKey('my-price-tomato')), findsOneWidget);
    expect(_inCell('area-price-tomato', '25'), findsNothing);

    community.failReads = false;
    await tapKey(tester, 'area-prices-retry');
    expect(find.byKey(const ValueKey('area-prices-retry')), findsNothing);
    expect(_inCell('area-price-tomato', '25'), findsOneWidget);
  });

  testWidgets('a search with no match says so', (tester) async {
    await _openPrices(tester, MemoryCommunity(MemoryServer(), 'bob'));
    expect(find.text('لا نتائج'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('price-area')), 'ززززز');
    await tester.pumpAndSettle();
    expect(find.text('لا نتائج'), findsOneWidget);
  });

  testWidgets('a large price shrinks to fit its cell at large text', (
    tester,
  ) async {
    final server = MemoryServer();
    await _seed(server, [1250.5, 1250.5]);
    await _openPrices(tester, MemoryCommunity(server, 'bob'));
    await _chooseArea(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final number = find.descendant(
      of: find.byKey(const ValueKey('area-price-tomato')),
      matching: find.text('1250.5'),
    );
    expect(number, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(number);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      tester.getSize(find.byKey(const ValueKey('area-price-tomato'))).width,
      78,
    );
  });
}
