import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kai_persona.dart';

/// Perfil acústico con pitch y velocidad prosódica.
class KaiAcousticProfile {
  final double pitch;
  final double speechRate;
  final double volume;

  const KaiAcousticProfile({
    required this.pitch,
    required this.speechRate,
    this.volume = 1.0,
  });
}

/// Servicio singleton para la síntesis de voz (TTS) de Kai con modulación
/// prosódica reactiva a emociones y sanitización inteligente de código.
class KaiTtsService extends ChangeNotifier {
  static final KaiTtsService instance = KaiTtsService._internal();
  KaiTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isEnabled = true;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String? _selectedVoiceName;
  KaiEmotion _lastEmotion = KaiEmotion.neutral;
  double _uniqueVoicePitch = 1.0;
  Map<String, String>? _uniqueVoice;
  VoidCallback? _onCompletionCallback;

  FlutterTts get flutterTts => _flutterTts;
  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String? get selectedVoiceName => _selectedVoiceName;
  KaiEmotion get lastEmotion => _lastEmotion;
  double get uniqueVoicePitch => _uniqueVoicePitch;
  Map<String, String>? get uniqueVoice => _uniqueVoice;

  /// Modulación acústica oficial para cada emoción de Kai.
  static const Map<KaiEmotion, KaiAcousticProfile> emotionAcoustics = {
    KaiEmotion.neutral: KaiAcousticProfile(pitch: 1.20, speechRate: 0.50, volume: 1.0),
    KaiEmotion.happy: KaiAcousticProfile(pitch: 1.28, speechRate: 0.54, volume: 1.0),
    KaiEmotion.thinking: KaiAcousticProfile(pitch: 1.12, speechRate: 0.44, volume: 1.0),
    KaiEmotion.focused: KaiAcousticProfile(pitch: 1.16, speechRate: 0.50, volume: 1.0),
    KaiEmotion.smug: KaiAcousticProfile(pitch: 1.22, speechRate: 0.49, volume: 1.0),
  };

  /// Asigna un listener que se dispara al terminar la locución del audio actual
  void setOnCompletion(VoidCallback? callback) {
    _onCompletionCallback = callback;
  }

  /// Obtiene el perfil acústico para una emoción determinada.
  KaiAcousticProfile getProfileForEmotion(KaiEmotion emotion) {
    return emotionAcoustics[emotion] ?? emotionAcoustics[KaiEmotion.neutral]!;
  }

  /// Inicializa el motor TTS, carga la huella de voz única por dispositivo y configura callbacks.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await _flutterTts.setEngine("com.google.android.tts");
        } catch (_) {}
      }

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        _onCompletionCallback?.call();
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
      });

      // 5. HUELLA DE VOZ ÚNICA POR DISPOSITIVO (Voice Fingerprint)
      await _initializeUniqueVoice();

      final base = emotionAcoustics[KaiEmotion.neutral]!;
      await _flutterTts.setSpeechRate(base.speechRate);
      await _flutterTts.setVolume(base.volume);

      _isInitialized = true;
    } catch (e) {
      debugPrint("Error al inicializar KaiTtsService: $e");
    }
  }

  /// 5. Inicializa o recupera la huella de voz persistente en SharedPreferences.
  Future<void> _initializeUniqueVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const String key = 'kai_voice_profile';
      final String? savedProfileJson = prefs.getString(key);

      if (savedProfileJson != null && savedProfileJson.isNotEmpty) {
        // Si SÍ existe: Cargar y aplicar configuración guardada
        final Map<String, dynamic> profile = jsonDecode(savedProfileJson);
        final String? name = profile['name'] as String?;
        final String locale = profile['locale'] as String? ?? 'es-ES';
        final double pitch = (profile['pitch'] as num?)?.toDouble() ?? 1.0;

        _uniqueVoicePitch = pitch;
        if (name != null) {
          _uniqueVoice = {'name': name, 'locale': locale};
          _selectedVoiceName = name;
          try {
            await _flutterTts.setVoice(_uniqueVoice!);
          } catch (_) {}
        }
        try {
          await _flutterTts.setPitch(_uniqueVoicePitch);
        } catch (_) {}
      } else {
        // Si NO existe (primera vez):
        // a) Obtener lista de voces disponibles en español
        try {
          await _flutterTts.setLanguage("es-ES");
        } catch (_) {}

        final List<Map<String, String>> spanishVoices = [];
        try {
          final dynamic rawVoices = await _flutterTts.getVoices;
          if (rawVoices is List && rawVoices.isNotEmpty) {
            for (final item in rawVoices) {
              if (item is Map) {
                final name = (item['name'] ?? '').toString();
                final locale = (item['locale'] ?? '').toString().toLowerCase();
                if (locale.startsWith('es') ||
                    name.toLowerCase().contains('es-') ||
                    name.toLowerCase().contains('spanish') ||
                    name.toLowerCase().contains('español')) {
                  spanishVoices.add({
                    'name': name,
                    'locale': item['locale']?.toString() ?? 'es-ES',
                  });
                }
              }
            }
          }
        } catch (_) {}

        // b) Seleccionar una voz al azar de la lista
        Map<String, String> selectedVoice;
        if (spanishVoices.isNotEmpty) {
          final randomIndex = Random().nextInt(spanishVoices.length);
          selectedVoice = spanishVoices[randomIndex];
        } else {
          selectedVoice = {'name': 'es-es-x-sfb-local', 'locale': 'es-ES'};
        }

        // c) Generar un valor aleatorio de pitch (tono) entre 0.8 y 1.2
        final randomPitch = double.parse((0.8 + (Random().nextDouble() * 0.4)).toStringAsFixed(2));
        _uniqueVoicePitch = randomPitch;
        _uniqueVoice = selectedVoice;
        _selectedVoiceName = selectedVoice['name'];

        // d) Aplicar y guardar identificador de voz y pitch en SharedPreferences
        try {
          await _flutterTts.setVoice(selectedVoice);
          await _flutterTts.setPitch(_uniqueVoicePitch);
        } catch (_) {}

        await prefs.setString(key, jsonEncode({
          'name': selectedVoice['name'],
          'locale': selectedVoice['locale'],
          'pitch': _uniqueVoicePitch,
        }));
      }
    } catch (e) {
      debugPrint("Error al configurar huella de voz única: $e");
    }
  }

  /// Método público para inicializar o recargar la huella de voz.
  Future<void> initializeUniqueVoice() => _initializeUniqueVoice();

  /// Activa o desactiva la síntesis de voz.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!_isEnabled && _isSpeaking) {
      stop();
    }
    notifyListeners();
  }

  /// Conmuta el estado de TTS activado/desactivado.
  void toggleEnabled() {
    setEnabled(!_isEnabled);
  }

  /// Sanitizador estricto de texto y código Markdown para locución natural.
  static String sanitizeForTts(String rawText) {
    if (rawText.trim().isEmpty) return "";

    String text = rawText;

    // 1. Remover tokens ChatML y de control de modelos
    text = text
        .replaceAll("<|im_start|>", "")
        .replaceAll("<|im_end|>", "")
        .replaceAll("<|endoftext|>", "");

    // 2. Remover tags de emoción [emo:xxx]
    text = text.replaceAll(RegExp(r'\[emo:[a-zA-Z0-9_-]+\]', caseSensitive: false), ' ');

    // 3. Reemplazar bloques de código Markdown ```dart ... ``` por frase natural
    text = text.replaceAll(
      RegExp(r'```(?:[a-zA-Z0-9_-]*\n)?[\s\S]*?```'),
      ' He generado un fragmento de código en pantalla. ',
    );

    // 4. Extraer texto de código inline `codigo` manteniendo la palabra legible
    text = text.replaceAllMapped(RegExp(r'`([^`\n]+)`'), (match) {
      final codeContent = match.group(1) ?? '';
      return ' $codeContent ';
    });

    // 5. Limpiar enlaces Markdown [Texto del enlace](url) -> Texto del enlace
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (match) {
      return match.group(1) ?? '';
    });

    // 6. Remover tags HTML
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 7. Remover símbolos de formato Markdown y caracteres especiales ruidosos
    // Preservando letras con acentos, números, signos gramaticales (.,?!:;¿¡) y guiones en palabras
    text = text.replaceAll(RegExp(r'[\*\_~#>{}\[\]|\\^$@&/`]+'), ' ');

    // 8. Normalizar espacios en blanco y saltos de línea repetidos
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Modula los parámetros prosódicos según la emoción y reproduce el texto sanitizado.
  Future<void> speakWithEmotion(String rawText, KaiEmotion emotion) async {
    if (!_isEnabled || rawText.trim().isEmpty) return;

    // Sanitizar texto para locución humana fluida
    final cleanText = sanitizeForTts(rawText);
    if (cleanText.isEmpty) return;

    try {
      // Detener cualquier audio previo para evitar solapamientos
      await stop();

      if (!_isInitialized) {
        await init();
      }

      _lastEmotion = emotion;
      final profile = getProfileForEmotion(emotion);

      // Combinar tono único de dispositivo con modulación por emoción
      final effectivePitch = (_uniqueVoicePitch * (profile.pitch / 1.20)).clamp(0.5, 2.0);

      await _flutterTts.setPitch(effectivePitch);
      await _flutterTts.setSpeechRate(profile.speechRate);
      await _flutterTts.setVolume(profile.volume);

      _isSpeaking = true;
      notifyListeners();

      await _flutterTts.speak(cleanText);
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint("Error en speakWithEmotion: $e");
    }
  }

  /// Detiene inmediatamente la síntesis de voz en curso.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }
}
