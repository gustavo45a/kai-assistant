import 'package:flutter/material.dart';

class WindowsXPErrorDialog extends StatelessWidget {
  final String mensaje;
  final String titulo;

  const WindowsXPErrorDialog({
    super.key,
    required this.mensaje,
    this.titulo = "Error crítico - Vantablack Hub",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: Color(0xFFECE9D8),
        border: Border(
          top: BorderSide(color: Colors.white, width: 2),
          left: BorderSide(color: Colors.white, width: 2),
          right: BorderSide(color: Color(0xFF404040), width: 2),
          bottom: BorderSide(color: Color(0xFF404040), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BARRA DE TÍTULO DE WINDOWS XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0055EA), Color(0xFF0A246A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          titulo,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD42A00),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Center(
                      child: Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CUERPO DEL DIÁLOGO (CÍRCULO ROJO CON 'X' Y TEXTO DESCRIPTIVO)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // BOTÓN INFERIOR RETRO [ ACEPTAR ]
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECE9D8),
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                        left: BorderSide(color: Colors.white, width: 2),
                        right: BorderSide(color: Color(0xFF404040), width: 2),
                        bottom: BorderSide(color: Color(0xFF404040), width: 2),
                      ),
                    ),
                    child: const Text(
                      "Aceptar",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
