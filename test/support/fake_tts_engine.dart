import 'dart:async';

import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';

final class FakeTtsEngine implements TtsEngine {
  final List<String> spoken = [];
  final List<AppLanguage> languages = [];
  final List<double> rates = [];
  final List<String> resumed = [];
  final available = <AppLanguage, bool>{
    AppLanguage.en: true,
    AppLanguage.ru: true,
  };

  Completer<TtsSpeakResult>? pending;
  String? lastText;
  AppLanguage? lastLanguage;
  var pauseCount = 0;
  var stopCount = 0;
  TtsFailure? availabilityFailure;
  Future<void> Function(int count)? onRate;

  @override
  Future<void> warmup() async {}

  @override
  Future<bool> isAvailable(AppLanguage language) async {
    final failure = availabilityFailure;
    if (failure != null) throw failure;
    return available[language] ?? false;
  }

  @override
  Future<void> setRate(double rate) async {
    rates.add(rate);
    final hook = onRate;
    if (hook != null) await hook(rates.length);
  }

  @override
  Future<TtsSpeakResult> speak(String text, {required AppLanguage language}) {
    lastText = text;
    lastLanguage = language;
    spoken.add(text);
    languages.add(language);
    return _wait();
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _finish(const TtsSpeakResult(TtsUtteranceEnd.paused));
  }

  @override
  Future<TtsSpeakResult> resume() {
    final text = lastText;
    if (text == null) {
      return Future.value(const TtsSpeakResult(TtsUtteranceEnd.cancelled));
    }
    resumed.add(text);
    return _wait();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _finish(const TtsSpeakResult(TtsUtteranceEnd.cancelled));
  }

  void completeCurrent() {
    _finish(const TtsSpeakResult(TtsUtteranceEnd.completed));
  }

  Future<TtsSpeakResult> _wait() {
    final completer = Completer<TtsSpeakResult>();
    pending = completer;
    return completer.future;
  }

  void _finish(TtsSpeakResult result) {
    final current = pending;
    if (current == null || current.isCompleted) return;
    pending = null;
    current.complete(result);
  }
}
