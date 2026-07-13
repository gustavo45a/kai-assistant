import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const ZinosApp());

class ZinosApp extends StatelessWidget {
  const ZinosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const ZinosHome(),
      );
}

class ZinosHome extends StatefulWidget {
  const ZinosHome({super.key});
  @override
  State<ZinosHome> createState() => _ZinosHomeState();
}

class _ZinosHomeState extends State<ZinosHome> {
  // CONFIGURACIÓN
  final String _versionActual = "1.0.0";
// Esta es la ruta directa a tu archivo en tu servidor gratuito de GitHub
final String _urlApkRemoto = "https://gustavo45a.github.io/kai-assistant/app-release.apk";
  bool _descargando = false;
  double _progreso = 0.0;
  String _estadoTexto = "Sistema operativo al día";

  Future<void> _ejecutarActualizacionNativa() async {
    setState(() {
      _descargando = true;
      _estadoTexto = "Buscando nueva versión en el servidor...";
    });

    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Error al acceder al almacenamiento");

      final rutaInstalador = "${dir.path}/zinos_update.apk";

      await dio.download(
        _urlApkRemoto,
        rutaInstalador,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            setState(() {
              _progreso = recibido / total;
              _estadoTexto = "Descargando: ${(recibido / 1024 / 1024).toStringAsFixed(1)} MB";
            });
          }
        },
      );

      setState(() {
        _descargando = false;
        _estadoTexto = "¡Descarga lista! Búscalo en tu carpeta de archivos.";
      });
    } catch (e) {
      setState(() {
        _descargando = false;
        _estadoTexto = "Error: No se pudo conectar con el servidor.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Orbe Apple Intelligence
              Container(
                width: 110, height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF5CCBFF), Color(0xFFE47CFF), Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.all_inclusive, color: Colors.white, size: 55),
              ),
              const SizedBox(height: 24),
              Text(
                "KAI OS — v$_versionActual",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _estadoTexto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_descargando)
                LinearProgressIndicator(
                  value: _progreso,
                  color: const Color(0xFF5CCBFF),
                  backgroundColor: Colors.white10,
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _ejecutarActualizacionNativa,
                  child: const Text("Buscar Actualizaciones OTA"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
