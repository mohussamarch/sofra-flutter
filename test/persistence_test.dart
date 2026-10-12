import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/state_store.dart';
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
    Widget app(Map<String, dynamic>? data) => MaterialApp(
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SofraHome(store: store, initialData: data),
      ),
    );
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    await exerciseDemoFlow(tester);
    await tester.pumpAndSettle();
    final before = jsonEncode(store.data);
    expect(store.data!['name'], 'مريم');
    expect(store.data!['planned'], isNull);
    final rice = (store.data!['stock'] as List).singleWhere(
      (s) => s['id'] == 'rice',
    );
    expect(rice['quantity'], 100);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(await store.load()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-fridge')), findsOneWidget);
    await tapKey(tester, 'open-home-settings');
    expect(find.text('مريم'), findsWidgets);
    expect(jsonEncode(store.data), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed save is visible and retry saves the pending data', (
    tester,
  ) async {
    final store = TestStore()..fail = true;
    await tester.pumpWidget(MaterialApp(home: SofraHome(store: store)));
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
      await tester.pumpWidget(MaterialApp(home: SofraHome(store: store)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('field-country')));
      await tester.tap(find.byKey(const ValueKey('field-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('السعودية · ريال سعودي').last);
      await tester.pumpAndSettle();
      await completeOnboarding(tester);
      expect(store.data!['country'], 'SA');
      expect(find.byKey(const ValueKey('nav-profile')), findsNothing);
      expect(find.byKey(const ValueKey('open-home-settings')), findsOneWidget);
      expect(find.text('وش بنطبخ اليوم؟'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      await tapKey(tester, 'open-home-settings');
      expect(find.text('مريم'), findsWidgets);
    },
  );
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
