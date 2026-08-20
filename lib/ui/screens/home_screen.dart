import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'live_mode_screen.dart';
import '../../models/app_theme.dart';
import '../../models/local_model.dart';
import '../../models/chat_thread.dart';
import '../../models/kai_persona.dart';
import '../../services/hardware_scanner.dart';
import '../../services/local_llm_service.dart';
import '../../services/memory_service.dart';
import '../../services/app_settings.dart';
import '../../services/kai_sprite_service.dart';
import '../../services/kai_tts_service.dart';
import '../widgets/windows_xp_error_dialog.dart';
import '../widgets/theme_selector_modal.dart';
import '../widgets/dynamic_multicolor_background.dart';
import '../widgets/kai_avatar_view.dart';
import '../widgets/apple_glass_icon_button.dart';

class VantablackHome extends StatefulWidget {
  final String username;
  final AppThemeStyle currentTheme;
  final Function(AppThemeStyle) onThemeChanged;

  const VantablackHome({
    super.key,
    required this.username,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<VantablackHome> createState() => _VantablackHomeState();
}

class _VantablackHomeState extends State<VantablackHome> {
  final String _versionHub = "3.0.0";
  final int _currentBuildNumber = 40;
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/docs/vantablack_hub.apk";
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late AppThemeStyle _currentThemeStyle;
  CoreMode _currentMode = CoreMode.normal;
  KaiEmotion _currentKaiEmotion = KaiEmotion.neutral;
  List<ChatThread> _threads = [
    ChatThread(
      id: "instancia_local_default",
      title: "Chat con Kai",
      iaModel: "llama_3_2_1b",
      modeloInicializado: true,
      messages: [
        {"sender": "system", "text": "BIENVENIDO AL NÚCLEO LOCAL VANTABLACK."},
      ],
    ),
  ];
  String? _activeThreadId;

  Color? _customAccentColor;
  String? _customBgImagePath;

  bool _isGenerating = false;
  bool _isEngineInitializing = true;
  bool _descargandoOta = false;
  bool _descargandoModelo = false;
  double _progresoOta = 0.0;
  double _progresoModelo = 0.0;

  double _freeRamGb = 4.0;
  double _totalRamGb = 8.0;
  int _cpuCores = 4;

  bool isZRamEnabled = true;
  bool isWebServidorActive = false;
  bool isModoPro = false;
  bool isVirtualAssistantActive = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _currentStreamingMessage = ValueNotifier<String>('');

  final List<LocalModel> _modelosDisponibles = [
    LocalModel(
      id: "llama_3_2_1b",
      name: "Llama 3.2 1B Instruct",
      size: "750 MB",
      requiredRamGb: 2.5,
      urlGguf: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      badge: "RECOMENDADO",
      badgeColor: const Color(0xFF00B4D8),
      description: "Modelo ultrarrápido optimizado por Meta para dispositivos móviles con RAM ajustada.",
    ),
    LocalModel(
      id: "qwen_0.5b_chat_q4",
      name: "Qwen 2.5 0.5B Chat",
      size: "390 MB",
      requiredRamGb: 1.5,
      urlGguf: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
      badge: "LIGERO",
      badgeColor: const Color(0xFF2ECC71),
      description: "Respuesta instantánea con huella de RAM mínima. Ideal para pruebas en caliente.",
    ),
    LocalModel(
      id: "deepseek_r1_1.5b",
      name: "DeepSeek R1 Distill 1.5B",
      size: "1.1 GB",
      requiredRamGb: 3.8,
      urlGguf: "https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
      badge: "RAZONAMIENTO",
      badgeColor: const Color(0xFF9D4EDD),
      description: "Capacidad avanzada de razonamiento y resolución de código paso a paso.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentThemeStyle = widget.currentTheme;
    _isEngineInitializing = true;

    // 2. INICIALIZACIÓN ASÍNCRONA NO BLOQUEANTE (Sin congelar el Main Thread)
    Future.microtask(() async {
      try {
        await KaiTtsService.instance.init();
        await MemoryService.instance.init();
        final colorVal = await AppSettings.getCustomAccentColor();
        final bgPath = await AppSettings.getCustomBgImagePath();
        final diagnostic = await HardwareScanner.scan();

        await _verificarModelosDescargados();
        await _cargarDatosDesdeDisco();

        // Inicialización en background si el modelo local ya existe
        if (_activeThread.rutaModeloLocal != null && File(_activeThread.rutaModeloLocal!).existsSync()) {
          try {
            await LocalLLMService.instance.initializeRealModel(_activeThread.rutaModeloLocal!, threads: 4);
            _activeThread.modeloInicializado = true;
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _customAccentColor = colorVal != null ? Color(colorVal) : null;
            _customBgImagePath = bgPath;
            _cpuCores = diagnostic['cores'] ?? 4;
            _freeRamGb = (diagnostic['freeRamGb'] as num?)?.toDouble() ?? 4.0;
            _totalRamGb = (diagnostic['totalRamGb'] as num?)?.toDouble() ?? 8.0;
            _isEngineInitializing = false;
          });
        }
        await _checkUpdates();
      } catch (e) {
        if (mounted) {
          setState(() {
            _isEngineInitializing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _currentStreamingMessage.dispose();
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    await KaiTtsService.instance.speakWithEmotion(text, _currentKaiEmotion);
  }

  Future<void> _toggleListening() async {
    if (!_speechInitialized) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("Se requiere permiso de micrófono para reconocimiento de voz.", titulo: "Permiso denegado - Vantablack Hub");
        }
        return;
      }
      _speechInitialized = await _speechToText.initialize(
        onError: (e) => setState(() => _isListening = false),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
    }

    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _chatController.text = result.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
      );
    }
  }

  Future<void> _checkUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get("https://gustavo45a.github.io/kai-assistant/version.json");
      if (response.statusCode == 200) {
        final data = response.data;
        int remoteBuild = data['build_number'] ?? _currentBuildNumber;
        if (remoteBuild > _currentBuildNumber) {
          _ejecutarActualizacionOTA();
        }
      }
    } catch (_) {}
  }

  Future<void> _ejecutarActualizacionOTA() async {
    setState(() {
      _descargandoOta = true;
      _progresoOta = 0.0;
    });

    try {
      final dir = await getTemporaryDirectory();
      final savePath = "${dir.path}/vantablack_update.apk";
      final dio = Dio();

      await dio.download(
        _urlApkRemoto,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoOta = received / total;
            });
          }
        },
      );

      setState(() {
        _descargandoOta = false;
      });

      await OpenFile.open(savePath);
    } catch (e) {
      setState(() {
        _descargandoOta = false;
      });
      if (mounted) {
        _mostrarModalErrorWindowsXP("Fallo al descargar la actualización OTA: $e");
      }
    }
  }

  Future<void> _verificarModelosDescargados() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (var model in _modelosDisponibles) {
        final filePath = "${dir.path}/${model.id}.gguf";
        final file = File(filePath);
        model.isDownloaded = await file.exists();
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _descargarModeloLlmNativamente(ChatThread thread, {LocalModel? model}) async {
    final targetModel = model ?? _modelosDisponibles.firstWhere(
      (m) => m.id == thread.iaModel,
      orElse: () => _modelosDisponibles.first,
    );

    setState(() {
      _descargandoModelo = true;
      _progresoModelo = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${targetModel.id}.gguf";
      final dio = Dio();

      await dio.download(
        targetModel.urlGguf,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoModelo = received / total;
            });
          }
        },
      );

      targetModel.isDownloaded = true;
      thread.iaModel = targetModel.id;
      thread.rutaModeloLocal = filePath;

      await LocalLLMService.instance.initializeRealModel(filePath, threads: 4);
      thread.modeloInicializado = true;

      setState(() {
        _descargandoModelo = false;
      });

      await _guardarDatosEnDisco();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2029),
            content: Text("¡Modelo ${targetModel.name} listo para usar!", style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _descargandoModelo = false;
      });
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al descargar modelo local: $e");
      }
    }
  }

  Future<void> _cargarDatosDesdeDisco() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('vantablack_threads');
      if (jsonStr != null) {
        final List dynamicList = jsonDecode(jsonStr);
        _threads = dynamicList.map((item) => ChatThread.fromJson(item)).toList();
      }

      if (_threads.isEmpty) {
        _crearNuevaInstanciaLocal("llama_3_2_1b");
      } else {
        _activeThreadId = _threads.first.id;
      }
      setState(() {});
    } catch (_) {
      if (_threads.isEmpty) {
        _crearNuevaInstanciaLocal("llama_3_2_1b");
      }
    }
  }

  Future<void> _guardarDatosEnDisco() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_threads.map((t) => t.toJson()).toList());
      await prefs.setString('vantablack_threads', jsonStr);
    } catch (_) {}
  }

  void _crearNuevaInstanciaLocal(String modelId) {
    final newId = const Uuid().v4();
    final newThread = ChatThread(
      id: newId,
      title: "Nuevo Chat",
      iaModel: modelId,
      modeloInicializado: true,
      messages: [
        {"sender": "system", "text": "INSTANCIA KAI INICIALIZADA."},
      ],
    );
    setState(() {
      _threads.insert(0, newThread);
      _activeThreadId = newId;
    });
    _guardarDatosEnDisco();
  }

  void _borrarThread(String id) {
    if (_threads.length <= 1) {
      _crearNuevaInstanciaLocal("llama_3_2_1b");
      _threads.removeWhere((t) => t.id == id);
      setState(() {});
      _guardarDatosEnDisco();
      return;
    }
    setState(() {
      _threads.removeWhere((t) => t.id == id);
      if (_activeThreadId == id) {
        _activeThreadId = _threads.first.id;
      }
    });
    _guardarDatosEnDisco();
  }

  ChatThread get _activeThread {
    return _threads.firstWhere(
      (t) => t.id == _activeThreadId,
      orElse: () => _threads.isNotEmpty
          ? _threads.first
          : ChatThread(id: '0', title: 'Default', iaModel: 'llama_3_2_1b', modeloInicializado: true, messages: []),
    );
  }

  Future<void> _procesarMensajeLocal([String? customPrompt]) async {
    final threadActual = _activeThread;
    final promptToSend = customPrompt ?? _chatController.text.trim();

    // 2. BLOQUEO DE ESTADO: Prevenir envíos múltiples concurrentes y 'Bad state: Already generating'
    if (promptToSend.isEmpty || threadActual.pensando || _isGenerating) return;

    if (customPrompt == null) {
      _chatController.clear();
    }
    await KaiTtsService.instance.stop();

    // Actualizar título del chat si es el primer mensaje del usuario
    if (threadActual.messages.where((m) => m["sender"] == "user").isEmpty) {
      final shortTitle = promptToSend.length > 26 ? "${promptToSend.substring(0, 24)}..." : promptToSend;
      threadActual.title = shortTitle;
    }

    setState(() {
      _isGenerating = true;
      _currentKaiEmotion = KaiEmotion.thinking;
      threadActual.messages.add({"sender": "user", "text": promptToSend});
      threadActual.messages.add({"sender": "assistant", "text": "..."});
      threadActual.pensando = true;
    });

    _currentStreamingMessage.value = "...";
    _scrollToBottom();

    // Extraer memoria aprendida
    MemoryService.instance.extractMemoryFromInteraction(promptToSend);

    try {
      if (!LocalLLMService.instance.isModelLoaded && threadActual.rutaModeloLocal != null) {
        // 3. OPTIMIZACIÓN C++: 4 hilos configurados para rendimiento móvil óptimo
        await LocalLLMService.instance.initializeRealModel(threadActual.rutaModeloLocal!, threads: 4);
        threadActual.modeloInicializado = true;
      }

      if (LocalLLMService.instance.isModelLoaded) {
        final stream = LocalLLMService.instance.generateResponseStream(
          promptToSend,
          {
            'modoEstudiante': _currentMode == CoreMode.estudiante,
            'mode': _currentMode,
            'username': widget.username,
            'memoriaAprendida': MemoryService.instance.isLearningEnabled
                ? MemoryService.instance.memories
                : <String>[],
          },
          history: threadActual.messages,
        );

        final responseBuffer = StringBuffer();
        await for (final chunk in stream) {
          if (!_isGenerating) break;
          responseBuffer.write(chunk);
          final parseResult = KaiPersona.extractEmotionFromStream(responseBuffer.toString());
          final cleanStreaming = parseResult.cleanText.isNotEmpty ? parseResult.cleanText : responseBuffer.toString();

          if (parseResult.detectedEmotion != null && parseResult.detectedEmotion != _currentKaiEmotion) {
            _currentKaiEmotion = parseResult.detectedEmotion!;
          }

          // 1. OPTIMIZACIÓN DE RENDERIZADO: Aislamiento del token en ValueNotifier sin setState() global
          _currentStreamingMessage.value = cleanStreaming;
        }

        final finalResult = KaiPersona.extractEmotionFromStream(responseBuffer.toString());
        final cleanText = finalResult.cleanText.isNotEmpty ? finalResult.cleanText : responseBuffer.toString();

        if (finalResult.detectedEmotion != null) {
          _currentKaiEmotion = finalResult.detectedEmotion!;
        }
        threadActual.messages.last = {"sender": "assistant", "text": cleanText};
        await _speakText(cleanText);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        final fallbackMsg = "El modelo ${_getNomModel(_activeThread.iaModel)} no está descargado aún. Pulsa el botón de descarga en la barra superior o en el sidebar para cargarlo localmente.";
        threadActual.messages.last = {"sender": "assistant", "text": fallbackMsg};
        _currentKaiEmotion = KaiEmotion.neutral;
      }
    } catch (e) {
      // 4. MANEJO DE ERRORES: Capturar fallo y presentar mensaje amigable en el chat
      final errorMsg = "⚠️ Lo siento, ocurrió un error durante la inferencia local ($e). Por favor, intenta de nuevo.";
      threadActual.messages.last = {"sender": "assistant", "text": errorMsg};
      _currentKaiEmotion = KaiEmotion.neutral;
    } finally {
      // 2. BLOQUEO DE ESTADO: Resetear isGenerating tanto al finalizar como al fallar
      _currentStreamingMessage.value = "";
      if (mounted) {
        setState(() {
          threadActual.pensando = false;
          _isGenerating = false;
        });
        _scrollToBottom();
        _guardarDatosEnDisco();
      }
    }
  }

  String _getNomModel(String id) {
    for (final m in _modelosDisponibles) {
      if (m.id == id) return m.name;
    }
    return id;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- MODAL DE MODELOS Y DESCARGA DIRECTA HUGGING FACE ---
  void _mostrarModalModelos() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = AppThemeConfig.getTheme(_currentThemeStyle);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF141721),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E3245), width: 1.2),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.memory_rounded, color: theme.primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              "MODELOS GGUF LOCALES",
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Descarga modelos de Hugging Face y ejecútalos 100% offline con inferencia nativa.",
                      style: TextStyle(color: theme.subtitleColor, fontSize: 11.5),
                    ),
                    const SizedBox(height: 16),
                    ..._modelosDisponibles.map((model) {
                      final isActiveInThread = _activeThread.iaModel == model.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActiveInThread
                              ? const Color(0xFF1A2234)
                              : const Color(0xFF1B1D27),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActiveInThread
                                ? theme.primaryColor.withValues(alpha: 0.6)
                                : const Color(0xFF282C3D),
                            width: isActiveInThread ? 1.4 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        model.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: model.badgeColor.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: model.badgeColor, width: 0.8),
                                        ),
                                        child: Text(
                                          model.badge,
                                          style: TextStyle(
                                            color: model.badgeColor,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  model.size,
                                  style: TextStyle(
                                    color: theme.subtitleColor,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              model.description,
                              style: TextStyle(color: theme.subtitleColor, fontSize: 11, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "RAM Req: ${model.requiredRamGb} GB",
                                  style: TextStyle(color: theme.subtitleColor, fontSize: 10.5, fontFamily: 'monospace'),
                                ),
                                if (model.isDownloaded) ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isActiveInThread
                                          ? theme.primaryColor
                                          : const Color(0xFF2A2D3D),
                                      foregroundColor: isActiveInThread ? Colors.black : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _activeThread.iaModel = model.id;
                                        _activeThread.modeloInicializado = true;
                                      });
                                      _guardarDatosEnDisco();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(isActiveInThread ? Icons.check_circle_rounded : Icons.play_arrow_rounded, size: 14),
                                    label: Text(
                                      isActiveInThread ? "Activo" : "Usar en Chat",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ] else if (_descargandoModelo && _activeThread.iaModel == model.id) ...[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          LinearProgressIndicator(value: _progresoModelo, color: theme.primaryColor),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${(_progresoModelo * 100).toStringAsFixed(0)}%",
                                            style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _descargarModeloLlmNativamente(_activeThread, model: model);
                                    },
                                    icon: const Icon(Icons.cloud_download_rounded, size: 14),
                                    label: Text("Descargar (${model.size})", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL DE ESTADO COGNITIVO Y SPRITES DE KAI ---
  void _mostrarModalKaiStatus(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141721),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E3245), width: 1.2),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "NÚCLEO KAI AI",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: theme.textColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    KaiAvatarView(
                      emotion: _currentKaiEmotion,
                      isThinking: _isGenerating,
                      size: 72,
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    Text(KaiPersona.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textColor)),
                    Text(
                      KaiPersona.roleTitle,
                      style: TextStyle(fontSize: 11, color: _currentKaiEmotion.moodColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),

                    // Emociones
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: KaiEmotion.values.map((emotion) {
                        final isSelected = emotion == _currentKaiEmotion;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _currentKaiEmotion = emotion);
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? emotion.moodColor.withValues(alpha: 0.22)
                                  : const Color(0xFF1B1D27),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? emotion.moodColor : const Color(0xFF282C3D),
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(emotion.fallbackIcon, size: 13, color: emotion.moodColor),
                                const SizedBox(width: 4),
                                Text(
                                  emotion.label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.textColor : theme.subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Sprites locales
                    FutureBuilder<Map<KaiEmotion, bool>>(
                      future: KaiSpriteService.instance.checkSpritesExist(),
                      builder: (context, snapshot) {
                        final spriteMap = snapshot.data ?? {};
                        final allReady = KaiEmotion.values.every((e) => spriteMap[e] == true);
                        final readyCount = KaiEmotion.values.where((e) => spriteMap[e] == true).length;
                        final isGenerating = KaiSpriteService.instance.isGenerating;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1D27),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: allReady ? theme.primaryColor.withValues(alpha: 0.4) : const Color(0xFFFF9500).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("SPRITES LOCALES", style: TextStyle(fontSize: 10, color: theme.subtitleColor, fontWeight: FontWeight.bold)),
                                  Text("$readyCount/5 Listos", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: allReady ? const Color(0xFF2ECC71) : const Color(0xFFFF9500))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isGenerating) ...[
                                LinearProgressIndicator(value: KaiSpriteService.instance.generationProgress, color: theme.primaryColor),
                                const SizedBox(height: 4),
                                Text(KaiSpriteService.instance.generationStatusMessage, style: TextStyle(fontSize: 10, color: theme.primaryColor)),
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: () async {
                                      await KaiSpriteService.instance.generateAllSprites(
                                        onProgress: (p, s, e) {
                                          if (context.mounted) setModalState(() {});
                                        },
                                      );
                                      if (context.mounted) setModalState(() {});
                                    },
                                    icon: const Icon(Icons.palette_rounded, size: 14),
                                    label: Text(allReady ? "Regenerar Sprites HD" : "Generar Sprites (Offline PNG)", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL DE AJUSTES & TELEMETRÍA (REEMPLAZO DE CARDS BULKY DEL SIDEBAR) ---
  void _mostrarModalAjustesTelemetria() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = AppThemeConfig.getTheme(_currentThemeStyle);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141721),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E3245), width: 1.2),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: theme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "AJUSTES & TELEMETRÍA",
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // TELEMETRÍA HARDWARE
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D27),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF282C3D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.developer_board_rounded, color: theme.primaryColor, size: 16),
                              const SizedBox(width: 6),
                              Text("HARDWARE & MEMORIA", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Cores CPU:", style: TextStyle(color: theme.subtitleColor, fontSize: 11)),
                              Text("$_cpuCores Hilos", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("RAM Disponible:", style: TextStyle(color: theme.subtitleColor, fontSize: 11)),
                              Text("${_freeRamGb.toStringAsFixed(1)} GB / ${_totalRamGb.toStringAsFixed(1)} GB", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // APRENDIZAJE IA
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D27),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF282C3D)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Aprendizaje Continuo IA", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text("Memorias aprendidas: ${MemoryService.instance.memories.length}", style: TextStyle(color: theme.subtitleColor, fontSize: 10.5)),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: MemoryService.instance.isLearningEnabled,
                            activeTrackColor: theme.primaryColor,
                            onChanged: (val) async {
                              await MemoryService.instance.setLearningEnabled(val);
                              setDialogState(() {});
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ACTUALIZACIÓN OTA
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E3245)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _ejecutarActualizacionOTA,
                        icon: const Icon(Icons.system_update_rounded, size: 16, color: Color(0xFFFF9500)),
                        label: Text("Buscar Actualización OTA (v$_versionHub #$_currentBuildNumber)", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                    ),
                    if (_descargandoOta) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _progresoOta, color: const Color(0xFFFF9500)),
                      const SizedBox(height: 4),
                      Text("Descargando: ${(_progresoOta * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Color(0xFFFF9500), fontSize: 10)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL TOOLBOX (HERRAMIENTAS / ATTACHMENTS) ---
  void _mostrarModalToolbox(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141721),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2E3245), width: 1.2),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.handyman_rounded, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text("HERRAMIENTAS LOCALES", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 1.0)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 18),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildToolTile(
                      theme: theme,
                      title: "Cámara OCR",
                      subtitle: "Capturar -> IA",
                      icon: Icons.photo_camera_rounded,
                      color: const Color(0xFFFF0055),
                      onTap: () {
                        Navigator.pop(context);
                        _tomarFotoYAnalizarIA(source: ImageSource.camera);
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Galería OCR",
                      subtitle: "Imagen -> IA",
                      icon: Icons.image_rounded,
                      color: const Color(0xFF00B4D8),
                      onTap: () {
                        Navigator.pop(context);
                        _tomarFotoYAnalizarIA(source: ImageSource.gallery);
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Resumidor RAG",
                      subtitle: "Inyectar .txt / .pdf",
                      icon: Icons.description_rounded,
                      color: const Color(0xFF9D4EDD),
                      onTap: () {
                        Navigator.pop(context);
                        _ejecutarResumidorRagLocal();
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Cajón Dev",
                      subtitle: "JSON & Código",
                      icon: Icons.code_rounded,
                      color: const Color(0xFF2ECC71),
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarCajonUtilidadesDev();
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Voz de Kai",
                      subtitle: KaiTtsService.instance.isEnabled ? "Activada" : "Silenciada",
                      icon: KaiTtsService.instance.isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: const Color(0xFF00E5FF),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          KaiTtsService.instance.toggleEnabled();
                        });
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Modo Live",
                      subtitle: "Voz Continua IA",
                      icon: Icons.graphic_eq_rounded,
                      color: const Color(0xFF00E5FF),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => LiveModeScreen(
                              username: widget.username,
                              currentTheme: _currentThemeStyle,
                              initialMode: _currentMode,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildToolTile(
                      theme: theme,
                      title: "Modelos GGUF",
                      subtitle: "Gestionar",
                      icon: Icons.cloud_download_rounded,
                      color: const Color(0xFFFF9500),
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarModalModelos();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolTile({
    required AppThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppleGlassPill(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 16,
      borderColor: color.withValues(alpha: 0.35),
      backgroundColor: const Color(0xFF181A24).withValues(alpha: 0.65),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.30), width: 0.8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
                Text(subtitle, style: TextStyle(color: theme.subtitleColor, fontSize: 9.5), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- OCR Y RAG ISOLATE HELPERS ---
  Future<void> _tomarFotoYAnalizarIA({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final textoDetectado = recognizedText.text.trim();
      if (textoDetectado.isEmpty) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("No se detectó texto legible en la imagen.");
        }
        return;
      }

      _chatController.text = "Analiza el siguiente texto extraído mediante OCR:\n\n$textoDetectado";
      _procesarMensajeLocal();
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error en módulo OCR: $e");
      }
    }
  }

  Future<void> _ejecutarResumidorRagLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'md', 'json'],
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) return;

      final path = result.files.first.path!;
      final extension = path.split('.').last.toLowerCase();
      String contenidoExtraido = "";

      if (extension == 'pdf') {
        final bytes = await File(path).readAsBytes();
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        contenidoExtraido = extractor.extractText();
        document.dispose();
      } else {
        contenidoExtraido = await File(path).readAsString();
      }

      if (contenidoExtraido.trim().isEmpty) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("El archivo seleccionado está vacío.");
        }
        return;
      }

      final fragmento = contenidoExtraido.length > 2000
          ? "${contenidoExtraido.substring(0, 2000)}...\n[Truncado para límite de contexto]"
          : contenidoExtraido;

      _chatController.text = "Documento inyectado vía RAG (${path.split('/').last}):\n\n$fragmento\n\nPor favor analiza y resume este contenido.";
      _procesarMensajeLocal();
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al procesar documento RAG: $e");
      }
    }
  }

  void _mostrarCajonUtilidadesDev() {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    final textEditController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141721),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.code_rounded, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text("Cajón Dev: Formateador", style: TextStyle(color: theme.textColor, fontSize: 14)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textEditController,
                  maxLines: 8,
                  style: TextStyle(color: theme.textColor, fontSize: 11.5, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: "Pega JSON o código aquí...",
                    hintStyle: TextStyle(color: theme.subtitleColor),
                    filled: true,
                    fillColor: const Color(0xFF1B1D27),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                        onPressed: () {
                          try {
                            final obj = jsonDecode(textEditController.text);
                            const encoder = JsonEncoder.withIndent('  ');
                            textEditController.text = encoder.convert(obj);
                          } catch (_) {}
                        },
                        child: const Text("Formatear JSON", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.secondaryColor),
                        onPressed: () {
                          _chatController.text = "Analiza el siguiente código y optimízalo:\n\n```\n${textEditController.text}\n```";
                          Navigator.pop(context);
                          _procesarMensajeLocal();
                        },
                        child: const Text("Enviar a Kai", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalErrorWindowsXP(String mensaje, {String titulo = "Error crítico - Vantablack Hub"}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: WindowsXPErrorDialog(
          titulo: titulo,
          mensaje: mensaje,
        ),
      ),
    );
  }

  // --- ESTRUCTURA PRINCIPAL BUILD ---
  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    final mediaQuery = MediaQuery.of(context);
    final isLandscapeScreen = mediaQuery.orientation == Orientation.landscape;
    final isWideScreen = mediaQuery.size.width >= 640;
    final shouldShowDrawer = !isLandscapeScreen && !isWideScreen;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF08090C),
      drawer: shouldShowDrawer
          ? Drawer(
              backgroundColor: const Color(0xFF141721),
              child: SafeArea(
                child: _buildSidebarContent(theme, isLandscape: false, isDrawer: true),
              ),
            )
          : null,
      body: DynamicMulticolorBackground(
        customAccentColor: _customAccentColor,
        customBgImagePath: _customBgImagePath,
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final useTwoColumns = isLandscape || constraints.maxWidth >= 640;

                    if (useTwoColumns) {
                      const sidebarWidth = 260.0;

                      return Row(
                        children: [
                          // BARRA LATERAL NATIVA TRANSLÚCIDA ESTILO CHATGPT
                          Container(
                            width: sidebarWidth,
                            decoration: const BoxDecoration(
                              color: Color(0xDE141721),
                              border: Border(right: BorderSide(color: Color(0xFF232738), width: 0.8)),
                            ),
                            child: _buildSidebarContent(theme, isLandscape: isLandscape),
                          ),
                          // ÁREA DE CHAT PRINCIPAL
                          Expanded(
                            child: _buildChatArea(
                              theme,
                              isLandscape: isLandscape,
                              showMenuButton: false,
                              constraints: constraints,
                            ),
                          ),
                        ],
                      );
                    }

                    // MODO MÓVIL RETRATO
                    return _buildChatArea(
                      theme,
                      isLandscape: false,
                      showMenuButton: true,
                      constraints: constraints,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- BARRA LATERAL MINIMALISTA ESTILO CHATGPT ---
  Widget _buildSidebarContent(AppThemeData theme, {required bool isLandscape, bool isDrawer = false}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Título superior
          Row(
            children: [
              KaiAvatarView(
                emotion: _currentKaiEmotion,
                size: 26,
                theme: theme,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "KAI ASSISTANT",
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isDrawer)
                AppleGlassIconButton(
                  icon: CupertinoIcons.xmark,
                  size: 28,
                  iconSize: 13,
                  borderRadius: 10,
                  tooltip: "Cerrar",
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón + Nuevo Chat con cápsula Apple Glass
          AppleGlassCapsuleButton(
            icon: CupertinoIcons.add,
            label: "Nuevo Chat",
            primaryColor: theme.primaryColor,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              _crearNuevaInstanciaLocal(_activeThread.iaModel);
            },
          ),
          const SizedBox(height: 10),

          // Botón de Gestión de Modelos GGUF con píldora de vidrio
          AppleGlassPill(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              _mostrarModalModelos();
            },
            child: Row(
              children: [
                Icon(Icons.cloud_download_rounded, color: theme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Modelos GGUF",
                    style: TextStyle(color: theme.textColor, fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Text(
                    "${_modelosDisponibles.where((m) => m.isDownloaded).length}/3",
                    style: TextStyle(color: theme.primaryColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header de sección de chats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "CHATS RECIENTES",
              style: TextStyle(
                fontSize: 9.5,
                color: theme.subtitleColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Lista de threads limpios estilo Apple Glass
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _threads.length,
            itemBuilder: (context, index) {
              final thread = _threads[index];
              final isSelected = thread.id == _activeThreadId;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: AppleGlassPill(
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  backgroundColor: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.16)
                      : const Color(0xFF161822).withValues(alpha: 0.40),
                  borderColor: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.08),
                  onTap: () {
                    setState(() => _activeThreadId = thread.id);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble_2,
                        size: 14,
                        color: isSelected ? theme.primaryColor : theme.subtitleColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? theme.textColor : theme.subtitleColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_threads.length > 1)
                        AppleGlassIconButton(
                          icon: CupertinoIcons.trash,
                          size: 22,
                          iconSize: 12,
                          borderRadius: 8,
                          isDestructive: true,
                          tooltip: "Borrar chat",
                          onTap: () => _borrarThread(thread.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Footer: Ajustes & Telemetría y perfil de usuario
          const Divider(height: 1, color: Color(0xFF26293B)),
          const SizedBox(height: 10),

          AppleGlassPill(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              _mostrarModalAjustesTelemetria();
            },
            child: Row(
              children: [
                Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Ajustes & Telemetría",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.textColor, fontSize: 11.5),
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 14, color: theme.subtitleColor),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Perfil de usuario compacto
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                child: Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "U", style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HEADER SUPERIOR TRANSPARENTE MINIMALISTA APPLE GLASS ---
  Widget _buildHeader(AppThemeData theme, {required bool isLandscape, required bool showMenuButton}) {
    final activeModelName = _getNomModel(_activeThread.iaModel);

    return LayoutBuilder(
      builder: (context, headerConstraints) {
        final isCompact = headerConstraints.maxWidth < 440;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 12 : 10,
            vertical: isLandscape ? 4 : 5,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              if (showMenuButton) ...[
                Builder(
                  builder: (scaffoldContext) => AppleGlassIconButton(
                    icon: Icons.menu_rounded,
                    size: 32,
                    iconSize: 17,
                    borderRadius: 10,
                    tooltip: "Menú lateral",
                    onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // Chip Selector de Modelo Central con Dropdown Apple Glass
              Flexible(
                child: AppleGlassPill(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onTap: _mostrarModalModelos,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.memory_rounded, size: 13, color: theme.primaryColor),
                      const SizedBox(width: 4),
                      if (_isEngineInitializing) ...[
                        SizedBox(
                          width: 9,
                          height: 9,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          activeModelName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_down, size: 10, color: theme.subtitleColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Switch de Modos Apple Glass (Segmented Control completo en amplio, botón táctil en compacto)
              if (!isCompact)
                AppleGlassSegmentedControl<CoreMode>(
                  selectedValue: _currentMode,
                  height: 30,
                  activeColor: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                  onValueChanged: (mode) => setState(() => _currentMode = mode),
                  children: const {
                    CoreMode.normal: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 12),
                        SizedBox(width: 3),
                        Text("Normal"),
                      ],
                    ),
                    CoreMode.estudiante: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 12),
                        SizedBox(width: 3),
                        Text("Estudiante"),
                      ],
                    ),
                  },
                )
              else
                AppleGlassIconButton(
                  icon: _currentMode == CoreMode.estudiante ? Icons.school_rounded : Icons.bolt_rounded,
                  size: 32,
                  iconSize: 15,
                  borderRadius: 10,
                  isActive: true,
                  activeGlowColor: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                  iconColor: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                  tooltip: _currentMode == CoreMode.estudiante ? "Modo Estudiante" : "Modo Normal",
                  onTap: () {
                    setState(() {
                      _currentMode = _currentMode == CoreMode.normal ? CoreMode.estudiante : CoreMode.normal;
                    });
                  },
                ),
              const SizedBox(width: 4),

              // Botón Modo Live (Voz Continua) Apple Glass
              AppleGlassIconButton(
                icon: Icons.graphic_eq_rounded,
                size: 32,
                iconSize: 16,
                borderRadius: 10,
                isActive: true,
                activeGlowColor: const Color(0xFF00E5FF),
                tooltip: "Modo Live (Voz Continua)",
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => LiveModeScreen(
                        username: widget.username,
                        currentTheme: _currentThemeStyle,
                        initialMode: _currentMode,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),

              // Botón TTS Apple Glass
              AppleGlassIconButton(
                icon: KaiTtsService.instance.isEnabled ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill,
                size: 32,
                iconSize: 15,
                borderRadius: 10,
                isActive: KaiTtsService.instance.isEnabled,
                activeGlowColor: const Color(0xFF00E5FF),
                tooltip: "Voz de Kai",
                onTap: () {
                  setState(() {
                    KaiTtsService.instance.toggleEnabled();
                  });
                },
              ),
              const SizedBox(width: 4),

              // Selector de temas Apple Glass
              AppleGlassIconButton(
                icon: CupertinoIcons.paintbrush,
                size: 32,
                iconSize: 15,
                borderRadius: 10,
                tooltip: "Tema visual",
                onTap: () {
                  mostrarSelectorTemasModal(
                    context,
                    _currentThemeStyle,
                    (newTheme) {
                      setState(() => _currentThemeStyle = newTheme);
                      widget.onThemeChanged(newTheme);
                    },
                  );
                },
              ),
              const SizedBox(width: 4),

              // Avatar de Kai
              GestureDetector(
                onTap: () => _mostrarModalKaiStatus(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _currentKaiEmotion.moodColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: KaiAvatarView(
                    emotion: _currentKaiEmotion,
                    isThinking: _isGenerating,
                    size: 26,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ÁREA DE CHAT & HERO ESTILO CHATGPT ---
  Widget _buildChatArea(
    AppThemeData theme, {
    required bool isLandscape,
    required bool showMenuButton,
    required BoxConstraints constraints,
  }) {
    final userMessages = _activeThread.messages.where((m) => m["sender"] == "user" || m["sender"] == "assistant").toList();
    final isEmptyChat = userMessages.isEmpty;

    return Column(
      children: [
        _buildHeader(theme, isLandscape: isLandscape, showMenuButton: showMenuButton),

        Expanded(
          child: isEmptyChat
              ? _buildEmptyChatHero(theme, isLandscape)
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isLandscape ? 20 : 16, vertical: 12),
                  itemCount: _activeThread.messages.length,
                  itemBuilder: (context, index) {
                    final msg = _activeThread.messages[index];
                    if (msg["sender"] == "system") return const SizedBox.shrink();
                    final isLast = index == _activeThread.messages.length - 1;
                    return _buildChatMessageBubble(msg, theme, constraints, isLandscape, isLast: isLast);
                  },
                ),
        ),

        _buildFloatingInputBar(theme, isLandscape),
      ],
    );
  }

  // --- HERO DE BIENVENIDA CUANDO EL CHAT ESTÁ VACÍO ---
  Widget _buildEmptyChatHero(AppThemeData theme, bool isLandscape) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KaiAvatarView(
              emotion: _currentKaiEmotion,
              size: isLandscape ? 60 : 72,
              isThinking: _isGenerating,
              theme: theme,
            ),
            const SizedBox(height: 12),
            Text(
              "¿En qué puedo ayudarte hoy, ${widget.username}?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isLandscape ? 17 : 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Asistente técnico local • Inferencia 100% en dispositivo",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: theme.subtitleColor),
            ),
            if (_isEngineInitializing) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Iniciando motor...",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.primaryColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Tarjetas de sugerencia Apple Glass
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionPill("⚡ Crear un script en Flutter", theme),
                _buildSuggestionPill("🧠 Explicar arquitectura MVVM", theme),
                _buildSuggestionPill("🔍 Optimizar memoria RAM", theme),
                _buildSuggestionPill("🛠️ Depurar código Dart", theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionPill(String text, AppThemeData theme) {
    return AppleGlassPill(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      onTap: _isGenerating ? null : () => _procesarMensajeLocal(text.substring(2).trim()),
      child: Text(text, style: TextStyle(color: theme.textColor, fontSize: 11.5, fontWeight: FontWeight.w500)),
    );
  }

  // --- BURBUJAS DE MENSAJES ESTILO CHATGPT ---
  Widget _buildChatMessageBubble(
    Map<String, dynamic> msg,
    AppThemeData theme,
    BoxConstraints constraints,
    bool isLandscape, {
    bool isLast = false,
  }) {
    final sender = msg["sender"];
    final rawText = msg["text"] ?? '';
    final cleanText = KaiPersona.cleanEmotionTags(rawText);

    if (sender == "user") {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * (isLandscape ? 0.65 : 0.82)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2B32),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: SelectableText(
            cleanText,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
          ),
        ),
      );
    }

    // Mensaje de Kai (Asistente)
    // 1. OPTIMIZACIÓN DE RENDERIZADO:
    // Si la IA está generando y este es el último mensaje en streaming,
    // se suscribe al ValueNotifier de modo que SOLO esta burbuja se reconstruya por token.
    final bool isStreamingActive = _isGenerating && isLast;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaiAvatarView(
            emotion: _currentKaiEmotion,
            size: 26,
            theme: theme,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isStreamingActive
                ? ValueListenableBuilder<String>(
                    valueListenable: _currentStreamingMessage,
                    builder: (context, streamingVal, _) {
                      final displayText = streamingVal.isNotEmpty ? streamingVal : (cleanText.isNotEmpty ? cleanText : "...");
                      final cleanStreaming = KaiPersona.cleanEmotionTags(displayText);
                      return _buildFormattedAssistantContent(cleanStreaming, theme);
                    },
                  )
                : _buildFormattedAssistantContent(cleanText, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAssistantContent(String text, AppThemeData theme) {
    // Si contiene bloques de código ```dart ... ```
    if (text.contains('```')) {
      final parts = text.split('```');
      final List<Widget> children = [];

      for (int i = 0; i < parts.length; i++) {
        if (i % 2 == 0) {
          // Texto normal
          if (parts[i].trim().isNotEmpty) {
            children.add(
              SelectableText(
                parts[i].trim(),
                style: TextStyle(color: theme.textColor, fontSize: 13.5, height: 1.45),
              ),
            );
          }
        } else {
          // Bloque de código
          final codeBlock = parts[i];
          final lines = codeBlock.split('\n');
          final lang = lines.isNotEmpty && lines.first.trim().isNotEmpty ? lines.first.trim() : "code";
          final codeContent = lines.length > 1 ? lines.sublist(1).join('\n') : codeBlock;

          children.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF13151F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF282C3F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1C28),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.toUpperCase(), style: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: codeContent));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Código copiado al portapapeles"), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 12, color: theme.subtitleColor),
                              const SizedBox(width: 4),
                              Text("Copiar", style: TextStyle(color: theme.subtitleColor, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      codeContent.trim(),
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }

    return SelectableText(
      text,
      style: TextStyle(color: theme.textColor, fontSize: 13.5, height: 1.45),
    );
  }

  // --- BARRA INFERIOR DE ENTRADA ESTILO APPLE GLASS ---
  Widget _buildFloatingInputBar(AppThemeData theme, bool isLandscape) {
    final hasText = _chatController.text.trim().isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLandscape ? 18 : 14,
        vertical: isLandscape ? 6 : 10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C27).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botón + Apple Glass
              AppleGlassIconButton(
                icon: CupertinoIcons.plus,
                size: 36,
                iconSize: 18,
                borderRadius: 18,
                iconColor: theme.primaryColor,
                tooltip: "Herramientas y OCR",
                onTap: _isGenerating ? null : () => _mostrarModalToolbox(context),
              ),

              const SizedBox(width: 4),

              // Campo de texto expandible (deshabilitado cuando _isGenerating == true)
              Expanded(
                child: TextField(
                  controller: _chatController,
                  enabled: !_isGenerating,
                  minLines: 1,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: _isGenerating ? theme.subtitleColor : theme.textColor,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: (_activeThread.pensando || _isGenerating) ? "Kai está procesando..." : "Pregunta a Kai...",
                    hintStyle: TextStyle(color: theme.subtitleColor, fontSize: 13.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                  onSubmitted: (_) => _isGenerating ? null : _procesarMensajeLocal(),
                ),
              ),

              const SizedBox(width: 4),

              // Botón Micrófono Apple Glass con onda/glow activo
              AppleGlassIconButton(
                icon: _isListening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                size: 36,
                iconSize: 18,
                borderRadius: 18,
                isActive: _isListening,
                isPulsing: _isListening,
                activeGlowColor: const Color(0xFFFF3B30),
                iconColor: _isListening ? const Color(0xFFFF3B30) : theme.subtitleColor,
                tooltip: _isListening ? "Escuchando..." : "Dictado por voz",
                onTap: _isGenerating ? null : _toggleListening,
              ),

              const SizedBox(width: 4),

              // Botón Enviar Apple Glass con aura cian (deshabilitado / onPressed: null mientras genera)
              AppleGlassIconButton(
                icon: _isGenerating ? CupertinoIcons.stop_fill : CupertinoIcons.arrow_up,
                size: 36,
                iconSize: 18,
                borderRadius: 18,
                isActive: !_isGenerating && hasText,
                activeGlowColor: const Color(0xFF00E5FF),
                isDestructive: false,
                isPulsing: false,
                backgroundColor: !_isGenerating && hasText
                    ? theme.primaryColor.withValues(alpha: 0.95)
                    : const Color(0xFF282C3D).withValues(alpha: 0.60),
                iconColor: !_isGenerating && hasText
                    ? Colors.black
                    : const Color(0xFF94A3B8),
                tooltip: _isGenerating ? "Generando respuesta..." : "Enviar mensaje",
                onTap: (_isGenerating || !hasText) ? null : () => _procesarMensajeLocal(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
