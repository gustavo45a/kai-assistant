import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kai_persona.dart';
import 'app_settings.dart';
import 'neural_tts_service.dart';

/// Perfil acústico con pitch y velocidad prosódica.
class KaiAcousticProfile {
  final double pitch;
  final double speechRate;
  final double volume;

  /// Velocidad relativa para la voz neuronal (1.0 = natural).
  final double neuralSpeed;

  const KaiAcousticProfile({
    required this.pitch,
    required this.speechRate,
    this.volume = 1.0,
    this.neuralSpeed = 1.0,
  });
}

/// Servicio singleton para la síntesis de voz (TTS) de Kai con modulación
/// prosódica reactiva a emociones y sanitización inteligente de código.
///
/// Usa la voz neuronal offline ([NeuralTtsService]) cuando hay una instalada y
/// activada; si no, la mejor voz del sistema disponible.
class KaiTtsService extends ChangeNotifier {
  static final KaiTtsService instance = KaiTtsService._internal();
  KaiTtsService._internal();

  static const String keyVoiceProfile = 'kai_voice_profile';
  static const String keyUseNeural = 'tts_use_neural';
  static const int _voiceProfileVersion = 2;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isEnabled = true;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _useNeural = true;
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

  /// El usuario quiere la voz neuronal cuando esté disponible.
  bool get useNeural => _useNeural;

  /// Se hablará con la voz neuronal en la próxima locución.
  bool get isUsingNeural => _useNeural && NeuralTtsService.instance.isReady;

  /// Nombre legible de la voz activa.
  String get activeVoiceLabel {
    final neural = NeuralTtsService.instance.selectedVoice;
    if (isUsingNeural && neural != null) return '${neural.name} (${neural.accent}) · Neuronal';
    return '${_selectedVoiceName ?? "Voz del sistema"} · Sistema';
  }

  /// Modulación acústica para cada emoción de Kai. Variaciones sutiles: los
  /// saltos grandes de tono son los que hacían sonar la voz robótica.
  static const Map<KaiEmotion, KaiAcousticProfile> emotionAcoustics = {
    KaiEmotion.neutral: KaiAcousticProfile(pitch: 1.00, speechRate: 0.48, neuralSpeed: 1.00),
    KaiEmotion.happy: KaiAcousticProfile(pitch: 1.06, speechRate: 0.52, neuralSpeed: 1.06),
    KaiEmotion.thinking: KaiAcousticProfile(pitch: 0.97, speechRate: 0.44, neuralSpeed: 0.92),
    KaiEmotion.focused: KaiAcousticProfile(pitch: 1.00, speechRate: 0.47, neuralSpeed: 0.97),
    KaiEmotion.smug: KaiAcousticProfile(pitch: 1.03, speechRate: 0.47, neuralSpeed: 0.98),
  };

  /// Asigna un listener que se dispara al terminar la locución del audio actual
  void setOnCompletion(VoidCallback? callback) {
    _onCompletionCallback = callback;
  }

  /// Obtiene el perfil acústico para una emoción determinada.
  KaiAcousticProfile getProfileForEmotion(KaiEmotion emotion) {
    return emotionAcoustics[emotion] ?? emotionAcoustics[KaiEmotion.neutral]!;
  }

  /// Inicializa el motor TTS, carga la huella de voz del dispositivo y configura callbacks.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _useNeural = prefs.getBool(keyUseNeural) ?? true;

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

      await _initializeUniqueVoice();

      final base = emotionAcoustics[KaiEmotion.neutral]!;
      await _flutterTts.setSpeechRate(base.speechRate);
      await _flutterTts.setVolume(base.volume);

      _isInitialized = true;
    } catch (e) {
      debugPrint("Error al inicializar KaiTtsService: $e");
    }

    if (!kIsWeb) {
      unawaited(NeuralTtsService.instance.init());
    }
  }

  Future<void> setUseNeural(bool value) async {
    _useNeural = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyUseNeural, value);
    notifyListeners();
  }

  /// Locale de voz según el dialecto elegido en la configuración inicial.
  static String localeForDialect(String dialect) {
    final d = dialect.toLowerCase();
    if (d.contains('méxico') || d.contains('mexico')) return 'es-MX';
    if (d.contains('españa') || d.contains('espana')) return 'es-ES';
    if (d.contains('argentina')) return 'es-AR';
    if (d.contains('colombia')) return 'es-CO';
    return 'es-US';
  }

  /// Puntúa una voz del sistema: locale exacto, alta calidad y que funcione sin internet.
  static int scoreVoice(Map<String, String> voice, String preferredLocale) {
    final locale = (voice['locale'] ?? '').replaceAll('_', '-').toLowerCase();
    final name = (voice['name'] ?? '').toLowerCase();
    var score = 0;
    if (locale == preferredLocale.toLowerCase()) {
      score += 40;
    } else if (locale.startsWith(preferredLocale.toLowerCase().split('-').first)) {
      score += 10;
    }
    final quality = int.tryParse(voice['quality'] ?? '') ?? 0;
    if (quality >= 400) score += 20;
    if (quality >= 500) score += 10;
    if (voice['network_required'] == '1' || voice['network_required'] == 'true' || name.contains('network')) {
      score -= 30;
    }
    if (name.contains('local')) score += 5;
    return score;
  }

  /// Inicializa o recupera la voz del sistema elegida para este dispositivo.
  Future<void> _initializeUniqueVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedProfileJson = prefs.getString(keyVoiceProfile);
      Map<String, dynamic>? saved;
      if (savedProfileJson != null && savedProfileJson.isNotEmpty) {
        saved = jsonDecode(savedProfileJson) as Map<String, dynamic>;
        // Los perfiles antiguos tenían tonos aleatorios de 0.8–1.2: se recalculan.
        if (saved['v'] != _voiceProfileVersion) saved = null;
      }

      if (saved != null) {
        final String? name = saved['name'] as String?;
        final String locale = saved['locale'] as String? ?? 'es-ES';
        _uniqueVoicePitch = (saved['pitch'] as num?)?.toDouble() ?? 1.0;
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
        return;
      }

      final preferredLocale = localeForDialect(await AppSettings.getDialect());
      try {
        await _flutterTts.setLanguage(preferredLocale);
      } catch (_) {}

      final List<Map<String, String>> spanishVoices = [];
      try {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List) {
          for (final item in rawVoices) {
            if (item is Map) {
              final voice = item.map((k, v) => MapEntry(k.toString(), v.toString()));
              final locale = (voice['locale'] ?? '').toLowerCase();
              if (locale.startsWith('es')) spanishVoices.add(voice);
            }
          }
        }
      } catch (_) {}

      Map<String, String> selectedVoice;
      if (spanishVoices.isNotEmpty) {
        spanishVoices.sort((a, b) => scoreVoice(b, preferredLocale).compareTo(scoreVoice(a, preferredLocale)));
        final best = spanishVoices.first;
        selectedVoice = {'name': best['name'] ?? '', 'locale': best['locale'] ?? preferredLocale};
      } else {
        selectedVoice = {'name': 'es-es-x-sfb-local', 'locale': 'es-ES'};
      }

      // Pequeña variación por dispositivo (0.96–1.04) para darle carácter sin distorsionar.
      _uniqueVoicePitch = double.parse((0.96 + (Random().nextDouble() * 0.08)).toStringAsFixed(2));
      _uniqueVoice = selectedVoice;
      _selectedVoiceName = selectedVoice['name'];

      try {
        await _flutterTts.setVoice(selectedVoice);
        await _flutterTts.setPitch(_uniqueVoicePitch);
      } catch (_) {}

      await prefs.setString(keyVoiceProfile, jsonEncode({
        'v': _voiceProfileVersion,
        'name': selectedVoice['name'],
        'locale': selectedVoice['locale'],
        'pitch': _uniqueVoicePitch,
      }));
    } catch (e) {
      debugPrint("Error al configurar la voz del sistema: $e");
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
  /// No espera a que termine de hablar: el fin se notifica con [setOnCompletion].
  Future<void> speakWithEmotion(String rawText, KaiEmotion emotion) async {
    if (!_isEnabled || rawText.trim().isEmpty) return;

    final cleanText = sanitizeForTts(rawText);
    if (cleanText.isEmpty) return;

    try {
      await stop();

      if (!_isInitialized) {
        await init();
      }

      _lastEmotion = emotion;
      final profile = getProfileForEmotion(emotion);

      if (isUsingNeural) {
        _isSpeaking = true;
        notifyListeners();
        unawaited(_speakNeural(cleanText, profile));
        return;
      }

      final effectivePitch = (_uniqueVoicePitch * profile.pitch).clamp(0.5, 2.0);
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

  Future<void> _speakNeural(String text, KaiAcousticProfile profile) async {
    var finished = false;
    try {
      finished = await NeuralTtsService.instance.speak(text, speed: profile.neuralSpeed);
    } catch (e) {
      // Si la voz neuronal falla (memoria insuficiente, archivo dañado), usar la del sistema.
      debugPrint("Voz neuronal no disponible, usando la del sistema: $e");
      _isSpeaking = false;
      final pitch = (_uniqueVoicePitch * profile.pitch).clamp(0.5, 2.0);
      try {
        await _flutterTts.setPitch(pitch);
        await _flutterTts.setSpeechRate(profile.speechRate);
        await _flutterTts.speak(text);
      } catch (_) {}
      return;
    }
    if (!finished) return;
    _isSpeaking = false;
    notifyListeners();
    _onCompletionCallback?.call();
  }

  /// Detiene inmediatamente la síntesis de voz en curso.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    try {
      await NeuralTtsService.instance.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }
}
