import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_settings_repository.dart';
import 'settings_repository.dart';

Future<SettingsRepository> openSettingsRepository() async {
  final preferences = await SharedPreferences.getInstance();
  return PreferencesSettingsRepository(preferences);
}
