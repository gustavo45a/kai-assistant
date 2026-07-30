import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ZRamMemoryManager {
  static Future<Map<String, dynamic>> optimizeMemory(bool isEnabled) async {
    double freedMb = 0.0;
    if (isEnabled) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final files = tempDir.listSync(recursive: true);
          for (var file in files) {
            if (file is File) {
              final len = await file.length();
              freedMb += len / (1024 * 1024);
              try {
                await file.delete();
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    return {
      'freedMb': freedMb,
      'status': 'Caché liberada correctamente'
    };
  }
}
