import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_style.dart';

enum _BlockType { paragraph, heading, bullet, numbered, code }

class _Block {
  final _BlockType type;
  final String text;
  final String? marker;
  final int level;

  const _Block(this.type, this.text, {this.marker, this.level = 0});
}

/// Renderizador ligero de Markdown para las respuestas de Kai: párrafos,
/// títulos, listas, bloques de código e inline **negrita**, *cursiva* y `código`.
/// Usa `Text.rich` (no `SelectableText`) para que la lista se desplace fluida.
class KaiMarkdown extends StatelessWidget {
  final String text;
  final ChatColors colors;
  final double fontSize;

  const KaiMarkdown({super.key, required this.text, required this.colors, this.fontSize = 15});

  static final RegExp _fence = RegExp(r'^\s*```');
  static final RegExp _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final RegExp _inline = RegExp(r'(\*\*[^*\n]+\*\*|`[^`\n]+`|\*[^*\s\n][^*\n]*\*)');

  static List<_Block> _parse(String source) {
    final blocks = <_Block>[];
    final lines = source.split('\n');
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(_Block(_BlockType.paragraph, paragraph.join('\n')));
        paragraph.clear();
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_fence.hasMatch(line)) {
        flushParagraph();
        final lang = line.trim().substring(3).trim();
        final code = <String>[];
        i++;
        // Un bloque sin cerrar (respuesta aún en streaming) se muestra igualmente.
        while (i < lines.length && !_fence.hasMatch(lines[i])) {
          code.add(lines[i]);
          i++;
        }
        blocks.add(_Block(_BlockType.code, code.join('\n'), marker: lang));
        continue;
      }
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        flushParagraph();
        blocks.add(_Block(_BlockType.heading, heading.group(2)!, level: heading.group(1)!.length));
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        blocks.add(_Block(_BlockType.bullet, bullet.group(1)!));
        continue;
      }
      final numbered = _numbered.firstMatch(line);
      if (numbered != null) {
        flushParagraph();
        blocks.add(_Block(_BlockType.numbered, numbered.group(2)!, marker: '${numbered.group(1)}.'));
        continue;
      }
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      paragraph.add(line);
    }
    flushParagraph();
    return blocks;
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final token = m.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(text: token.substring(2, token.length - 2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: base.fontSize! * 0.9,
            backgroundColor: colors.surfaceHigh,
          ),
        ));
      } else {
        spans.add(TextSpan(text: token.substring(1, token.length - 1), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: colors.text, fontSize: fontSize, height: 1.55);
    final blocks = _parse(text);
    final children = <Widget>[];

    for (final block in blocks) {
      switch (block.type) {
        case _BlockType.paragraph:
          children.add(Text.rich(TextSpan(style: base, children: _inlineSpans(block.text, base))));
          break;
        case _BlockType.heading:
          final size = block.level <= 1 ? fontSize + 5 : (block.level == 2 ? fontSize + 3 : fontSize + 1);
          final style = base.copyWith(fontSize: size, fontWeight: FontWeight.w700, height: 1.35);
          children.add(Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(TextSpan(style: style, children: _inlineSpans(block.text, style))),
          ));
          break;
        case _BlockType.bullet:
        case _BlockType.numbered:
          children.add(Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: block.type == _BlockType.bullet ? 18 : 24,
                  child: Text(block.type == _BlockType.bullet ? '•' : block.marker!, style: base.copyWith(color: colors.muted)),
                ),
                Expanded(child: Text.rich(TextSpan(style: base, children: _inlineSpans(block.text, base)))),
              ],
            ),
          ));
          break;
        case _BlockType.code:
          children.add(_CodeBlock(code: block.text, language: block.marker ?? '', colors: colors));
          break;
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          children[i],
        ],
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final ChatColors colors;

  const _CodeBlock({required this.code, required this.language, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.isEmpty ? 'código' : language,
                    style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 1)),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: colors.muted, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: Text(
              code,
              style: TextStyle(color: colors.text, fontFamily: 'monospace', fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
