import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';

import '../../models/app_theme.dart';
import '../../models/chat_thread.dart';
import '../../models/kai_persona.dart';
import '../../services/local_llm_service.dart';
import '../../services/kai_tts_service.dart';
import '../../services/memory_service.dart';
import '../widgets/apple_glass_icon_button.dart';

/// Estados del ciclo de conversación en tiempo real del Modo Live
enum LiveModeState {
  listening, // Escuchando activamente la voz del usuario con VAD
  thinking,  // Procesando en LLM local, timer de sonidos de relleno activo
  speaking,  // Locución en tiempo real por oraciones acumuladas (Chunking)
  paused,    // Conversación en pausa manual
}

class LiveModeScreen extends StatefulWidget {
  final String username;
  final AppThemeStyle currentTheme;
  final CoreMode initialMode;

  const LiveModeScreen({
    super.key,
    required this.username,
    required this.currentTheme,
    this.initialMode = CoreMode.normal,
  });

  @override
  State<LiveModeScreen> createState() => _LiveModeScreenState();
}

class _LiveModeScreenState extends State<LiveModeScreen>
    with TickerProviderStateMixin {
  // 1. CONTROLADORES DE ANIMACIÓN (Respiración y Resplandor)
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  // Estado del Modo Live
  LiveModeState _liveState = LiveModeState.listening;
  CoreMode _currentMode = CoreMode.normal;
  KaiEmotion _currentKaiEmotion = KaiEmotion.neutral;

  // 2. ACTIVE LISTENING & SONIDOS DE RELLENO (Thinking Timers)
  Timer? _thinkingTimer2s;
  Timer? _thinkingTimer5s;
  bool _hasReceivedFirstToken = false;
  bool _isPlayingFiller = false;

  // 3. STT NATIVO (Speech-to-Text & VAD)
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isSpeechAvailable = false;
  String _userSpeechBuffer = "";
  Timer? _vadSilenceTimer;
  static const Duration _vadSilenceDuration = Duration(milliseconds: 1600);

  // 4. TTS EN TIEMPO REAL (Chunking por Puntuación)
  final StringBuffer _llmTokenBuffer = StringBuffer();
  final List<String> _pendingSpeechQueue = [];
  bool _isFlushingSpeechQueue = false;
  String _currentAiResponseFull = "";

  // Transcripción en vivo
  String _liveTranscript = "Di algo para comenzar a hablar con Kai...";

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    // 1. Animación de respiración suave (escala 1.0 a 1.055)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.055).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 18.0, end: 42.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    // Animación de ondas expansivas / ondas de audio
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );

    // Inicializar subsistemas de audio y voz
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeLiveAudioPipeline();
    });
  }

  @override
  void dispose() {
    _stopThinkingTimer();
    _vadSilenceTimer?.cancel();
    _breathController.dispose();
    _rippleController.dispose();
    KaiTtsService.instance.stop();
    _speechToText.stop();
    super.dispose();
  }

  /// Inicializa la pipeline completa: Micrófono (STT) y Huella de Voz Única (TTS)
  Future<void> _initializeLiveAudioPipeline() async {
    // 5. Inicializar Huella de Voz Única por Dispositivo en KaiTtsService
    await KaiTtsService.instance.init();

    // Callback de fin de locución para reactivar la escucha continua automáticamente
    KaiTtsService.instance.setOnCompletion(() {
      if (mounted && _liveState == LiveModeState.speaking) {
        if (_pendingSpeechQueue.isEmpty) {
          _isFlushingSpeechQueue = false;
          _onAiFinishedSpeaking();
        } else {
          _playNextSpeechChunk();
        }
      }
    });

    // 3. Inicializar STT Nativo
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        setState(() {
          _liveTranscript = "Se requiere permiso de micrófono para el Modo Live.";
        });
      }
      return;
    }

    _isSpeechAvailable = await _speechToText.initialize(
      onError: (SpeechRecognitionError error) {
        debugPrint("[STT Live Error]: ${error.errorMsg}");
        if (mounted && _liveState == LiveModeState.listening) {
          _restartListeningDebounced();
        }
      },
      onStatus: (String status) {
        if (status == 'notListening' || status == 'done') {
          if (_liveState == LiveModeState.listening && _userSpeechBuffer.trim().isNotEmpty) {
            _onUserStoppedSpeakingVAD();
          }
        }
      },
    );

    _speechInitialized = true;
    if (mounted) {
      _startListening();
    }
  }

  // ==========================================
  // 2. ACTIVE LISTENING (Sonidos de Relleno)
  // ==========================================

  /// Activa los temporizadores de Active Listening si el LLM tarda en responder
  void _startThinkingTimer() {
    _stopThinkingTimer();
    _hasReceivedFirstToken = false;

    // Timer de 2 segundos: Reproduce primer murmullo / relleno sutil
    _thinkingTimer2s = Timer(const Duration(milliseconds: 2000), () {
      if (!_hasReceivedFirstToken && mounted && _liveState == LiveModeState.thinking) {
        _playFillerSound(isFirst: true);
      }
    });

    // Timer de 5 segundos: Reproduce segundo murmullo de pensamiento profundo
    _thinkingTimer5s = Timer(const Duration(milliseconds: 5000), () {
      if (!_hasReceivedFirstToken && mounted && _liveState == LiveModeState.thinking) {
        _playFillerSound(isFirst: false);
      }
    });
  }

  /// Cancela INMEDIATAMENTE los temporizadores en cuanto llega el primer token del LLM
  void _stopThinkingTimer() {
    _hasReceivedFirstToken = true;
    _thinkingTimer2s?.cancel();
    _thinkingTimer5s?.cancel();
    _thinkingTimer2s = null;
    _thinkingTimer5s = null;

    if (_isPlayingFiller) {
      KaiTtsService.instance.stop();
      _isPlayingFiller = false;
    }
  }

  /// Reproduce un sonido de relleno acústico ligero ('umm', 'hmm')
  Future<void> _playFillerSound({required bool isFirst}) async {
    if (_hasReceivedFirstToken || _liveState != LiveModeState.thinking) return;

    _isPlayingFiller = true;
    HapticFeedback.lightImpact();

    final fillerPhrase = isFirst ? "Umm..." : "Hmm...";
    if (mounted) {
      setState(() {
        _liveTranscript = isFirst ? "Kai está reflexionando..." : "Kai está estructurando la respuesta...";
      });
    }

    try {
      // Intentar reproducir murmullo vocal natural a baja intensidad
      await KaiTtsService.instance.speakWithEmotion(fillerPhrase, KaiEmotion.thinking);
    } catch (_) {}
  }

  // ==========================================
  // 3. STT NATIVO (Speech-to-Text & VAD)
  // ==========================================

  /// Inicia la escucha del usuario con detección de actividad de voz (VAD)
  Future<void> _startListening() async {
    if (!_speechInitialized || !_isSpeechAvailable || _liveState == LiveModeState.paused) return;

    await KaiTtsService.instance.stop();
    _userSpeechBuffer = "";

    setState(() {
      _liveState = LiveModeState.listening;
      _currentKaiEmotion = KaiEmotion.neutral;
      _liveTranscript = "Escuchando tu voz...";
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (_liveState != LiveModeState.listening) return;

          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            _userSpeechBuffer = words;
            if (mounted) {
              setState(() {
                _liveTranscript = '"$_userSpeechBuffer"';
              });
            }

            // VAD: Reiniciar temporizador de silencio continuo al detectar voz activa
            _vadSilenceTimer?.cancel();
            _vadSilenceTimer = Timer(_vadSilenceDuration, () {
              if (_liveState == LiveModeState.listening && _userSpeechBuffer.trim().isNotEmpty) {
                _onUserStoppedSpeakingVAD();
              }
            });
          }

          if (result.finalResult && words.isNotEmpty) {
            _vadSilenceTimer?.cancel();
            _onUserStoppedSpeakingVAD();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          onDevice: true,
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("[STT Listen Exception]: $e");
    }
  }

  /// Detiene la escucha y transfiere la consulta al motor LLM local
  Future<void> _onUserStoppedSpeakingVAD() async {
    _vadSilenceTimer?.cancel();
    final promptText = _userSpeechBuffer.trim();
    if (promptText.isEmpty) {
      _startListening();
      return;
    }

    await _speechToText.stop();
    HapticFeedback.mediumImpact();

    // Iniciar procesamiento con el LLM
    _dispatchPromptToLocalLlm(promptText);
  }

  void _restartListeningDebounced() {
    _vadSilenceTimer?.cancel();
    _vadSilenceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _liveState == LiveModeState.listening) {
        _startListening();
      }
    });
  }

  // ==========================================
  // 4. INFERENCIA LLM & TTS CHUNKING
  // ==========================================

  /// Envía el prompt al LLM y procesa tokens en tiempo real mediante oraciones divididas
  Future<void> _dispatchPromptToLocalLlm(String promptText) async {
    setState(() {
      _liveState = LiveModeState.thinking;
      _currentKaiEmotion = KaiEmotion.thinking;
      _liveTranscript = "Kai está pensando...";
      _currentAiResponseFull = "";
    });

    // 2. Iniciar temporizador de sonidos de relleno
    _startThinkingTimer();

    _llmTokenBuffer.clear();
    _pendingSpeechQueue.clear();
    _isFlushingSpeechQueue = false;

    // Extraer memoria aprendida
    MemoryService.instance.extractMemoryFromInteraction(promptText);

    try {
      final stream = LocalLLMService.instance.generateResponseStream(
        promptText,
        {
          'modoEstudiante': _currentMode == CoreMode.estudiante,
          'mode': _currentMode,
          'username': widget.username,
          'memoriaAprendida': MemoryService.instance.isLearningEnabled
              ? MemoryService.instance.memories
              : <String>[],
        },
      );

      await for (final chunk in stream) {
        // En el primer token recibido del LLM, cancelar sonidos de relleno INMEDIATAMENTE
        if (!_hasReceivedFirstToken) {
          _stopThinkingTimer();
          if (mounted) {
            setState(() {
              _liveState = LiveModeState.speaking;
            });
          }
        }

        _llmTokenBuffer.write(chunk);
        _currentAiResponseFull += chunk;

        // Extraer emoción detectada
        final parsed = KaiPersona.extractEmotionFromStream(_currentAiResponseFull);
        if (parsed.detectedEmotion != null && parsed.detectedEmotion != _currentKaiEmotion) {
          if (mounted) {
            setState(() {
              _currentKaiEmotion = parsed.detectedEmotion!;
            });
          }
        }

        // 4. TTS EN TIEMPO REAL (Chunking): Detectar signos de puntuación (. ? !)
        _extractAndEnqueueCompletedSentences();
      }

      // Al finalizar el stream, vaciar cualquier fragmento residual pendiente
      _flushRemainingSentence();
    } catch (e) {
      _stopThinkingTimer();
      const errorSentence = "Lo siento, tuve un problema al procesar la respuesta.";
      _enqueueSpeechSentence(errorSentence);
    }
  }

  /// Extrae oraciones completas delimitadas por signos de puntuación (. ? !)
  void _extractAndEnqueueCompletedSentences() {
    final bufferText = _llmTokenBuffer.toString();

    // Expresión regular para localizar delimitadores de oración seguidos de espacio o salto de línea
    final RegExp sentenceRegex = RegExp(r'([^\.\?!:\n]+[\.\?!:\n])(?:\s+|\n|$)');
    final match = sentenceRegex.firstMatch(bufferText);

    if (match != null) {
      final completedSentence = match.group(1) ?? '';
      if (completedSentence.trim().length >= 3) {
        _enqueueSpeechSentence(completedSentence.trim());

        // Remover la oración extraída del buffer
        final remaining = bufferText.substring(match.end);
        _llmTokenBuffer.clear();
        _llmTokenBuffer.write(remaining);

        // Disparar la locución de la cola inmediatamente
        _pumpSpeechQueue();
      }
    }
  }

  /// Encola el fragmento final restante una vez terminado el stream del LLM
  void _flushRemainingSentence() {
    final remaining = _llmTokenBuffer.toString().trim();
    if (remaining.isNotEmpty) {
      _enqueueSpeechSentence(remaining);
      _llmTokenBuffer.clear();
      _pumpSpeechQueue();
    } else if (_pendingSpeechQueue.isEmpty && !_isFlushingSpeechQueue) {
      _onAiFinishedSpeaking();
    }
  }

  /// Agrega una oración sanitizada a la cola de voz
  void _enqueueSpeechSentence(String sentence) {
    final clean = KaiPersona.cleanEmotionTags(sentence).trim();
    final sanitized = KaiTtsService.sanitizeForTts(clean);
    if (sanitized.isNotEmpty) {
      _pendingSpeechQueue.add(sanitized);
    }
  }

  /// Procesa secuencialmente las oraciones de la cola de voz sin solapamiento
  Future<void> _pumpSpeechQueue() async {
    if (_isFlushingSpeechQueue || _pendingSpeechQueue.isEmpty) return;
    _isFlushingSpeechQueue = true;
    _playNextSpeechChunk();
  }

  /// Reproduce el siguiente fragmento en cola a través de TTS
  Future<void> _playNextSpeechChunk() async {
    if (_pendingSpeechQueue.isEmpty) {
      _isFlushingSpeechQueue = false;
      return;
    }

    final sentenceToSpeak = _pendingSpeechQueue.removeAt(0);

    if (mounted) {
      setState(() {
        _liveState = LiveModeState.speaking;
        _liveTranscript = sentenceToSpeak;
      });
    }

    await KaiTtsService.instance.speakWithEmotion(sentenceToSpeak, _currentKaiEmotion);
  }

  /// Llamado cuando la IA termina de hablar todas las oraciones encoladas
  void _onAiFinishedSpeaking() {
    if (!mounted || _liveState == LiveModeState.paused) return;

    setState(() {
      _liveState = LiveModeState.listening;
      _currentKaiEmotion = KaiEmotion.neutral;
      _liveTranscript = "Escuchando tu voz...";
    });

    // Reactivar micrófono automáticamente para conversación continua sin manos
    _startListening();
  }

  /// Alterna entre pausa manual y escucha activa
  void _togglePauseLiveMode() {
    if (_liveState == LiveModeState.paused) {
      setState(() {
        _liveState = LiveModeState.listening;
      });
      _startListening();
    } else {
      _stopThinkingTimer();
      _vadSilenceTimer?.cancel();
      _speechToText.stop();
      KaiTtsService.instance.stop();
      _pendingSpeechQueue.clear();

      setState(() {
        _liveState = LiveModeState.paused;
        _liveTranscript = "Modo Live en pausa. Toca el micrófono para continuar.";
      });
    }
  }

  // ==========================================
  // CONSTRUCCIÓN DE LA INTERFAZ (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(widget.currentTheme);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    final Color glowColor = _getGlowColorForState(theme);

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      body: Stack(
        children: [
          // 1. Fondo espacial atmosférico oscuro con desenfoque de cristal
          Positioned.fill(
            child: RepaintBoundary(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.1),
                    radius: 1.1,
                    colors: [
                      Color(0xFF141724),
                      Color(0xFF0C0E14),
                      Color(0xFF08090C),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2. Ondas de audio / Ripples expansivos detrás del Avatar
          if (_liveState == LiveModeState.speaking || _liveState == LiveModeState.listening)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    final progress = _rippleAnimation.value;
                    final rippleRadius = 140.0 + (progress * 130.0);
                    final opacity = (1.0 - progress) * (_liveState == LiveModeState.speaking ? 0.35 : 0.20);

                    return Center(
                      child: Container(
                        width: rippleRadius * 2,
                        height: rippleRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: glowColor.withValues(alpha: opacity),
                            width: 1.6,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 3. Contenido Central: Avatar Respirante, Resplandor y Subtítulos
          SafeArea(
            child: Column(
              children: [
                // Cabecera con botón de cerrar y selector de modo
                _buildTopAppBar(theme),

                const Spacer(flex: 1),

                // 1. AVATAR CON ANIMACIÓN DE RESPIRACIÓN Y RESPLANDOR PULSANTE
                Center(
                  child: AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      final scale = _scaleAnimation.value;
                      final glowBlur = _glowAnimation.value;

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: isLandscape ? 170 : 210,
                          height: isLandscape ? 170 : 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              // Resplandor difuso exterior (Glow)
                              BoxShadow(
                                color: glowColor.withValues(
                                  alpha: _liveState == LiveModeState.speaking
                                      ? 0.48
                                      : (_liveState == LiveModeState.thinking ? 0.40 : 0.28),
                                ),
                                blurRadius: glowBlur,
                                spreadRadius: _liveState == LiveModeState.speaking ? 8 : 4,
                              ),
                              // Sombra de profundidad interior
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.60),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Imagen de Kai Avatar con fallback seguro
                                Image.asset(
                                  'assets/images/kai_avatar.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/kai_image.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF1B1D27),
                                        child: Icon(
                                          _currentKaiEmotion.fallbackIcon,
                                          size: 80,
                                          color: glowColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Filtro sutil de gradiente de iluminación
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.25),
                                      ],
                                      stops: const [0.65, 1.0],
                                    ),
                                    border: Border.all(
                                      color: glowColor.withValues(alpha: 0.55),
                                      width: 2.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Nombre & Emoción de Kai
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor,
                        boxShadow: [BoxShadow(color: glowColor, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusBadgeText(),
                      style: TextStyle(
                        color: glowColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Transcripción en vivo estilo Apple Glass
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141622).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Text(
                          _liveTranscript,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // 5. Huella de voz única activa (Badge informativo)
                _buildVoiceFingerprintBadge(theme),

                const SizedBox(height: 18),

                // Controles inferiores Apple Glass
                _buildBottomControls(theme),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barra superior de navegación y modo
  Widget _buildTopAppBar(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón cerrar Live Mode
          AppleGlassIconButton(
            icon: CupertinoIcons.xmark,
            size: 38,
            iconSize: 18,
            borderRadius: 12,
            tooltip: "Salir de Modo Live",
            onTap: () => Navigator.of(context).pop(),
          ),

          // Título central
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: theme.primaryColor, size: 20),
              const SizedBox(width: 6),
              Text(
                "KAI LIVE",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          // Switch de modo de respuesta
          AppleGlassIconButton(
            icon: _currentMode == CoreMode.estudiante ? Icons.school_rounded : Icons.bolt_rounded,
            size: 38,
            iconSize: 18,
            borderRadius: 12,
            isActive: true,
            activeGlowColor: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
            tooltip: _currentMode == CoreMode.estudiante ? "Modo Estudiante Activo" : "Modo Normal Activo",
            onTap: () {
              setState(() {
                _currentMode = _currentMode == CoreMode.normal ? CoreMode.estudiante : CoreMode.normal;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Badge que muestra la huella de voz única configurada en este dispositivo
  Widget _buildVoiceFingerprintBadge(AppThemeData theme) {
    final voiceName = KaiTtsService.instance.selectedVoiceName ?? "Voz Neural";
    final pitch = KaiTtsService.instance.uniqueVoicePitch;
    final shortName = voiceName.split('-').last.toUpperCase();

    return AppleGlassPill(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fingerprint_rounded, size: 14, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(
            "Huella de voz: $shortName • Pitch ${pitch.toStringAsFixed(2)}x",
            style: TextStyle(
              color: theme.subtitleColor,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Barra inferior con botón principal de control
  Widget _buildBottomControls(AppThemeData theme) {
    final bool isPaused = _liveState == LiveModeState.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón principal de Micrófono / Pausa grande
        GestureDetector(
          onTap: _togglePauseLiveMode,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaused
                  ? const Color(0xFF282C3D)
                  : theme.primaryColor.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: isPaused
                      ? Colors.black.withValues(alpha: 0.3)
                      : theme.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              isPaused ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
              size: 30,
              color: isPaused ? const Color(0xFF94A3B8) : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Retorna el color de resplandor dinámico según el estado actual de la IA
  Color _getGlowColorForState(AppThemeData theme) {
    switch (_liveState) {
      case LiveModeState.listening:
        return const Color(0xFF00E5FF); // Cian eléctrico brillante
      case LiveModeState.thinking:
        return const Color(0xFF9D4EDD); // Violeta neón reflexivo
      case LiveModeState.speaking:
        return const Color(0xFF2ECC71); // Esmeralda dinámico al hablar
      case LiveModeState.paused:
        return const Color(0xFF64748B); // Gris tenue
    }
  }

  /// Retorna el texto del estado de la IA
  String _getStatusBadgeText() {
    switch (_liveState) {
      case LiveModeState.listening:
        return "KAI ESCUCHANDO...";
      case LiveModeState.thinking:
        return "KAI PENSANDO...";
      case LiveModeState.speaking:
        return "KAI HABLANDO...";
      case LiveModeState.paused:
        return "MODO LIVE EN PAUSA";
    }
  }
}
