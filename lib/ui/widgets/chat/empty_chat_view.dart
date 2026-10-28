import 'package:flutter/material.dart';
import 'chat_style.dart';

class ChatSuggestion {
  final IconData icon;
  final String title;
  final String prompt;

  const ChatSuggestion(this.icon, this.title, this.prompt);
}

/// Pantalla inicial de un chat vacío: saludo con degradado al estilo Gemini.
class EmptyChatView extends StatelessWidget {
  final String username;
  final ChatColors colors;
  final bool isEngineInitializing;
  final ValueChanged<String> onSuggestion;

  const EmptyChatView({
    super.key,
    required this.username,
    required this.colors,
    required this.isEngineInitializing,
    required this.onSuggestion,
  });

  static const List<ChatSuggestion> suggestions = [
    ChatSuggestion(Icons.code_rounded, 'Escribe código', 'Crea un script en Flutter que lea un archivo JSON'),
    ChatSuggestion(Icons.lightbulb_outline_rounded, 'Explícame algo', 'Explícame la arquitectura MVVM con un ejemplo sencillo'),
    ChatSuggestion(Icons.edit_note_rounded, 'Ayúdame a escribir', 'Ayúdame a escribir un correo formal para pedir una cita'),
    ChatSuggestion(Icons.school_outlined, 'Estudia conmigo', 'Hazme un resumen para estudiar las leyes de Newton'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName = username.trim().split(' ').first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 420;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => colors.brandGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    firstName.isEmpty ? 'Hola' : 'Hola, $firstName',
                    style: TextStyle(
                      fontSize: compact ? 30 : 38,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¿En qué puedo ayudarte hoy?',
                  style: TextStyle(
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    letterSpacing: -0.3,
                    color: colors.muted.withValues(alpha: 0.75),
                  ),
                ),
                if (isEngineInitializing) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: colors.accent),
                      ),
                      const SizedBox(width: 8),
                      Text('Preparando a Kai…', style: TextStyle(color: colors.muted, fontSize: 13)),
                    ],
                  ),
                ],
                SizedBox(height: compact ? 18 : 32),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in suggestions)
                      _SuggestionCard(
                        suggestion: s,
                        colors: colors,
                        width: constraints.maxWidth >= 560 ? 240 : (constraints.maxWidth - 58) / 2,
                        onTap: () => onSuggestion(s.prompt),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final ChatSuggestion suggestion;
  final ChatColors colors;
  final double width;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.colors, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(suggestion.icon, size: 20, color: colors.accent),
                const SizedBox(height: 10),
                Text(
                  suggestion.title,
                  style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12.5, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
