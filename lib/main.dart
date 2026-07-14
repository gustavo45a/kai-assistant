import 'dart:io';
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

  ChatThread({
    required this.id,
    required this.title,
    required this.botName,
    required this.iaModel,
    required this.messages,
  });
}

class _AlterforgeHomeState extends State<AlterforgeHome> {
  final String _versionHub = "1.0.0";
  final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/app-release.apk";

  // Estructura de Hilos de Chat estilo Gemini
  List<ChatThread> _threads = [];
  String? _activeThreadId;

  bool _descargando = false;
  double _progreso = 0.0;
  String _estadoTexto = "Alterforge Core: Estable";

  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Creamos un hilo inicial por defecto
    final initialId = const Uuid().v4();
    _threads.add(ChatThread(
      id: initialId,
      title: "Sistema operativo Zinos",
      botName: "KAI",
      iaModel: "Zinos Core Local 3B",
      messages: [
        {"sender": "system", "text": "ALTERFORGE ENGINE v1.0.0. Núcleo Zynoox IA inicializado."},
        {"sender": "assistant", "text": "Variante KAI cargada (Modelo: Zinos Core Local 3B). Procesando localmente."},
      ],
    ));
    _activeThreadId = initialId;
  }

  ChatThread get _activeThread => _threads.firstWhere((t) => t.id == _activeThreadId);

  // --- ESCANEO NATIVO DE HARDWARE DE TU TABLET ---
  void _mostrarSelectorNuevoChat() {
    String selectedBot = "KAI";
    String selectedIA = "Zinos Core Light 1.5B";
    bool analizandoHardware = true;
    String hardwareRecomendacion = "Analizando especificaciones físicas...";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Simulación del escaneo de hardware local (CPU/NPU/RAM) al abrir el Modal
            if (analizandoHardware) {
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) {
                  setModalState(() {
                    analizandoHardware = false;
                    // Diagnóstico basado en el rendimiento típico de la arquitectura de la Tab
                    hardwareRecomendacion = "Scanner: 8GB RAM detectados / GPU Adreno activa.\n"
                        "Recomendado para tu hardware: Modelos de 1.5B a 3B parámetros para latencia cero.";
                    selectedIA = "Zinos Core Local 3B"; // Auto-selecciona el óptimo
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121620),
              title: const Text("⚙️ Forjar Nuevo Canal Inteligente"),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CONTENEDOR DE DIAGNÓSTICO DE HARDWARE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: analizandoHardware ? Colors.white.withOpacity(0.02) : const Color(0xFF07090E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: analizandoHardware ? Colors.white10 : const Color(0xFF00B4D8).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          if (analizandoHardware)
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B4D8)),
                            )
                          else
                            const Icon(Icons.developer_board, color: Color(0xFF00B4D8), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hardwareRecomendacion,
                              style: TextStyle(
                                fontSize: 12, 
                                color: analizandoHardware ? Colors.white38 : Colors.whitee7,
                                fontFamily: 'monospace'
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // SELECCIÓN DE VARIANTE/BOT
                    const Text("Elige la variante del Bot:", style: TextStyle(fontSize: 13, color: Colors.white70)),
                    DropdownButton<String>(
                      value: selectedBot,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF121620),
                      items: ["KAI", "SELENE", "CHRONOS"].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedBot = val!),
                    ),
                    const SizedBox(height: 16),
                    // SELECCIÓN DE MODELO LLM LOCAL
                    const Text("Asignar arquitectura IA local:", style: TextStyle(fontSize: 13, color: Colors.white70)),
                    DropdownButton<String>(
                      value: selectedIA,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF121620),
                      items: ["Zinos Core Light 1.5B", "Zinos Core Local 3B", "Zinos Heavy Pro 7B (Lento)"].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedIA = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6)),
                  onPressed: analizandoHardware ? null : () {
                    setState(() {
                      final newId = const Uuid().v4();
                      _threads.insert(0, ChatThread(
                        id: newId,
                        title: "Instancia $selectedBot (${selectedIA.split(' ')[2]})",
                        botName: selectedBot,
                        iaModel: selectedIA,
                        messages: [
                          {"sender": "system", "text": "Canal forjado con arquitectura $selectedIA."},
                          {"sender": "assistant", "text": "Hola, soy la variante $selectedBot. Sistema local listo para operar de forma privada."},
                        ],
                      ));
                      _activeThreadId = newId;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Forjar Chat"),
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
    setState(() {
      _descargando = true;
      _estadoTexto = "Escaneando nube Zynoox...";
    });
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Error I/O");
      final rutaInstalador = "${dir.path}/alterforge_update.apk";
      await dio.download(_urlApkRemoto, rutaInstalador, onReceiveProgress: (recibido, total) {
        if (total != -1) {
          setState(() {
            _progreso = recibido / total;
            _estadoTexto = "Forjando OTA: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB";
          });
        }
      });
      setState(() { _descargando = false; _estadoTexto = "¡OTA lista! Instala desde almacenamiento."; });
    } catch (e) {
      setState(() { _descargando = false; _estadoTexto = "Forja en V$_versionHub"; });
    }
  }

  void _enviarMensaje() {
    if (_chatController.text.trim().isEmpty) return;
    setState(() {
      _activeThread.messages.add({"sender": "user", "text": _chatController.text});
      _activeThread.messages.add({
        "sender": "assistant",
        "text": "[${_activeThread.botName} via ${_activeThread.iaModel}]: Computando respuesta en el procesador local..."
      });
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ==========================================
          // BARRA LATERAL ESTILO GEMINI (ALTERFORGE HUB)
          // ==========================================
          Container(
            width: 260,
            color: const Color(0xFF0F131A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Botón del Yunque Interno de Alterforge
                Center(
                  child: GestureDetector(
                    onTap: _ejecutarActualizacionOTA,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF00B4D8).withOpacity(0.2), blurRadius: 15)],
                        gradient: const LinearGradient(colors: [Color(0xFF90E0EF), Color(0xFF0096C7)]),
                      ),
                      child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 45),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text("ALTERFORGE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                ),
                const Center(
                  child: Text("BY ZYNOOX IA", style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1)),
                ),
                const SizedBox(height: 20),
                
                // BOTÓN: NUEVO CHAT (DISPARADOR DEL HARDWARE SCANNER)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2530),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _mostrarSelectorNuevoChat,
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF00B4D8)),
                    label: const Text("Nuevo chat", style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Recientes", style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                
                // LISTA DE HILOS ABIERTOS EN TU COMPILACIÓN
                Expanded(
                  child: ListView.builder(
                    itemCount: _threads.length,
                    itemBuilder: (context, index) {
                      final thread = _threads[index];
                      final isSelected = thread.id == _activeThreadId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF1E2530),
                          leading: Icon(Icons.chat_bubble_outline, size: 15, color: isSelected ? const Color(0xFF00B4D8) : Colors.white38),
                          title: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13),
                          ),
                          onTap: () => setState(() => _activeThreadId = thread.id),
                        ),
                      );
                    },
                  ),
                ),
                
                // Monitor del estado de descarga OTA inferior
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_estadoTexto, style: const TextStyle(fontSize: 10, color: Colors.white24)),
                )
              ],
            ),
          ),
          
          // ==========================================
          // ENTORNO DE CHAT ACTIVO
          // ==========================================
          Expanded(
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _activeThread.messages.length,
                      itemBuilder: (context, index) {
                        final msg = _activeThread.messages[index];
                        final sender = msg["sender"];
                        
                        Alignment align = Alignment.centerLeft;
                        Color bg = const Color(0xFF151922);
                        if (sender == "user") {
                          align = Alignment.centerRight;
                          bg = const Color(0xFF0077B6);
                        } else if (sender == "system") {
                          align = Alignment.center;
                          bg = Colors.transparent;
                        }

                        return Align(
                          alignment: align,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: sender == "system" ? Border.all(color: Colors.white10) : null,
                            ),
                            child: Text(
                              msg["text"]!,
                              style: TextStyle(
                                color: sender == "system" ? Colors.white38 : Colors.white,
                                fontSize: sender == "system" ? 11 : 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Entrada de texto principal
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: "Pregúntale a ${_activeThread.botName}...",
                              hintStyle: const TextStyle(color: Colors.white24),
                              fillColor: const Color(0xFF0F131A),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, color: Colors.white),
                          backgroundColor: const Color(0xFF005F73),
                          onPressed: _enviarMensaje,
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