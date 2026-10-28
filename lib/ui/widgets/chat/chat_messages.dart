import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_style.dart';
import 'kai_markdown.dart';

/// Mensaje del usuario: burbuja discreta alineada a la derecha.
class UserMessageBubble extends StatelessWidget {
  final String text;
  final ChatColors colors;
  final double maxWidth;

  const UserMessageBubble({super.key, required this.text, required this.colors, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Mensaje copiado'), duration: Duration(seconds: 1)),
          );
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.only(top: 18, bottom: 6, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: colors.userBubble,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(text, style: TextStyle(color: colors.text, fontSize: 15, height: 1.45)),
        ),
      ),
    );
  }
}

/// Respuesta de Kai sin burbuja, a todo el ancho, con acciones debajo.
class AssistantMessageView extends StatelessWidget {
  final String text;
  final ChatColors colors;
  final bool isStreaming;
  final VoidCallback? onSpeak;

  const AssistantMessageView({
    super.key,
    required this.text,
    required this.colors,
    this.isStreaming = false,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final waiting = isStreaming && (text.isEmpty || text == '...');
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaiMark(colors: colors, size: 20),
          const SizedBox(height: 8),
          if (waiting)
            TypingIndicator(color: colors.muted)
          else
            KaiMarkdown(text: text, colors: colors),
          if (!isStreaming && text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _ActionIcon(
                  icon: Icons.copy_rounded,
                  tooltip: 'Copiar',
                  color: colors.muted,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Respuesta copiada'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                if (onSpeak != null)
                  _ActionIcon(icon: Icons.volume_up_rounded, tooltip: 'Leer en voz alta', color: colors.muted, onTap: onSpeak!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: color),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

/// Tres puntos que laten mientras Kai prepara la respuesta.
class TypingIndicator extends StatefulWidget {
  final Color color;

  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_controller.value - i * 0.18) % 1.0;
              final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.35 + 0.65 * t),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
