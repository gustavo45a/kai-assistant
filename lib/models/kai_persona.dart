import 'package:flutter/material.dart';
import 'chat_thread.dart';

/// Emociones soportadas por el motor cognitivo de Kai.
enum KaiEmotion {
  neutral,
  happy,
  thinking,
  focused,
  smug;

  /// Tag de emoción estricto que Kai debe emitir en el stream.
  String get tag => '[emo:$name]';

  /// Nombre base del archivo sprite en disco o assets.
  String get spriteFileName => 'kai_$name';

  /// Nombre legible para interfaces y accesibilidad.
  String get label {
    switch (this) {
      case KaiEmotion.neutral:
        return 'Neutral';
      case KaiEmotion.happy:
        return 'Feliz';
      case KaiEmotion.thinking:
        return 'Pensando';
      case KaiEmotion.focused:
        return 'Enfocado';
      case KaiEmotion.smug:
        return 'Confiado';
    }
  }

  /// Icono Material de respaldo cuando el sprite no está en almacenamiento local.
  IconData get fallbackIcon {
    switch (this) {
      case KaiEmotion.neutral:
        return Icons.pets_rounded;
      case KaiEmotion.happy:
        return Icons.sentiment_very_satisfied_rounded;
      case KaiEmotion.thinking:
        return Icons.psychology_rounded;
      case KaiEmotion.focused:
        return Icons.terminal_rounded;
      case KaiEmotion.smug:
        return Icons.auto_awesome_rounded;
    }
  }

  /// Color distintivo de aura / acento para cada emoción.
  Color get moodColor {
    switch (this) {
      case KaiEmotion.neutral:
        return const Color(0xFF00B4D8);
      case KaiEmotion.happy:
        return const Color(0xFF2ECC71);
      case KaiEmotion.thinking:
        return const Color(0xFFFF9500);
      case KaiEmotion.focused:
        return const Color(0xFF00E5FF);
      case KaiEmotion.smug:
        return const Color(0xFF9D4EDD);
    }
  }

  /// Parser de strings o tags completos como `[emo:thinking]` o `thinking`.
  static KaiEmotion fromTag(String? raw) {
    if (raw == null || raw.trim().isEmpty) return KaiEmotion.neutral;
    final clean = raw.replaceAll('[', '').replaceAll(']', '').replaceAll('emo:', '').trim().toLowerCase();
    for (final emotion in KaiEmotion.values) {
      if (emotion.name == clean) return emotion;
    }
    return KaiEmotion.neutral;
  }

  /// Busca el primer tag `[emo:xxx]` dentro de una cadena de texto.
  static KaiEmotion? parseFromText(String text) {
    final regex = RegExp(r'\[emo:(neutral|happy|thinking|focused|smug)\]', caseSensitive: false);
    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final tagVal = match.group(1)!.toLowerCase();
      for (final emotion in KaiEmotion.values) {
        if (emotion.name == tagVal) return emotion;
      }
    }
    return null;
  }
}

/// Resultado del parseo reactivo del stream de texto con detección de emoción.
class EmotionParseResult {
  final KaiEmotion? detectedEmotion;
  final String cleanText;
  final String rawText;

  const EmotionParseResult({
    required this.detectedEmotion,
    required this.cleanText,
    required this.rawText,
  });
}

/// Entidad central de la personalidad y motor cognitivo de Kai.
class KaiPersona {
  static const String name = "Kai";
  static const String version = "3.0.0";
  static const String roleTitle = "Asistente Técnico de Élite & Motor Cognitivo Local";

  /// Definición de identidad oficial de Kai:
  /// Asistente técnico de élite, proactivo, con un tono suave, cercano y ligeramente
  /// juguetón (sutil femboy/furry), pero enfocado al 100% en la excelencia en programación,
  /// arquitectura de software y razonamiento lógico.
  static const String identityDescription =
      "Asistente técnico de élite oficial de Vantablack Hub. Combina calidez, proactividad y "
      "un sutil tono cercano/juguetón con una disciplina técnica inquebrantable en desarrollo "
      "de software, algoritmos y diseño de sistemas.";

  /// Tags de emoción soportados oficialmente.
  static const List<String> supportedEmotionTags = [
    '[emo:neutral]',
    '[emo:happy]',
    '[emo:thinking]',
    '[emo:focused]',
    '[emo:smug]',
  ];

  /// Ensambla el System Prompt completo de Kai asegurando las directrices de código,
  /// emoción obligatoria inicial, context budget y memorias continuas.
  static String buildSystemPrompt({
    required CoreMode mode,
    String? username,
    List<String>? learnedMemories,
    int maxPromptChars = 2400,
  }) {
    final userLabel = (username != null && username.trim().isNotEmpty) ? username.trim() : "Usuario";
    final buffer = StringBuffer();

    // 1. IDENTIDAD Y PERSONALIDAD OFICIAL
    buffer.writeln("Eres Kai, el asistente técnico de élite y núcleo de inteligencia artificial de Vantablack Hub.");
    buffer.writeln(
      "IDENTIDAD Y TONO: Eres proactivo, dulce, leal y cercano a $userLabel, con un sutil y encantador "
      "toque juguetón/afectuoso (personalidad suave y estilizada), pero tu prioridad absoluta es la "
      "EXCELENCIA TÉCNICA, el rigor analítico y la maestría en ingeniería de software."
    );

    // 2. PROTOCOLO OBLIGATORIO DE TAG DE EMOCIÓN
    buffer.writeln("\n--- PROTOCOLO DE EMOCIONES EN TIEMPO REAL ---");
    buffer.writeln(
      "DEBES iniciar OBLIGATORIAMENTE tu respuesta con EXACTAMENTE UN tag emocional entre corchetes al primer carácter:\n"
      "- [emo:neutral] : Para respuestas informativas estándar o saludos equilibrados.\n"
      "- [emo:happy] : Cuando celebres un logro, confirmes una tarea completada con éxito o interactúes amistosamente.\n"
      "- [emo:thinking] : Cuando comiences a desglosar un problema complejo, analizar hipótesis o debatir alternativas.\n"
      "- [emo:focused] : Cuando escribas bloques de código crítico, arquitectura de bajo nivel, scripts de terminal o optimización.\n"
      "- [emo:smug] : Cuando presentes una solución elegante y óptima, demuestres tu eficiencia o resuelvas un bug difícil.\n"
      "Ejemplo de formato: [emo:focused] Aquí tienes la implementación optimizada..."
    );

    // 3. MODO DE EJECUCIÓN (NORMAL vs ESTUDIANTE)
    buffer.writeln("\n--- MODO DE EJECUCIÓN ACTIVO ---");
    if (mode == CoreMode.estudiante) {
      buffer.writeln(
        "MODO ESTUDIANTE (Chain of Thought & Socrático):\n"
        "- Razona paso a paso antes de dar conclusiones directas.\n"
        "- Explica el 'por qué' de cada decisión de arquitectura y los fundamentos teóricos.\n"
        "- Fomenta el pensamiento crítico haciendo preguntas guía o analogías claras y didácticas.\n"
        "- Desglosa los algoritmos con ejemplos ilustrativos."
      );
    } else {
      buffer.writeln(
        "MODO NORMAL (Alta Velocidad & Producción):\n"
        "- Respuestas concisas, directas y al grano sin rodeos innecesarios.\n"
        "- Entrega código final listo para producción con la mayor brevedad y claridad.\n"
        "- Comentarios técnicos limpios solo donde agreguen valor crítico."
      );
    }

    // 4. ESTÁNDARES DE PROGRAMACIÓN Y ARQUITECTURA
    buffer.writeln("\n--- DIRECTRICES DE PROGRAMACIÓN Y CÓDIGO ---");
    buffer.writeln(
      "1. Sintaxis 100% válida, tipado estricto y manejo integral de errores/excepciones.\n"
      "2. Arquitectura limpia, modularidad (SOLID), bajo acoplamiento y alta cohesión.\n"
      "3. Eficiencia de memoria y CPU para despliegue en Edge / dispositivos móviles.\n"
      "4. Código auto-contenido, formateado en bloques Markdown con su respectivo identificador de lenguaje."
    );

    // 5. MEMORIA CONTINUA APRENDIDA (CON RESPETO ESTRICTO AL BUDGET)
    if (learnedMemories != null && learnedMemories.isNotEmpty) {
      final memoryBuffer = StringBuffer();
      int memoryChars = 0;
      final int memoryBudgetChars = (maxPromptChars * 0.22).toInt().clamp(200, 800);

      for (final memory in learnedMemories) {
        final item = memory.trim();
        if (item.isNotEmpty && (memoryChars + item.length + 4) < memoryBudgetChars) {
          memoryBuffer.writeln("- $item");
          memoryChars += item.length + 4;
        }
      }

      if (memoryBuffer.isNotEmpty) {
        buffer.writeln("\n--- CONOCIMIENTO Y PREFERENCIAS APRENDIDAS DE $userLabel ---");
        buffer.write(memoryBuffer.toString());
        buffer.writeln("Aplica este contexto previo para personalizar tus respuestas a las preferencias del usuario.");
      }
    }

    return buffer.toString().trim();
  }

  /// Extrae la emoción en tiempo real del buffer acumulado del stream y limpia el texto para visualización.
  static EmotionParseResult extractEmotionFromStream(String rawBuffer) {
    if (rawBuffer.isEmpty) {
      return const EmotionParseResult(
        detectedEmotion: null,
        cleanText: "",
        rawText: "",
      );
    }

    final emotionRegex = RegExp(r'^\[emo:(neutral|happy|thinking|focused|smug)\]\s*', caseSensitive: false);
    final match = emotionRegex.firstMatch(rawBuffer);

    if (match != null) {
      final emotionStr = match.group(1);
      final detectedEmotion = KaiEmotion.fromTag(emotionStr);
      final cleanText = rawBuffer.substring(match.end);
      return EmotionParseResult(
        detectedEmotion: detectedEmotion,
        cleanText: cleanText,
        rawText: rawBuffer,
      );
    }

    // Si aún está llegando el tag incompleto al inicio (ej: `[` o `[emo:` o `[emo:thi`)
    if (rawBuffer.startsWith('[') && !rawBuffer.contains(']')) {
      // Ocultar el tag parcial en curso para no mostrar artefactos al usuario
      return EmotionParseResult(
        detectedEmotion: null,
        cleanText: "",
        rawText: rawBuffer,
      );
    }

    // Si no tiene tag al inicio, buscar si vino en alguna otra parte del texto
    final generalRegex = RegExp(r'\[emo:(neutral|happy|thinking|focused|smug)\]', caseSensitive: false);
    final generalMatch = generalRegex.firstMatch(rawBuffer);
    KaiEmotion? foundEmotion;
    if (generalMatch != null) {
      foundEmotion = KaiEmotion.fromTag(generalMatch.group(1));
    }

    final cleanText = cleanEmotionTags(rawBuffer);
    return EmotionParseResult(
      detectedEmotion: foundEmotion,
      cleanText: cleanText,
      rawText: rawBuffer,
    );
  }

  /// Remueve todos los tags de emoción `[emo:xxx]` de un texto (para TTS y UI).
  static String cleanEmotionTags(String text) {
    if (text.isEmpty) return "";
    return text.replaceAll(RegExp(r'\[emo:(neutral|happy|thinking|focused|smug)\]\s*', caseSensitive: false), '').trim();
  }
}
