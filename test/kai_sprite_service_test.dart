import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/models/kai_persona.dart';
import 'package:vantablack_hub/services/kai_sprite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;

  setUpAll(() {
    tempTestDir = Directory.systemTemp.createTempSync('kai_sprites_test_dir');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempTestDir.path;
      },
    );
  });

  tearDownAll(() {
    try {
      if (tempTestDir.existsSync()) {
        tempTestDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('KaiSpriteService Tests', () {
    test('visualPrompts contains prompts for all 5 emotions', () {
      for (final emotion in KaiEmotion.values) {
        expect(KaiSpriteService.visualPrompts.containsKey(emotion), isTrue);
        expect(KaiSpriteService.visualPrompts[emotion], isNotEmpty);
      }
    });

    test('generateProceduralSpriteBytes creates valid PNG bytes', () async {
      final bytes = await KaiSpriteService.instance.generateProceduralSpriteBytes(KaiEmotion.happy, width: 256, height: 256);
      expect(bytes, isNotEmpty);
      // Verificación de cabecera mágica PNG: 0x89 0x50 0x4E 0x47
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });

    test('saveSprite and getSpritePath save and locate sprite on disk', () async {
      final bytes = await KaiSpriteService.instance.generateProceduralSpriteBytes(KaiEmotion.focused, width: 128, height: 128);
      final file = await KaiSpriteService.instance.saveSprite(KaiEmotion.focused, bytes);

      expect(await file.exists(), isTrue);

      final path = await KaiSpriteService.instance.getSpritePath(KaiEmotion.focused);
      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);

      final statusMap = await KaiSpriteService.instance.checkSpritesExist();
      expect(statusMap[KaiEmotion.focused], isTrue);
    });

    test('generateAllSprites generates all 5 emotions with progress updates', () async {
      final List<double> recordedProgress = [];

      await KaiSpriteService.instance.generateAllSprites(
        onProgress: (progress, status, currentEmotion) {
          recordedProgress.add(progress);
        },
      );

      expect(recordedProgress, isNotEmpty);
      expect(await KaiSpriteService.instance.areAllSpritesGenerated(), isTrue);

      final statusMap = await KaiSpriteService.instance.checkSpritesExist();
      for (final emotion in KaiEmotion.values) {
        expect(statusMap[emotion], isTrue, reason: 'Sprite for ${emotion.name} should exist');
      }
    });

    test('deleteSprites cleans up sprites directory', () async {
      await KaiSpriteService.instance.deleteSprites();
      final statusMap = await KaiSpriteService.instance.checkSpritesExist();
      for (final emotion in KaiEmotion.values) {
        expect(statusMap[emotion], isFalse);
      }
    });
  });
}
