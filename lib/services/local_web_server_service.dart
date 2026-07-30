import 'dart:io';
import '../models/chat_thread.dart';

class LocalWebServerService {
  static final LocalWebServerService instance = LocalWebServerService._internal();
  LocalWebServerService._internal();

  HttpServer? _server;
  String _serverIp = 'Buscando IP...';
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String get serverUrl => 'http://$_serverIp:8080';

  Future<void> startServer(List<ChatThread> Function() getThreads) async {
    if (_isRunning) return;

    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _serverIp = addr.address;
            break;
          }
        }
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _isRunning = true;

      _server!.listen((HttpRequest request) {
        request.response.headers.contentType = ContentType.html;
        
        final threads = getThreads();
        final sb = StringBuffer();
        sb.writeln("<!DOCTYPE html><html><head><title>Vantablack Hub Remote</title>");
        sb.writeln("<meta charset='utf-8'><style>body{background:#020408;color:#00B4D8;font-family:sans-serif;padding:20px;} .card{background:#090D14;padding:15px;margin-bottom:10px;border-radius:8px;border:1px solid #00B4D8;}</style></head><body>");
        sb.writeln("<h1>⚡ VANTABLACK LOCAL SERVER REMOTE</h1>");
        sb.writeln("<p>Conexión remota activa desde Galaxy Tab / Red Local.</p>");
        sb.writeln("<h2>Instancias de Chat Activas:</h2>");
        
        for (var t in threads) {
          sb.writeln("<div class='card'><h3>${t.title} (${t.iaModel})</h3>");
          sb.writeln("<p>Mensajes: ${t.messages.length}</p></div>");
        }
        
        sb.writeln("</body></html>");
        request.response.write(sb.toString());
        request.response.close();
      });
    } catch (e) {
      _isRunning = false;
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
    }
  }
}
