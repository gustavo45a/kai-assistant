import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantablack_hub/main.dart';
import 'package:vantablack_hub/ui/screens/kai_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
  });

  testWidgets('VantablackApp smoke test renders setup on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const VantablackApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(VantablackApp), findsOneWidget);
    expect(find.byType(KaiSetupScreen), findsOneWidget);
  });
}
