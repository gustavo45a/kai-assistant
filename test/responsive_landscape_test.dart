import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantablack_hub/models/app_theme.dart';
import 'package:vantablack_hub/models/chat_thread.dart';
import 'package:vantablack_hub/ui/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'vantablack_threads': jsonEncode([
        ChatThread(
          id: 'test_thread_1',
          title: 'Matriz LLAMA 3.2',
          iaModel: 'llama_3_2_1b',
          modeloInicializado: true,
          messages: [
            {'sender': 'system', 'text': 'Sistema iniciado.'},
            {'sender': 'user', 'text': 'Hola KAI'},
            {'sender': 'bot', 'text': 'Hola Gustavo, ¿en qué puedo ayudarte hoy?'},
          ],
        ).toJson(),
      ]),
    });
  });

  Widget buildTestWidget({Size size = const Size(800, 400), EdgeInsets viewInsets = EdgeInsets.zero}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: viewInsets,
        ),
        child: VantablackHome(
          username: "Gustavo",
          currentTheme: AppThemeStyle.vantablackGlass,
          onThemeChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('Scaffold has resizeToAvoidBottomInset set to true', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(size: const Size(800, 400)));
    await tester.pump(const Duration(milliseconds: 100));

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    final Scaffold scaffold = tester.widget(scaffoldFinder);
    expect(scaffold.resizeToAvoidBottomInset, isTrue);
  });

  testWidgets('Landscape mode renders 2-column layout with scrollable sidebar and chat area', (WidgetTester tester) async {
    // Set landscape screen dimensions (width: 900, height: 420)
    tester.view.physicalSize = const Size(1800, 840);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(size: const Size(900, 420)));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify OrientationBuilder is present
    expect(find.byType(OrientationBuilder), findsOneWidget);

    // Verify LayoutBuilder is present
    expect(find.byType(LayoutBuilder), findsAtLeastNWidgets(1));

    // Verify SingleChildScrollView is present for scrollable sidebar
    expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

    // Verify TextField exists for chat
    expect(find.byType(TextField), findsOneWidget);

    // Verify model badge is displayed
    expect(find.byIcon(Icons.memory_rounded), findsOneWidget);
  });

  testWidgets('Landscape mode with on-screen keyboard (bottom insets) does not overflow', (WidgetTester tester) async {
    // Landscape with small height and keyboard up (380 height with 180 keyboard inset)
    tester.view.physicalSize = const Size(1600, 760);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      buildTestWidget(
        size: const Size(800, 380),
        viewInsets: const EdgeInsets.only(bottom: 180),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify no RenderFlex overflow error was thrown and chat field is present
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Portrait mode provides drawer on mobile screen widths', (WidgetTester tester) async {
    // Portrait mobile screen (width: 390, height: 844)
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(size: const Size(390, 844)));
    await tester.pump(const Duration(milliseconds: 100));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.drawer, isNotNull);

    // Verify menu button is visible in top bar in mobile portrait
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });
}
