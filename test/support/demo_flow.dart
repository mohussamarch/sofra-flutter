import 'package:flutter_test/flutter_test.dart';

Future<void> exerciseDemoFlow(WidgetTester tester) async {
  Future<void> tapText(String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  await tapText('يلا نضيف المكونات');
  await tapText('حمّل مكونات المثال');
  await tapText('شوفي تلجتي');
  expect(find.text('دي تلجتك'), findsOneWidget);
  await tapText('اقترحي وصفات');
  await tapText('فراخ بالفرن مع رز وسلطة');
  expect(find.textContaining('ناقص 200'), findsWidgets);
  await tapText('ضيفي الوجبة للسفرة');
  expect(find.text('السفرة جاهزة للتخطيط'), findsOneWidget);
  await tapText('حاكي شراء الناقص وإضافته للمخزون');
  await tapText('ابدئي طبخة النهاردة');
  for (var i = 0; i < 3; i++) {
    await tapText('الخطوة اللي بعدها');
  }
  await tapText('خلصنا الطبخ · اخصمي المكونات');
  expect(find.text('بالهنا والشفا!'), findsOneWidget);
}
