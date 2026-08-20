import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/models/chat_thread.dart';
import 'package:vantablack_hub/models/kai_persona.dart';

void main() {
  group('KaiPersona & KaiEmotion Tests', () {
    test('KaiEmotion enum tags and properties', () {
      expect(KaiEmotion.neutral.tag, '[emo:neutral]');
      expect(KaiEmotion.happy.tag, '[emo:happy]');
      expect(KaiEmotion.thinking.tag, '[emo:thinking]');
      expect(KaiEmotion.focused.tag, '[emo:focused]');
      expect(KaiEmotion.smug.tag, '[emo:smug]');

      expect(KaiEmotion.neutral.spriteFileName, 'kai_neutral');
      expect(KaiEmotion.fromTag('[emo:thinking]'), KaiEmotion.thinking);
      expect(KaiEmotion.fromTag('focused'), KaiEmotion.focused);
      expect(KaiEmotion.fromTag('invalid'), KaiEmotion.neutral);
    });

    test('KaiPersona builds rich system prompt for Normal Mode', () {
      final prompt = KaiPersona.buildSystemPrompt(
        mode: CoreMode.normal,
        username: "Gustavo",
        learnedMemories: ["Usa Flutter y Dart", "Prefiere Clean Architecture"],
      );

      expect(prompt, contains("Eres Kai"));
      expect(prompt, contains("Gustavo"));
      expect(prompt, contains("[emo:neutral]"));
      expect(prompt, contains("[emo:focused]"));
      expect(prompt, contains("MODO NORMAL"));
      expect(prompt, contains("Usa Flutter y Dart"));
    });

    test('KaiPersona builds rich system prompt for Student Mode', () {
      final prompt = KaiPersona.buildSystemPrompt(
        mode: CoreMode.estudiante,
        username: "Alex",
      );

      expect(prompt, contains("MODO ESTUDIANTE"));
      expect(prompt, contains("Chain of Thought"));
      expect(prompt, contains("Alex"));
    });

    test('extractEmotionFromStream parses leading emotion tag and clean text', () {
      const streamText = "[emo:smug] Aquí está la solución óptima en O(log n).";
      final result = KaiPersona.extractEmotionFromStream(streamText);

      expect(result.detectedEmotion, KaiEmotion.smug);
      expect(result.cleanText, "Aquí está la solución óptima en O(log n).");
    });

    test('extractEmotionFromStream handles in-progress partial tag without leaking bracket', () {
      const partial1 = "[";
      final res1 = KaiPersona.extractEmotionFromStream(partial1);
      expect(res1.detectedEmotion, isNull);
      expect(res1.cleanText, "");

      const partial2 = "[emo:thi";
      final res2 = KaiPersona.extractEmotionFromStream(partial2);
      expect(res2.detectedEmotion, isNull);
      expect(res2.cleanText, "");

      const fullTag = "[emo:thinking] Analizando...";
      final res3 = KaiPersona.extractEmotionFromStream(fullTag);
      expect(res3.detectedEmotion, KaiEmotion.thinking);
      expect(res3.cleanText, "Analizando...");
    });

    test('cleanEmotionTags removes all emotion tags cleanly', () {
      const text = "[emo:happy] ¡Hola mundo! [emo:neutral]";
      final clean = KaiPersona.cleanEmotionTags(text);
      expect(clean, "¡Hola mundo!");
    });
  });
}
