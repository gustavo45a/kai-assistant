import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class DynamicMulticolorBackground extends StatefulWidget {
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
  State<DynamicMulticolorBackground> createState() => _DynamicMulticolorBackgroundState();
}

class _DynamicMulticolorBackgroundState extends State<DynamicMulticolorBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _palette;
  late double _randomStartAngle;
  late double _speedMultiplier;

  // Paletas de colores multicolor vibrantes y futuristas
  static const List<List<Color>> _presetPalettes = [
    [Color(0xFF00B4D8), Color(0xFF7B2CBF), Color(0xFFFF007F), Color(0xFF00F0FF)], // Neon Cyberpunk
    [Color(0xFF00F5D4), Color(0xFF00B4D8), Color(0xFF3A0CA3), Color(0xFF7209B7)], // Aurora Boreal
    [Color(0xFFFF007F), Color(0xFFFF9500), Color(0xFF7928CA), Color(0xFF0070F3)], // Prism Flame
    [Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFF6366F1), Color(0xFF8B5CF6)], // Emerald Pulse
    [Color(0xFFFF0055), Color(0xFF7A00FF), Color(0xFF00E5FF), Color(0xFFFFB703)], // Sunset Synthwave
    [Color(0xFF9D4EDD), Color(0xFFFF007F), Color(0xFF00F5D4), Color(0xFF0077B6)], // Cosmic Plasma
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    
    // Elegir una paleta única y aleatoria al entrar a la app
    _palette = List.from(_presetPalettes[random.nextInt(_presetPalettes.length)]);
    if (widget.customAccentColor != null) {
      _palette[0] = widget.customAccentColor!;
    }
    
    _randomStartAngle = random.nextDouble() * 2 * math.pi;
    _speedMultiplier = 0.8 + random.nextDouble() * 0.4;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (14 / _speedMultiplier).round()),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant DynamicMulticolorBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customAccentColor != oldWidget.customAccentColor && widget.customAccentColor != null) {
      setState(() {
        _palette[0] = widget.customAccentColor!;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomImage = widget.customBgImagePath != null &&
        widget.customBgImagePath!.isNotEmpty &&
        File(widget.customBgImagePath!).existsSync();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final angle = _randomStartAngle + (value * 2 * math.pi);

        // Transición y rotación dinámica de gradientes multicolor
        final alignX1 = math.cos(angle);
        final alignY1 = math.sin(angle);
        final alignX2 = math.cos(angle + math.pi);
        final alignY2 = math.sin(angle + math.pi);

        // Desplazamiento dinámico HSL para rotación sutil de matiz
        final color1 = HSLColor.fromColor(_palette[0]).withHue((HSLColor.fromColor(_palette[0]).hue + (value * 40)) % 360).toColor();
        final color2 = HSLColor.fromColor(_palette[1]).withHue((HSLColor.fromColor(_palette[1]).hue + (value * 30)) % 360).toColor();
        final color3 = HSLColor.fromColor(_palette[2]).withHue((HSLColor.fromColor(_palette[2]).hue + (value * 50)) % 360).toColor();
        final color4 = HSLColor.fromColor(_palette[3]).withHue((HSLColor.fromColor(_palette[3]).hue + (value * 20)) % 360).toColor();

        return Stack(
          children: [
            // Capa 1: Base oscura
            Container(color: const Color(0xFF020408)),

            // Capa 1.5: Imagen personalizada de fondo si existe
            if (hasCustomImage)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: Image.file(
                    File(widget.customBgImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Capa 2: Gradiente multicolor animado
            Opacity(
              opacity: hasCustomImage ? widget.opacity * 0.5 : widget.opacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(alignX1, alignY1),
                    end: Alignment(alignX2, alignY2),
                    colors: [
                      color1.withValues(alpha: 0.45),
                      color2.withValues(alpha: 0.35),
                      color3.withValues(alpha: 0.40),
                      color4.withValues(alpha: 0.30),
                    ],
                    stops: const [0.0, 0.35, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // Capa 3: Esfera de luz flotante radial
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(math.sin(angle * 1.5) * 0.7, math.cos(angle * 1.5) * 0.7),
                      radius: 1.2,
                      colors: [
                        color3.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Capa 4: Contenido de la app
            widget.child,
          ],
        );
      },
    );
  }
}
