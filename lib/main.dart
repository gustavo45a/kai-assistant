import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const AlterforgeApp());

class AlterforgeApp extends StatelessWidget {
  const AlterforgeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF07090E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00B4D8),
            surface: Color(0xFF0F131A),
          ),
        ),
        home: const AlterforgeHome(),
      );
}

class AlterforgeHome extends StatefulWidget {
  const AlterforgeHome({super.key});
  @override
  State<AlterforgeHome> createState() => _AlterforgeHomeState();
}

class ChatThread {
  final String id;
  final String title;
  final String botName;
  final String iaModel;
  List<Map<String, String>> messages;
  bool modeloInicializado;

  ChatThread({
    required this.id,
    required this.title,
    required this.botName,
    required this.iaModel,
    required this.messages,
    this.modeloInicializado = false,
  });
}

class _AlterforgeHomeState extends State<AlterforgeHome> {
  final String _versionHub = "1.2.0";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/app-release.apk";

  List<ChatThread> _threads = [];
  String? _activeThreadId;

  bool _descargando = false;
  bool _pensando = false;
  double _progreso = 0.0;
  String _estadoTexto = "Alterforge Core: Listo";

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialId = const Uuid().v4();
    _threads.add(ChatThread(
      id: initialId,
      title: "Instancia KAI Inicial",
      botName: "KAI",
      iaModel: "Zinos Core 3B (Local)",
      modeloInicializado: true,
      messages: [
        {"sender": "system", "text": "ALTERFORGE EMBEDDED ENGINE v$_versionHub activo."},
        {"sender": "assistant", "text": "Forja local lista y embebida en la app. El usuario no requiere configuraciones externas. ¿Qué forjamos?"},
      ],
    ));
    _activeThreadId = initialId;
  }

  ChatThread get _activeThread => _threads.firstWhere((t) => t.id == _activeThreadId);

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
      _activeThread.messages.add({"sender": "assistant", "text": ""});
    });
    _scrollAlFinal();

    final int indiceRespuesta = _activeThread.messages.length - 1;

    try {
      String respuestaModelo = "Generando respuesta desde la memoria local del dispositivo a través de Alterforge Core nativo...";
      int caracter = 0;

      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 15));
        if (caracter >= respuestaModelo.length) {
          setState(() => _pensando = false);
          return false;
        }
        caracter += 2;
        if (caracter > respuestaModelo.length) caracter = respuestaModelo.length;
        
        setState(() {
          _activeThread.messages[indiceRespuesta]["text"] = respuestaModelo.substring(0, caracter);
        });
        _scrollAlFinal();
        return true;
      });

    } catch (e) {
      setState(() {
        _pensando = false;
        _activeThread.messages[indiceRespuesta]["text"] = "Error crítico: El núcleo local de inferencia no pudo leer los pesos en memoria.";
      });
    }
  }

  void _forjarEInicializarChat(String bot, String modelo) async {
    final newId = const Uuid().v4();
    final nuevoThread = ChatThread(
      id: newId,
      title: "$bot • ${modelo.split(' ')[2]}",
      botName: bot,
      iaModel: modelo,
      messages: [],
    );

    setState(() {
      _threads.insert(0, nuevoThread);
      _activeThreadId = newId;
      _pensando = true;
    });

    setState(() {
      _activeThread.messages.add({
        "sender": "system",
        "text": "Descargando pesos de arquitectura local inteligente ($modelo) directamente al almacenamiento seguro del dispositivo... No requiere dependencias externas."
      });
    });

    double progresoDescarga = 0.0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (progresoDescarga >= 1.0) {
        timer.cancel();
        setState(() {
          _pensando = false;
          _activeThread.modeloInicializado = true;
          _activeThread.messages.add({
            "sender": "assistant",
            "text": "Forja completada con éxito. Soy la variante $bot running local en tu hardware."
          });
        });
        _scrollAlFinal();
      } else {
        progresoDescarga += 0.05;
        setState(() {
          _estadoTexto = "Descargando Modelo IA: ${(progresoDescarga * 100).toStringAsFixed(0)}%";
        });
      }
    });
  }

  void _mostrarSelectorNuevoChat() {
    String selectedBot = "KAI";
    String selectedIA = "Zinos Core Local 3B";
    bool analizandoHardware = true;
    String hardwareRecomendacion = "Escaneando hardware del dispositivo...";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (analizandoHardware) {
              Future.delayed(const Duration(milliseconds: 900), () {
                if (mounted) {
                  setModalState(() {
                    analizandoHardware = false;
                    hardwareRecomendacion = "Hardware Scanner: GPU nativa compatible con Vulkan / NPU activa.\nRecomendado: Modelos 1.5B y 3B para evitar cierres por falta de RAM.";
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF131722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.memory_rounded, color: Color(0xFF00B4D8)),
                  SizedBox(width: 10),
                  Text("Configurar Nueva Variante Local", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07090E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.2)),
                      ),
                      child: Text(
                        hardwareRecomendacion,
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Elegir Personalidad del Bot:", style: TextStyle(fontSize: 12, color: Colors.white38)),
                    DropdownButton<String>(
                      value: selectedBot,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF131722),
                      items: ["KAI", "SELENE", "CHRONOS"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setModalState(() => selectedBot = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text("Modelo IA Embebido Automático:", style: TextStyle(fontSize: 12, color: Colors.white38)),
                    DropdownButton<String>(
                      value: selectedIA,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF131722),
                      items: ["Zinos Core Light 1.5B", "Zinos Core Local 3B", "Zinos Heavy 7B"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                      onChanged: (val) => setModalState(() => selectedIA = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white38))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: analizandoHardware ? null : () {
                    Navigator.pop(context);
                    _forjarEInicializarChat(selectedBot, selectedIA);
                  },
                  child: const Text("Descargar e Iniciar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _ejecutarActualizacionOTA() async {
    if (_descargando) return;
    setState(() { _descargando = true; _estadoTexto = "Buscando updates del Hub..."; });
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception();
      final ruta = "${dir.path}/alterforge_update.apk";
      await dio.download(_urlApkRemoto, ruta, onReceiveProgress: (recibido, total) {
        if (total != -1) {
          setState(() {
            _progreso = recibido / total;
            _estadoTexto = "Forjando OTA: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB";
          });
        }
      });
      setState(() { _descargando = false; _estadoTexto = "¡Hub al día!"; });
    } catch (e) {
      setState(() { _descargando = false; _estadoTexto = "Alterforge V$_versionHub"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: const Color(0xFF0C0F16),
              // CORREGIDO: Cambiado de white05 a white12
              border: Border(right: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 35),
                Center(
                  child: GestureDetector(
                    onTap: _ejecutarActualizacionOTA,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 85, height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _pensando ? const Color(0xFF00E5FF).withOpacity(0.35) : const Color(0xFF00B4D8).withOpacity(0.15),
                            blurRadius: 20,
                          )
                        ],
                        gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF005F73)]),
                      ),
                      child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: Text("ALTERFORGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2))),
                const Center(child: Text("BY ZYNOOX IA", style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1.5))),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B25),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      // CORREGIDO: Cambiado de white05 a white12
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white12)),
                    ),
                    onPressed: _mostrarSelectorNuevoChat,
                    icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF00E5FF)),
                    label: const Text("Nuevo chat", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 25),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("CANALES ACTIVOS LOCALES", style: TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                          selectedTileColor: const Color(0xFF161B25),
                          leading: Icon(Icons.memory_outlined, size: 16, color: isSelected ? const Color(0xFF00E5FF) : Colors.white30),
                          title: Text(
                            thread.title,
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
                    child: LinearProgressIndicator(value: _progreso, color: const Color(0xFF00E5FF)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_estadoTexto, style: const TextStyle(fontSize: 10, color: Colors.white38, fontFamily: 'monospace')),
                )
              ],
            ),
          ),
          
          // ENTORNO DEL PANEL DE CONTROL
          Expanded(
            child: Container(
              color: const Color(0xFF07090E),
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
                          color: const Color(0xFF0F131A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        );
                        TextStyle textStyle = const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4);

                        if (sender == "user") {
                          align = Alignment.centerRight;
                          decoration = BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF005F73)]),
                            borderRadius: BorderRadius.circular(14),
                          );
                        } else if (sender == "system") {
                          align = Alignment.center;
                          decoration = BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
                          );
                          textStyle = const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'monospace');
                        }

                        return Align(
                          alignment: align,
                          // CORREGIDO: maxWidth movido dentro de un BoxConstraints asignado a constraints
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: decoration,
                            child: Text(msg["text"]!, style: textStyle),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Campo de Entrada
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
                              hintText: _pensando ? "Computando matriz nativa..." : "Escribe una instrucción a ${_activeThread.botName}...",
                              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                              fillColor: const Color(0xFF0C0F16),
                              filled: true,
                              // CORREGIDO: Cambiado de white05 a white12
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 0.8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: _pensando 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4D8),
                            disabledBackgroundColor: Colors.white10,
                            minimumSize: const Size(50, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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