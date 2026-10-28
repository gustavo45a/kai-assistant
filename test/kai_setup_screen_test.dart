import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantablack_hub/models/app_theme.dart';
import 'package:vantablack_hub/services/app_settings.dart';
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

  group('KaiSetupScreen Widget & Flow Tests', () {
    testWidgets('Renders the hello screen and navigates through all 6 setup steps', (WidgetTester tester) async {
      String? completedUser;
      AppThemeStyle? completedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: KaiSetupScreen(
            initialTheme: AppThemeStyle.vantablackGlass,
            onComplete: (user, theme) {
              completedUser = user;
              completedTheme = theme;
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      Future<void> next(String label) async {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // PASO 1: Hola
      expect(find.text("Bienvenido a Kai"), findsOneWidget);
      await next("Comenzar");

      // PASO 2: Nombre (Continuar deshabilitado hasta escribir uno)
      expect(find.text("¿Cómo te llamas?"), findsOneWidget);
      final continuar = find.widgetWithText(FilledButton, "Continuar");
      expect(tester.widget<FilledButton>(continuar).onPressed, isNull);
      await tester.enterText(find.byType(TextField), "Alex");
      await tester.pump();
      expect(tester.widget<FilledButton>(continuar).onPressed, isNotNull);
      await next("Continuar");

      // PASO 3: Dialecto
      expect(find.text("¿Cómo hablas?"), findsOneWidget);
      await tester.tap(find.text("Español México"));
      await tester.pump(const Duration(milliseconds: 100));
      await next("Continuar");

      // PASO 4: Trato
      expect(find.text("¿Cómo prefieres que te trate?"), findsOneWidget);
      await tester.tap(find.text("No binario / Neutro"));
      await tester.pump(const Duration(milliseconds: 100));
      await next("Continuar");

      // PASO 5: Voz (se elige la del sistema para no descargar nada en el test)
      expect(find.text("Elige la voz de Kai"), findsOneWidget);
      await tester.tap(find.text("Voz del sistema"));
      await tester.pump(const Duration(milliseconds: 100));
      await next("Continuar");

      // PASO 6: Listo
      expect(find.text("Todo listo, Alex"), findsOneWidget);
      await tester.tap(find.text("Empezar a usar Kai"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify onComplete called and SharedPreferences updated
      expect(completedUser, "Alex");
      expect(completedTheme, AppThemeStyle.vantablackGlass);
      expect(await AppSettings.hasCompletedOnboarding(), isTrue);
      expect(await AppSettings.getUsername(), "Alex");
      expect(await AppSettings.getDialect(), "Español México");
      expect(await AppSettings.getGender(), "No binario / Neutro");
    });
  });
}
