import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/models/kai_persona.dart';
import 'package:vantablack_hub/ui/widgets/kai_avatar_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KaiAvatarView Widget Tests', () {
    testWidgets('Renders fallback avatar with emotion icon when sprite is absent', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KaiAvatarView(
              emotion: KaiEmotion.thinking,
              isThinking: true,
              size: 48,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(KaiAvatarView), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.byIcon(KaiEmotion.thinking.fallbackIcon), findsOneWidget);
    });

    testWidgets('Displays label and reacts to emotion change smoothly', (WidgetTester tester) async {
      KaiEmotion currentEmotion = KaiEmotion.neutral;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    KaiAvatarView(
                      emotion: currentEmotion,
                      showLabel: true,
                      size: 40,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentEmotion = KaiEmotion.happy;
                        });
                      },
                      child: const Text("Change Emotion"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text("Kai"), findsOneWidget);
      expect(find.text("Neutral"), findsOneWidget);

      await tester.tap(find.text("Change Emotion"));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text("Feliz"), findsOneWidget);
      expect(find.byIcon(KaiEmotion.happy.fallbackIcon), findsOneWidget);
    });
  });
}
