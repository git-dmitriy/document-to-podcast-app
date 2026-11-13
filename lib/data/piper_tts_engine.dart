import 'dart:async';

import 'dart:typed_data';

import '../domain/app_language.dart';
import '../domain/audio_cache_key.dart';
import '../domain/playback_settings.dart';
import '../domain/speech_chunks.dart';
import '../domain/tts_engine.dart';
import '../domain/voice_package.dart';
import 'audio_cache.dart';
import 'model_downloader.dart';
import 'piper_voice.dart';

final class PiperTtsEngine implements TtsEngine {
  PiperTtsEngine({required this._voices, required this._host, this._cache});

  final ModelDownloader _voices;
  final PiperVoiceHost _host;
  final AudioCache? _cache;
  final Map<VoiceId, PiperVoiceClient> _clients = {};

  PiperVoiceClient? _active;
  Completer<TtsUtteranceEnd>? _interrupt;
  Future<void>? _chunkPlayback;
  Completer<void>? _resumeCancel;
  List<String> _chunks = const [];
  AppLanguage? _utteranceLanguage;
  var _rate = PlaybackSettings.defaultRate;
  var _chunkIndex = 0;
  var _generation = 0;
  var _chunkStarted = false;
  var _disposed = false;

  @override
  Future<void> warmup() async {
    for (final voice in voiceCatalog) {
      final model = await _voices.installedModel(voice.id);
      if (model == null || _clients.containsKey(voice.id)) continue;
      final client = await _openModel(voice, model);
      if (_disposed) {
        await client.dispose();
        return;
      }
      _clients[voice.id] = client;
    }
  }

  @override
  Future<bool> isAvailable(AppLanguage language) async {
    final id = voiceIdForLanguage(language);
    if (id == null) return false;
    if (_clients.containsKey(id)) return true;
    final model = await _voices.installedModel(id);
    return model != null;
  }

  @override
  Future<void> setRate(double rate) async {
    if (rate.isNaN) return;
    _rate = clampPlaybackRate(rate);
  }

  @override
  Future<TtsSpeakResult> speak(
    String text, {
    required AppLanguage language,
  }) async {
    await _cancelActive();
    if (_disposed) return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
    final chunks = splitSpeechChunks(text);
    if (chunks.isEmpty) return const TtsSpeakResult(TtsUtteranceEnd.completed);
    final client = await _clientFor(language);
    if (_disposed) return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
    if (client == null) {
      final id = voiceIdForLanguage(language);
      final title = id == null ? 'Quality' : voiceById(id).title;
      return TtsSpeakResult(
        TtsUtteranceEnd.failed,
        message: 'The $title voice is not installed.',
      );
    }
    _active = client;
    _utteranceLanguage = language;
    _chunks = chunks;
    _chunkIndex = 0;
    return _speakQueued(client, _generation);
  }

  @override
  Future<void> pause() async {
    final interrupt = _interrupt;
    if (interrupt != null && !interrupt.isCompleted) {
      interrupt.complete(TtsUtteranceEnd.paused);
    }
    final active = _active;
    if (active == null) return;
    try {
      await active.pause();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not pause quality speech.', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<TtsSpeakResult> resume() async {
    final client = _active;
    final playback = _chunkPlayback;
    if (client == null || playback == null || _disposed) {
      return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
    }
    final generation = _generation;
    try {
      await client.resume();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not resume quality speech.', cause: error),
        stackTrace,
      );
    }
    if (_disposed || generation != _generation) {
      return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
    }
    final cancel = Completer<void>();
    _resumeCancel = cancel;
    final outcome = await _untilPlaybackEnds(playback, cancel);
    _resumeCancel = null;
    if (outcome == _ChunkOutcome.cancelled || generation != _generation) {
      return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
    }
    if (outcome == _ChunkOutcome.failed) {
      return const TtsSpeakResult(
        TtsUtteranceEnd.failed,
        message: 'Could not speak this section.',
      );
    }
    if (_chunkStarted) _chunkIndex++;
    _chunkPlayback = null;
    return _speakQueued(client, generation);
  }

  @override
  Future<void> stop() => _cancelActive();

  @override
  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _finishInterrupt(TtsUtteranceEnd.cancelled);
    final resumeCancel = _resumeCancel;
    if (resumeCancel != null && !resumeCancel.isCompleted) {
      resumeCancel.complete();
    }
    final clients = _clients.values.toList();
    _clients.clear();
    _active = null;
    _chunkPlayback = null;
    Object? failure;
    StackTrace? failureTrace;
    for (final client in clients) {
      try {
        await client.stop();
      } catch (error, stackTrace) {
        failure ??= error;
        failureTrace ??= stackTrace;
      }
      try {
        await client.dispose();
      } catch (error, stackTrace) {
        failure ??= error;
        failureTrace ??= stackTrace;
      }
    }
    if (failure != null && failureTrace != null) {
      Error.throwWithStackTrace(
        TtsFailure('Could not stop quality speech.', cause: failure),
        failureTrace,
      );
    }
  }

  Future<TtsSpeakResult> _speakQueued(
    PiperVoiceClient client,
    int generation,
  ) async {
    while (_chunkIndex < _chunks.length) {
      if (_disposed || generation != _generation) {
        return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
      }
      final interrupt = Completer<TtsUtteranceEnd>();
      _interrupt = interrupt;
      _chunkStarted = false;
      final playback = _startChunk(
        client,
        _chunks[_chunkIndex],
        generation,
        interrupt,
      );
      _chunkPlayback = playback;
      unawaited(_watchChunk(playback, interrupt, generation));
      final end = await interrupt.future;
      if (end == TtsUtteranceEnd.paused) {
        return const TtsSpeakResult(TtsUtteranceEnd.paused);
      }
      if (end == TtsUtteranceEnd.cancelled || generation != _generation) {
        return const TtsSpeakResult(TtsUtteranceEnd.cancelled);
      }
      if (end == TtsUtteranceEnd.failed) {
        return const TtsSpeakResult(
          TtsUtteranceEnd.failed,
          message: 'Could not speak this section.',
        );
      }
      _chunkIndex++;
      _chunkPlayback = null;
    }
    _chunks = const [];
    return const TtsSpeakResult(TtsUtteranceEnd.completed);
  }

  Future<void> _startChunk(
    PiperVoiceClient client,
    String chunk,
    int generation,
    Completer<TtsUtteranceEnd> interrupt,
  ) {
    if (!client.canPlayRenderedAudio || _cache == null) {
      _chunkStarted = true;
      return client.speak(chunk);
    }
    return _playCached(client, chunk, generation, interrupt);
  }

  Future<void> _playCached(
    PiperVoiceClient client,
    String chunk,
    int generation,
    Completer<TtsUtteranceEnd> interrupt,
  ) async {
    final language = _utteranceLanguage;
    final voice = language == null ? null : voiceIdForLanguage(language);
    if (voice == null) {
      _chunkStarted = true;
      await client.speak(chunk);
      return;
    }
    final key = AudioCacheKey(
      text: chunk,
      voice: voice.name,
      rate: _rate,
      engine: SpeechEngine.quality.name,
    );
    final cache = _cache;
    Uint8List? audio;
    if (cache != null) {
      try {
        audio = await cache.read(key);
      } on AudioCacheException {
        audio = null;
      }
    }
    if (_shouldAbandon(generation, interrupt)) return;
    if (audio == null || audio.isEmpty) {
      audio = await client.render(chunk);
      if (_shouldAbandon(generation, interrupt)) return;
      if (audio == null || audio.isEmpty) {
        _chunkStarted = true;
        await client.speak(chunk);
        return;
      }
      if (cache != null) {
        try {
          await cache.write(key, audio);
        } on AudioCacheException {
          // Playback can continue with the samples just rendered.
        }
      }
      if (_shouldAbandon(generation, interrupt)) return;
    }
    _chunkStarted = true;
    await client.play(audio);
  }

  bool _shouldAbandon(int generation, Completer<TtsUtteranceEnd> interrupt) {
    return _disposed || generation != _generation || interrupt.isCompleted;
  }

  Future<void> _watchChunk(
    Future<void> playback,
    Completer<TtsUtteranceEnd> interrupt,
    int generation,
  ) async {
    try {
      await playback;
      if (generation == _generation && !interrupt.isCompleted) {
        interrupt.complete(TtsUtteranceEnd.completed);
      }
    } catch (_) {
      if (generation == _generation && !interrupt.isCompleted) {
        interrupt.complete(TtsUtteranceEnd.failed);
      }
    }
  }

  Future<_ChunkOutcome> _untilPlaybackEnds(
    Future<void> playback,
    Completer<void> cancel,
  ) async {
    var failed = false;
    final done = playback.then<bool>((_) => true).catchError((Object _) {
      failed = true;
      return false;
    });
    final finished = await Future.any<bool>([
      done,
      cancel.future.then((_) => false),
    ]);
    if (cancel.isCompleted) return _ChunkOutcome.cancelled;
    if (failed || !finished) return _ChunkOutcome.failed;
    return _ChunkOutcome.completed;
  }

  Future<void> _cancelActive() async {
    _generation++;
    _finishInterrupt(TtsUtteranceEnd.cancelled);
    final cancel = _resumeCancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
    final active = _active;
    _chunkPlayback = null;
    if (active == null) return;
    try {
      await active.stop();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not stop quality speech.', cause: error),
        stackTrace,
      );
    }
  }

  void _finishInterrupt(TtsUtteranceEnd end) {
    final interrupt = _interrupt;
    if (interrupt != null && !interrupt.isCompleted) {
      interrupt.complete(end);
    }
  }

  Future<PiperVoiceClient?> _clientFor(AppLanguage language) async {
    final id = voiceIdForLanguage(language);
    if (id == null) return null;
    final existing = _clients[id];
    if (existing != null) return existing;
    final model = await _voices.installedModel(id);
    if (model == null) return null;
    final client = await _openModel(voiceById(id), model);
    if (_disposed) {
      await client.dispose();
      return null;
    }
    _clients[id] = client;
    return client;
  }

  Future<PiperVoiceClient> _openModel(
    VoicePackage voice,
    InstalledVoiceModel model,
  ) async {
    try {
      return await _host.open(
        modelPath: model.modelPath,
        configPath: model.configPath,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not open the ${voice.title} voice.', cause: error),
        stackTrace,
      );
    }
  }
}

enum _ChunkOutcome { completed, failed, cancelled }
