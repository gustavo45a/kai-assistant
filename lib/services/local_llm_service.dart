import 'dart:io';
import 'dart:async';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'zram_memory_manager.dart';

class LocalLLMService {
  static final LocalLLMService instance = LocalLLMService._internal();
  LocalLLMService._internal();

  final LlamaController _controller = LlamaController();
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String _modelPath = '';

  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _isModelLoaded;

  Future<void> stop() async {
    try {
      if (_isGenerating) {
        await _controller.stop();
        _isGenerating = false;
      }
    } catch (_) {}
  }

  Future<void> initializeRealModel(String path, {int threads = 2}) async {
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
    final safeThreads = (threads > 0 && threads <= 2) ? threads : 2;

    try {
      await _controller.loadModel(
        modelPath: _modelPath,
        threads: safeThreads,
        contextSize: 768,
      );
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      throw Exception("RAM insuficiente o error al alojar el modelo local: $e");
    }
  }

  Stream<String> generateResponseStream(String prompt, Map<String, dynamic> variables, {List<Map<String, String>>? history}) async* {
    if (!_isModelLoaded) {
      yield "[ERROR HARDWARE]: El motor local no está inicializado. Descarga los pesos del modelo Hugging Face primero.";
      return;
    }

    if (_isGenerating) {
      await stop();
    }

    _isGenerating = true;

    final StringBuffer promptFormatted = StringBuffer();
    promptFormatted.writeln("<|im_start|>system");
    promptFormatted.writeln("Eres VANTABLACK, una matriz de inteligencia artificial offline de alta eficiencia.");
    if (variables['modoEstudiante'] == true) {
      promptFormatted.writeln("MODO ESTUDIANTE ACTIVO: Explica de forma didáctica, clara y con ejemplos paso a paso.");
    }
    final List<String>? learnedMemories = variables['memoriaAprendida'] as List<String>?;
    if (learnedMemories != null && learnedMemories.isNotEmpty) {
      promptFormatted.writeln("MEMORIA CONTINUA APRENDIDA DE CHATS ANTERIORES:");
      for (var memory in learnedMemories) {
        promptFormatted.writeln("- $memory");
      }
      promptFormatted.writeln("Utiliza este conocimiento previo sobre el usuario para responder de forma personalizada.");
    }
    promptFormatted.writeln("<|im_end|>");

    if (history != null && history.isNotEmpty) {
      final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (var msg in recentHistory) {
        final role = msg['sender'] == 'user' ? 'user' : 'assistant';
        final text = msg['text'] ?? '';
        if (text.isNotEmpty && !text.startsWith('[ERROR')) {
          final cleanText = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
          promptFormatted.writeln("<|im_start|>$role");
          promptFormatted.writeln(cleanText);
          promptFormatted.writeln("<|im_end|>");
        }
      }
    }

    final cleanPrompt = prompt.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
    promptFormatted.writeln("<|im_start|>user");
    promptFormatted.writeln(cleanPrompt);
    promptFormatted.writeln("<|im_end|>");
    promptFormatted.writeln("<|im_start|>assistant");

    try {
      final stream = _controller.generate(
        prompt: promptFormatted.toString(),
        maxTokens: 512,
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
      yield "\n[EXCEPCIÓN EN MOTOR NATIVO C++]: $e";
    } finally {
      _isGenerating = false;
    }
  }
}
