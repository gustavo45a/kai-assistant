import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../models/app_theme.dart';
import '../../models/local_model.dart';
import '../../models/chat_thread.dart';
import '../../services/hardware_scanner.dart';
import '../../services/local_llm_service.dart';
import '../../services/zram_memory_manager.dart';
import '../../services/memory_service.dart';
import '../../services/app_settings.dart';
import '../widgets/windows_xp_error_dialog.dart';
import '../widgets/theme_selector_modal.dart';
import '../widgets/dynamic_multicolor_background.dart';

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
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  Color? _customAccentColor;
  String? _customBgImagePath;

  bool _isGenerating = false;
  bool _descargandoOta = false;
  bool _descargandoModelo = false;
  double _progresoOta = 0.0;
  double _progresoModelo = 0.0;

  double _freeRamGb = 4.0;
  double _totalRamGb = 8.0;
  int _cpuCores = 4;

  bool isZRamEnabled = true;
  final bool _ttsEnabled = false;
  bool isWebServidorActive = false;
  bool isModoPro = false;
  bool isVirtualAssistantActive = false;

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _initTts();
    scheduleMicrotask(() async {
      await MemoryService.instance.init();
      final colorVal = await AppSettings.getCustomAccentColor();
      final bgPath = await AppSettings.getCustomBgImagePath();
      final diagnostic = await HardwareScanner.scan();
      if (mounted) {
        setState(() {
          _customAccentColor = colorVal != null ? Color(colorVal) : null;
          _customBgImagePath = bgPath;
          _cpuCores = diagnostic['cores'];
          _freeRamGb = diagnostic['freeRamGb'];
          _totalRamGb = diagnostic['totalRamGb'];
        });
      }
      await _verificarModelosDescargados();
      await _cargarDatosDesdeDisco();
      await _checkUpdates();
    });
  }

  Future<void> _initTts() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _flutterTts.setEngine("com.google.android.tts");
      }
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("Error TTS: $e");
    }
  }

  Future<void> _speakText(String text) async {
    if (!_ttsEnabled || text.isEmpty) return;
    try {
      final cleanText = text
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'[\*\_~`]'), '')
          .trim();
      if (cleanText.isNotEmpty) {
        await _flutterTts.speak(cleanText);
      }
    } catch (_) {}
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
      _speechInitialized = await _speechToText.initialize();
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
            _chatController.selection = TextSelection.fromPosition(
              TextPosition(offset: _chatController.text.length),
            );
          });
        },
        listenOptions: stt.SpeechListenOptions(localeId: "es_ES"),
      );
    }
  }

  Future<void> _checkUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get("https://gustavo45a.github.io/kai-assistant/version.json");
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        final latestVersion = data["version"] ?? _versionHub;
        final latestBuild = data["buildNumber"] is int ? data["buildNumber"] : int.tryParse(data["buildNumber"].toString()) ?? 40;
        final remoteUrl = data["url"] ?? _urlApkRemoto;

        if ((latestBuild > _currentBuildNumber || latestVersion != _versionHub) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00B4D8),
              content: Text("⚡ Nueva actualización Vantablack Hub (Build #$latestBuild) disponible!"),
              action: SnackBarAction(
                label: "ACTUALIZAR",
                textColor: Colors.black,
                onPressed: () => _ejecutarActualizacionOTA(urlDownload: remoteUrl),
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _ejecutarActualizacionOTA({String? urlDownload}) async {
    if (_descargandoOta) return;
    setState(() {
      _descargandoOta = true;
      _progresoOta = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/vantablack_update.apk";
      final dio = Dio();

      await dio.download(
        urlDownload ?? _urlApkRemoto,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoOta = received / total;
            });
          }
        },
      );

      setState(() => _descargandoOta = false);
      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("APK guardado en: $savePath")),
        );
      }
    } catch (e) {
      setState(() => _descargandoOta = false);
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al descargar la actualización OTA: $e");
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

  Future<void> _descargarModeloLlmNativamente(ChatThread thread) async {
    final model = _modelosDisponibles.firstWhere(
      (m) => m.id == thread.iaModel,
      orElse: () => _modelosDisponibles.first,
    );

    setState(() {
      _descargandoModelo = true;
      _progresoModelo = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/${model.id}.gguf";
      final dio = Dio();

      await dio.download(
        model.urlGguf,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progresoModelo = received / total;
            });
          }
        },
      );

      model.isDownloaded = true;
      thread.rutaModeloLocal = filePath;

      await LocalLLMService.instance.initializeRealModel(filePath, threads: _cpuCores > 2 ? 2 : 1);
      thread.modeloInicializado = true;

      setState(() {
        _descargandoModelo = false;
      });

      await _guardarDatosEnDisco();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Modelo ${model.name} inicializado nativamente!")),
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
      title: "Matriz ${modelId.toUpperCase().replaceAll('_', ' ')}",
      iaModel: modelId,
      messages: [
        {"sender": "system", "text": "INSTANCIA KAI V3 INICIALIZADA."},
      ],
    );
    setState(() {
      _threads.add(newThread);
      _activeThreadId = newId;
    });
    _guardarDatosEnDisco();
  }

  ChatThread get _activeThread {
    return _threads.firstWhere(
      (t) => t.id == _activeThreadId,
      orElse: () => _threads.isNotEmpty ? _threads.first : ChatThread(id: '0', title: 'Default', iaModel: 'llama_3_2_1b', messages: []),
    );
  }

  Future<void> _procesarMensajeLocal() async {
    final threadActual = _activeThread;
    if (_chatController.text.trim().isEmpty || threadActual.pensando || _isGenerating) return;

    final textoUsuario = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _isGenerating = true;
      threadActual.messages.add({"sender": "user", "text": textoUsuario});
      threadActual.messages.add({"sender": "assistant", "text": "..."});
      threadActual.pensando = true;
    });

    _scrollToBottom();

    // Extraer memoria aprendida si el aprendizaje continuo está activo
    MemoryService.instance.extractMemoryFromInteraction(textoUsuario);

    try {
      if (!LocalLLMService.instance.isModelLoaded && threadActual.rutaModeloLocal != null) {
        await LocalLLMService.instance.initializeRealModel(threadActual.rutaModeloLocal!, threads: 2);
        threadActual.modeloInicializado = true;
      }

      if (LocalLLMService.instance.isModelLoaded) {
        final stream = LocalLLMService.instance.generateResponseStream(
          textoUsuario,
          {
            'modoEstudiante': _currentMode == CoreMode.estudiante,
            'memoriaAprendida': MemoryService.instance.isLearningEnabled
                ? MemoryService.instance.memories
                : <String>[],
          },
          history: threadActual.messages,
        );

        final responseBuffer = StringBuffer();
        await for (final chunk in stream) {
          responseBuffer.write(chunk);
          if (mounted) {
            setState(() {
              threadActual.messages.last = {"sender": "assistant", "text": responseBuffer.toString()};
            });
            _scrollToBottom();
          }
        }
        await _speakText(responseBuffer.toString());
      } else {
        await Future.delayed(const Duration(seconds: 1));
        final fallbackMsg = "El modelo ${threadActual.iaModel} requiere ser descargado a almacenamiento local primero.";
        setState(() {
          threadActual.messages.last = {"sender": "assistant", "text": fallbackMsg};
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          threadActual.messages.last = {"sender": "assistant", "text": "[EXCEPCIÓN LOCAL]: $e"};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          threadActual.pensando = false;
        });
      } else {
        _isGenerating = false;
        threadActual.pensando = false;
      }
      await _guardarDatosEnDisco();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- PANEL DE HERRAMIENTAS LOCALES (TOOLBOX) ---
  void _mostrarModalToolbox(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: theme.shadows,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handyman_rounded, color: theme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    "PANEL DE HERRAMIENTAS LOCALES (TOOLBOX)",
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.subtitleColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _buildToolTile(
                    theme: theme,
                    title: "Tomar Foto Cámara",
                    subtitle: "Cámara -> Análisis IA",
                    icon: Icons.photo_camera_rounded,
                    color: const Color(0xFFFF0055),
                    onTap: () {
                      Navigator.pop(context);
                      _tomarFotoYAnalizarIA(source: ImageSource.camera);
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Captura y Análisis",
                    subtitle: "Screenshot -> Modelo IA",
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF00B4D8),
                    onTap: () {
                      Navigator.pop(context);
                      _ejecutarCapturaPantallaAnalisis();
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Resumidor RAG Local",
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
                    title: "Cajón Utilidades Dev",
                    subtitle: "Formatear JSON / Code",
                    icon: Icons.code_rounded,
                    color: const Color(0xFF2ECC71),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarCajonUtilidadesDev();
                    },
                  ),
                  _buildToolTile(
                    theme: theme,
                    title: "Optimizador Memoria",
                    subtitle: "Limpiar Caché y RAM",
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFF9500),
                    onTap: () {
                      Navigator.pop(context);
                      _ejecutarOptimizadorMemoria();
                    },
                  ),
                ],
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.subtitleColor,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TOOL 1: Captura de pantalla y análisis
  Future<void> _ejecutarCapturaPantallaAnalisis() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          _mostrarModalErrorWindowsXP("No se pudo obtener el renderizado de la pantalla actual.");
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null && mounted) {
        final promptController = TextEditingController(
          text: "Analiza la captura de pantalla de esta interfaz e identifica los elementos visuales clave.",
        );

        showDialog(
          context: context,
          builder: (context) {
            final theme = AppThemeConfig.getTheme(_currentThemeStyle);
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Captura de Pantalla", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(bytes, height: 180, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: promptController,
                      maxLines: 3,
                      style: TextStyle(color: theme.textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Instrucción de análisis IA",
                        labelStyle: TextStyle(color: theme.subtitleColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar", style: TextStyle(color: theme.subtitleColor)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                    final prompt = promptController.text.trim();
                    _chatController.text = "[CAPTURA DE PANTALLA ADJUNTA - VANTABLACK V3]\n$prompt";
                    _procesarMensajeLocal();
                  },
                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                  label: const Text("Enviar a la IA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al capturar pantalla: $e");
      }
    }
  }

  // TOOL 1.5: Tomar foto con cámara y análisis con IA
  Future<void> _tomarFotoYAnalizarIA({required ImageSource source}) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            _mostrarModalErrorWindowsXP(
              "Se requiere permiso de cámara para tomar fotos.",
              titulo: "Permiso Denegado - Vantablack Hub",
            );
          }
          return;
        }
      }

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      final promptController = TextEditingController(
        text: "Analiza esta fotografía e identifica los elementos visuales principales, detalles u objetos.",
      );

      showDialog(
        context: context,
        builder: (context) {
          final theme = AppThemeConfig.getTheme(_currentThemeStyle);
          return AlertDialog(
            backgroundColor: theme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
            title: Row(
              children: [
                Icon(Icons.photo_camera_rounded, color: _getModeAccentColor(theme)),
                const SizedBox(width: 8),
                Text(
                  source == ImageSource.camera ? "Foto Tomada con Cámara" : "Foto de Galería",
                  style: TextStyle(color: theme.textColor, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(bytes, height: 200, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: promptController,
                    maxLines: 3,
                    style: TextStyle(color: theme.textColor, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Instrucción de Análisis para la IA",
                      labelStyle: TextStyle(color: theme.subtitleColor),
                      filled: true,
                      fillColor: theme.backgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancelar", style: TextStyle(color: theme.subtitleColor)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _getModeAccentColor(theme)),
                onPressed: () {
                  Navigator.pop(context);
                  final prompt = promptController.text.trim();
                  _chatController.text = "[FOTOGRAFÍA CAPTURADA - VANTABLACK VISION]\n"
                      "Archivo: ${pickedFile.name} | Tamaño: ${bytes.length} bytes\n\n"
                      "Instrucción: $prompt";
                  _procesarMensajeLocal();
                },
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                label: const Text("Analizar con la IA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al procesar foto: $e");
      }
    }
  }

  // TOOL 2: Resumidor RAG Local
  Future<void> _ejecutarResumidorRagLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'md', 'json', 'log', 'csv', 'dart', 'py'],
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        String rawBytesString = '';

        if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          final ext = pickedFile.extension?.toLowerCase() ?? '';
          final bytes = await file.readAsBytes();
          if (ext == 'pdf') {
            rawBytesString = _parsePdfBytes(bytes);
          } else {
            rawBytesString = utf8.decode(bytes, allowMalformed: true);
          }
        } else if (pickedFile.bytes != null) {
          final ext = pickedFile.extension?.toLowerCase() ?? '';
          if (ext == 'pdf') {
            rawBytesString = _parsePdfBytes(pickedFile.bytes!);
          } else {
            rawBytesString = utf8.decode(pickedFile.bytes!, allowMalformed: true);
          }
        }

        // Filtrado estricto de texto: elimina caracteres corruptos o no imprimibles
        String cleanText = rawBytesString.replaceAll(RegExp(r'[^\x20-\x7E\n\áéíóúÁÉÍÓÚñÑüÜ]'), '');

        // Rechazo limpio antes de invocar el motor C++ si el archivo no contiene texto legible
        if (cleanText.trim().isEmpty) {
          if (mounted) {
            _mostrarModalErrorWindowsXP("El documento '${pickedFile.name}' no contiene texto legible o es un archivo binario no compatible.");
          }
          return;
        }

        if (cleanText.length > 3000) {
          cleanText = "${cleanText.substring(0, 3000)}\n...[CONTENIDO TRUNCADO POR TAMAÑO DE CONTEXTO]";
        }

        _chatController.text = "[DOCUMENTO RAG LOCAL: ${pickedFile.name}]\n"
            "Formato: .${pickedFile.extension} | Tamaño: ${pickedFile.size} bytes\n\n"
            "--- CONTENIDO EXTRAÍDO ---\n"
            "$cleanText\n"
            "--- FIN CONTENIDO ---\n\n"
            "Genera un resumen estructurado con puntos clave de este documento.";

        _procesarMensajeLocal();
      }
    } catch (e) {
      if (mounted) {
        _mostrarModalErrorWindowsXP("Error al leer archivo RAG: $e");
      }
    }
  }

  String _parsePdfBytes(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();
      final cleaned = extractedText.replaceAll(RegExp(r'[^\x20-\x7E\n\áéíóúÁÉÍÓÚñÑüÜ]'), '').trim();
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    } catch (e) {
      debugPrint("Error al extraer texto de PDF: $e");
    }
    return "";
  }

  void _mostrarModalErrorWindowsXP(String mensaje, {String titulo = "Error crítico - Vantablack Hub"}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: WindowsXPErrorDialog(mensaje: mensaje, titulo: titulo),
        );
      },
    );
  }

  // TOOL 3: Cajón de Utilidades Dev
  void _mostrarCajonUtilidadesDev() {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    final codeController = TextEditingController();
    String validationResult = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.code_rounded, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Cajón de Utilidades Dev", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      maxLines: 7,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Pega aquí tu fragmento de Código o JSON sin formatear...",
                        hintStyle: TextStyle(color: theme.subtitleColor),
                        filled: true,
                        fillColor: theme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8)),
                          onPressed: () {
                            try {
                              final obj = jsonDecode(codeController.text);
                              final pretty = const JsonEncoder.withIndent('  ').convert(obj);
                              setDialogState(() {
                                codeController.text = pretty;
                                validationResult = "✅ JSON Válido y Formateado Correctamente";
                              });
                            } catch (e) {
                              setDialogState(() {
                                validationResult = "❌ Error de Sintaxis JSON: $e";
                              });
                            }
                          },
                          icon: const Icon(Icons.data_object_rounded, size: 14, color: Colors.black),
                          label: const Text("Formatear JSON", style: TextStyle(color: Colors.black, fontSize: 11)),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
                          onPressed: () {
                            final code = codeController.text;
                            int openBraces = 0, openParens = 0, openBrackets = 0;
                            for (var rune in code.runes) {
                              final char = String.fromCharCode(rune);
                              if (char == '{') openBraces++;
                              if (char == '}') openBraces--;
                              if (char == '(') openParens++;
                              if (char == ')') openParens--;
                              if (char == '[') openBrackets++;
                              if (char == ']') openBrackets--;
                            }
                            if (openBraces == 0 && openParens == 0 && openBrackets == 0) {
                              setDialogState(() {
                                validationResult = "✅ Símbolos balanceados ({}, (), []). Sintaxis correcta.";
                              });
                            } else {
                              setDialogState(() {
                                validationResult = "⚠️ Desbalance: Braces: $openBraces, Parens: $openParens, Brackets: $openBrackets";
                              });
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
                          label: const Text("Validar Sintaxis", style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                    if (validationResult.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationResult,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: validationResult.startsWith("✅") ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cerrar", style: TextStyle(color: theme.subtitleColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context);
                    if (codeController.text.isNotEmpty) {
                      _chatController.text = "```\n${codeController.text}\n```\nRevisa este fragmento de código.";
                    }
                  },
                  child: const Text("Inyectar en Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // TOOL 4: Optimizador de Memoria
  Future<void> _ejecutarOptimizadorMemoria() async {
    final result = await ZRamMemoryManager.optimizeMemory(true);
    final freedMb = (result['freedMb'] as double).toStringAsFixed(2);
    final hardware = await HardwareScanner.scan();
    final freeRam = (hardware['freeRamGb'] as double).toStringAsFixed(2);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          final theme = AppThemeConfig.getTheme(_currentThemeStyle);
          return AlertDialog(
            backgroundColor: theme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
            title: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFF9500)),
                const SizedBox(width: 8),
                Text("Optimizador Galaxy Tab RAM", style: TextStyle(color: theme.textColor, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("¡Optimización de memoria ejecutada con éxito!"),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Caché Eliminada:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$freedMb MB", style: const TextStyle(fontSize: 12, color: Color(0xFFFF9500), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("RAM Libre en Galaxy Tab:", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text("$freeRam GB", style: const TextStyle(fontSize: 12, color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9500)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }
  Color _getModeAccentColor(AppThemeData theme) {
    if (_customAccentColor != null) return _customAccentColor!;
    return _currentMode == CoreMode.estudiante
        ? const Color(0xFF9D4EDD)
        : theme.primaryColor;
  }

  IconData _getModeSendIcon() {
    return _currentMode == CoreMode.estudiante
        ? Icons.school_rounded
        : Icons.arrow_upward_rounded;
  }

  void _mostrarModalPersonalizarFondoColores() {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);
    final List<Color> sampleColors = [
      const Color(0xFF00B4D8), // Cían Cyber
      const Color(0xFF9D4EDD), // Púrpura Neón
      const Color(0xFF2ECC71), // Verde Esmeralda
      const Color(0xFFFF9500), // Ámbar Dorado
      const Color(0xFFFF0055), // Rojo Carmesí
      const Color(0xFFFF007F), // Rosa Y2K
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.wallpaper_rounded, color: _getModeAccentColor(theme)),
                  const SizedBox(width: 8),
                  Text("Personalizar Fondo y Colores", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("1. Color de Acento Personalizado", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ...sampleColors.map((color) {
                          final isSelected = _customAccentColor?.toARGB32() == color.toARGB32();
                          return InkWell(
                            onTap: () async {
                              await AppSettings.saveCustomAccentColor(color.toARGB32());
                              setDialogState(() {
                                _customAccentColor = color;
                              });
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 10)]
                                    : [],
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                            ),
                          );
                        }),
                        InkWell(
                          onTap: () async {
                            await AppSettings.saveCustomAccentColor(null);
                            setDialogState(() {
                              _customAccentColor = null;
                            });
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text("2. Imagen de Fondo Personalizada", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    if (_customBgImagePath != null && _customBgImagePath!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.image_rounded, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _customBgImagePath!.split('/').last,
                              style: TextStyle(color: theme.subtitleColor, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () async {
                              await AppSettings.saveCustomBgImagePath(null);
                              setDialogState(() {
                                _customBgImagePath = null;
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        foregroundColor: theme.textColor,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: theme.borderColor),
                        ),
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                          final path = result.files.first.path!;
                          await AppSettings.saveCustomBgImagePath(path);
                          setDialogState(() {
                            _customBgImagePath = path;
                          });
                          setState(() {});
                        }
                      },
                      icon: Icon(Icons.upload_file_rounded, size: 18, color: _getModeAccentColor(theme)),
                      label: const Text("Cargar Imagen de Fondo (.png/.jpg)", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _getModeAccentColor(theme)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- COMPONENTES VISUALES Y HEADER ---
  @override
  Widget build(BuildContext context) {
    final theme = AppThemeConfig.getTheme(_currentThemeStyle);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: DynamicMulticolorBackground(
        customAccentColor: _customAccentColor,
        customBgImagePath: _customBgImagePath,
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            decoration: BoxDecoration(gradient: theme.backgroundGradient),
          child: Row(
            children: [
              // BARRA LATERAL NATIVA
              Container(
                width: 270,
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  border: Border(right: BorderSide(color: theme.borderColor, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),
                    
                    Center(
                      child: GestureDetector(
                        onTap: _ejecutarActualizacionOTA,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 130, height: 130, 
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            boxShadow: theme.shadows,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.cardColor,
                                  child: Icon(
                                    Icons.shield_rounded,
                                    color: theme.primaryColor,
                                    size: 36,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),

                    _buildHardwareTelemetryCard(theme),
                    
                    _buildContinuousLearningCard(theme),
                    
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLiquidGlassButton(
                            theme: theme,
                            title: "Modo Normal",
                            icon: Icons.bolt_rounded,
                            isSelected: _currentMode == CoreMode.normal,
                            activeColor: theme.primaryColor,
                            onTap: () => setState(() => _currentMode = CoreMode.normal),
                          ),
                          _buildLiquidGlassButton(
                            theme: theme,
                            title: "Estudiante",
                            icon: Icons.menu_book_rounded,
                            isSelected: _currentMode == CoreMode.estudiante,
                            activeColor: theme.secondaryColor,
                            onTap: () => setState(() => _currentMode = CoreMode.estudiante),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textColor,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            side: BorderSide(color: theme.borderColor),
                          ),
                        ),
                        onPressed: _mostrarSelectorNuevoChat,
                        icon: Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
                        label: const Text("Nueva Instancia", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("MATRICES LOCALES ACTIVAS", style: TextStyle(fontSize: 9, color: theme.subtitleColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _threads.length,
                        itemBuilder: (context, index) {
                          final thread = _threads[index];
                          final isSelected = thread.id == _activeThreadId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              selected: isSelected,
                              selectedTileColor: theme.cardColor,
                              leading: Icon(Icons.code_rounded, size: 16, color: isSelected ? theme.primaryColor : theme.subtitleColor),
                              title: Text(
                                thread.title,
                                style: TextStyle(color: isSelected ? theme.textColor : theme.subtitleColor, fontSize: 12.5),
                              ),
                              onTap: () {
                                setState(() {
                                  _activeThreadId = thread.id;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    if (_descargandoOta)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Descargando actualización...", style: TextStyle(fontSize: 9, color: Colors.amber)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: _progresoOta, color: const Color(0xFFFF9500), minHeight: 2),
                          ],
                        ),
                      ),
                    if (_descargandoModelo)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Descargando pesos de IA...", style: TextStyle(fontSize: 9, color: theme.primaryColor)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: _progresoModelo, color: theme.primaryColor, minHeight: 2),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("User: ${widget.username} | V$_versionHub", style: TextStyle(fontSize: 9, color: theme.subtitleColor, fontFamily: 'monospace')),
                    )
                  ],
                ),
              ),
              
              // NÚCLEO DEL CHAT
              Expanded(
                child: Column(
                  children: [
                    // BARRA SUPERIOR CON SELECCIONADOR DE TEMA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        border: Border(bottom: BorderSide(color: theme.borderColor, width: 0.8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _activeThread.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.memory_rounded, size: 12, color: theme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Modelo: ${_activeThread.iaModel}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                 icon: Icon(Icons.wallpaper_rounded, color: _getModeAccentColor(theme), size: 20),
                                 tooltip: "Personalizar Fondo y Colores",
                                 onPressed: _mostrarModalPersonalizarFondoColores,
                               ),
                               const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.palette_rounded, color: theme.primaryColor, size: 20),
                                tooltip: "Cambiar Tema Visual",
                                onPressed: () {
                                  mostrarSelectorTemasModal(
                                    context,
                                    _currentThemeStyle,
                                    (newTheme) {
                                      setState(() {
                                        _currentThemeStyle = newTheme;
                                      });
                                      widget.onThemeChanged(newTheme);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: _activeThread.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _activeThread.messages[index];
                          final sender = msg["sender"];
                          
                          Alignment align = Alignment.centerLeft;
                          BoxDecoration decoration = BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            border: Border.all(color: theme.borderColor),
                            boxShadow: theme.shadows,
                          );
                          TextStyle textStyle = TextStyle(color: theme.textColor, fontSize: 14, height: 1.4);

                          if (sender == "user") {
                            align = Alignment.centerRight;
                            decoration = BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(theme.borderRadius),
                              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
                            );
                          } else if (sender == "system") {
                            align = Alignment.center;
                            decoration = BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            );
                            textStyle = TextStyle(color: theme.primaryColor, fontSize: 11, fontFamily: 'monospace');
                          }

                          return Align(
                            alignment: align,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: decoration,
                              child: Text(msg["text"]!, style: textStyle),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: _descargandoModelo 
                          ? Column(
                              children: [
                                LinearProgressIndicator(value: _progresoModelo, color: theme.primaryColor),
                                const SizedBox(height: 8),
                                Text(
                                  "Descargando modelo: ${(_progresoModelo * 100).toStringAsFixed(0)}% completado",
                                  style: TextStyle(fontSize: 12, color: theme.subtitleColor),
                                ),
                              ],
                            )
                          : !_activeThread.modeloInicializado
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9500),
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () => _descargarModeloLlmNativamente(_activeThread),
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text("Descargar Modelo Nativamente (${_activeThread.iaModel})"),
                                )
                              : Container(
                                  margin: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceColor,
                                      borderRadius: BorderRadius.circular(theme.borderRadius),
                                      border: Border.all(color: theme.borderColor, width: 1.2),
                                      boxShadow: theme.shadows,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _chatController,
                                          minLines: 1,
                                          maxLines: 5,
                                          style: TextStyle(color: theme.textColor, fontSize: 14, height: 1.4),
                                          onSubmitted: (_) => _procesarMensajeLocal(),
                                          decoration: InputDecoration(
                                            hintText: (_activeThread.pensando || _isGenerating) ? "Procesando matriz nativa..." : "Escribe un mensaje...",
                                            hintStyle: TextStyle(color: theme.subtitleColor, fontSize: 14),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // BOTÓN TOOLBOX (MALETÍN / HERRAMIENTAS)
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => _mostrarModalToolbox(context),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor.withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1),
                                                ),
                                                child: Icon(Icons.work_rounded, color: theme.primaryColor, size: 20),
                                              ),
                                            ),

                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _currentMode = _currentMode == CoreMode.normal
                                                          ? CoreMode.estudiante
                                                          : CoreMode.normal;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: _currentMode == CoreMode.estudiante
                                                          ? theme.secondaryColor.withValues(alpha: 0.25)
                                                          : theme.primaryColor.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: _currentMode == CoreMode.estudiante
                                                            ? theme.secondaryColor
                                                            : theme.primaryColor,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          _currentMode == CoreMode.estudiante ? Icons.school_rounded : Icons.bolt_rounded,
                                                          size: 13,
                                                          color: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _currentMode == CoreMode.estudiante ? "Estudiante" : "Local",
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: _currentMode == CoreMode.estudiante ? theme.secondaryColor : theme.primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  icon: Icon(
                                                    Icons.photo_camera_rounded,
                                                    color: _getModeAccentColor(theme),
                                                    size: 20,
                                                  ),
                                                  tooltip: "Tomar Foto con Cámara",
                                                  onPressed: () => _tomarFotoYAnalizarIA(source: ImageSource.camera),
                                                ),
                                                const SizedBox(width: 4),

                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  icon: Icon(
                                                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                                    color: _isListening ? const Color(0xFFFF0055) : theme.subtitleColor,
                                                    size: 20,
                                                  ),
                                                  onPressed: _toggleListening,
                                                ),
                                                const SizedBox(width: 6),

                                                GestureDetector(
                                                  onTap: (_activeThread.pensando || _isGenerating) ? null : () => _procesarMensajeLocal(),
                                                  child: Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: _getModeAccentColor(theme),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: _getModeAccentColor(theme).withValues(alpha: 0.5),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: (_activeThread.pensando || _isGenerating)
                                                          ? const SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                            )
                                                          : Icon(_getModeSendIcon(), color: Colors.black, size: 20),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLiquidGlassButton({
    required AppThemeData theme,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor : theme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : theme.subtitleColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : theme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareTelemetryCard(AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board_rounded, color: theme.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                "HARDWARE GALAXY TAB",
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cuerpos CPU:", style: TextStyle(fontSize: 10, color: theme.subtitleColor)),
              Text("$_cpuCores Hilos", style: TextStyle(fontSize: 10, color: theme.textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RAM Libre:", style: TextStyle(fontSize: 10, color: theme.subtitleColor)),
              Text("${_freeRamGb.toStringAsFixed(1)} GB / ${_totalRamGb.toStringAsFixed(1)} GB", style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousLearningCard(AppThemeData theme) {
    final memory = MemoryService.instance;
    final isEnabled = memory.isLearningEnabled;
    final count = memory.memories.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: isEnabled ? theme.primaryColor.withValues(alpha: 0.5) : theme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    color: isEnabled ? theme.primaryColor : theme.subtitleColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "APRENDIZAJE IA",
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: isEnabled,
                activeTrackColor: theme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) async {
                  await memory.setLearningEnabled(val);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isEnabled
                ? "Aprende preferencias de tus chats."
                : "Aprendizaje pausado.",
            style: TextStyle(fontSize: 9.5, color: theme.subtitleColor),
          ),
          if (isEnabled) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _mostrarModalMemoriaAprendida,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ver Memoria ($count)",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: theme.primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarModalMemoriaAprendida() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = AppThemeConfig.getTheme(_currentThemeStyle);
            final memories = MemoryService.instance.memories;

            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
              title: Row(
                children: [
                  Icon(Icons.psychology_rounded, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Memoria Aprendida de Chats", style: TextStyle(color: theme.textColor, fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: memories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "La IA aún no ha registrado memorias. Continúa conversando con la IA para que aprenda automáticamente sobre ti y tus preferencias.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.subtitleColor, fontSize: 13),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: memories.length,
                              separatorBuilder: (_, __) => const Divider(height: 8, color: Colors.white12),
                              itemBuilder: (context, idx) {
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.bookmark_rounded, size: 16, color: theme.primaryColor),
                                  title: Text(
                                    memories[idx],
                                    style: TextStyle(color: theme.textColor, fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                    onPressed: () async {
                                      await MemoryService.instance.removeMemoryAt(idx);
                                      setDialogState(() {});
                                      setState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                if (memories.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await MemoryService.instance.clearMemories();
                      setDialogState(() {});
                      setState(() {});
                    },
                    child: const Text("Borrar Memoria", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarSelectorNuevoChat() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = AppThemeConfig.getTheme(_currentThemeStyle);
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
          title: Text("Nueva Instancia de IA Local", style: TextStyle(color: theme.textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _modelosDisponibles.map((model) {
              return ListTile(
                title: Text(model.name, style: TextStyle(color: theme.textColor, fontSize: 14)),
                subtitle: Text("${model.size} | RAM Req: ${model.requiredRamGb}GB", style: TextStyle(color: theme.subtitleColor, fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: model.badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(model.badge, style: TextStyle(color: model.badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _crearNuevaInstanciaLocal(model.id);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
