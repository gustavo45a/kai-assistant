import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../models/kai_persona.dart';
import '../../services/kai_sprite_service.dart';

/// Widget reactivo para mostrar el avatar / sprite dinámico de Kai con soporte
/// para carga desde almacenamiento local (`/sprites/kai_<emotion>.webp|png`),
/// transiciones animadas con [AnimatedSwitcher] y fallback visual elegante.
class KaiAvatarView extends StatefulWidget {
  final KaiEmotion emotion;
  final bool isThinking;
  final double size;
  final VoidCallback? onTap;
  final bool showBadge;
  final bool showLabel;
  final AppThemeData? theme;

  const KaiAvatarView({
    super.key,
    required this.emotion,
    this.isThinking = false,
    this.size = 40.0,
    this.onTap,
    this.showBadge = true,
    this.showLabel = false,
    this.theme,
  });

  @override
  State<KaiAvatarView> createState() => _KaiAvatarViewState();
}

class _KaiAvatarViewState extends State<KaiAvatarView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  File? _localSpriteFile;

  bool get _shouldPulse => widget.isThinking || widget.emotion == KaiEmotion.thinking;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
    }

    KaiSpriteService.instance.addListener(_onSpriteServiceUpdated);
    _checkLocalSpriteDisk();
  }

  void _onSpriteServiceUpdated() {
    if (mounted) {
      _checkLocalSpriteDisk();
    }
  }

  @override
  void didUpdateWidget(covariant KaiAvatarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _checkLocalSpriteDisk();
    }

    if (_shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    KaiSpriteService.instance.removeListener(_onSpriteServiceUpdated);
    _pulseController.dispose();
    super.dispose();
  }

  /// Busca el sprite en el almacenamiento local a través de KaiSpriteService.
  Future<void> _checkLocalSpriteDisk() async {
    try {
      final spritePath = await KaiSpriteService.instance.getSpritePath(widget.emotion);
      File? foundFile;
      if (spritePath != null) {
        final f = File(spritePath);
        if (await f.exists()) {
          foundFile = f;
        }
      }

      if (mounted) {
        setState(() {
          _localSpriteFile = foundFile;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localSpriteFile = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = widget.emotion.moodColor;

    Widget avatarCore = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('${widget.emotion.name}_${_localSpriteFile?.path ?? "fallback"}'),
        child: _buildAvatarBody(moodColor),
      ),
    );

    // Si está pensando o procesando, añadimos animación pulsante suave
    if (_shouldPulse) {
      avatarCore = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final double val = _pulseAnimation.value;
          return Transform.scale(
            scale: val,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: moodColor.withValues(alpha: (0.45 * val).clamp(0.0, 1.0)),
                    blurRadius: 12 * val,
                    spreadRadius: 2 * val,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: avatarCore,
      );
    }

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCore,
        if (widget.showBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: _buildEmotionBadge(moodColor),
          ),
      ],
    );

    if (widget.showLabel) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Kai",
                style: TextStyle(
                  color: widget.theme?.textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.size * 0.35,
                ),
              ),
              Text(
                widget.emotion.label,
                style: TextStyle(
                  color: moodColor,
                  fontSize: widget.size * 0.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _buildAvatarBody(Color moodColor) {
    if (_localSpriteFile != null && _localSpriteFile!.existsSync()) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: moodColor.withValues(alpha: 0.8), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: moodColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            _localSpriteFile!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackVectorAvatar(moodColor),
          ),
        ),
      );
    }

    return _buildFallbackVectorAvatar(moodColor);
  }

  /// Fallback elegante y estilizado cuando no existe sprite local descargado en disco.
  Widget _buildFallbackVectorAvatar(Color moodColor) {
    final double iconSize = widget.size * 0.52;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColor.withValues(alpha: 0.3),
            const Color(0xFF020408),
          ],
        ),
        border: Border.all(
          color: moodColor.withValues(alpha: 0.75),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.28),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.emotion.fallbackIcon,
          color: moodColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildEmotionBadge(Color moodColor) {
    final double badgeSize = (widget.size * 0.38).clamp(12.0, 18.0);

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF090D14),
        border: Border.all(color: moodColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: badgeSize * 0.45,
          height: badgeSize * 0.45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: moodColor,
          ),
        ),
      ),
    );
  }
}
