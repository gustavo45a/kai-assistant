import 'dart:io';
import 'package:flutter/material.dart';

/// Fondo estático de alto rendimiento para móvil (Zero-Ticker / Zero-GPU Overhead):
/// - Reemplaza los AnimationControllers continuos y el BackdropFilter de 90px por
///   un BoxDecoration optimizado con gradientes radiales estáticos compilados en GPU.
/// - Cero uso de CPU / GPU cuando la aplicación está inactiva (idle).
class DynamicMulticolorBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? customAccentColor;
  final String? customBgImagePath;

  const DynamicMulticolorBackground({
    super.key,
    required this.child,
    this.opacity = 0.85,
    this.customAccentColor,
    this.customBgImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCustomImage = customBgImagePath != null &&
        customBgImagePath!.isNotEmpty &&
        File(customBgImagePath!).existsSync();

    final Color accentCyan = customAccentColor ?? const Color(0xFF00E5FF);
    const Color deepPurple = Color(0xFF7928CA);
    const Color darkBase = Color(0xFF08090C);

    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. BASE ESTÁTICA CON GRADIENTES RADIALES COMPILADOS (Cero Tickers / Cero Shaders pesados)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: darkBase,
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.6),
                  radius: 1.2,
                  colors: [
                    accentCyan.withValues(alpha: 0.12 * opacity),
                    deepPurple.withValues(alpha: 0.08 * opacity),
                    darkBase,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 1.2. Resplandor ambiental secundario estático inferior
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, 0.7),
                  radius: 1.0,
                  colors: [
                    deepPurple.withValues(alpha: 0.09 * opacity),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 1.5. Imagen personalizada si está configurada
          if (hasCustomImage)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.file(
                  File(customBgImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // 2. CONTENIDO PRINCIPAL AISLADO EN SU PROPIO REPAINT BOUNDARY
          Positioned.fill(
            child: RepaintBoundary(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
