import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabkha_demo/data/purchase_reader.dart';
import 'package:tabkha_demo/domain/ingredient_directory.dart';
import 'package:tabkha_demo/domain/quick_add.dart';
import 'package:tabkha_demo/features/quick_add_screen.dart';
import 'package:tabkha_demo/main.dart';

import 'persistence_test.dart' show TestStore;
import 'support/demo_flow.dart';

class FakeReader implements PurchaseReader {
  FakeReader(this.reply, {this.fail = false});
  final String reply;
  final bool fail;
  int images = 0, texts = 0;

  @override
  Future<List<QuickLine>> readImage(
    Uint8List bytes,
    String mimeType,
    IngredientDirectory directory,
  ) async {
    images++;
    if (fail) throw StateError('offline');
    return linesFromReply(reply, directory);
  }

  @override
  Future<List<QuickLine>> readText(
    String text,
    IngredientDirectory directory,
  ) async {
    texts++;
    if (fail) throw StateError('offline');
    return linesFromReply(reply, directory);
  }
}

Future<IngredientDirectory> directory() =>
    IngredientDirectory.load((path) => File(path).readAsString());

void main() {
  test(
    'a typed list becomes lines with amounts only where they are said',
    () async {
      final d = await directory();
      final lines = parseQuickText(
        '٢ كيلو طماطم، لبن\n6 بيض\nنص كيلو جبنة بيضاء؛ كيلو ونص رز\nتونة 3 علبة\nطماطم وخيار\nشيء غريب',
        d,
      );
      String show(QuickLine l) => '${l.entry?.id}:${l.quantity}:${l.unit}';
      expect(lines.map(show), [
        'tomato:2.0:kg',
        'milk:null:null',
        'eggs:6.0:count',
        'white-cheese:0.5:kg',
        'rice:1.5:kg',
        'tuna:3.0:علبة',
        'tomato:null:null',
        'cucumber:null:null',
        'null:null:null',
      ]);
      expect(lines.first.sure, isTrue);
    },
  );

  test(
    'a bare number is not an amount for something not kept by the piece',
    () async {
      final d = await directory();
      final line = parseQuickText('2 لبن', d).single;
      expect(line.entry!.id, 'milk');
      expect(line.quantity, isNull);
    },
  );

  test(
    'a longer product text finds the ingredient inside it, flagged to check',
    () async {
      final d = await directory();
      final found = matchIngredient(d, 'لبن جهينة كامل الدسم')!;
      expect(found.entry.id, 'milk');
      expect(found.sure, isFalse);
      expect(matchIngredient(d, 'الطماطم')!.entry.id, 'tomato');
      expect(matchIngredient(d, 'xyz'), isNull);
    },
  );

  test(
    'the reader reply is not trusted: bad ids, units and numbers are dropped',
    () async {
      final d = await directory();
      final lines = linesFromReply(
        '{"items":['
        '{"raw":"JUHAYNA MILK 1L x2","id":"milk","name":"لبن","quantity":2,"unit":"l","paid":84.5},'
        '{"raw":"Tomato","id":"no-such-id","name":"طماطم","quantity":1,"unit":"علبة","paid":0},'
        '{"raw":"Shampoo","id":"","name":"","quantity":-3,"unit":"","paid":-1}'
        ']}',
        d,
      );
      expect(lines[0].entry!.id, 'milk');
      expect(lines[0].quantity, 2);
      expect(lines[0].unit, 'l');
      expect(lines[0].paid, 84.5);
      expect(lines[1].entry!.id, 'tomato');
      expect(lines[1].quantity, isNull, reason: 'tomato is not kept in cans');
      expect(lines[1].paid, isNull);
      expect(lines[2].entry, isNull);
      expect(linesFromReply('', d), isEmpty);
    },
  );

  testWidgets(
    'typed list and receipt photo are reviewed, then saved in one go',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = FakeReader(
        '{"items":['
        '{"raw":"JUHAYNA MILK 1L x2","id":"milk","name":"لبن","quantity":2,"unit":"l","paid":84.5},'
        '{"raw":"MYSTERY ITEM","id":"","name":"","quantity":0,"unit":"","paid":10}'
        ']}',
      );
      final oldReader = purchaseReader, oldPick = pickPurchaseImage;
      purchaseReader = () => reader;
      pickPurchaseImage = (_) async => (Uint8List(4), 'image/jpeg');
      addTearDown(() {
        purchaseReader = oldReader;
        pickPurchaseImage = oldPick;
      });
      final store = TestStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
            ),
          ),
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
      await completeOnboarding(tester);
      await openStock(tester);

      // Typed: read on the phone, the reader is never called.
      await tapKey(tester, 'quick-add');
      await tester.enterText(
        find.byKey(const ValueKey('quick-add-text')),
        '2 كيلو طماطم، 6 بيض، لبن',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'quick-add-read');
      expect(reader.texts, 0);
      expect(find.text('3 جاهزة'), findsOneWidget);
      // Milk has no amount: give it one.
      await tapKey(tester, 'quick-amount-2');
      await tester.enterText(
        find.byKey(const ValueKey('quick-amount-input')),
        '1.5',
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'quick-amount-save');
      await tapKey(tester, 'quick-add-save');
      List stock() => (store.data!['kitchen'] as Map)['inventory'] as List;
      Map lot(String id) => stock().singleWhere((v) => v['ingredientId'] == id);
      expect(lot('tomato')['quantity'], 2);
      expect(lot('tomato')['unit'], 'kg');
      expect(lot('eggs')['quantity'], 6);
      expect(lot('milk')['quantity'], 1.5);
      expect(lot('milk')['unit'], 'l');

      // Photo: the reader's draft, one line without an ingredient.
      await tapKey(tester, 'quick-add');
      await tapKey(tester, 'quick-add-camera');
      expect(reader.images, 1);
      expect(find.text('1 بلا مكوّن'), findsOneWidget);
      await tapKey(tester, 'quick-add-save');
      expect(
        lot('milk')['quantity'],
        3.5,
        reason: 'joins the lot already there',
      );
      final kitchen = store.data!['kitchen'] as Map;
      expect((kitchen['purchases'] as List).single['amount'], 84.5);
      expect(
        (kitchen['prices'] as List).single,
        containsPair('ingredientId', 'milk'),
      );
      expect(stock().length, 3, reason: 'the unknown line is not added');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed photo read says so and leaves typing open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final oldReader = purchaseReader, oldPick = pickPurchaseImage;
    purchaseReader = () => FakeReader('', fail: true);
    pickPurchaseImage = (_) async => (Uint8List(4), 'image/jpeg');
    addTearDown(() {
      purchaseReader = oldReader;
      pickPurchaseImage = oldPick;
    });
    final store = TestStore();
    await tester.pumpWidget(
      MaterialApp(
        // As in the app: its snack bars float.
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
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
    await completeOnboarding(tester);
    await openStock(tester);
    await tapKey(tester, 'quick-add');
    await tapKey(tester, 'quick-add-gallery');
    expect(find.byKey(const ValueKey('quick-add-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-add-text')), findsOneWidget);
    expect(((store.data!['kitchen'] as Map)['inventory'] as List), isEmpty);
  });
}
