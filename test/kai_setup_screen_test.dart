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
    testWidgets('Renders Step 1 Welcome and navigates through all 5 setup steps', (WidgetTester tester) async {
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

      // PASO 1: Welcome
      expect(find.text("Bienvenido a Kai"), findsOneWidget);
      expect(find.text("Comenzar Configuración"), findsOneWidget);

      // Tap Comenzar
      await tester.tap(find.text("Comenzar Configuración"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // PASO 2: Nombre de Usuario
      expect(find.text("¿Cómo te llamas?"), findsOneWidget);
      expect(find.text("Continuar"), findsOneWidget);

      // Select chip "Alex"
      await tester.tap(find.text("Alex"));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Continuar
      await tester.tap(find.text("Continuar"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // PASO 3: Dialecto
      expect(find.text("Selecciona tu Dialecto"), findsOneWidget);
      expect(find.text("Español México"), findsOneWidget);

      // Tap Español México
      await tester.tap(find.text("Español México"));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Continuar
      await tester.tap(find.text("Continuar"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // PASO 4: Trato e Identidad
      expect(find.text("Trato e Identidad"), findsOneWidget);
      expect(find.text("No binario / Neutro"), findsOneWidget);

      // Tap No binario / Neutro
      await tester.tap(find.text("No binario / Neutro"));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Continuar
      await tester.tap(find.text("Continuar"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // PASO 5: Resumen y Activación
      expect(find.text("¡Todo Listo, Alex!"), findsOneWidget);
      expect(find.text("⚡ Activar Núcleo de Kai"), findsOneWidget);

      // Tap Activar
      await tester.tap(find.text("⚡ Activar Núcleo de Kai"));
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
