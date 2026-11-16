enum AppLanguage {
  ru,
  en;

  String get speechLocale => switch (this) {
    AppLanguage.ru => 'ru-RU',
    AppLanguage.en => 'en-US',
  };

  String get label => switch (this) {
    AppLanguage.ru => 'Russian',
    AppLanguage.en => 'English',
  };

  static AppLanguage? byCode(String code) {
    for (final language in AppLanguage.values) {
      if (language.name == code) return language;
    }
    return null;
  }
}
