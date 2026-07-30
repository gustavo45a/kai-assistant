enum CoreMode { estudiante, normal }

class ChatThread {
  final String id;
  String title;
  String iaModel;
  final List<Map<String, String>> messages;
  bool modeloInicializado;
  String? rutaModeloLocal;
  bool pensando;

  ChatThread({
    required this.id,
    required this.title,
    required this.iaModel,
    required this.messages,
    this.modeloInicializado = false,
    this.rutaModeloLocal,
    this.pensando = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iaModel': iaModel,
        'messages': messages,
        'modeloInicializado': modeloInicializado,
        'rutaModeloLocal': rutaModeloLocal,
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        id: json['id'],
        title: json['title'],
        iaModel: json['iaModel'],
        messages: List<Map<String, String>>.from(
          (json['messages'] as List).map((item) => Map<String, String>.from(item)),
        ),
        modeloInicializado: json['modeloInicializado'] ?? false,
        rutaModeloLocal: json['rutaModeloLocal'],
        pensando: false,
      );
}
