import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'device_profile.dart';

/// Voz Piper (VITS) en español publicada por el proyecto sherpa-onnx.
class NeuralVoice {
  final String id;
  final String name;
  final String accent;
  final String quality;
  final int sizeMb;
  final bool lightweight;

  const NeuralVoice({
    required this.id,
    required this.name,
    required this.accent,
    required this.quality,
    required this.sizeMb,
    this.lightweight = false,
  });

  String get archiveName => 'vits-piper-$id';
  String get url => 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$archiveName.tar.bz2';
  String get onnxFile => '$id.onnx';
}

enum NeuralVoiceStatus { notDownloaded, downloading, installing, ready }

/// Voz neuronal offline: descarga e instala voces Piper y las sintetiza con
/// sherpa-onnx en un isolate aparte para no bloquear la interfaz.
class NeuralTtsService extends ChangeNotifier {
  static final NeuralTtsService instance = NeuralTtsService._internal();
  NeuralTtsService._internal();

  static const String keySelectedVoice = 'neural_voice_id';

  static const List<NeuralVoice> voices = [
    NeuralVoice(id: 'es_MX-claude-high', name: 'Claude', accent: 'México', quality: 'Alta', sizeMb: 64),
    NeuralVoice(id: 'es_AR-daniela-high', name: 'Daniela', accent: 'Argentina', quality: 'Alta', sizeMb: 110),
    NeuralVoice(id: 'es_ES-davefx-medium', name: 'Dave', accent: 'España', quality: 'Media', sizeMb: 64),
    NeuralVoice(id: 'es_MX-ald-medium', name: 'Ald', accent: 'México', quality: 'Media', sizeMb: 64),
    NeuralVoice(id: 'es_ES-carlfm-x_low', name: 'Carl', accent: 'España', quality: 'Ligera', sizeMb: 25, lightweight: true),
  ];

  final Map<String, NeuralVoiceStatus> _status = {};
  final Map<String, double> _progress = {};
  final Map<String, CancelToken> _cancelTokens = {};
  String? _selectedVoiceId;
  Directory? _voicesDir;
  bool _initialized = false;

  _TtsWorker? _worker;
  String? _workerVoiceId;
  AudioPlayer? _player;
  int _session = 0;
  int _wavCounter = 0;
  Completer<void>? _playbackDone;

  String? get selectedVoiceId => _selectedVoiceId;
  NeuralVoice? get selectedVoice => _voiceById(_selectedVoiceId);
  NeuralVoiceStatus statusOf(String id) => _status[id] ?? NeuralVoiceStatus.notDownloaded;
  double progressOf(String id) => _progress[id] ?? 0.0;

  /// Hay una voz seleccionada e instalada lista para hablar.
  bool get isReady => _selectedVoiceId != null && statusOf(_selectedVoiceId!) == NeuralVoiceStatus.ready;

  /// Voz sugerida según la gama del dispositivo.
  NeuralVoice get recommendedVoice =>
      DeviceProfile.instance.isLowEnd ? voices.firstWhere((v) => v.lightweight) : voices.first;

  static NeuralVoice? _voiceById(String? id) {
    if (id == null) return null;
    for (final v in voices) {
      if (v.id == id) return v;
    }
    return null;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final support = await getApplicationSupportDirectory();
      _voicesDir = Directory('${support.path}/voices');
      await _voicesDir!.create(recursive: true);
      for (final v in voices) {
        _status[v.id] = await _isInstalled(v) ? NeuralVoiceStatus.ready : NeuralVoiceStatus.notDownloaded;
      }
      final prefs = await SharedPreferences.getInstance();
      _selectedVoiceId = prefs.getString(keySelectedVoice);
      if (_selectedVoiceId != null && statusOf(_selectedVoiceId!) != NeuralVoiceStatus.ready) {
        _selectedVoiceId = null;
      }
    } catch (e) {
      debugPrint('NeuralTtsService.init: $e');
    }
    notifyListeners();
  }

  Directory _voiceDir(NeuralVoice v) => Directory('${_voicesDir!.path}/${v.archiveName}');

  Future<bool> _isInstalled(NeuralVoice v) async {
    final dir = _voiceDir(v);
    return await File('${dir.path}/${v.onnxFile}').exists() &&
        await File('${dir.path}/tokens.txt').exists() &&
        await Directory('${dir.path}/espeak-ng-data').exists();
  }

  Future<void> selectVoice(String id) async {
    if (statusOf(id) != NeuralVoiceStatus.ready) return;
    _selectedVoiceId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedVoice, id);
    notifyListeners();
  }

  /// Descarga e instala una voz. Se descarga a `.part` y solo se marca lista
  /// cuando la extracción terminó, para que un corte de red no deje una voz rota.
  Future<void> download(NeuralVoice v) async {
    await init();
    final s = statusOf(v.id);
    if (s == NeuralVoiceStatus.downloading || s == NeuralVoiceStatus.installing) return;

    final archivePath = '${_voicesDir!.path}/${v.archiveName}.tar.bz2';
    final partialPath = '$archivePath.part';
    final cancelToken = CancelToken();
    _cancelTokens[v.id] = cancelToken;
    _setStatus(v.id, NeuralVoiceStatus.downloading, progress: 0);

    try {
      await Dio().download(
        v.url,
        partialPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _progress[v.id] = received / total;
            notifyListeners();
          }
        },
      );
      await File(partialPath).rename(archivePath);

      _setStatus(v.id, NeuralVoiceStatus.installing);
      final outDir = _voicesDir!.path;
      // La descompresión bz2 es CPU intensiva: va en un isolate aparte.
      await compute(_extractVoiceArchive, [archivePath, outDir]);
      await File(archivePath).delete();

      if (!await _isInstalled(v)) {
        throw Exception('La voz descargada está incompleta.');
      }
      _setStatus(v.id, NeuralVoiceStatus.ready);
      if (_selectedVoiceId == null) await selectVoice(v.id);
    } catch (e) {
      for (final path in [partialPath, archivePath]) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      _setStatus(v.id, NeuralVoiceStatus.notDownloaded);
      if (e is DioException && CancelToken.isCancel(e)) return;
      rethrow;
    } finally {
      _cancelTokens.remove(v.id);
    }
  }

  void cancelDownload(String id) => _cancelTokens[id]?.cancel();

  Future<void> deleteVoice(NeuralVoice v) async {
    await init();
    if (_workerVoiceId == v.id) {
      await stop();
      _worker?.dispose();
      _worker = null;
      _workerVoiceId = null;
    }
    try {
      final dir = _voiceDir(v);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    _setStatus(v.id, NeuralVoiceStatus.notDownloaded);
    if (_selectedVoiceId == v.id) {
      _selectedVoiceId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keySelectedVoice);
      notifyListeners();
    }
  }

  void _setStatus(String id, NeuralVoiceStatus status, {double? progress}) {
    _status[id] = status;
    if (progress != null) _progress[id] = progress;
    notifyListeners();
  }

  Future<_TtsWorker> _ensureWorker() async {
    final voice = selectedVoice!;
    if (_worker != null && _workerVoiceId == voice.id) return _worker!;
    _worker?.dispose();
    final dir = _voiceDir(voice).path;
    _worker = await _TtsWorker.spawn(
      model: '$dir/${voice.onnxFile}',
      tokens: '$dir/tokens.txt',
      dataDir: '$dir/espeak-ng-data',
      threads: DeviceProfile.instance.ttsThreads,
    );
    _workerVoiceId = voice.id;
    return _worker!;
  }

  /// Divide el texto en frases para empezar a hablar en cuanto la primera esté lista.
  @visibleForTesting
  static List<String> splitSentences(String text, {int maxChars = 220}) {
    final raw = text
        .split(RegExp(r'(?<=[.!?…;:])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final result = <String>[];
    var buffer = '';
    for (final sentence in raw) {
      if (buffer.isEmpty) {
        buffer = sentence;
      } else if (buffer.length < 40 && buffer.length + sentence.length + 1 <= maxChars) {
        // Une frases muy cortas para que la entonación fluya.
        buffer = '$buffer $sentence';
      } else {
        result.add(buffer);
        buffer = sentence;
      }
    }
    if (buffer.isNotEmpty) result.add(buffer);
    return result;
  }

  /// Sintetiza y reproduce [text]. Mientras suena una frase ya se genera la siguiente.
  /// Devuelve `true` si terminó de hablar y `false` si se detuvo antes.
  Future<bool> speak(String text, {double speed = 1.0}) async {
    if (!isReady) return false;
    await stop();
    final session = ++_session;
    final sentences = splitSentences(text);
    if (sentences.isEmpty) return true;

    final worker = await _ensureWorker();
    final tmp = await getTemporaryDirectory();
    _player ??= AudioPlayer();

    Future<_Audio> pending = worker.generate(sentences.first, speed);
    for (var i = 0; i < sentences.length; i++) {
      final audio = await pending;
      if (session != _session) return false;
      if (i + 1 < sentences.length) {
        pending = worker.generate(sentences[i + 1], speed);
      }
      if (audio.samples.isEmpty) continue;

      final file = File('${tmp.path}/kai_tts_${_wavCounter++ % 3}.wav');
      await file.writeAsBytes(encodeWav(audio.samples, audio.sampleRate), flush: true);
      if (session != _session) return false;

      final done = Completer<void>();
      _playbackDone = done;
      final sub = _player!.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      try {
        await _player!.play(DeviceFileSource(file.path));
      } catch (e) {
        await sub.cancel();
        rethrow;
      }
      await done.future;
      await sub.cancel();
      if (session != _session) return false;
    }
    return true;
  }

  Future<void> stop() async {
    _session++;
    final done = _playbackDone;
    if (done != null && !done.isCompleted) done.complete();
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Convierte muestras float (-1..1) a un WAV PCM de 16 bits mono.
  @visibleForTesting
  static Uint8List encodeWav(Float32List samples, int sampleRate) {
    final dataLength = samples.length * 2;
    final bytes = ByteData(44 + dataLength);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      bytes.setInt16(44 + i * 2, v, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

/// Función de nivel superior para que el isolate no arrastre el estado del servicio.
Future<void> _extractVoiceArchive(List<String> paths) => extractFileToDisk(paths[0], paths[1]);

class _Audio {
  final Float32List samples;
  final int sampleRate;
  const _Audio(this.samples, this.sampleRate);
}

/// Isolate de larga vida que mantiene el modelo cargado y genera audio por frase.
class _TtsWorker {
  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<_Audio>> _pending = {};
  int _nextId = 0;

  _TtsWorker._(this._isolate, this._commands, this._responses) {
    _responses.listen((message) {
      if (message is List && message.length == 3) {
        final completer = _pending.remove(message[0] as int);
        final data = (message[1] as TransferableTypedData).materialize().asFloat32List();
        completer?.complete(_Audio(data, message[2] as int));
      }
    });
  }

  static Future<_TtsWorker> spawn({
    required String model,
    required String tokens,
    required String dataDir,
    required int threads,
  }) async {
    final responses = ReceivePort();
    final ready = Completer<SendPort>();
    late final StreamSubscription sub;
    final setup = ReceivePort();
    sub = setup.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
      } else if (message is String) {
        ready.completeError(Exception(message));
      }
      sub.cancel();
      setup.close();
    });
    final isolate = await Isolate.spawn(
      _entry,
      [setup.sendPort, responses.sendPort, model, tokens, dataDir, threads],
      debugName: 'kai_tts',
    );
    final commands = await ready.future;
    return _TtsWorker._(isolate, commands, responses);
  }

  Future<_Audio> generate(String text, double speed) {
    final id = _nextId++;
    final completer = Completer<_Audio>();
    _pending[id] = completer;
    _commands.send([id, text, speed]);
    return completer.future;
  }

  void dispose() {
    _commands.send(null);
    _responses.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete(_Audio(Float32List(0), 0));
    }
    _pending.clear();
    _isolate.kill(priority: Isolate.beforeNextEvent);
  }

  static void _entry(List<Object> args) {
    final setup = args[0] as SendPort;
    final out = args[1] as SendPort;
    sherpa.OfflineTts tts;
    try {
      sherpa.initBindings();
      tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: args[2] as String,
            tokens: args[3] as String,
            dataDir: args[4] as String,
          ),
          numThreads: args[5] as int,
        ),
      ));
    } catch (e) {
      setup.send('No se pudo cargar la voz neuronal: $e');
      return;
    }

    final commands = ReceivePort();
    setup.send(commands.sendPort);
    commands.listen((message) {
      if (message == null) {
        tts.free();
        commands.close();
        return;
      }
      final m = message as List;
      final audio = tts.generate(text: m[1] as String, speed: m[2] as double);
      out.send([
        m[0] as int,
        TransferableTypedData.fromList([audio.samples]),
        audio.sampleRate,
      ]);
    });
  }
}
