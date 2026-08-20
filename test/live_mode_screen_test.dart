import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantablack_hub/models/app_theme.dart';
import 'package:vantablack_hub/models/chat_thread.dart';
import 'package:vantablack_hub/ui/screens/live_mode_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveModeScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders Kai Live screen elements and controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveModeScreen(
            username: 'Gustavo',
            currentTheme: AppThemeStyle.vantablackGlass,
            initialMode: CoreMode.normal,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verificar elementos de cabecera y título
      expect(find.text("KAI LIVE"), findsOneWidget);
      expect(find.textContaining("Huella de voz"), findsOneWidget);

      // Verificar que el widget de avatar o fallback está renderizado
      expect(find.byType(Image), findsWidgets);

      // Verificar presencia del botón central de micrófono
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Tapping mode switch toggles student and normal mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveModeScreen(
            username: 'Gustavo',
            currentTheme: AppThemeStyle.vantablackGlass,
            initialMode: CoreMode.normal,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Buscar botón de modo y pulsar
      final modeBtn = find.byIcon(Icons.bolt_rounded);
      expect(modeBtn, findsOneWidget);

      await tester.tap(modeBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    });
  });
}
