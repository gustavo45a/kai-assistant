import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/ui/widgets/apple_glass_icon_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleGlassIconButton Widget Tests', () {
    testWidgets('Renders with icon and responds to tap gesture', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleGlassIconButton(
                icon: CupertinoIcons.mic_fill,
                size: 40,
                tooltip: "Dictado",
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.mic_fill), findsOneWidget);
      expect(find.byType(AppleGlassIconButton), findsOneWidget);

      await tester.tap(find.byType(AppleGlassIconButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });

    testWidgets('Active and pulsing states apply glow effect without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleGlassIconButton(
                icon: CupertinoIcons.stop_fill,
                isActive: true,
                isPulsing: true,
                isDestructive: true,
                activeGlowColor: Color(0xFFFF3B30),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.stop_fill), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppleGlassCapsuleButton Widget Tests', () {
    testWidgets('Renders label and icon, triggers onTap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleGlassCapsuleButton(
                icon: CupertinoIcons.add,
                label: "Nuevo Chat",
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text("Nuevo Chat"), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);

      await tester.tap(find.byType(AppleGlassCapsuleButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });
  });

  group('AppleGlassSegmentedControl Widget Tests', () {
    testWidgets('Switches value when option is tapped', (WidgetTester tester) async {
      String selected = "normal";

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AppleGlassSegmentedControl<String>(
                    selectedValue: selected,
                    onValueChanged: (val) => setState(() => selected = val),
                    children: const {
                      "normal": Text("Normal"),
                      "estudiante": Text("Estudiante"),
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text("Normal"), findsOneWidget);
      expect(find.text("Estudiante"), findsOneWidget);

      await tester.tap(find.text("Estudiante"));
      await tester.pumpAndSettle();

      expect(selected, "estudiante");
    });
  });

  group('AppleGlassPill Widget Tests', () {
    testWidgets('Renders custom child and triggers tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleGlassPill(
                onTap: () => tapped = true,
                child: const Text("⚡ Crear script"),
              ),
            ),
          ),
        ),
      );

      expect(find.text("⚡ Crear script"), findsOneWidget);

      await tester.tap(find.byType(AppleGlassPill));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });
  });
}
