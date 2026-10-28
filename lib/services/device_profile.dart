import 'hardware_scanner.dart';

/// Gama del dispositivo, usada para ajustar efectos visuales, hilos del LLM y voz.
enum DeviceTier { low, mid, high }

/// Perfil de rendimiento calculado una vez al arrancar a partir de RAM y núcleos.
class DeviceProfile {
  static final DeviceProfile instance = DeviceProfile._internal();
  DeviceProfile._internal();

  DeviceTier _tier = DeviceTier.mid;
  int _cores = 4;
  double _totalRamGb = 4.0;
  bool _isLoaded = false;

  DeviceTier get tier => _tier;
  int get cores => _cores;
  double get totalRamGb => _totalRamGb;
  bool get isLoaded => _isLoaded;
  bool get isLowEnd => _tier == DeviceTier.low;

  /// Hilos de inferencia: en gama baja se deja un núcleo libre para que la UI no se congele.
  int get llmThreads {
    switch (_tier) {
      case DeviceTier.low:
        return (_cores - 1).clamp(1, 3);
      case DeviceTier.mid:
      case DeviceTier.high:
        return _cores >= 6 ? 4 : (_cores - 1).clamp(1, 4);
    }
  }

  /// Contexto del LLM: 1024 tokens en gama baja para no agotar la RAM.
  int get llmContextSize => _tier == DeviceTier.low ? 1024 : 2048;

  /// Hilos para la voz neuronal.
  int get ttsThreads => _tier == DeviceTier.high ? 2 : 1;

  /// Animaciones decorativas (pulsos, brillos). Se apagan en gama baja.
  bool get decorativeAnimations => _tier != DeviceTier.low;

  Future<void> load() async {
    if (_isLoaded) return;
    final hw = await HardwareScanner.scan();
    _cores = (hw['cores'] as int?) ?? 4;
    _totalRamGb = (hw['totalRamGb'] as num?)?.toDouble() ?? 4.0;
    _tier = classify(cores: _cores, totalRamGb: _totalRamGb);
    _isLoaded = true;
  }

  static DeviceTier classify({required int cores, required double totalRamGb}) {
    if (totalRamGb < 4.5 || cores <= 4) return DeviceTier.low;
    if (totalRamGb >= 7.5 && cores >= 8) return DeviceTier.high;
    return DeviceTier.mid;
  }
}
