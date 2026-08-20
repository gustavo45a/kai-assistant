import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/services/local_llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalLLMService Prompt Assembly Tests', () {
    test('buildChatMLPrompt formats ChatML structure with Kai persona', () {
      final prompt = LocalLLMService.instance.buildChatMLPrompt(
        prompt: "¿Cómo optimizo un algoritmo de ordenamiento en Dart?",
        variables: {
          'modoEstudiante': false,
          'username': 'Gustavo',
          'memoriaAprendida': ['Prefiere Dart 3.0', 'Enfoque en Clean Code'],
        },
        history: [
          {'sender': 'user', 'text': 'Hola Kai'},
          {'sender': 'assistant', 'text': 'Hola Gustavo, ¿en qué puedo ayudarte hoy?'},
        ],
        overrideContextSize: 2048,
      );

      expect(prompt, contains("<|im_start|>system"));
      expect(prompt, contains("Eres Kai"));
      expect(prompt, contains("[emo:neutral]"));
      expect(prompt, contains("Gustavo"));
      expect(prompt, contains("Prefiere Dart 3.0"));
      expect(prompt, contains("<|im_end|>"));

      expect(prompt, contains("<|im_start|>user\nHola Kai\n<|im_end|>"));
      expect(prompt, contains("<|im_start|>assistant\nHola Gustavo, ¿en qué puedo ayudarte hoy?\n<|im_end|>"));
      expect(prompt, contains("<|im_start|>user\n¿Cómo optimizo un algoritmo de ordenamiento en Dart?\n<|im_end|>"));
      expect(prompt, endsWith("<|im_start|>assistant\n"));
    });

    test('buildChatMLPrompt limits history to the last 6 interactions to protect context window', () {
      final longHistory = List.generate(
        15,
        (index) => {
          'sender': index % 2 == 0 ? 'user' : 'assistant',
          'text': 'Mensaje histórico número $index',
        },
      );

      final prompt = LocalLLMService.instance.buildChatMLPrompt(
        prompt: "Última pregunta",
        variables: {
          'modoEstudiante': false,
          'username': 'Gustavo',
        },
        history: longHistory,
        overrideContextSize: 1024,
      );

      // Los primeros mensajes deben haber sido descartados
      expect(prompt, isNot(contains("Mensaje histórico número 0")));
      expect(prompt, isNot(contains("Mensaje histórico número 5")));
      // Los últimos mensajes deben estar presentes
      expect(prompt, contains("Mensaje histórico número 14"));
      expect(prompt, contains("Mensaje histórico número 13"));
      expect(prompt, contains("Última pregunta"));
    });

    test('generateResponseStream safely yields error message when model is not initialized', () async {
      final stream = LocalLLMService.instance.generateResponseStream(
        "Hola",
        {'mode': 'normal'},
      );

      final events = await stream.toList();
      expect(events.isNotEmpty, true);
      expect(events.first, contains("ERROR HARDWARE"));
      expect(LocalLLMService.instance.isGenerating, false);
    });
  });
}
