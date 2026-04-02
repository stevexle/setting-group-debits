import 'package:flutter_test/flutter_test.dart';
import 'package:setting_group_debits/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SettlementApp());

    // Verify that our dashboard is present.
    expect(find.text('Quyết toán nợ nhóm'), findsOneWidget);
  });
}
