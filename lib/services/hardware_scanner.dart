import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class HardwareScanner {
  static Future<Map<String, dynamic>> scan() async {
    final cores = kIsWeb ? 1 : Platform.numberOfProcessors;
    double freeRamGb = 4.0;
    double totalRamGb = 8.0;

    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      try {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          double? memTotal;
          double? memAvailable;
          double? memFree;
          
          for (var line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memTotal = kb / (1024 * 1024);
              }
            } else if (line.startsWith('MemAvailable:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memAvailable = kb / (1024 * 1024);
              }
            } else if (line.startsWith('MemFree:')) {
              final parts = line.split(RegExp(r'\s+'));
              final kb = double.tryParse(parts[1]);
              if (kb != null) {
                memFree = kb / (1024 * 1024);
              }
            }
          }
          freeRamGb = memAvailable ?? memFree ?? 4.0;
          totalRamGb = memTotal ?? 8.0;
        }
      } catch (_) {}
    } else {
      freeRamGb = cores > 4 ? 5.5 : 3.2;
      totalRamGb = cores > 4 ? 8.0 : 4.0;
    }

    final recommendedModelId = totalRamGb >= 7.5 ? "llama_3_2_1b" : "qwen_0.5b_chat_q4";

    return {
      'cores': cores,
      'freeRamGb': freeRamGb,
      'totalRamGb': totalRamGb,
      'recommendedModelId': recommendedModelId,
    };
  }
}
