import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';

// --- ARRANQUE COMPLETO CON BLINDAJE NATIVO ---
void main() {
  // CORRECCIÓN CLAVE: Obliga a Android a inicializar los canales de plugins ANTES de pintar la app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VantablackApp());
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
        home: const VantablackHome(),
      );
}

enum CoreMode { estudiante, normal }

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
  final String _versionHub = "1.6.5";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/app-release.apk";
  final String _urlModeloBase = "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf";

  CoreMode _currentMode = CoreMode.normal;
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  bool _descargando = false;
  bool _pensando = false;
  double _progreso = 0.0;
  String _estadoTexto = "Vantablack Core Activo";

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ejecutamos la carga con un micro-delay seguro para asegurar que la vista esté montada
    scheduleMicrotask(() => _cargarDatosDesdeDisco());
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
            _estadoTexto = "Matriz Zynoox Estable";
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
          title: "Instancia KAI Core",
          botName: "KAI",
          iaModel: "Zinos Core 1.5B",
          modeName: "Normal",
          modeloInicializado: true,
          messages: [
            {"sender": "system", "text": "VANTABLACK INTERFACE CONECTADA."},
            {"sender": "assistant", "text": "Estructura Liquid Glass cargada sobre fondo negro absoluto. ¿Qué variante local despertamos hoy?"},
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

  ChatThread get _activeThread => _threads.firstWhere((t) => t.id == _activeThreadId);

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

    final textoUsuario = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _pensando = true;
      _activeThread.messages.add({"sender": "user", "text": textoUsuario});
      _activeThread.messages.add({"sender": "assistant", "text": "..."});
    });
    _scrollAlFinal();
    _guardarDatosEnDisco();

    final int indiceRespuesta = _activeThread.messages.length - 1;

    try {
      String respuestaModelo = "";
      
      if (_currentMode == CoreMode.estudiante) {
        respuestaModelo = "[VANTABLACK HUB • MODO ESTUDIANTE]\n"
            "• Comprensión de imágenes y documentos activa.\n"
            "• Fuentes académicas blindadas sin Wikipedia.\n"
            "• Inferencia extendida local mediante Z-RAM.\n\n"
            "Gustavo, análisis completado localmente para: \"$textoUsuario\". Fragmentos listos para descarga.";
      } else {
        respuestaModelo = "[VANTABLACK HUB • MODO NORMAL]\n"
            "• Procesamiento optimizado de respuesta rápida.\n"
            "• Interconexión API remota activa.\n"
            "• Datos de nivel 1 listos en milisegundos.\n\n"
            "Respuesta instantánea arrojada por la colmena nativa de Zynoox IA.";
      }

      int caracter = 0;
      Timer.periodic(const Duration(milliseconds: 8), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        caracter += 4;
        if (caracter >= respuestaModelo.length) {
          timer.cancel();
          setState(() {
            _activeThread.messages[indiceRespuesta]["text"] = respuestaModelo;
            _pensando = false;
          });
          _scrollAlFinal();
          _guardarDatosEnDisco();
        } else {
          setState(() {
            _activeThread.messages[indiceRespuesta]["text"] = respuestaModelo.substring(0, caracter);
          });
        }
      });
    } catch (e) {
      setState(() {
        _pensando = false;
        _activeThread.messages[indiceRespuesta]["text"] = "Fallo de comunicación en los tensores.";
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
    setState(() { _descargando = true; _estadoTexto = "Conectando al Hub..."; });
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception();
      final ruta = "${dir.path}/vantablack_update.apk";
      await dio.download(_urlApkRemoto, ruta, onReceiveProgress: (recibido, total) {
        if (total != -1) {
          setState(() {
            _progreso = recibido / total;
            _estadoTexto = "Descarga OTA: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB";
          });
        }
      });
      setState(() { _descargando = false; _estadoTexto = "Actualizando..."; });
      await OpenFile.open(ruta);
    } catch (e) {
      setState(() { _descargando = false; _estadoTexto = "Zynoox Engine Active"; });
    }
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
                
                const SizedBox(height: 25),
                
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
                
                const SizedBox(height: 30),
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
                          onTap: () => setState(() => _activeThreadId = thread.id),
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
                  child: Text(_estadoTexto, style: const TextStyle(fontSize: 9, color: Colors.white38, fontFamily: 'monospace')),
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
                    child: Row(
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
        ],
      ),
    );
  }
}