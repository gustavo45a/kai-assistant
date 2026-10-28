import 'package:flutter/material.dart';
import '../../../models/app_theme.dart';

/// Colores neutros del chat derivados del tema activo, al estilo de Claude/Gemini:
/// superficies planas y apenas elevadas, sin vidrio ni sombras.
class ChatColors {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color userBubble;
  final Color text;
  final Color muted;
  final Color divider;
  final Color accent;
  final Color accentSecondary;
  final Color codeBackground;

  const ChatColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.userBubble,
    required this.text,
    required this.muted,
    required this.divider,
    required this.accent,
    required this.accentSecondary,
    required this.codeBackground,
  });

  factory ChatColors.of(AppThemeData theme) {
    Color mix(double t) => Color.lerp(theme.backgroundColor, theme.textColor, t)!;
    return ChatColors(
      background: theme.backgroundColor,
      surface: mix(0.06),
      surfaceHigh: mix(0.10),
      userBubble: mix(0.12),
      text: theme.textColor,
      muted: theme.subtitleColor,
      divider: mix(0.12),
      accent: theme.primaryColor,
      accentSecondary: theme.secondaryColor,
      codeBackground: Color.lerp(theme.backgroundColor, Colors.black, 0.35)!,
    );
  }

  /// Degradado de la marca de Kai (saludo y logotipo).
  LinearGradient get brandGradient => LinearGradient(
        colors: [accent, accentSecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Logotipo estático de Kai: una chispa con el degradado del tema.
/// Sustituye al avatar animado en cada mensaje, que era costoso de redibujar.
class KaiMark extends StatelessWidget {
  final double size;
  final ChatColors colors;

  const KaiMark({super.key, required this.colors, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => colors.brandGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(Icons.auto_awesome, size: size, color: Colors.white),
    );
  }
}
