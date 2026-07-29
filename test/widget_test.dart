import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/main.dart';

void main() {
  testWidgets('VantablackApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VantablackApp());
    expect(find.byType(VantablackApp), findsOneWidget);
  });
}
