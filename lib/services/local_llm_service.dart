import 'dart:io';
import 'dart:async';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import '../models/chat_thread.dart';
import '../models/kai_persona.dart';
import 'zram_memory_manager.dart';
import 'hardware_scanner.dart';

class LocalLLMService {
  static final LocalLLMService instance = LocalLLMService._internal();
  LocalLLMService._internal();

  final LlamaController _controller = LlamaController();
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String _modelPath = '';
  int _currentContextSize = 1024;

  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _isModelLoaded;
  int get currentContextSize => _currentContextSize;

  Future<void> stop() async {
    try {
      if (_isGenerating) {
        await _controller.stop();
        _isGenerating = false;
      }
    } catch (_) {}
  }

  Future<void> initializeRealModel(String path, {int threads = 4, int? overrideContextSize}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("Modelo local no encontrado en el almacenamiento. Requiere descarga inicial.");
    }

    if (_isModelLoaded && _modelPath == path) {
      return;
    }

    ZRamMemoryManager.optimizeMemory(true);

    if (_isModelLoaded) {
      try {
        await _controller.dispose();
      } catch (_) {}
      _isModelLoaded = false;
    }

    _modelPath = path;
    // Parámetros estrictos para móviles: 4 hilos para alto rendimiento sin saturar el sistema
    final safeThreads = (threads > 0 && threads <= 4) ? threads : 4;

    // Reducción estricta de contextSize para móviles (1024 o máximo 2048)
    final hardware = await HardwareScanner.scan();
    final freeRam = (hardware['freeRamGb'] as num?)?.toDouble() ?? 4.0;
    _currentContextSize = (overrideContextSize ?? (freeRam >= 3.5 ? 2048 : 1024)).clamp(1024, 2048);

    try {
      await _controller.loadModel(
        modelPath: _modelPath,
        threads: safeThreads,
        contextSize: _currentContextSize,
      );
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      throw Exception("RAM insuficiente o error al alojar el modelo local con contextSize $_currentContextSize: $e");
    }
  }

  /// Construye y formatea el prompt ChatML con el System Prompt oficial de Kai,
  /// respetando estrictamente el presupuesto de contexto (context budget) y limitando
  /// el historial a los últimos 4 a 6 mensajes para prevenir 'Failed to decode prompt'.
  String buildChatMLPrompt({
    required String prompt,
    required Map<String, dynamic> variables,
    List<Map<String, String>>? history,
    int? overrideContextSize,
  }) {
    final int ctxSize = (overrideContextSize ?? _currentContextSize).clamp(1024, 2048);
    const int reservedMaxTokens = 512;
    final int availablePromptTokens = (ctxSize - reservedMaxTokens - 64).clamp(256, 1536);
    final int maxPromptChars = (availablePromptTokens * 3.2).toInt();

    final CoreMode mode = variables['modoEstudiante'] == true
        ? CoreMode.estudiante
        : (variables['mode'] is CoreMode ? variables['mode'] : CoreMode.normal);
    final String? username = variables['username'] as String?;
    final List<String>? learnedMemories = variables['memoriaAprendida'] as List<String>?;

    // 1. Inyección del System Prompt oficial de Kai
    final String kaiSystemPrompt = KaiPersona.buildSystemPrompt(
      mode: mode,
      username: username,
      learnedMemories: learnedMemories,
      maxPromptChars: maxPromptChars,
    );

    // 2. Limpiar y truncar de forma segura el Prompt del Usuario actual
    String cleanPrompt = prompt.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '').trim();
    final int userPromptMaxChars = (maxPromptChars * 0.55).toInt();
    if (cleanPrompt.length > userPromptMaxChars) {
      cleanPrompt = "${cleanPrompt.substring(0, userPromptMaxChars)}\n[...contenido truncado por límite de contexto...]";
    }

    // 3. Ensamblar Historial Reciente: Filtrar y recortar estrictamente a los últimos 4-6 mensajes
    final List<Map<String, String>> validHistory = [];
    if (history != null && history.isNotEmpty) {
      // Filtrar mensajes de sistema y mensajes vacíos / de error
      final filteredHistory = history.where((msg) {
        final text = msg['text'] ?? '';
        final sender = msg['sender'] ?? '';
        return sender != 'system' && text.isNotEmpty && !text.startsWith('[ERROR') && !text.startsWith('⚠️') && text != '...';
      }).toList();

      // Recortar estrictamente a un máximo de 6 mensajes (las interacciones más recientes)
      final recentHistory = filteredHistory.length > 6
          ? filteredHistory.sublist(filteredHistory.length - 6)
          : filteredHistory;

      int historyCharsAcc = 0;
      final maxHistoryChars = (maxPromptChars * 0.35).toInt();
      for (var i = recentHistory.length - 1; i >= 0; i--) {
        final msg = recentHistory[i];
        final text = msg['text'] ?? '';
        final cleanText = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '').trim();
        if (historyCharsAcc + cleanText.length <= maxHistoryChars) {
          validHistory.insert(0, {
            'role': msg['sender'] == 'user' ? 'user' : 'assistant',
            'text': cleanText,
          });
          historyCharsAcc += cleanText.length;
        }
      }
    }

    // 4. Formateo estricto ChatML
    final StringBuffer promptFormatted = StringBuffer();
    promptFormatted.writeln("<|im_start|>system");
    promptFormatted.writeln(kaiSystemPrompt);
    promptFormatted.writeln("<|im_end|>");

    for (var msg in validHistory) {
      promptFormatted.writeln("<|im_start|>${msg['role']}");
      promptFormatted.writeln(msg['text']);
      promptFormatted.writeln("<|im_end|>");
    }

    promptFormatted.writeln("<|im_start|>user");
    promptFormatted.writeln(cleanPrompt);
    promptFormatted.writeln("<|im_end|>");
    promptFormatted.writeln("<|im_start|>assistant");

    return promptFormatted.toString();
  }

  Stream<String> generateResponseStream(String prompt, Map<String, dynamic> variables, {List<Map<String, String>>? history}) async* {
    if (!_isModelLoaded) {
      yield "⚠️ [ERROR HARDWARE]: El motor local no está inicializado. Descarga los pesos del modelo Hugging Face primero.";
      return;
    }

    if (_isGenerating) {
      await stop();
    }

    _isGenerating = true;

    try {
      final String promptFormatted = buildChatMLPrompt(
        prompt: prompt,
        variables: variables,
        history: history,
      );

      const int reservedMaxTokens = 512;

      final stream = _controller.generate(
        prompt: promptFormatted,
        maxTokens: reservedMaxTokens,
        temperature: 0.6,
        topP: 0.9,
        repeatPenalty: 1.18,
      );

      await for (final chunk in stream) {
        if (!_isGenerating) break;
        if (chunk.contains("<|im_end|>") || chunk.contains("<|endoftext|>")) {
          final cleanChunk = chunk.replaceAll("<|im_end|>", "").replaceAll("<|endoftext|>", "");
          if (cleanChunk.isNotEmpty) yield cleanChunk;
          break;
        }
        yield chunk;
      }
    } catch (e) {
      yield "\n⚠️ [Error en motor nativo]: No se pudo decodificar o generar respuesta: $e";
    } finally {
      _isGenerating = false;
    }
  }
}
