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
    test('Acoustic profiles keep subtle, natural variations per emotion', () {
      final happy = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.happy);
      expect(happy.pitch, 1.06);
      expect(happy.speechRate, 0.52);

      final thinking = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.thinking);
      expect(thinking.pitch, 0.97);
      expect(thinking.speechRate, 0.44);
      expect(thinking.neuralSpeed, lessThan(1.0));

      final neutral = KaiTtsService.instance.getProfileForEmotion(KaiEmotion.neutral);
      expect(neutral.pitch, 1.00);
      expect(neutral.neuralSpeed, 1.00);

      for (final profile in KaiTtsService.emotionAcoustics.values) {
        expect(profile.pitch, inInclusiveRange(0.95, 1.08));
        expect(profile.neuralSpeed, inInclusiveRange(0.9, 1.1));
      }
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

    test('initializeUniqueVoice persists a subtle per-device pitch in 0.96-1.04 range', () async {
      await KaiTtsService.instance.initializeUniqueVoice();
      expect(KaiTtsService.instance.uniqueVoicePitch, greaterThanOrEqualTo(0.96));
      expect(KaiTtsService.instance.uniqueVoicePitch, lessThanOrEqualTo(1.04));
    });

    test('localeForDialect maps onboarding dialects to voice locales', () {
      expect(KaiTtsService.localeForDialect('Español México'), 'es-MX');
      expect(KaiTtsService.localeForDialect('Español España'), 'es-ES');
      expect(KaiTtsService.localeForDialect('Español Argentina'), 'es-AR');
      expect(KaiTtsService.localeForDialect('Español Neutro Internacional'), 'es-US');
    });

    test('scoreVoice prefers exact locale, high quality and offline voices', () {
      final offlineMx = {'name': 'es-mx-x-esc-local', 'locale': 'es-MX', 'quality': '400', 'network_required': '0'};
      final networkMx = {'name': 'es-mx-x-esc-network', 'locale': 'es-MX', 'quality': '400', 'network_required': '1'};
      final offlineEs = {'name': 'es-es-x-eee-local', 'locale': 'es-ES', 'quality': '400', 'network_required': '0'};
      expect(KaiTtsService.scoreVoice(offlineMx, 'es-MX'), greaterThan(KaiTtsService.scoreVoice(networkMx, 'es-MX')));
      expect(KaiTtsService.scoreVoice(offlineMx, 'es-MX'), greaterThan(KaiTtsService.scoreVoice(offlineEs, 'es-MX')));
    });
  });
}
