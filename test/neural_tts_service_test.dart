import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantablack_hub/services/device_profile.dart';
import 'package:vantablack_hub/services/neural_tts_service.dart';

void main() {
  group('NeuralTtsService helpers', () {
    test('splitSentences keeps sentence boundaries and merges very short ones', () {
      final parts = NeuralTtsService.splitSentences(
        'Hola. Soy Kai, tu asistente local y privado. ¿En qué te ayudo hoy?\nPuedo programar contigo.',
      );
      expect(parts, [
        'Hola. Soy Kai, tu asistente local y privado.',
        '¿En qué te ayudo hoy? Puedo programar contigo.',
      ]);
    });

    test('splitSentences ignores empty input', () {
      expect(NeuralTtsService.splitSentences('   \n  '), isEmpty);
    });

    test('encodeWav writes a valid 16-bit mono PCM header', () {
      final wav = NeuralTtsService.encodeWav(Float32List.fromList([0.0, 0.5, -0.5, 1.0]), 22050);
      final data = ByteData.sublistView(wav);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(data.getUint16(22, Endian.little), 1);
      expect(data.getUint32(24, Endian.little), 22050);
      expect(data.getUint32(40, Endian.little), 8);
      expect(data.getInt16(46, Endian.little), 16384);
      expect(data.getInt16(50, Endian.little), 32767);
      expect(wav.length, 44 + 8);
    });

    test('voice catalog points to sherpa-onnx Piper releases and has a lightweight option', () {
      for (final v in NeuralTtsService.voices) {
        expect(v.url, startsWith('https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-es_'));
        expect(v.url, endsWith('.tar.bz2'));
      }
      expect(NeuralTtsService.voices.where((v) => v.lightweight), isNotEmpty);
    });
  });

  group('DeviceProfile', () {
    test('classifies low, mid and high tiers', () {
      expect(DeviceProfile.classify(cores: 4, totalRamGb: 3.0), DeviceTier.low);
      expect(DeviceProfile.classify(cores: 8, totalRamGb: 4.0), DeviceTier.low);
      expect(DeviceProfile.classify(cores: 8, totalRamGb: 6.0), DeviceTier.mid);
      expect(DeviceProfile.classify(cores: 8, totalRamGb: 12.0), DeviceTier.high);
    });
  });
}
