import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

/// Desenfoque de fondo opcional. `BackdropFilter` vuelve a muestrear todo lo que
/// hay detrás en cada frame, y con decenas de botones sobre una lista que se
/// desplaza era la principal causa de tirones; por eso está apagado por defecto.
class GlassBlur extends StatelessWidget {
  /// Permite reactivar el vidrio esmerilado globalmente (p. ej. en equipos potentes).
  static bool enabled = false;

  final double sigma;
  final Widget child;

  const GlassBlur({super.key, required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
