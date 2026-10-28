import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/app/reminders.dart';
import 'package:tabkha_demo/data/community_backend.dart';
import 'package:tabkha_demo/data/state_store.dart';
import 'package:tabkha_demo/features/barcode_scan.dart';
import 'package:tabkha_demo/main.dart';

import 'support/demo_flow.dart';

class TestStore implements StateStore {
  Map<String, dynamic>? data;
  bool fail = false;
  @override
  String get label => 'محفوظ للاختبار';
  @override
  Future<Map<String, dynamic>?> load() async => data;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (fail) throw StateError('Unavailable');
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}

void main() {
  testWidgets('cooking result and profile survive closing and reopening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TestStore();
    final recipes = await warmRecipes(tester);
    final assets = await warmAssets(tester);
    Widget app(Map<String, dynamic>? data) => MaterialApp(
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SofraHome(
          store: store,
          initialData: data,
          recipes: recipes,
          readAsset: assets,
          showScene: false,
        ),
      ),
    );
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    await exerciseDemoFlow(tester);
    await tester.pumpAndSettle();
    final before = jsonEncode(store.data);
    expect(store.data!['name'], 'مريم');
    final kitchen = store.data!['kitchen'] as Map;
    final onion = (kitchen['inventory'] as List).singleWhere(
      (s) => s['ingredientId'] == 'onion',
    );
    expect(onion['quantity'], 0);
    final cooked = (kitchen['history'] as List).single as Map;
    expect(cooked['recipeId'], 'eg-koshari');
    expect(cooked['cost'], isNull);
    expect(cooked['untrackedStockLines'], isNotEmpty);
    expect((kitchen['plans'] as List).single['completed'], isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(await store.load()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('circle-style')), findsOneWidget);
    await openCorner(tester, 'profile');
    expect(find.text('مريم'), findsWidgets);
    expect(jsonEncode(store.data), before);

    // The kitchen's look is saved with the profile.
    await openCorner(tester, 'style');
    expect(find.byKey(const ValueKey('look-cane')), findsNothing);
    for (final key in [
      'look-style-japandi',
      'look-cane',
      'look-rug-rug_teal',
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tapKey(tester, key);
    }
    expect(store.data!['kitchenLook'], {
      'style': 'japandi',
      'cane': '1',
      'rug': 'rug_teal',
    });
    await tester.ensureVisible(
      find.byKey(const ValueKey('look-style-classic')),
    );
    await tapKey(tester, 'look-style-classic');
    expect((store.data!['kitchenLook'] as Map).containsKey('style'), isFalse);
    expect(find.byKey(const ValueKey('style-cabinet-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save is visible and retry saves the pending data', (
    tester,
  ) async {
    final store = TestStore()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SofraHome(
          store: store,
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'onboarding-next');
    await tester.enterText(find.byKey(const ValueKey('field-name')), 'اختبار');
    await tester.pumpAndSettle();
    expect(find.text('إعادة الحفظ'), findsOneWidget);
    expect(store.data, isNull);
    store.fail = false;
    await tester.tap(find.text('إعادة الحفظ'));
    await tester.pumpAndSettle();
    expect(store.data!['name'], 'اختبار');
    expect(find.text('إعادة الحفظ'), findsNothing);
  });

  test(
    'writer serializes immutable snapshots and recovers after failure',
    () async {
      final store = DelayedStore();
      final writer = StateWriter(store);
      final input = <String, dynamic>{'quantity': 1};
      final first = writer.save(input);
      input['quantity'] = 2;
      final second = writer.save(input);
      await Future<void>.delayed(Duration.zero);
      expect(store.received, [1]);
      store.first.complete();
      await Future.wait([first, second]);
      expect(store.received, [1, 2]);
      final failing = TestStore()..fail = true;
      final recovery = StateWriter(failing);
      await expectLater(recovery.save({'value': 1}), throwsStateError);
      failing.fail = false;
      await recovery.save({'value': 2});
      expect(failing.data!['value'], 2);
    },
  );
  testWidgets(
    'country selection persists and home settings leave the bottom bar',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TestStore();
      await tester.pumpWidget(
        MaterialApp(
          home: SofraHome(
            store: store,
            recipes: await warmRecipes(tester),
            readAsset: await warmAssets(tester),
            showScene: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('field-country')));
      await tester.tap(find.byKey(const ValueKey('field-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('السعودية · ريال سعودي').last);
      await tester.pumpAndSettle();
      await completeOnboarding(tester);
      expect(store.data!['country'], 'SA');
      expect(find.byKey(const ValueKey('circle-profile')), findsOneWidget);
      await tapKey(tester, 'nav-table');
      expect(find.text('على سفرة اليوم'), findsOneWidget);
      await openCorner(tester, 'profile');
      expect(find.text('مريم'), findsWidgets);
    },
  );
  testWidgets('reminder choices in settings are saved', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TestStore();
    final sink = SilentReminders();
    await tester.pumpWidget(
      MaterialApp(
        home: SofraHome(
          store: store,
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
          reminders: sink,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await openCorner(tester, 'settings');
    expect(find.text('دون تذكير'), findsNWidgets(3));
    await tapKey(tester, 'reminder-before-60');
    await tapKey(tester, 'reminder-stock');
    expect(store.data!['remindBefore'], 60);
    expect(store.data!['stockAlerts'], isFalse);
    // No meal time set yet, so nothing is scheduled.
    expect(sink.scheduled, isEmpty);
  });
  testWidgets('a scanned code is linked once, then goes straight to amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    scanWithCamera = false;
    addTearDown(() => scanWithCamera = true);
    final store = TestStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: SofraHome(
          store: store,
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
          reminders: SilentReminders(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await openStock(tester);
    await tapKey(tester, 'add-ingredients');
    await tapKey(tester, 'add-stock-scan');
    await tester.enterText(
      find.byKey(const ValueKey('barcode-manual')),
      '6220000000001',
    );
    await tapKey(tester, 'barcode-manual-go');
    expect(find.text('هذا المنتج غير موجود في بياناتنا بعد'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('scan-search')), 'رز');
    await tester.pumpAndSettle();
    await tapKey(tester, 'scan-pick-rice');
    expect(store.data!['barcodeLinks'], {'6220000000001': 'rice'});
    await tester.enterText(find.byKey(const ValueKey('add-amount')), '250');
    await tapKey(tester, 'add-unit-g');
    await tapKey(tester, 'add-stock-save');

    await tapKey(tester, 'add-stock-scan');
    await tester.enterText(
      find.byKey(const ValueKey('barcode-manual')),
      '6220000000001',
    );
    await tapKey(tester, 'barcode-manual-go');
    expect(find.byKey(const ValueKey('scan-search')), findsNothing);
    expect(find.byKey(const ValueKey('add-amount')), findsOneWidget);
  });
  testWidgets('community: join a kitchen by code, then the other parts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final server = MemoryServer();
    final owner = MemoryCommunity(server, 'alice');
    final kid = await owner.createSharedKitchen(const {'schema': 1}, 'Alice');
    final code = await owner.createInvite(kid);
    var reopened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: SofraHome(
          store: TestStore(),
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
          reminders: SilentReminders(),
          community: MemoryCommunity(server, 'bob'),
          reopen: () => reopened++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await openCorner(tester, 'community');
    // Home first: story ring to add, creator circles, empty feed.
    expect(find.byKey(const ValueKey('story-add')), findsOneWidget);
    expect(find.byKey(const ValueKey('creator-manal-alalem')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-recipes-empty')),
      findsOneWidget,
    );
    await tapKey(tester, 'story-add');
    await tester.enterText(
      find.byKey(const ValueKey('story-text')),
      'عملنا ملوخية',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'story-color-3');
    await tapKey(tester, 'story-post');
    expect(server.stories.single.text, 'عملنا ملوخية');
    // The viewer runs a timer, so step frames instead of settling.
    await tester.tap(find.byKey(const ValueKey('story-ring-bob')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('عملنا ملوخية'), findsWidgets);
    expect(find.byKey(const ValueKey('story-text-shown')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('story-close')));
    await tester.pumpAndSettle();
    await tapKey(tester, 'creator-manal-alalem');
    expect(find.byKey(const ValueKey('creator-name')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tapKey(tester, 'community-kitchen');
    expect(find.byKey(const ValueKey('kitchen-share')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('kitchen-code')), 'nope');
    await tapKey(tester, 'kitchen-join');
    expect(find.byKey(const ValueKey('kitchen-error')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('kitchen-code')), code);
    await tapKey(tester, 'kitchen-join');
    expect(reopened, 1);
    expect(server.kitchens[kid]!['members'], ['alice', 'bob']);
    await tapKey(tester, 'community-prices');
    expect(find.text('اكتب منطقتك أولًا.'), findsOneWidget);
    await tapKey(tester, 'community-challenge');
    await tapKey(tester, 'challenge-join');
    expect(find.byKey(const ValueKey('challenge-entry-bob')), findsOneWidget);
  });

  testWidgets('community without an account says it needs one', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: SofraHome(
          recipes: await warmRecipes(tester),
          readAsset: await warmAssets(tester),
          showScene: false,
          reminders: SilentReminders(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await openCorner(tester, 'community');
    expect(
      find.byKey(const ValueKey('community-needs-account')),
      findsOneWidget,
    );
  });
}

class DelayedStore extends TestStore {
  final first = Completer<void>();
  final received = <int>[];
  @override
  Future<void> save(Map<String, dynamic> value) async {
    received.add(value['quantity'] as int);
    if (received.length == 1) await first.future;
    await super.save(value);
  }
}
