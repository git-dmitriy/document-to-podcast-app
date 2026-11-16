import 'package:shared_preferences/shared_preferences.dart';

import 'quality_prompt_store.dart';

final class PreferencesQualityPromptStore implements QualityPromptStore {
  PreferencesQualityPromptStore(this._preferences);

  static const dismissedKey = 'quality_prompt_dismissed_v1';

  final SharedPreferences _preferences;

  @override
  Future<bool> isDismissed() async {
    return _preferences.getBool(dismissedKey) ?? false;
  }

  @override
  Future<void> dismiss() {
    return _preferences.setBool(dismissedKey, true);
  }
}
