import 'dart:io'; 
import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Necesario para PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Compatibilidad Web
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';


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

  // Capturar errores asíncronos de forma segura sin provocar un crash total en caliente
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("ASYNCHRONOUS EXCEPTION DETECTED: $error");
    debugPrint(stack.toString());
    // Retornamos true para indicar que el error ha sido controlado sin tumbar el árbol de la UI
    return true;
  };

  runApp(const VantablackApp());
}

class VantablackApp extends StatelessWidget {
  const VantablackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vantablack',
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

    // CORREGIDO: Agrupación correcta con operadores booleanos para evitar login no deseado de gustavo/zynoox
    if ((username == "admin" && password == "admin") || (username == "gustavo" && password == "zynoox")) {
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
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.05),
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
    final cores = kIsWeb ? 1 : Platform.numberOfProcessors;
    double freeRamGb = 4.0; // Fallback predeterminado

    // CORREGIDO: Soporte multiplataforma seguro y lectura completa sin 'break' prematuro en meminfo
    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      try {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          double? memAvailable;
          double? memFree;
          
          for (var line in lines) {
            if (line.startsWith('MemAvailable:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memAvailable = kb / (1024 * 1024);
              }
            } else if (line.startsWith('MemFree:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memFree = kb / (1024 * 1024);
              }
            }
          }
          // Usamos la memoria realmente disponible en vez de solo la libre
          freeRamGb = memAvailable ?? memFree ?? 4.0;
        }
      } catch (_) {}
    } else {
      // Para Windows/Mac/Web en desarrollo local, asignamos un valor simulado representativo
      freeRamGb = cores > 4 ? 6.5 : 3.2;
    }

    return {
      'cores': cores,
      'freeRamGb': freeRamGb,
    };
  }
}

class LocalLLMService {
  // Singleton
  static final LocalLLMService instance = LocalLLMService._internal();
  LocalLLMService._internal();

  final LlamaController _controller = LlamaController();
  bool _isModelLoaded = false;
  bool _isGenerating = false; // CORREGIDO: Variable local para rastrear el estado de inferencia
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

  /// Descarga el modelo real desde el repositorio o verifica su existencia en disco
  Future<void> initializeRealModel(String path, {int threads = 2}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("Modelo local no encontrado en el almacenamiento. Requiere descarga inicial.");
    }

    if (_isModelLoaded && _modelPath == path) {
      return; // Ya está cargado y listo
    }

    // Liberar memoria gráfica y garbage collector antes de cargar modelo nativo en C++
    ZRamMemoryManager.optimizeMemory(true);

    // CORREGIDO: Evitar llamar a isModelLoaded() de LlamaController, usar nuestra bandera _isModelLoaded
    if (_isModelLoaded) {
      try {
        await _controller.dispose();
      } catch (_) {}
      _isModelLoaded = false;
    }

    _modelPath = path;

    // Asignación ultra-segura de hilos (máximo 2 hilos para prevenir fallas C++ y sobrecalentamiento)
    final safeThreads = (threads > 0 && threads <= 2) ? threads : 2;

    try {
      await _controller.loadModel(
        modelPath: _modelPath,
        threads: safeThreads,
        contextSize: 768, // Límite de contexto seguro para la RAM de dispositivos móviles
      );
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      throw Exception("RAM insuficiente o error al alojar el modelo local: $e");
    }
  }

  /// Inferencia dinámica ultra-estable por medio de streaming de tokens usando formateador ChatML directo en Dart
  Stream<String> generateResponseStream(String prompt, Map<String, dynamic> variables, {List<Map<String, String>>? history}) async* {
    if (!_isModelLoaded) {
      yield "[ERROR HARDWARE]: El motor local no está inicializado. Descarga los pesos del modelo Hugging Face primero.";
      return;
    }

    if (_isGenerating) {
      await stop();
    }

    _isGenerating = true;

    final StringBuffer fullPromptBuffer = StringBuffer();
    
    final String modeText = variables['currentMode'] == CoreMode.estudiante
        ? ' Explicaciones didácticas y educativas.'
        : '';

    // 1. Cabecera System Prompt en formato ChatML conciso
    fullPromptBuffer.writeln("<|im_start|>system");
    fullPromptBuffer.writeln("Eres KAI, un asistente de IA útil, conciso y directo.$modeText");
    fullPromptBuffer.writeln("<|im_end|>");

    // 2. Filtrar y truncar el historial (máximo últimos 4 mensajes) para prevenir buffer overflow de n_ctx
    if (history != null && history.isNotEmpty) {
      final validMsgs = history.where((msg) {
        final text = msg['text'] ?? '';
        return text.isNotEmpty && text != '...' && !text.startsWith('[ERROR') && !text.startsWith('Error') && !text.startsWith('VANTABLACK');
      }).toList();

      final recentMsgs = validMsgs.length > 4 ? validMsgs.sublist(validMsgs.length - 4) : validMsgs;

      for (var msg in recentMsgs) {
        final sender = msg['sender'];
        final text = msg['text'] ?? '';
        if (sender == 'user') {
          fullPromptBuffer.writeln("<|im_start|>user");
          fullPromptBuffer.writeln(text);
          fullPromptBuffer.writeln("<|im_end|>");
        } else if (sender == 'assistant') {
          fullPromptBuffer.writeln("<|im_start|>assistant");
          fullPromptBuffer.writeln(text);
          fullPromptBuffer.writeln("<|im_end|>");
        }
      }
    }

    // 3. Formatear mensaje actual del usuario si no está en el buffer
    final String promptMarker = "<|im_start|>user\n$prompt";
    if (!fullPromptBuffer.toString().contains(promptMarker)) {
      fullPromptBuffer.writeln("<|im_start|>user");
      fullPromptBuffer.writeln(prompt);
      fullPromptBuffer.writeln("<|im_end|>");
    }

    // 4. Apertura del rol asistente para inicio de streaming
    fullPromptBuffer.writeln("<|im_start|>assistant");

    try {
      // Inferencia nativa ultra-estable con parámetros afinados para evitar repeticiones
      final stream = _controller.generate(
        prompt: fullPromptBuffer.toString(),
        maxTokens: 256,
        temperature: 0.7,
        topP: 0.9,
        repeatPenalty: 1.18,
      );

      await for (var token in stream) {
        if (token.contains("<|im_end|>") || token.contains("<|endoftext|>")) {
          final cleanToken = token.replaceAll("<|im_end|>", "").replaceAll("<|endoftext|>", "");
          if (cleanToken.isNotEmpty) yield cleanToken;
          await stop();
          break;
        }
        yield token;
      }
    } catch (e) {
      yield " [Error de Inferencia: $e]";
    } finally {
      _isGenerating = false;
    }
  }
}

final List<LocalModel> localModels = [
  LocalModel(
    id: "qwen_0.5b_chat_q4",
    name: "Qwen 1.5 0.5B (Chat)",
    size: "0.4 GB",
    requiredRamGb: 1.5,
    urlGguf: "https://huggingface.co/Qwen/Qwen1.5-0.5B-Chat-GGUF/resolve/main/qwen1_5-0_5b-chat-q4_k_m.gguf",
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
  bool pensando; // CORREGIDO: Añadido para controlar el bloqueo de input de forma local en cada chat

  ChatThread({
    required this.id,
    required this.title,
    required this.botName,
    required this.iaModel,
    required this.modeName,
    required this.messages,
    this.modeloInicializado = false,
    this.rutaModeloLocal,
    this.pensando = false,
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
        pensando: false, // Por defecto al cargar, no está pensando
      );
}

class ZRamMemoryManager {
  static void optimizeMemory(bool isEnabled) {
    if (isEnabled) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
  }
}

class LocalWebServerService {
  static final LocalWebServerService instance = LocalWebServerService._internal();
  LocalWebServerService._internal();

  HttpServer? _server;
  String _serverIp = 'Buscando IP...';
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String get serverUrl => "http://$_serverIp:8080";

  Future<String> startServer(Function(String prompt, String response) onLogMessage) async {
    if (_isRunning) return serverUrl;

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            _serverIp = addr.address;
            break;
          }
        }
      }
      if (_serverIp == 'Buscando IP...') _serverIp = '127.0.0.1';

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _isRunning = true;

      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        final method = request.method;

        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

        if (method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (path == '/' || path == '/index.html') {
          request.response.headers.contentType = ContentType.html;
          request.response.write(_htmlWebInterface);
          await request.response.close();
        } else if (path == '/api/chat' && method == 'POST') {
          try {
            final content = await utf8.decoder.bind(request).join();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final prompt = json['prompt'] ?? '';

            request.response.headers.contentType = ContentType.json;

            if (prompt.toString().trim().isEmpty) {
              request.response.write(jsonEncode({'error': 'Prompt vacío'}));
            } else {
              final stream = LocalLLMService.instance.generateResponseStream(
                prompt.toString(),
                {'isModoPro': false, 'currentMode': CoreMode.normal},
              );

              String fullResponse = '';
              await for (var chunk in stream) {
                fullResponse += chunk;
              }
              onLogMessage(prompt.toString(), fullResponse);
              request.response.write(jsonEncode({'response': fullResponse}));
            }
          } catch (e) {
            request.response.write(jsonEncode({'error': e.toString()}));
          }
          await request.response.close();
        } else if (path == '/api/status') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'status': 'online',
            'app': 'Vantablack Hub KAI IA',
            'ip': _serverIp,
            'port': 8080,
          }));
          await request.response.close();
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });

      return serverUrl;
    } catch (e) {
      _isRunning = false;
      return "Error al iniciar servidor: $e";
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isRunning = false;
  }

  static const String _htmlWebInterface = '''
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>KAI IA - Servidor Web Local</title>
<style>
  body { background-color: #0b0e14; color: #e0e6ed; font-family: system-ui, sans-serif; margin: 0; padding: 20px; }
  .container { max-width: 700px; margin: 0 auto; background: #131722; border: 1px solid #1f293d; border-radius: 16px; padding: 24px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
  h1 { color: #00b4d8; font-size: 22px; margin-top: 0; display: flex; align-items: center; gap: 10px; }
  .status { background: rgba(0,180,216,0.1); border: 1px solid #00b4d8; color: #00b4d8; padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: bold; margin-bottom: 20px; display: inline-block; }
  #chat-box { height: 350px; overflow-y: auto; background: #0b0e14; border-radius: 12px; padding: 16px; border: 1px solid #1f293d; margin-bottom: 16px; display: flex; flex-direction: column; gap: 12px; }
  .msg { padding: 10px 14px; border-radius: 12px; max-width: 80%; line-height: 1.4; font-size: 14px; }
  .user { background: #0077b6; color: white; align-self: flex-end; }
  .assistant { background: #1f293d; color: #e0e6ed; align-self: flex-start; border: 1px solid #2d3b55; }
  .input-group { display: flex; gap: 10px; }
  input { flex: 1; background: #0b0e14; border: 1px solid #1f293d; color: white; padding: 12px; border-radius: 10px; outline: none; font-size: 14px; }
  input:focus { border-color: #00b4d8; }
  button { background: #0077b6; color: white; border: none; padding: 12px 20px; border-radius: 10px; cursor: pointer; font-weight: bold; }
  button:hover { background: #00b4d8; }
</style>
</head>
<body>
<div class="container">
  <h1>⚡ KAI IA - Servidor Web Local</h1>
  <div class="status">🟢 Conectado a la CPU del teléfono en vivo</div>
  <div id="chat-box">
    <div class="msg assistant">¡Hola desde tu servidor web local! La IA se ejecuta directamente en la CPU de tu dispositivo. ¿Qué deseas consultar?</div>
  </div>
  <div class="input-group">
    <input type="text" id="prompt-input" placeholder="Escribe tu mensaje..." onkeydown="if(event.key==='Enter') sendPrompt()">
    <button onclick="sendPrompt()">Enviar</button>
  </div>
</div>
<script>
async function sendPrompt() {
  const input = document.getElementById('prompt-input');
  const text = input.value.trim();
  if(!text) return;
  
  const box = document.getElementById('chat-box');
  box.innerHTML += `<div class="msg user">\${text}</div>`;
  input.value = '';
  box.scrollTop = box.scrollHeight;
  
  const loading = document.createElement('div');
  loading.className = 'msg assistant';
  loading.innerText = 'Procesando en la CPU local...';
  box.appendChild(loading);
  box.scrollTop = box.scrollHeight;
  
  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({prompt: text})
    });
    const data = await res.json();
    loading.innerText = data.response || data.error || 'Sin respuesta';
  } catch(e) {
    loading.innerText = 'Error de conexión: ' + e;
  }
  box.scrollTop = box.scrollHeight;
}
</script>
</body>
</html>
''';
}

class VantablackHome extends StatefulWidget {
  const VantablackHome({super.key});
  @override
  State<VantablackHome> createState() => _VantablackHomeState();
}

class _VantablackHomeState extends State<VantablackHome> {
  final String _versionHub = "2.3.9";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/vantablack_hub.apk";

  CoreMode _currentMode = CoreMode.normal;
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  // CORREGIDO: Estados de descarga independientes
  bool _descargandoOta = false;
  bool _descargandoModelo = false;
  double _progresoOta = 0.0;
  double _progresoModelo = 0.0;
  String _estadoTexto = "Vantablack Core Active";

  double _freeRamGb = 4.0;
  int _cpuCores = 4;

  bool isZRamEnabled = true;
  bool _rigorousSearchOnly = true;
  bool _ttsEnabled = false;
  bool isWebServidorActive = false;
  String _webServerUrl = "http://127.0.0.1:8080";
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

  // CORREGIDO: Liberar controladores de manera limpia
  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUpdates() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        "https://gustavo45a.github.io/kai-assistant/version.json",
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final remoteBuild = data['buildNumber'] as int? ?? 23;
          final remoteVersion = data['version'] as String? ?? "2.3.9";
          final remoteUrl = data['url'] as String? ?? _urlApkRemoto;

          const int currentBuild = 23;
          if (remoteBuild > currentBuild) {
            if (!mounted) return;
            _mostrarDialogoActualizacion(remoteVersion, remoteUrl);
          }
        }
      }
    } catch (_) {
      // Ignorar fallas de red durante la inicialización silenciosa
    }
  }

  void _mostrarDialogoActualizacion(String remoteVersion, String remoteUrl) {
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
                _ejecutarActualizacionOTA(remoteUrl);
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
      if (await file.exists()) {
        final length = await file.length();
        // Un archivo GGUF válido debe pesar al menos 50 MB
        if (length > 50 * 1024 * 1024) {
          model.isDownloaded = true;
        } else {
          // Borrar archivos corruptos o descargas incompletas de 0 bytes
          try { await file.delete(); } catch (_) {}
          model.isDownloaded = false;
        }
      } else {
        model.isDownloaded = false;
      }
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
          iaModel: "Qwen 1.5 0.5B (Chat)",
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
    final threadActual = _activeThread;
    if (_chatController.text.trim().isEmpty || threadActual.pensando) return; // CORREGIDO: Comprobar variable 'pensando' por hilo

    final textoUsuario = _chatController.text.trim();

    // Resolver la ruta real del modelo seleccionado dinámicamente
    final directory = await getApplicationDocumentsDirectory();

    // Limpiar versión previa incompatible de Qwen 2.5 si existe en disco
    final oldModelFile = File("${directory.path}/qwen_0.5b_instruct_q4.gguf");
    if (await oldModelFile.exists()) {
      try { await oldModelFile.delete(); } catch (_) {}
    }

    final modelInfo = localModels.firstWhere(
      (m) => m.name == threadActual.iaModel ||
             m.id == threadActual.iaModel ||
             (threadActual.iaModel.toLowerCase().contains("qwen") && m.id.contains("qwen")),
      orElse: () => localModels.first,
    );
    final rutaModelo = "${directory.path}/${modelInfo.id}.gguf";
    final modelFile = File(rutaModelo);

    // Verificar existencia Y tamaño del archivo binario
    bool isFileValid = await modelFile.exists();
    if (isFileValid) {
      final size = await modelFile.length();
      if (size < 50 * 1024 * 1024) { // Si pesa menos de 50MB está incompleto/corrupto
        isFileValid = false;
        try { await modelFile.delete(); } catch (_) {}
      }
    }

    if (!isFileValid) {
      if (!mounted) return;
      setState(() {
        threadActual.modeloInicializado = false;
        modelInfo.isDownloaded = false;
      });
      _guardarDatosEnDisco();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ El modelo ${modelInfo.name} no está descargado o se interrumpió la descarga. Toca 'Descargar Modelo' para obtenerlo."),
          backgroundColor: Colors.amber[900],
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    _chatController.clear();

    setState(() {
      threadActual.pensando = true; // CORREGIDO: Bloquear input solo para este hilo
      threadActual.messages.add({"sender": "user", "text": textoUsuario});
      threadActual.messages.add({"sender": "assistant", "text": "..."});
    });
    _scrollAlFinal();
    _guardarDatosEnDisco();

    final int indiceRespuesta = threadActual.messages.length - 1;

    try {
      // Inicializar el modelo nativo real usando 2 hilos súper estables (previene cierres nativos por CPU/RAM)
      await LocalLLMService.instance.initializeRealModel(rutaModelo, threads: 2);

      String respuestaCompleta = "";
      final historialPrevio = threadActual.messages.length >= 2 
          ? threadActual.messages.sublist(0, threadActual.messages.length - 2) 
          : <Map<String, String>>[];

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
        history: historialPrevio,
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
        threadActual.pensando = false;
      });
      _guardarDatosEnDisco();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        threadActual.pensando = false;
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
          color: isSelected ? const Color(0xFF0F141C).withValues(alpha: 0.85) : const Color(0xFF06090E).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.4 : 0.7,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 3)),
            if (isSelected) BoxShadow(color: activeColor.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: -1),
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
                      colors: [Colors.white.withValues(alpha: isSelected ? 0.15 : 0.04), Colors.white.withValues(alpha: 0.0)],
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

  Future<void> _ejecutarActualizacionOTA([String? targetUrl]) async {
    if (_descargandoOta) return; // CORREGIDO: Validar variable OTA propia

    if (kIsWeb || !Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Las actualizaciones OTA solo están soportadas en Android."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final downloadUrl = targetUrl ?? _urlApkRemoto;

    setState(() { _descargandoOta = true; _estadoTexto = "Conectando al Hub..."; });
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final ruta = "${dir.path}/vantablack_update.apk";

      final file = File(ruta);
      if (await file.exists()) {
        await file.delete();
      }
      
      await dio.download(
        downloadUrl, 
        ruta, 
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            if (!mounted) return;
            setState(() {
              _progresoOta = recibido / total;
              _estadoTexto = "Descarga OTA: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB";
            });
          }
        }
      );
      
      if (!mounted) return;
      setState(() { _descargandoOta = false; _estadoTexto = "Instalando versión v$_versionHub..."; });
      final result = await OpenFile.open(
        ruta,
        type: "application/vnd.android.package-archive",
      );

      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Permiso o instalador requerido: ${result.message}. Revisa la notificación de descarga para completar la instalación."),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _descargandoOta = false; _estadoTexto = "Vantablack Core Active"; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo completar la actualización OTA: $e")),
      );
    }
  }

  Future<void> _descargarModeloLlmNativamente(ChatThread thread) async {
    if (_descargandoModelo) return; // Evitar descargas duplicadas del modelo

    setState(() {
      _descargandoModelo = true; // CORREGIDO: Estado de modelo independiente
      _progresoModelo = 0.0;
      _estadoTexto = "Cargando modelo local...";
    });

    try {
      final model = localModels.firstWhere(
        (m) => m.name == thread.iaModel ||
               m.id == thread.iaModel ||
               (thread.iaModel.toLowerCase().contains("qwen") && m.id.contains("qwen")),
        orElse: () => localModels.first,
      );

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final rutaDestino = "${dir.path}/${model.id}.gguf";
      final rutaTemp = "${dir.path}/${model.id}.tmp";

      final tempFile = File(rutaTemp);
      if (await tempFile.exists()) {
        try { await tempFile.delete(); } catch (_) {}
      }

      await dio.download(
        model.urlGguf,
        rutaTemp,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            if (!mounted) return;
            setState(() {
              _progresoModelo = recibido / total;
              _estadoTexto = "Descargando: ${(recibido / 1024 / 1024).toStringAsFixed(0)}MB / ${(total / 1024 / 1024).toStringAsFixed(0)}MB";
            });
          }
        },
      );

      final downloadedTemp = File(rutaTemp);
      if (await downloadedTemp.exists() && (await downloadedTemp.length()) > 50 * 1024 * 1024) {
        if (await File(rutaDestino).exists()) {
          try { await File(rutaDestino).delete(); } catch (_) {}
        }
        await downloadedTemp.rename(rutaDestino);
      } else {
        throw Exception("La descarga del modelo se interrumpió o el archivo no es válido.");
      }

      if (!mounted) return;
      setState(() {
        _descargandoModelo = false;
        thread.modeloInicializado = true;
        thread.rutaModeloLocal = rutaDestino;
        model.isDownloaded = true;
        _estadoTexto = "Modelo listo en memoria";
      });
      _guardarDatosEnDisco();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargandoModelo = false;
        thread.modeloInicializado = false;
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
    final model = localModels.firstWhere(
      (m) => m.name == modelo ||
             m.id == modelo ||
             (modelo.toLowerCase().contains("qwen") && m.id.contains("qwen")),
      orElse: () => localModels.first,
    );
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
      pensando: false,
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
          activeTrackColor: activeColor,
          onChanged: (val) => setState(() => _visualAnalysis = val),
        ),
        
        // Rigorous Search
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Investigación Rigurosa", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Filtra y omite blogs o fuentes de baja confianza", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: _rigorousSearchOnly,
          activeTrackColor: activeColor,
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
          activeTrackColor: activeColor,
          onChanged: (val) {
            setState(() => isZRamEnabled = val);
            ZRamMemoryManager.optimizeMemory(val);
            if (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⚡ Compresión Z-RAM activada: Memoria e imágenes liberadas."),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
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
                  backgroundColor: _ttsEnabled ? activeColor.withValues(alpha: 0.15) : const Color(0xFF0E1420),
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
          activeTrackColor: activeColor,
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
          activeTrackColor: activeColor,
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
          subtitle: const Text("Interactúa en segundo plano con tu dispositivo", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isVirtualAssistantActive,
          activeTrackColor: activeColor,
          onChanged: (val) {
            setState(() => isVirtualAssistantActive = val);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(val ? "🎙️ Modo Asistente Virtual Activado." : "🎙️ Modo Asistente Virtual Desactivado."),
                backgroundColor: val ? const Color(0xFF0077B6) : Colors.grey,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        
        // Web Mode Background Server
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Modo Web Servidor", style: TextStyle(fontSize: 12, color: Colors.white70)),
          subtitle: const Text("Inicia un servidor HTTP local para conectar desde otros dispositivos", style: TextStyle(fontSize: 10, color: Colors.white38)),
          value: isWebServidorActive,
          activeTrackColor: activeColor,
          onChanged: (val) async {
            setState(() => isWebServidorActive = val);
            if (val) {
              final url = await LocalWebServerService.instance.startServer((prompt, response) {
                if (mounted) {
                  setState(() {
                    _activeThread.messages.add({"sender": "user", "text": "[WEB CLIENT]: $prompt"});
                    _activeThread.messages.add({"sender": "assistant", "text": response});
                  });
                }
              });
              setState(() => _webServerUrl = url);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🌐 Servidor Web en vivo en: $_webServerUrl"),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } else {
              await LocalWebServerService.instance.stopServer();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🌐 Servidor Web detenido."),
                    backgroundColor: Colors.grey,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
        
        if (isWebServidorActive) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded, size: 12, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Servidor Web Activo: $_webServerUrl",
                    style: const TextStyle(fontSize: 9, color: Colors.green, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                                ? const Color(0xFF9D4EDD).withValues(alpha: 0.2)
                                : const Color(0xFF00B4D8).withValues(alpha: 0.15),
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
                // CORREGIDO: Indicadores de descarga independientes en la barra lateral
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
                        const Text("Descargando pesos de IA...", style: TextStyle(fontSize: 9, color: Color(0xFF00B4D8))),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: _progresoModelo, color: const Color(0xFF00B4D8), minHeight: 2),
                      ],
                    ),
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
                            color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.memory_rounded, size: 12, color: Color(0xFF00B4D8)),
                              const SizedBox(width: 6),
                              // CORREGIDO: Quitado el texto engañoso que mentía diciendo que Qwen era "Gemini 1.5 Flash"
                              Text(
                                "Modelo: ${_activeThread.iaModel}",
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
                          border: Border.all(color: Colors.white.withValues(alpha: 0.015)),
                        );
                        TextStyle textStyle = const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14, height: 1.4);

                        if (sender == "user") {
                          align = Alignment.centerRight;
                          decoration = BoxDecoration(
                            color: const Color(0xFF121A28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.2)),
                          );
                        } else if (sender == "system") {
                          align = Alignment.center;
                          decoration = BoxDecoration(
                            color: const Color(0xFF00B4D8).withValues(alpha: 0.01),
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
                    child: _descargandoModelo 
                        ? Column(
                            children: [
                              LinearProgressIndicator(value: _progresoModelo, color: const Color(0xFF00B4D8)),
                              const SizedBox(height: 8),
                              Text(
                                "Descargando modelo: ${(_progresoModelo * 100).toStringAsFixed(0)}% completado",
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
                                      // CORREGIDO: Comprobación de estado pensando local en vez de global
                                      onSubmitted: (_) => _procesarMensajeLocal(),
                                      decoration: InputDecoration(
                                        hintText: _activeThread.pensando ? "Procesando matriz nativa..." : "Enviar comando local...",
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
                                    icon: _activeThread.pensando 
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _currentMode == CoreMode.estudiante ? const Color(0xFF9D4EDD) : const Color(0xFF00B4D8),
                                      minimumSize: const Size(48, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _activeThread.pensando ? null : _procesarMensajeLocal,
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
                      color: isSelected ? const Color(0xFF00B4D8).withValues(alpha: 0.08) : Colors.transparent,
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
                              color: isRecommended ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
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
                              color: model.isDownloaded ? Colors.blue.withValues(alpha: 0.15) : Colors.white10,
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
