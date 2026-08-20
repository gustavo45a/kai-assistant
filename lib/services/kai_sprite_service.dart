import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/kai_persona.dart';

/// Servicio singleton para la gestión, almacenamiento y generación en segundo plano
/// de los sprites locales de Kai.
class KaiSpriteService extends ChangeNotifier {
  static final KaiSpriteService instance = KaiSpriteService._internal();
  KaiSpriteService._internal();

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  KaiEmotion? _currentGeneratingEmotion;
  String _generationStatusMessage = "Inactivo";

  bool get isGenerating => _isGenerating;
  double get generationProgress => _generationProgress;
  KaiEmotion? get currentGeneratingEmotion => _currentGeneratingEmotion;
  String get generationStatusMessage => _generationStatusMessage;

  /// Prompts visuales de referencia para cada estado emocional de Kai.
  static const Map<KaiEmotion, String> visualPrompts = {
    KaiEmotion.neutral:
        "Kai cyberpunk avatar portrait, soft aesthetic, gentle and calm friendly expression, subtle feline ear contours, neon cyan accents, dark vantablack background, high detail vector digital art.",
    KaiEmotion.happy:
        "Kai cyberpunk avatar portrait, soft aesthetic, joyful warm smiling expression, sparkling emerald green neon accents, cheerful playful demeanor, dark futuristic background, high detail.",
    KaiEmotion.thinking:
        "Kai cyberpunk avatar portrait, soft aesthetic, contemplative analytical thinking expression, looking slightly up, glowing amber gold neon glyphs, holographic code projections, dark background.",
    KaiEmotion.focused:
        "Kai cyberpunk avatar portrait, soft aesthetic, intense concentrated coding gaze, electric blue and vibrant cyan neon visor HUD reflections, terminal matrix data, dark background.",
    KaiEmotion.smug:
        "Kai cyberpunk avatar portrait, soft aesthetic, confident clever smirk, winking, sleek futuristic collar, glowing magenta violet neon accents, elite hacker vibe, dark background.",
  };

  /// Obtiene o crea el directorio de sprites en almacenamiento local de la app.
  Future<Directory> getSpriteDirectory() async {
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        baseDir = await getTemporaryDirectory();
      } catch (_) {
        baseDir = Directory('${Directory.systemTemp.path}/kai_app_data');
      }
    }
    final spriteDir = Directory('${baseDir.path}/sprites');
    if (!await spriteDir.exists()) {
      await spriteDir.create(recursive: true);
    }
    return spriteDir;
  }

  /// Verifica la existencia en disco de los 5 sprites soportados (.webp o .png).
  Future<Map<KaiEmotion, bool>> checkSpritesExist() async {
    final Map<KaiEmotion, bool> results = {};
    try {
      final dir = await getSpriteDirectory();
      for (final emotion in KaiEmotion.values) {
        final webpFile = File('${dir.path}/kai_${emotion.name}.webp');
        final pngFile = File('${dir.path}/kai_${emotion.name}.png');
        final jpgFile = File('${dir.path}/kai_${emotion.name}.jpg');
        final exists = (await webpFile.exists()) || (await pngFile.exists()) || (await jpgFile.exists());
        results[emotion] = exists;
      }
    } catch (_) {
      for (final emotion in KaiEmotion.values) {
        results[emotion] = false;
      }
    }
    return results;
  }

  /// Indica si todos los sprites de Kai están disponibles localmente.
  Future<bool> areAllSpritesGenerated() async {
    final status = await checkSpritesExist();
    return status.values.every((exists) => exists == true);
  }

  /// Retorna la ruta absoluta del archivo sprite para la emoción dada, si existe.
  Future<String?> getSpritePath(KaiEmotion emotion) async {
    try {
      final dir = await getSpriteDirectory();
      final extensions = ['webp', 'png', 'jpg'];
      for (final ext in extensions) {
        final file = File('${dir.path}/kai_${emotion.name}.$ext');
        if (await file.exists()) {
          return file.path;
        }
      }

      // Comprobar directorios secundarios
      final searchDirs = <Directory>[];
      try {
        searchDirs.add(await getTemporaryDirectory());
      } catch (_) {}
      try {
        searchDirs.add(await getApplicationSupportDirectory());
      } catch (_) {}

      for (final sDir in searchDirs) {
        for (final ext in extensions) {
          final f1 = File('${sDir.path}/sprites/kai_${emotion.name}.$ext');
          if (await f1.exists()) return f1.path;
          final f2 = File('${sDir.path}/kai_${emotion.name}.$ext');
          if (await f2.exists()) return f2.path;
        }
      }

      // Comprobar ruta raíz estándar si existe
      for (final ext in extensions) {
        final rootFile = File('/sprites/kai_${emotion.name}.$ext');
        if (await rootFile.exists()) return rootFile.path;
      }
    } catch (_) {}
    return null;
  }

  /// Guarda y persiste los bytes de una imagen de sprite en el directorio local.
  Future<File> saveSprite(KaiEmotion emotion, Uint8List imageBytes, {String extension = 'png'}) async {
    final dir = await getSpriteDirectory();
    final file = File('${dir.path}/kai_${emotion.name}.$extension');
    await file.writeAsBytes(imageBytes, flush: true);

    // Evict de cache de imagen si fue cargada previamente
    try {
      await FileImage(file).evict();
    } catch (_) {}

    notifyListeners();
    return file;
  }

  /// Elimina los sprites almacenados en disco.
  Future<void> deleteSprites() async {
    try {
      final dir = await getSpriteDirectory();
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        for (final entity in entities) {
          if (entity is File && entity.path.contains('kai_')) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Renderiza proceduralmente un sprite PNG de alta definición con estética cyberpunk
  /// y diseño distintivo para la emoción de Kai.
  Future<Uint8List> generateProceduralSpriteBytes(KaiEmotion emotion, {int width = 512, int height = 512}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    final double w = width.toDouble();
    final double h = height.toDouble();
    final center = Offset(w / 2, h / 2);
    final moodColor = emotion.moodColor;

    // 1. Fondo Vantablack con gradiente radial hacia el color de la emoción
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        w * 0.7,
        [
          moodColor.withValues(alpha: 0.35),
          const Color(0xFF070B12),
          const Color(0xFF020408),
        ],
        [0.0, 0.65, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Patrón de rejilla cibernética sutil de fondo
    final gridPaint = Paint()
      ..color = moodColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const int gridSteps = 8;
    for (int i = 1; i < gridSteps; i++) {
      final double step = w * (i / gridSteps);
      canvas.drawLine(Offset(step, 0), Offset(step, h), gridPaint);
      canvas.drawLine(Offset(0, step), Offset(w, step), gridPaint);
    }

    // 3. Anillos orbitales de energía de Kai
    final ringPaint = Paint()
      ..color = moodColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, w * 0.42, ringPaint);

    final dashedRingPaint = Paint()
      ..color = moodColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, w * 0.36, dashedRingPaint);

    // 4. Silueta de orejitas / estilo suave furry cyberpunk
    final earPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.2),
        Offset(0, h * 0.5),
        [moodColor.withValues(alpha: 0.8), const Color(0xFF0F172A)],
      )
      ..style = PaintingStyle.fill;

    // Oreja Izquierda
    final leftEar = Path()
      ..moveTo(w * 0.26, h * 0.42)
      ..lineTo(w * 0.20, h * 0.16)
      ..lineTo(w * 0.40, h * 0.30)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    // Oreja Derecha
    final rightEar = Path()
      ..moveTo(w * 0.74, h * 0.42)
      ..lineTo(w * 0.80, h * 0.16)
      ..lineTo(w * 0.60, h * 0.30)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    // Brillos de orejitas
    final earGlowPaint = Paint()
      ..color = moodColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(leftEar, earGlowPaint);
    canvas.drawPath(rightEar, earGlowPaint);

    // 5. Núcleo Facial / Visor Cyberpunk de Kai
    final headRadius = w * 0.28;
    final headPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx, center.dy - 10),
        headRadius,
        [
          const Color(0xFF1E293B),
          const Color(0xFF090D16),
        ],
      );
    canvas.drawCircle(center, headRadius, headPaint);

    final headBorder = Paint()
      ..color = moodColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, headRadius, headBorder);

    // 6. Ojos / Visor dinámico según la emoción
    _drawEmotionFacialFeatures(canvas, center, w, h, emotion, moodColor);

    // 7. Badge y texto de identificación
    final badgePaint = Paint()
      ..color = const Color(0xFF020408)
      ..style = PaintingStyle.fill;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, h * 0.86), width: w * 0.46, height: h * 0.09),
      const Radius.circular(12),
    );
    canvas.drawRRect(badgeRect, badgePaint);

    final badgeBorder = Paint()
      ..color = moodColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(badgeRect, badgeBorder);

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: w * 0.046,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: moodColor))
      ..addText("KAI • ${emotion.name.toUpperCase()}");

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: w * 0.46));
    canvas.drawParagraph(paragraph, Offset(center.dx - (w * 0.46) / 2, h * 0.84));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Dibuja los rasgos y expresiones faciales cibernéticas de Kai.
  void _drawEmotionFacialFeatures(Canvas canvas, Offset center, double w, double h, KaiEmotion emotion, Color moodColor) {
    final eyePaint = Paint()
      ..color = moodColor
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = moodColor.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final mouthPaint = Paint()
      ..color = moodColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    final double eyeOffsetY = center.dy - (h * 0.04);
    final double leftEyeX = center.dx - (w * 0.11);
    final double rightEyeX = center.dx + (w * 0.11);

    switch (emotion) {
      case KaiEmotion.neutral:
        // Ojos serenos y amables
        canvas.drawCircle(Offset(leftEyeX, eyeOffsetY), w * 0.038, glowPaint);
        canvas.drawCircle(Offset(leftEyeX, eyeOffsetY), w * 0.035, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeOffsetY), w * 0.038, glowPaint);
        canvas.drawCircle(Offset(rightEyeX, eyeOffsetY), w * 0.035, eyePaint);

        // Boca suave
        final mouth = Path()
          ..moveTo(center.dx - (w * 0.04), center.dy + (h * 0.10))
          ..quadraticBezierTo(center.dx, center.dy + (h * 0.12), center.dx + (w * 0.04), center.dy + (h * 0.10));
        canvas.drawPath(mouth, mouthPaint);
        break;

      case KaiEmotion.happy:
        // Ojos alegres en arco (^ ^)
        final leftEyePath = Path()
          ..moveTo(leftEyeX - (w * 0.04), eyeOffsetY + (h * 0.01))
          ..quadraticBezierTo(leftEyeX, eyeOffsetY - (h * 0.035), leftEyeX + (w * 0.04), eyeOffsetY + (h * 0.01));
        final rightEyePath = Path()
          ..moveTo(rightEyeX - (w * 0.04), eyeOffsetY + (h * 0.01))
          ..quadraticBezierTo(rightEyeX, eyeOffsetY - (h * 0.035), rightEyeX + (w * 0.04), eyeOffsetY + (h * 0.01));
        canvas.drawPath(leftEyePath, mouthPaint);
        canvas.drawPath(rightEyePath, mouthPaint);

        // Sonrisa juguetona y amplia
        final smile = Path()
          ..moveTo(center.dx - (w * 0.06), center.dy + (h * 0.09))
          ..quadraticBezierTo(center.dx, center.dy + (h * 0.15), center.dx + (w * 0.06), center.dy + (h * 0.09));
        canvas.drawPath(smile, mouthPaint);
        break;

      case KaiEmotion.thinking:
        // Ojos analíticos con glifos de procesamiento
        canvas.drawCircle(Offset(leftEyeX, eyeOffsetY - (h * 0.015)), w * 0.035, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeOffsetY - (h * 0.015)), w * 0.035, eyePaint);

        // Holograma de datos en espiral sobre la frente
        final haloPaint = Paint()
          ..color = moodColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.dx, center.dy - (h * 0.16)), width: w * 0.22, height: h * 0.06),
          0,
          math.pi * 1.6,
          false,
          haloPaint,
        );

        // Boca pensativa recta
        canvas.drawLine(
          Offset(center.dx - (w * 0.03), center.dy + (h * 0.11)),
          Offset(center.dx + (w * 0.03), center.dy + (h * 0.11)),
          mouthPaint,
        );
        break;

      case KaiEmotion.focused:
        // Visor cybernetic HUD con líneas horizontales de escaneo
        final hudRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, eyeOffsetY), width: w * 0.38, height: h * 0.09),
          const Radius.circular(8),
        );
        final hudPaint = Paint()
          ..color = moodColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(hudRect, hudPaint);

        final hudStroke = Paint()
          ..color = moodColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(hudRect, hudStroke);

        // Puntos de enfoque en visor
        canvas.drawCircle(Offset(leftEyeX, eyeOffsetY), w * 0.025, eyePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeOffsetY), w * 0.025, eyePaint);

        // Boca firme y decidida
        canvas.drawLine(
          Offset(center.dx - (w * 0.035), center.dy + (h * 0.11)),
          Offset(center.dx + (w * 0.035), center.dy + (h * 0.11)),
          mouthPaint,
        );
        break;

      case KaiEmotion.smug:
        // Un ojo con guiño y otro pícaro / confiado
        // Ojo izquierdo guiñando (~)
        final winkPath = Path()
          ..moveTo(leftEyeX - (w * 0.035), eyeOffsetY)
          ..quadraticBezierTo(leftEyeX, eyeOffsetY - (h * 0.025), leftEyeX + (w * 0.035), eyeOffsetY);
        canvas.drawPath(winkPath, mouthPaint);

        // Ojo derecho confiado
        canvas.drawCircle(Offset(rightEyeX, eyeOffsetY), w * 0.032, eyePaint);

        // Sonrisa ladeada / Smirk
        final smirk = Path()
          ..moveTo(center.dx - (w * 0.03), center.dy + (h * 0.12))
          ..quadraticBezierTo(center.dx + (w * 0.02), center.dy + (h * 0.13), center.dx + (w * 0.07), center.dy + (h * 0.08));
        canvas.drawPath(smirk, mouthPaint);
        break;
    }
  }

  /// Orquestador para la generación asíncrona de los 5 sprites base en segundo plano.
  Future<void> generateAllSprites({
    Function(double progress, String status, KaiEmotion? currentEmotion)? onProgress,
  }) async {
    if (_isGenerating) return;

    _isGenerating = true;
    _generationProgress = 0.0;
    _generationStatusMessage = "Iniciando pipeline de sprites...";
    notifyListeners();

    try {
      final total = KaiEmotion.values.length;
      for (int i = 0; i < total; i++) {
        final emotion = KaiEmotion.values[i];
        _currentGeneratingEmotion = emotion;
        _generationProgress = i / total;
        _generationStatusMessage = "Sintetizando sprite de ${emotion.label}...";

        if (onProgress != null) {
          onProgress(_generationProgress, _generationStatusMessage, emotion);
        }
        notifyListeners();

        // 1. Generar bytes de imagen PNG procedural en alta definición
        final bytes = await generateProceduralSpriteBytes(emotion, width: 512, height: 512);

        // 2. Guardar en almacenamiento local de la aplicación
        await saveSprite(emotion, bytes, extension: 'png');

        // Pausa ligera para permitir renderizado UI sin jank
        await Future.delayed(const Duration(milliseconds: 120));
      }

      _generationProgress = 1.0;
      _generationStatusMessage = "¡Todos los sprites de Kai fueron generados exitosamente!";
      _currentGeneratingEmotion = null;

      if (onProgress != null) {
        onProgress(1.0, _generationStatusMessage, null);
      }
    } catch (e) {
      _generationStatusMessage = "Error en generación: $e";
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Genera un sprite específico individualmente.
  Future<void> generateSpriteForEmotion(KaiEmotion emotion) async {
    final bytes = await generateProceduralSpriteBytes(emotion, width: 512, height: 512);
    await saveSprite(emotion, bytes, extension: 'png');
    notifyListeners();
  }
}
