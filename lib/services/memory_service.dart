import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const String keyLearningEnabled = 'continuous_learning_enabled';
  static const String keyUserMemories = 'user_learned_memories';

  static final MemoryService instance = MemoryService._internal();
  MemoryService._internal();

  bool _isLearningEnabled = true;
  List<String> _memories = [];

  bool get isLearningEnabled => _isLearningEnabled;
  List<String> get memories => List.unmodifiable(_memories);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLearningEnabled = prefs.getBool(keyLearningEnabled) ?? true;
    final jsonStr = prefs.getString(keyUserMemories);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        _memories = list.map((e) => e.toString()).toList();
      } catch (_) {
        _memories = [];
      }
    }
  }

  Future<void> setLearningEnabled(bool enabled) async {
    _isLearningEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyLearningEnabled, enabled);
  }

  Future<void> addMemory(String memory) async {
    final cleanMemory = memory.trim();
    if (cleanMemory.isEmpty || _memories.contains(cleanMemory)) return;
    
    // Mantener un máximo de 20 recuerdos clave para optimizar context size
    if (_memories.length >= 20) {
      _memories.removeAt(0);
    }
    _memories.add(cleanMemory);
    await _saveToDisk();
  }

  Future<void> removeMemoryAt(int index) async {
    if (index >= 0 && index < _memories.length) {
      _memories.removeAt(index);
      await _saveToDisk();
    }
  }

  Future<void> clearMemories() async {
    _memories.clear();
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyUserMemories, jsonEncode(_memories));
    } catch (e) {
      debugPrint("Error al guardar memoria en disco: $e");
    }
  }

  /// Extrae heurísticamente datos clave del mensaje del usuario cuando la memoria continua está activa
  void extractMemoryFromInteraction(String userText) {
    if (!_isLearningEnabled || userText.trim().isEmpty) return;

    final lower = userText.toLowerCase();

    // Patrones de aprendizaje sobre identidad, preferencias y contexto
    final patterns = [
      RegExp(r'(?:me llamo|mi nombre es|dime|llámame)\s+([a-zA-záéíóúñÑ\s]{2,20})', caseSensitive: false),
      RegExp(r'(?:soy|trabajo como|trabajo de|me dedico a)\s+([a-zA-záéíóúñÑ\s]{3,30})', caseSensitive: false),
      RegExp(r'(?:me gusta|prefiero|mi lenguaje favorito es|uso)\s+([a-zA-záéíóúñÑ0-9\s]{3,40})', caseSensitive: false),
      RegExp(r'(?:estoy desarrollando|mi proyecto es|creando|programando)\s+([a-zA-záéíóúñÑ0-9\s]{3,40})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(userText);
      if (match != null && match.groupCount >= 1) {
        final extracted = userText.substring(match.start, match.end).trim();
        if (extracted.length > 5 && extracted.length < 80) {
          addMemory(extracted);
          return;
        }
      }
    }

    // Si el usuario da una instrucción explícita como "recuerda que...", "aprende que..."
    if (lower.contains("recuerda que") || lower.contains("aprende que") || lower.contains("nota que")) {
      final index = lower.indexOf("que ");
      if (index != -1 && index + 4 < userText.length) {
        final fact = userText.substring(index + 4).trim();
        if (fact.isNotEmpty && fact.length < 100) {
          addMemory(fact);
        }
      }
    }
  }
}
