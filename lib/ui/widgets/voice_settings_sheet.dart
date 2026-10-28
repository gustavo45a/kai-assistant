import 'package:flutter/material.dart';
import '../../models/app_theme.dart';
import '../../models/kai_persona.dart';
import '../../services/device_profile.dart';
import '../../services/kai_tts_service.dart';
import '../../services/neural_tts_service.dart';
import 'chat/chat_style.dart';

/// Abre la hoja de ajustes de voz de Kai.
Future<void> showVoiceSettingsSheet(BuildContext context, AppThemeData theme) {
  NeuralTtsService.instance.init();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceSettingsSheet(theme: theme),
  );
}

class VoiceSettingsSheet extends StatelessWidget {
  final AppThemeData theme;

  const VoiceSettingsSheet({super.key, required this.theme});

  static const String _sample = '¡Hola! Soy Kai. Así sueno ahora. ¿Te gusta cómo hablo?';

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.of(theme);
    final tts = KaiTtsService.instance;
    final neural = NeuralTtsService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([tts, neural]),
      builder: (context, _) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: BoxDecoration(
            color: Color.lerp(colors.background, colors.text, 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Voz de Kai', style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Ahora: ${tts.activeVoiceLabel}',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _SwitchRow(
                  colors: colors,
                  title: 'Leer respuestas en voz alta',
                  value: tts.isEnabled,
                  onChanged: tts.setEnabled,
                ),
                _SwitchRow(
                  colors: colors,
                  title: 'Voz neuronal hiperrealista',
                  subtitle: 'Funciona sin internet. Si no hay una voz descargada, se usa la del sistema.',
                  value: tts.useNeural,
                  onChanged: (v) => tts.setUseNeural(v),
                ),
                const SizedBox(height: 8),
                Text('VOCES NEURONALES', style: TextStyle(color: colors.muted, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                const SizedBox(height: 8),
                for (final v in NeuralTtsService.voices) _VoiceTile(voice: v, colors: colors),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: tts.isSpeaking
                        ? tts.stop
                        : () {
                            if (!tts.isEnabled) tts.setEnabled(true);
                            tts.speakWithEmotion(_sample, KaiEmotion.happy);
                          },
                    icon: Icon(tts.isSpeaking ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(tts.isSpeaking ? 'Detener' : 'Probar voz', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final ChatColors colors;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.colors, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeTrackColor: colors.accent,
      title: Text(title, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: colors.muted, fontSize: 12.5)),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  final NeuralVoice voice;
  final ChatColors colors;

  const _VoiceTile({required this.voice, required this.colors});

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await NeuralTtsService.instance.download(voice);
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('No se pudo descargar la voz ${voice.name}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = NeuralTtsService.instance;
    final status = service.statusOf(voice.id);
    final selected = service.selectedVoiceId == voice.id;
    final recommended = service.recommendedVoice.id == voice.id;

    Widget trailing;
    switch (status) {
      case NeuralVoiceStatus.notDownloaded:
        trailing = TextButton(
          onPressed: () => _download(context),
          child: Text('Descargar · ${voice.sizeMb} MB', style: TextStyle(color: colors.accent, fontSize: 12.5)),
        );
        break;
      case NeuralVoiceStatus.downloading:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: service.progressOf(voice.id) > 0 ? service.progressOf(voice.id) : null,
                strokeWidth: 2.4,
                color: colors.accent,
              ),
            ),
            IconButton(
              tooltip: 'Cancelar',
              icon: Icon(Icons.close_rounded, color: colors.muted, size: 18),
              onPressed: () => service.cancelDownload(voice.id),
            ),
          ],
        );
        break;
      case NeuralVoiceStatus.installing:
        trailing = Text('Instalando…', style: TextStyle(color: colors.muted, fontSize: 12.5));
        break;
      case NeuralVoiceStatus.ready:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Icon(Icons.check_circle_rounded, color: colors.accent, size: 22)
            else
              TextButton(
                onPressed: () => service.selectVoice(voice.id),
                child: Text('Usar', style: TextStyle(color: colors.accent, fontSize: 12.5)),
              ),
            IconButton(
              tooltip: 'Eliminar voz',
              icon: Icon(Icons.delete_outline_rounded, color: colors.muted, size: 20),
              onPressed: () => service.deleteVoice(voice),
            ),
          ],
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 14, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: selected ? colors.surfaceHigh : colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${voice.name} · ${voice.accent}',
                        style: TextStyle(color: colors.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
                    if (recommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Recomendada', style: TextStyle(color: colors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  voice.lightweight && DeviceProfile.instance.isLowEnd
                      ? 'Calidad ${voice.quality.toLowerCase()} · ideal para tu equipo'
                      : 'Calidad ${voice.quality.toLowerCase()}',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
