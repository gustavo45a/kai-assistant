import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget de botón con acabado Apple Glass de alta gama (iOS 18 / visionOS / macOS):
/// - Geometría Squircle con esquinas continuas.
/// - Vidrio esmerilado con desenfoque `BackdropFilter` (sigma 18).
/// - Luz perimetral interior con gradiente especular (highlight superior e iluminación de bisel).
/// - Sombra de profundidad difusa y aura de resplandor dinámico.
/// - Microinteracción táctil con física de resorte (Spring physics) en `onTapDown` / `onTapUp`.
class AppleGlassIconButton extends StatefulWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? activeGlowColor;
  final Color? highlightColor;
  final bool isActive;
  final bool isDestructive;
  final bool isPulsing;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? customBorder;

  const AppleGlassIconButton({
    super.key,
    this.icon,
    this.child,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.size = 40.0,
    this.iconSize = 18.0,
    this.borderRadius = 14.0,
    this.iconColor,
    this.backgroundColor,
    this.activeGlowColor,
    this.highlightColor,
    this.isActive = false,
    this.isDestructive = false,
    this.isPulsing = false,
    this.padding,
    this.customBorder,
  });

  @override
  State<AppleGlassIconButton> createState() => _AppleGlassIconButtonState();
}

class _AppleGlassIconButtonState extends State<AppleGlassIconButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppleGlassIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;
    final Color effectiveBaseColor = widget.backgroundColor ??
        (widget.isDestructive
            ? const Color(0xFF38141B).withValues(alpha: 0.65)
            : const Color(0xFF181A24).withValues(alpha: 0.58));

    final Color effectiveGlowColor = widget.activeGlowColor ??
        (widget.isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF00E5FF));

    final Color effectiveIconColor = widget.iconColor ??
        (widget.isActive
            ? effectiveGlowColor
            : (widget.isDestructive
                ? const Color(0xFFFF453A)
                : (_isHovered ? Colors.white : const Color(0xFFE2E8F0))));

    Widget buttonContent = AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseController]),
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final pulse = widget.isPulsing ? _pulseController.value : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                // Sombra de profundidad difusa
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                // Aura de resplandor activo / pulsante
                if (widget.isActive || widget.isPulsing)
                  BoxShadow(
                    color: effectiveGlowColor.withValues(
                      alpha: widget.isPulsing ? (0.25 + pulse * 0.35) : 0.28,
                    ),
                    blurRadius: widget.isPulsing ? (10 + pulse * 8) : 12,
                    spreadRadius: widget.isPulsing ? (pulse * 2) : 0.5,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: widget.padding ?? EdgeInsets.all(widget.size * 0.22),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? effectiveBaseColor.withValues(alpha: (effectiveBaseColor.a + 0.12).clamp(0.0, 1.0))
                        : effectiveBaseColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    // Luz de borde perimetral (Highlight superior, bisel inferior)
                    border: widget.customBorder ??
                        Border.all(
                          color: widget.isActive
                              ? effectiveGlowColor.withValues(alpha: 0.65)
                              : (_isHovered
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : (widget.highlightColor ?? Colors.white.withValues(alpha: 0.18))),
                          width: widget.isActive ? 1.3 : 0.9,
                        ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: widget.isActive ? 0.22 : 0.10),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Center(
                    child: widget.child ??
                        Icon(
                          widget.icon,
                          size: widget.iconSize,
                          color: effectiveIconColor,
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      buttonContent = Tooltip(
        message: widget.tooltip!,
        textStyle: const TextStyle(fontSize: 11, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF1E202B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: buttonContent,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? _handleTapDown : null,
        onTapUp: enabled ? _handleTapUp : null,
        onTapCancel: enabled ? _handleTapCancel : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: buttonContent,
      ),
    );
  }
}

/// Botón cápsula / píldora con acabado Apple Glass para acciones prominentes (e.g. "+ Nuevo Chat").
class AppleGlassCapsuleButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final bool isExpanded;

  const AppleGlassCapsuleButton({
    super.key,
    this.icon,
    required this.label,
    this.onTap,
    this.primaryColor,
    this.backgroundColor,
    this.height = 42.0,
    this.borderRadius = 20.0,
    this.isExpanded = true,
  });

  @override
  State<AppleGlassCapsuleButton> createState() => _AppleGlassCapsuleButtonState();
}

class _AppleGlassCapsuleButtonState extends State<AppleGlassCapsuleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.primaryColor ?? const Color(0xFF00E5FF);
    final Color bg = widget.backgroundColor ?? const Color(0xFF1E212E).withValues(alpha: 0.65);

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.20),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isHovered ? bg.withValues(alpha: (bg.a + 0.15).clamp(0.0, 1.0)) : bg,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: _isHovered
                          ? accent.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.18),
                      width: 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.18),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Row(
                    mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 17, color: accent),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

/// Selector segmentado estilo Apple (iOS Segmented Control) con reflejos de vidrio y física de resorte.
class AppleGlassSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final Map<T, Widget> children;
  final ValueChanged<T> onValueChanged;
  final Color? activeColor;
  final double height;

  const AppleGlassSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.children,
    required this.onValueChanged,
    this.activeColor,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveActiveColor = activeColor ?? const Color(0xFF00E5FF);

    return Container(
      height: height,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF141620).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children.entries.map((entry) {
              final isSelected = entry.key == selectedValue;

              return GestureDetector(
                onTap: () => onValueChanged(entry.key),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveActiveColor.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? effectiveActiveColor.withValues(alpha: 0.75)
                          : Colors.transparent,
                      width: 0.9,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: effectiveActiveColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          size: 13,
                          color: isSelected ? effectiveActiveColor : const Color(0xFF94A3B8),
                        ),
                        child: entry.value,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Contenedor de píldora de vidrio Apple para chips de sugerencias o badges interactivos.
class AppleGlassPill extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppleGlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 16.0,
  });

  @override
  State<AppleGlassPill> createState() => _AppleGlassPillState();
}

class _AppleGlassPillState extends State<AppleGlassPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutQuad,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? const Color(0xFF1B1D27).withValues(alpha: 0.65);
    final border = widget.borderColor ??
        (_isHovered
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.14));

    Widget content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: _isHovered ? bg.withValues(alpha: (bg.a + 0.15).clamp(0.0, 1.0)) : bg,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: border, width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );

    if (widget.onTap == null) return content;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}
