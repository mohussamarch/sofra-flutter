import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tabkha_demo/main.dart' as app;

import '../test/support/demo_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('house to recipe to planned meal to confirmed cooking', (
    tester,
  ) async {
    await tester.pumpWidget(const app.TabkhaApp());
    await tester.pumpAndSettle();

    await exerciseDemoFlow(tester);
  });
}
