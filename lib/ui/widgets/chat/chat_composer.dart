import 'package:flutter/material.dart';
import 'chat_style.dart';

/// Caja de texto inferior estilo Claude/Gemini.
///
/// Escucha el [controller] por su cuenta, así que escribir solo redibuja este
/// widget y no toda la pantalla de chat (antes cada tecla reconstruía todo).
class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final ChatColors colors;
  final bool isGenerating;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onMic;
  final VoidCallback onAttach;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.colors,
    required this.isGenerating,
    required this.isListening,
    required this.onSend,
    required this.onStop,
    required this.onMic,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: colors.text, fontSize: 16, height: 1.4),
            cursorColor: colors.accent,
            decoration: InputDecoration(
              hintText: isListening ? 'Te escucho…' : 'Pregúntale a Kai',
              hintStyle: TextStyle(color: colors.muted, fontSize: 16),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 6, right: 8),
            ),
            onSubmitted: (_) {
              if (!isGenerating) onSend();
            },
          ),
          Row(
            children: [
              _RoundIcon(
                icon: Icons.add_rounded,
                tooltip: 'Herramientas, fotos y documentos',
                color: colors.text,
                background: colors.surfaceHigh,
                onTap: isGenerating ? null : onAttach,
              ),
              const Spacer(),
              _RoundIcon(
                icon: isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                tooltip: isListening ? 'Detener dictado' : 'Dictar por voz',
                color: isListening ? Colors.redAccent : colors.muted,
                background: Colors.transparent,
                onTap: isGenerating ? null : onMic,
              ),
              const SizedBox(width: 4),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;
                  if (isGenerating) {
                    return _RoundIcon(
                      icon: Icons.stop_rounded,
                      tooltip: 'Detener respuesta',
                      color: colors.background,
                      background: colors.text,
                      onTap: onStop,
                    );
                  }
                  return _RoundIcon(
                    icon: Icons.arrow_upward_rounded,
                    tooltip: 'Enviar',
                    color: hasText ? colors.background : colors.muted,
                    background: hasText ? colors.text : colors.surfaceHigh,
                    onTap: hasText ? onSend : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 22, color: onTap == null ? color.withValues(alpha: 0.4) : color),
          ),
        ),
      ),
    );
  }
}
