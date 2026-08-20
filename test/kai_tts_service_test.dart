import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantablack_hub/models/kai_persona.dart';
import 'package:vantablack_hub/services/kai_tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KaiTtsService Acoustic Profiles & Sanitizer Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    test('Acoustic profiles match Kai emotion specifications', () {
      final happy = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.happy);
      expect(happy.pitch, 1.28);
      expect(happy.speechRate, 0.54);

      final thinking = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.thinking);
      expect(thinking.pitch, 1.12);
      expect(thinking.speechRate, 0.44);

      final focused = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.focused);
      expect(focused.pitch, 1.16);
      expect(focused.speechRate, 0.50);

      final smug = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.smug);
      expect(smug.pitch, 1.22);
      expect(smug.speechRate, 0.49);

      final neutral = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.neutral);
      expect(neutral.pitch, 1.20);
      expect(neutral.speechRate, 0.50);
    });

    test('sanitizeForTts replaces Markdown code blocks with natural speech phrase', () {
      const input = """
[emo:focused] Aquí tienes la función:
```dart
void main() {
  print("Hola Mundo");
}
```
¿Deseas ejecutarla ahora?
""";

      final sanitized = KaiTtsService.sanitizeForTts(input);
      expect(sanitized, contains("Aquí tienes la función:"));
      expect(sanitized, contains("He generado un fragmento de código en pantalla."));
      expect(sanitized, contains("¿Deseas ejecutarla ahora?"));
      expect(sanitized, isNot(contains("void main()")));
      expect(sanitized, isNot(contains("[emo:focused]")));
      expect(sanitized, isNot(contains("```")));
    });

    test('sanitizeForTts cleans inline code and preserves words', () {
      const input = "[emo:smug] Invoca `calculateMetrics(dataset)` para obtener el resultado en **O(1)**.";
      final sanitized = KaiTtsService.sanitizeForTts(input);

      expect(sanitized, contains("calculateMetrics(dataset)"));
      expect(sanitized, contains("O(1)"));
      expect(sanitized, isNot(contains("`")));
      expect(sanitized, isNot(contains("**")));
      expect(sanitized, isNot(contains("[emo:smug]")));
    });

    test('sanitizeForTts removes ChatML, HTML and special noise symbols', () {
      const input = """
<|im_start|>assistant
[emo:happy] ¡Excelente! ### Título de sección:
- Opción *A*
- Opción *B* <span class="badge">Nuevo</span>
<|im_end|>
""";

      final sanitized = KaiTtsService.sanitizeForTts(input);
      expect(sanitized, contains("¡Excelente! Título de sección: - Opción A - Opción B Nuevo"));
      expect(sanitized, isNot(contains("<|im_start|>")));
      expect(sanitized, isNot(contains("<|im_end|>")));
      expect(sanitized, isNot(contains("<span")));
      expect(sanitized, isNot(contains("###")));
      expect(sanitized, isNot(contains("[emo:happy]")));
    });

    test('toggleEnabled changes TTS state correctly', () {
      KaiTtsService.instance.setEnabled(true);
      expect(KaiTtsService.instance.isEnabled, isTrue);

      KaiTtsService.instance.toggleEnabled();
      expect(KaiTtsService.instance.isEnabled, isFalse);

      KaiTtsService.instance.setEnabled(true);
      expect(KaiTtsService.instance.isEnabled, isTrue);
    });

    test('initializeUniqueVoice generates and persists unique pitch in 0.8-1.2 range', () async {
      await KaiTtsService.instance.initializeUniqueVoice();
      expect(KaiTtsService.instance.uniqueVoicePitch, greaterThanOrEqualTo(0.8));
      expect(KaiTtsService.instance.uniqueVoicePitch, lessThanOrEqualTo(1.2));
    });
  });
}
