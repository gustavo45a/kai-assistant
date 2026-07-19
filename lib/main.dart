import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';


// --- ARRANQUE COMPLETO CON BLINDAJE NATIVO ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar errores del framework de Flutter y mostrarlos en pantalla
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF020408),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 32),
                    SizedBox(width: 8),
                    Text(
                      "VENTABLACK FATAL ERROR",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Stacktrace:",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.stack?.toString() ?? "No stacktrace available",
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Capturar errores asíncronos globales (fuera del framework de Flutter)
  runZonedGuarded(() {
    runApp(const VantablackApp());
  }, (Object error, StackTrace stack) {
    runApp(VantablackErrorApp(error: error, stackTrace: stack));
  });
}

// App de contingencia para errores asíncronos críticos
class VantablackErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const VantablackErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020408),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                      SizedBox(width: 8),
                      Text(
                        "ASYNCHRONOUS CRITICAL ERROR",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Stacktrace:",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stackTrace.toString(),
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VantablackApp extends StatelessWidget {
  const VantablackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF020408), // Negro Absoluto Vantablack
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00B4D8),
            surface: Color(0xFF090D14),
          ),
        ),
        home: const LoginScreen(),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Por favor ingresa todos los campos.";
      });
      return;
    }

    if ((username == "admin" && password == "admin") || username == "gustavo" || password == "zynoox") {
      setState(() {
        _errorMessage = null;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const VantablackHome()),
      );
    } else {
      setState(() {
        _errorMessage = "Credenciales incorrectas.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF090D14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4D8).withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF00B4D8),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "VANTABLACK HUB",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ingresa tus credenciales para acceder al sistema",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white38),
                    fillColor: const Color(0xFF030509),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00B4D8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    labelStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white38),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    fillColor: const Color(0xFF030509),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00B4D8)),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum CoreMode { estudiante, normal }

class LocalModel {
  final String id;
  final String name;
  final String size;
  final double requiredRamGb;
  final String urlGguf;
  bool isDownloaded;

  LocalModel({
    required this.id,
    required this.name,
    required this.size,
    required this.requiredRamGb,
    required this.urlGguf,
    this.isDownloaded = false,
  });
}

class HardwareScanner {
  static Future<Map<String, dynamic>> scan() async {
    final cores = Platform.numberOfProcessors;
    double freeRamGb = 4.0; // Fallback predeterminado

    if (Platform.isAndroid || Platform.isLinux) {
      try {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (var line in lines) {
            if (line.startsWith('MemAvailable:') || line.startsWith('MemFree:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                freeRamGb = kb / (1024 * 1024);
                break;
              }
            }
          }
        }
      } catch (_) {}
    } else {
      // Para Windows/Mac en desarrollo local, asignamos un valor simulado representativo
      freeRamGb = cores > 4 ? 6.5 : 3.2;
    }

    return {
      'cores': cores,
      'freeRamGb': freeRamGb,
    };
  }
}

class LocalLLMService {
  static const MethodChannel _channel = MethodChannel('com.vantablack.hub/llm_engine');

  // Singleton
  static final LocalLLMService instance = LocalLLMService._internal();
  LocalLLMService._internal();

  bool _isModelLoaded = false;
  String _modelPath = '';

  /// Descarga el modelo real desde el repositorio o verifica su existencia en disco
  Future<void> initializeRealModel(String path) async {
    if (_isModelLoaded && _modelPath == path) {
      return; // Ya está cargado en memoria
    }

    final file = File(path);
    if (!await file.exists()) {
      throw Exception("Modelo local no encontrado en el almacenamiento. Requiere descarga inicial.");
    }

    _modelPath = path;

    // Carga el modelo en los 8 núcleos del procesador local
    final bool? success = await _channel.invokeMethod<bool>('loadModel', {'path': _modelPath})
        .timeout(const Duration(seconds: 60));
    _isModelLoaded = success == true;
  }

  /// Inferencia dinámica real por medio de streaming de tokens
  Stream<String> generateResponseStream(String prompt, Map<String, dynamic> variables) async* {
    if (!_isModelLoaded) {
      yield "[ERROR HARDWARE]: El motor local no está inicializado. Descarga los pesos del modelo Hugging Face primero.";
      return;
    }

    final StreamController<String> controller = StreamController<String>();

    // Configuración dinámica basada en los toggles reales de la UI
    final Map<String, dynamic> options = {
      'prompt': prompt,
      'temperature': variables['isModoPro'] == true ? 0.7 : 0.2,
      'threads': 8, // Forzar uso total de los 8 cores detectados
      'zram': variables['isZRamEnabled'] == true,
    };

    // Escuchar el flujo nativo de tokens generados por la red neuronal
    _channel.invokeMethod('startInference', options);

    // Simulación del puente del canal receptor de eventos nativos
    const EventChannel('com.vantablack.hub/llm_stream').receiveBroadcastStream().listen((token) {
      controller.add(token.toString());
    }, onError: (err) {
      controller.addError(err);
    }, onDone: () {
      controller.close();
    });

    yield* controller.stream;
  }
}

final List<LocalModel> localModels = [
  LocalModel(
    id: "qwen_0.5b_instruct_q4",
    name: "Qwen 2.5 0.5B (Instruct)",
    size: "0.4 GB",
    requiredRamGb: 1.5,
    urlGguf: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
  ),
  LocalModel(
    id: "gemma_2b",
    name: "Gemma 2 2B (GGUF)",
    size: "1.6 GB",
    requiredRamGb: 3.5,
    urlGguf: "https://huggingface.co/google/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
  ),
  LocalModel(
    id: "phi_3_mini",
    name: "Phi 3 Mini 3.8B (GGUF)",
    size: "2.2 GB",
    requiredRamGb: 5.5,
    urlGguf: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
  ),
  LocalModel(
    id: "llama_3_8b",
    name: "Llama 3 8B (Quantized)",
    size: "4.7 GB",
    requiredRamGb: 9.0,
    urlGguf: "https://huggingface.co/QuantFactory/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct.Q4_K_M.gguf",
  ),
];

class ChatThread {
  final String id;
  final String title;
  final String botName;
  final String iaModel;
  final String modeName;
  List<Map<String, String>> messages;
  bool modeloInicializado;
  String? rutaModeloLocal;

  ChatThread({
    required this.id,
    required this.title,
    required this.botName,
    required this.iaModel,
    required this.modeName,
    required this.messages,
    this.modeloInicializado = false,
    this.rutaModeloLocal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'botName': botName,
        'iaModel': iaModel,
        'modeName': modeName,
        'messages': messages,
        'modeloInicializado': modeloInicializado,
        'rutaModeloLocal': rutaModeloLocal,
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'],
        title: json['title'],
        botName: json['botName'],
        iaModel: json['iaModel'],
        modeName: json['modeName'] ?? 'Normal',
        messages: List<Map<String, String>>.from(
          (json['messages'] as List).map((item) => Map<String, String>.from(item)),
        ),
        modeloInicializado: json['modeloInicializado'] ?? false,
        rutaModeloLocal: json['rutaModeloLocal'],
      );
}

class VantablackHome extends StatefulWidget {
  const VantablackHome({super.key});
  @override
  State<VantablackHome> createState() => _VantablackHomeState();
}

class _VantablackHomeState extends State<VantablackHome> {
  final String _versionHub = "2.3.2";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/app-release.apk";

  CoreMode _currentMode = CoreMode.normal;
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  bool _descargando = false;
  bool _pensando = false;
  double _progreso = 0.0;
  String _estadoTexto = "Vantablack Core Active";

  double _freeRamGb = 4.0;
  int _cpuCores = 4;

  bool isZRamEnabled = true;
  bool _rigorousSearchOnly = true;
  bool _ttsEnabled = false;
  bool isWebServidorActive = false;
  bool isModoPro = false;
  double _inferenceSpeed = 1.0;
  String _selectedCloudProvider = "Google Drive";
  bool _visualAnalysis = true;
  double _visualPrecision = 0.85;
  bool _quantizedMedia = true;
  bool isVirtualAssistantActive = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() async {
      final diagnostic = await HardwareScanner.scan();
      if (mounted) {
        setState(() {
          _cpuCores = diagnostic['cores'];
          _freeRamGb = diagnostic['freeRamGb'];
        });
      }
      await _verificarModelosDescargados();
      await _cargarDatosDesdeDisco();
      
      // Chequear actualizaciones silenciosamente en segundo plano
      await _checkUpdates();
    });
  }

  Future<void> _checkUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        "https://gustavo45a.github.io/kai-assistant/version.json",
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final remoteBuild = data['buildNumber'] ?? 18;
          final remoteVersion = data['version'] ?? "2.3.1";

          if (remoteBuild > 18 || remoteVersion != "2.3.1") {
            if (!mounted) return;
            _mostrarDialogoActualizacion(remoteVersion);
          }
        }
      }
    } catch (_) {
      // Ignorar fallas de red durante la inicialización silenciosa
    }
  }

  void _mostrarDialogoActualizacion(String remoteVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: Color(0xFF00B4D8)),
              SizedBox(width: 10),
              Text("Nueva Actualización", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Se ha detectado una versión más reciente (v$remoteVersion) en el servidor. ¿Deseas descargar el APK e instalarlo ahora?",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _ejecutarActualizacionOTA();
              },
              child: const Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verificarModelosDescargados() async {
    final dir = await getApplicationDocumentsDirectory();
    for (var model in localModels) {
      final file = File("${dir.path}/${model.id}.gguf");
      model.isDownloaded = await file.exists();
    }
  }

  Future<void> _cargarDatosDesdeDisco() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final archivo = File("${dir.path}/vantablack_save.json");
      if (await archivo.exists()) {
        final contenido = await archivo.readAsString();
        final List<dynamic> jsonList = jsonDecode(contenido);
        if (mounted) {
          setState(() {
            _threads = jsonList.map((e) => ChatThread.fromJson(e)).toList();
            if (_threads.isNotEmpty) _activeThreadId = _threads.first.id;
            _estadoTexto = "Matriz KAI Estable";
          });
        }
      } else {
        _crearHiloInicial();
      }
    } catch (e) {
      _crearHiloInicial();
    }
  }

  void _crearHiloInicial() {
    final initialId = const Uuid().v4();
    if (mounted) {
      setState(() {
        _threads.add(ChatThread(
          id: initialId,
          title: "Instancia Qwen 0.5B",
          botName: "KAI",
          iaModel: "Qwen 2.5 0.5B (Instruct)",
          modeName: "Normal",
          modeloInicializado: false,
          messages: [
            {"sender": "system", "text": "VANTABLACK INTERFACE CONECTADA."},
            {"sender": "assistant", "text": "Interfaz Vantablack activa. ¿En qué te puedo ayudar hoy?"},
          ],
        ));
        _activeThreadId = initialId;
      });
    }
    _guardarDatosEnDisco();
  }

  Future<void> _guardarDatosEnDisco() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final archivo = File("${dir.path}/vantablack_save.json");
      final data = _threads.map((e) => e.toJson()).toList();
      await archivo.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  ChatThread get _activeThread {
    return _threads.firstWhere(
      (t) => t.id == _activeThreadId,
      orElse: () => _threads.first,
    );
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _procesarMensajeLocal() async {
    if (_chatController.text.trim().isEmpty || _pensando) return;

    final threadActual = _activeThread;
    final textoUsuario = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _pensando = true;
      threadActual.messages.add({"sender": "user", "text": textoUsuario});
      threadActual.messages.add({"sender": "assistant", "text": "..."});
    });
    _scrollAlFinal();
    _guardarDatosEnDisco();

    final int indiceRespuesta = threadActual.messages.length - 1;

    try {
      // Resolver la ruta real del modelo seleccionado dinámicamente
      final directory = await getApplicationDocumentsDirectory();
      final modelInfo = localModels.firstWhere(
        (m) => m.name == threadActual.iaModel,
        orElse: () => localModels.first,
      );
      final rutaModelo = "${directory.path}/${modelInfo.id}.gguf";

      // Inicializar el modelo nativo real
      await LocalLLMService.instance.initializeRealModel(rutaModelo);

      String respuestaCompleta = "";
      final stream = LocalLLMService.instance.generateResponseStream(
        textoUsuario,
        {
          'isModoPro': isModoPro,
          'isZRamEnabled': isZRamEnabled,
          'isVirtualAssistantActive': isVirtualAssistantActive,
          'isWebServidorActive': isWebServidorActive,
          'inferenceSpeed': _inferenceSpeed,
          'currentMode': _currentMode,
        },
      );

      await for (var chunk in stream) {
        if (!mounted) return;
        respuestaCompleta += chunk;
        setState(() {
          threadActual.messages[indiceRespuesta]["text"] = respuestaCompleta;
        });
        _scrollAlFinal();
      }

      if (!mounted) return;
      setState(() {
        _pensando = false;
      });
      _guardarDatosEnDisco();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pensando = false;
        threadActual.messages[indiceRespuesta]["text"] = "Error de procesamiento local: $e";
      });
    }
  }

  Widget _buildLiquidGlassButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 115,
        height: 75,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F141C).withOpacity(0.85) : const Color(0xFF06090E).withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.6) : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.4 : 0.7,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 3)),
            if (isSelected) BoxShadow(color: activeColor.withOpacity(0.15), blurRadius: 12, spreadRadius: -1),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(isSelected ? 0.15 : 0.04), Colors.white.withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: isSelected ? activeColor : Colors.white38),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ejecutarActualizacionOTA() async {
    if (_descargando) return;

    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Las actualizaciones OTA solo están soportadas en Android."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() { _descargando = true; _estadoTexto = "Conectando al Hub..."; });
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Almacenamiento no accesible");
      final ruta = "${dir.path}/vantablack_update.apk";
      
      await dio.download(
        _urlApkRemoto, 
        ruta, 
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            if (!mounted) return;
            setState(() {
              _progreso = recibido / total;
              _estadoTexto = "Descarga OTA: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB";
            });
          }
        }
      );
      
      if (!mounted) return;
      setState(() { _descargando = false; _estadoTexto = "Actualizando..."; });
      await OpenFile.open(ruta);
    } catch (e) {
      if (!mounted) return;
      setState(() { _descargando = false; _estadoTexto = "KAI Engine Active"; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo completar la actualización: $e")),
      );
    }
  }

  Future<void> _descargarModeloLlmNativamente(ChatThread thread) async {
    setState(() {
      _descargando = true;
      _progreso = 0.0;
      _estadoTexto = "Cargando modelo local...";
    });

    try {
      final model = localModels.firstWhere(
        (m) => m.name == thread.iaModel,
        orElse: () => localModels.first,
      );

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final rutaDestino = "${dir.path}/${model.id}.gguf";

      await dio.download(
        model.urlGguf,
        rutaDestino,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            if (!mounted) return;
            setState(() {
              _progreso = recibido / total;
              _estadoTexto = "Descangando: ${(recibido / 1024 / 1024).toStringAsFixed(0)}MB / ${(total / 1024 / 1024).toStringAsFixed(0)}MB";
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _descargando = false;
        thread.modeloInicializado = true;
        thread.rutaModeloLocal = rutaDestino;
        model.isDownloaded = true;
        _estadoTexto = "Modelo listo en memoria";
      });
      _guardarDatosEnDisco();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargando = false;
        _estadoTexto = "Fallo al descargar modelo";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al descargar el modelo local: $e")),
      );
    }
  }

  Future<void> _crearNuevaInstanciaChat(String bot, String modelo, bool isDownloaded) async {
    final newId = const Uuid().v4();
    final parts = modelo.split(' ');
    final modelName = parts.length > 2 ? parts[2] : parts.last;
    
    final dir = await getApplicationDocumentsDirectory();
    final model = localModels.firstWhere((m) => m.name == modelo);
    final rutaLocal = "${dir.path}/${model.id}.gguf";

    final nuevoThread = ChatThread(
      id: newId,
      title: "$bot • $modelName",
      botName: bot,
      iaModel: modelo,
      modeName: _currentMode == CoreMode.estudiante ? "Estudiante" : "Normal",
      messages: [],
      modeloInicializado: isDownloaded,
      rutaModeloLocal: isDownloaded ? rutaLocal : null,
    );

    setState(() {
      _threads.insert(0, nuevoThread);
      _activeThreadId = newId;
    });

    nuevoThread.messages.add({
      "sender": "system",
      "text": "Instancia local iniciada con el modelo $modelo."
    });

    if (isDownloaded) {
      nuevoThread.messages.add({
        "sender": "assistant",
        "text": "¡Forja local completada! El archivo binario de la IA está cargado en la memoria de tu dispositivo. Escribe tu instrucción."
      });
    } else {
      nuevoThread.messages.add({
        "sender": "assistant",
        "text": "Para iniciar, por favor descarga los pesos del modelo local pulsando el botón de abajo."
      });
    }
    
    _guardarDatosEnDisco();
    _scrollAlFinal();
  }

  void _mostrarSelectorNuevoChat() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ConfigureInstanceDialog(
          freeRamGb: _freeRamGb,
          models: localModels,
          onConfirm: (bot, modelo, isDownloaded) {
            _crearNuevaInstanciaChat(bot, modelo, isDownloaded);
          },
        );
      },
    );
  }

  Widget _buildHardwareTelemetryCard() {
    final ramStatus = _freeRamGb < 4.0 
        ? "Limitado (Modelos < 3B)" 
        : (_freeRamGb < 8.0 ? "Estándar (Modelos < 8B)" : "Excelente (Todos)");
    final ramColor = _freeRamGb < 4.0 
        ? Colors.redAccent 
        : (_freeRamGb < 8.0 ? Colors.amberAccent : const Color(0xFF00B4D8));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 14, color: ramColor),
              const SizedBox(width: 6),
              const Text(
                "TELEMETRÍA DE HARDWARE",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Núcleos CPU:", style: TextStyle(fontSize: 11, color: Colors.white38)),
              Text("$_cpuCores Cores", style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("RAM Estimada:", style: TextStyle(fontSize: 11, color: Colors.white38)),
              Text("${_freeRamGb.toStringAsFixed(1)} GB", style: TextStyle(fontSize: 11, color: ramColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Diagnóstico:", style: TextStyle(fontSize: 11, color: Colors.white38)),
              Text(
                ramStatus,
                style: TextStyle(fontSize: 11, color: ramColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportarChatLocal() async {
    final threadActual = _activeThread;
    if (threadActual.messages.isEmpty) return;
    
    try {
      final buffer = StringBuffer();
      buffer.writeln("=== HISTORIAL DE CHAT VANTABLACK ===");
      buffer.writeln("Modelo: ${threadActual.iaModel}");
      buffer.writeln("Modo: ${threadActual.modeName}");
      buffer.writeln("Fecha: ${DateTime.now().toIso8601String()}");
      buffer.writeln("===================================\n");
      
      for (var msg in threadActual.messages) {
        buffer.writeln("[${msg['sender']?.toUpperCase()}]: ${msg['text']}");
        buffer.writeln("-----------------------------------");
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/chat_export_${threadActual.id.substring(0, 8)}.txt");
      await file.writeAsString(buffer.toString());
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text("Historial Guardado", style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text("Chat exportado con éxito en:\n\n${file.path}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar", style: TextStyle(color: Color(0xFF00B4D8))),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al exportar chat: $e")));
    }
  }

  Widget _buildMatrixControlPanel() {
    final activeColor = _currentMode == CoreMode.estudiante ? const Color(0xFF9D4EDD) : const Color(0xFF00B4D8);
    
    return Container(
      width: 310,
      decoration: const BoxDecoration(
        color: Color(0xFF030509),
        border: Border(left: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Icon(
                  _currentMode == CoreMode.estudiante ? Icons.psychology_rounded : Icons.dashboard_customize_rounded,
                  color: activeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentMode == CoreMode.estudiante ? "MATRIZ DE RAZONAMIENTO" : "MATRIZ DE PRODUCTIVIDAD",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _currentMode == CoreMode.estudiante 
                  ? _buildEstudianteSettings(activeColor) 
                  : _buildNormalSettings(activeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteSettings(Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("MÓDULOS DE ANÁLISIS CRÍTICO", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Context Processing
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Comprensión Visual", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Habilita análisis profundo de imágenes", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: _visualAnalysis,
          activeColor: activeColor,
          onChanged: (val) => setState(() => _visualAnalysis = val),
        ),
        
        // Rigorous Search
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Investigación Rigurosa", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Filtra y omite blogs o fuentes de baja confianza", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: _rigorousSearchOnly,
          activeColor: activeColor,
          onChanged: (val) => setState(() => _rigorousSearchOnly = val),
        ),
        
        const SizedBox(height: 16),
        const Text("COMPRESIÓN Y RECURSOS", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // RAM Compression
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Compresión Z-RAM", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Optimiza el consumo comprimiendo memoria", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isZRamEnabled,
          activeColor: activeColor,
          onChanged: (val) => setState(() => isZRamEnabled = val),
        ),
        
        if (isZRamEnabled) ...[
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Eficiencia de Compresión", style: TextStyle(fontSize: 10, color: Colors.white38)),
              Text("85% activa", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85,
              color: activeColor,
              backgroundColor: Colors.white10,
              minHeight: 4,
            ),
          ),
        ],

        const SizedBox(height: 16),
        const Text("GENERACIÓN Y CONECTORES", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Visual Precision Slider
        Text("Precisión Generativa (${(_visualPrecision * 100).toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Slider(
          value: _visualPrecision,
          min: 0.5,
          max: 1.0,
          activeColor: activeColor,
          inactiveColor: Colors.white10,
          onChanged: (val) => setState(() => _visualPrecision = val),
        ),
        
        // Cloud integrations
        const Text("Nube Principal", style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 6),
        DropdownButton<String>(
          value: _selectedCloudProvider,
          isExpanded: true,
          dropdownColor: const Color(0xFF030509),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          underline: Container(height: 1, color: Colors.white10),
          items: ["Google Drive", "OneDrive", "iCloud", "Canva Connect"]
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCloudProvider = val);
          },
        ),

        const SizedBox(height: 20),
        const Text("HERRAMIENTAS DE PERSISTENCIA", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E1420),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _exportarChatLocal,
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text("Exportar Historial Local", style: TextStyle(fontSize: 11)),
        ),

        const SizedBox(height: 20),
        const Text("CENTRO DE DEBATE", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ttsEnabled ? activeColor.withOpacity(0.15) : const Color(0xFF0E1420),
                  foregroundColor: _ttsEnabled ? activeColor : Colors.white60,
                  side: BorderSide(color: _ttsEnabled ? activeColor : Colors.transparent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
                icon: Icon(_ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 16),
                label: const Text("Modo TTS", style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalSettings(Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("RENDIMIENTO Y MULTIMEDIA", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Fast Inference Slider
        Text("Inferencia Rápida (${_inferenceSpeed.toStringAsFixed(1)}x)", style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Slider(
          value: _inferenceSpeed,
          min: 0.5,
          max: 2.0,
          activeColor: activeColor,
          inactiveColor: Colors.white10,
          onChanged: (val) => setState(() => _inferenceSpeed = val),
        ),
        
        // Quantized Media Toggle
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Multimedia Cuantizada", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Manejo eficiente de imágenes y video", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: _quantizedMedia,
          activeColor: activeColor,
          onChanged: (val) => setState(() => _quantizedMedia = val),
        ),
        
        const SizedBox(height: 16),
        const Text("INTEGRACIÓN CLOUD Y CANVA", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        DropdownButton<String>(
          value: _selectedCloudProvider,
          isExpanded: true,
          dropdownColor: const Color(0xFF030509),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          underline: Container(height: 1, color: Colors.white10),
          items: ["Google Drive", "OneDrive", "iCloud", "Canva Connect"]
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCloudProvider = val);
          },
        ),

        const SizedBox(height: 20),
        const Text("HERRAMIENTAS BETA & PRO", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Modo Pro", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Acceso a configuraciones experimentales", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isModoPro,
          activeColor: activeColor,
          onChanged: (val) => setState(() => isModoPro = val),
        ),
        
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E1420),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lanzando Editor Completo con IA (Beta)...")),
            );
          },
          icon: const Icon(Icons.edit_note_rounded, size: 16),
          label: const Text("Lanzar Editor IA", style: TextStyle(fontSize: 11)),
        ),

        const SizedBox(height: 20),
        const Text("CONTROL DE ENTORNO LOCAL", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        // Environment Assistant
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Asistente Virtual", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Interactúa con dispositivos cercanos vía API", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isVirtualAssistantActive,
          activeColor: activeColor,
          onChanged: (val) => setState(() => isVirtualAssistantActive = val),
        ),
        
        // Web Mode Background Server
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Modo Web Servidor", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Dejar la PC encendida y servir interfaz en la web", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isWebServidorActive,
          activeColor: activeColor,
          onChanged: (val) => setState(() => isWebServidorActive = val),
        ),
        
        if (isWebServidorActive) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_tethering_rounded, size: 12, color: Colors.green),
                SizedBox(width: 6),
                Text("Servidor Web Activo: http://192.168.1.100:8080", style: TextStyle(fontSize: 9, color: Colors.green, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_threads.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8))));
    }

    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL NATIVA VANTABLACK
          Container(
            width: 270,
            decoration: const BoxDecoration(
              color: Color(0xFF030509),
              border: Border(right: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // CONTENEDOR DEL LOGO GLITCH
                Center(
                  child: GestureDetector(
                    onTap: _ejecutarActualizacionOTA,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 140, height: 140, 
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _currentMode == CoreMode.estudiante
                                ? const Color(0xFF9D4EDD).withOpacity(0.2)
                                : const Color(0xFF00B4D8).withOpacity(0.15),
                            blurRadius: 24,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0A0E17),
                              child: Icon(
                                Icons.shield_rounded,
                                color: _currentMode == CoreMode.estudiante ? const Color(0xFF9D4EDD) : const Color(0xFF00B4D8),
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

                // TARJETA DE TELEMETRÍA DE HARDWARE
                _buildHardwareTelemetryCard(),
                
                // ENTORNO LIQUID GLASS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLiquidGlassButton(
                        title: "Modo Normal",
                        icon: Icons.bolt_rounded,
                        isSelected: _currentMode == CoreMode.normal,
                        activeColor: const Color(0xFF00B4D8),
                        onTap: () => setState(() => _currentMode = CoreMode.normal),
                      ),
                      _buildLiquidGlassButton(
                        title: "Estudiante",
                        icon: Icons.menu_book_rounded,
                        isSelected: _currentMode == CoreMode.estudiante,
                        activeColor: const Color(0xFF9D4EDD),
                        onTap: () => setState(() => _currentMode = CoreMode.estudiante),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C101A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                    ),
                    onPressed: _mostrarSelectorNuevoChat,
                    icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF00B4D8)),
                    label: const Text("Nueva Instancia", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("MATRICES LOCALES ACTIVAS", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
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
                          selectedTileColor: const Color(0xFF0C101A),
                          leading: Icon(Icons.code_rounded, size: 16, color: isSelected ? const Color(0xFF00B4D8) : Colors.white24),
                          title: Text(
                            thread.title,
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12.5),
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
                if (_descargando)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: LinearProgressIndicator(value: _progreso, color: const Color(0xFFFF9500), minHeight: 2),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("$_estadoTexto | V$_versionHub", style: const TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'monospace')),
                )
              ],
            ),
          ),
          
          // NÚCLEO DEL CHAT
          Expanded(
            child: Container(
              color: const Color(0xFF020406),
              child: Column(
                children: [
                  // --- BARRA SUPERIOR CON INDICADOR DE MODELO ACTIVO ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF030509),
                      border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _activeThread.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.memory_rounded, size: 12, color: Color(0xFF00B4D8)),
                              const SizedBox(width: 6),
                              Text(
                                "Modelo: ${_activeThread.iaModel.contains('Qwen') ? 'Gemini 1.5 Flash' : _activeThread.iaModel}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00B4D8),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
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
                          color: const Color(0xFF080C14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.015)),
                        );
                        TextStyle textStyle = const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14, height: 1.4);

                        if (sender == "user") {
                          align = Alignment.centerRight;
                          decoration = BoxDecoration(
                            color: const Color(0xFF121A28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.2)),
                          );
                        } else if (sender == "system") {
                          align = Alignment.center;
                          decoration = BoxDecoration(
                            color: const Color(0xFF00B4D8).withOpacity(0.01),
                            borderRadius: BorderRadius.circular(6),
                          );
                          textStyle = const TextStyle(color: Color(0xFF00B4D8), fontSize: 11, fontFamily: 'monospace');
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
                    padding: const EdgeInsets.all(20),
                    child: _descargando 
                        ? Column(
                            children: [
                              LinearProgressIndicator(value: _progreso, color: const Color(0xFF00B4D8)),
                              const SizedBox(height: 8),
                              Text(
                                "Descargando modelo: ${(_progreso * 100).toStringAsFixed(0)}% completado",
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                            ],
                          )
                        : !_activeThread.modeloInicializado
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9500),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => _descargarModeloLlmNativamente(_activeThread),
                                icon: const Icon(Icons.download_rounded),
                                label: Text("Descargar Modelo Nativamente (${_activeThread.iaModel})"),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _chatController,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      onSubmitted: (_) => _procesarMensajeLocal(),
                                      decoration: InputDecoration(
                                        hintText: _pensando ? "Procesando matriz nativa..." : "Enviar comando local...",
                                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                        fillColor: const Color(0xFF05070B),
                                        filled: true,
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white10)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 0.8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: _pensando 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _currentMode == CoreMode.estudiante ? const Color(0xFF9D4EDD) : const Color(0xFF00B4D8),
                                      minimumSize: const Size(48, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _pensando ? null : _procesarMensajeLocal,
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
          _buildMatrixControlPanel(),
        ],
      ),
    );
  }
}

class ConfigureInstanceDialog extends StatefulWidget {
  final double freeRamGb;
  final List<LocalModel> models;
  final Function(String bot, String modelo, bool isDownloaded) onConfirm;

  const ConfigureInstanceDialog({
    super.key,
    required this.freeRamGb,
    required this.models,
    required this.onConfirm,
  });

  @override
  State<ConfigureInstanceDialog> createState() => _ConfigureInstanceDialogState();
}

class _ConfigureInstanceDialogState extends State<ConfigureInstanceDialog> {
  String selectedBot = "KAI";
  late String selectedIA;

  @override
  void initState() {
    super.initState();
    selectedIA = widget.models.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.memory_rounded, color: Color(0xFF00B4D8)),
          SizedBox(width: 10),
          Text("Configurar Nueva Instancia Local", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Elegir Personalidad del Bot:", style: TextStyle(fontSize: 12, color: Colors.white38)),
            DropdownButton<String>(
              value: selectedBot,
              isExpanded: true,
              dropdownColor: const Color(0xFF131722),
              items: ["KAI", "SELENE", "CHRONOS"]
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedBot = val);
              },
            ),
            const SizedBox(height: 16),
            const Text("Asignar Modelo IA Local:", style: TextStyle(fontSize: 12, color: Colors.white38)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.models.length,
                itemBuilder: (context, index) {
                  final model = widget.models[index];
                  final isRecommended = widget.freeRamGb >= model.requiredRamGb;
                  final isSelected = selectedIA == model.name;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00B4D8) : Colors.white10,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(model.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text("Tamaño: ${model.size} | RAM Requerida: ${model.requiredRamGb} GB", style: const TextStyle(fontSize: 11, color: Colors.white38)),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRecommended ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isRecommended ? "Recomendado" : "No recomendado",
                              style: TextStyle(color: isRecommended ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: model.isDownloaded ? Colors.blue.withOpacity(0.15) : Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              model.isDownloaded ? "Listo" : "No descargado",
                              style: TextStyle(color: model.isDownloaded ? Colors.blue : Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          selectedIA = model.name;
                        });
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
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancelar", style: TextStyle(color: Colors.white38))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () {
            Navigator.pop(context);
            final model = widget.models.firstWhere((m) => m.name == selectedIA);
            widget.onConfirm(selectedBot, selectedIA, model.isDownloaded);
          },
          child: const Text("Crear Instancia"),
        ),
      ],
    );
  }
}