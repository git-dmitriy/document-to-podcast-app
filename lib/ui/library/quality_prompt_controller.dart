import 'package:flutter/foundation.dart';

import '../../data/quality_prompt_store.dart';

final class QualityPromptController extends ChangeNotifier {
  QualityPromptController({required this._store});

  final QualityPromptStore _store;
  var _loading = true;
  var _dismissed = false;
  var _disposed = false;

  bool get isLoading => _loading;

  bool get isDismissed => _dismissed;

  Future<void> load() async {
    final dismissed = await _store.isDismissed();
    if (_disposed) return;
    _dismissed = dismissed;
    _loading = false;
    _notify();
  }

  Future<void> dismiss() async {
    if (_disposed || _dismissed) return;
    _dismissed = true;
    _notify();
    await _store.dismiss();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
