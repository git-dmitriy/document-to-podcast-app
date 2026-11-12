enum AppLanguage {
  ru,
  en;

  static AppLanguage? byCode(String code) {
    for (final language in AppLanguage.values) {
      if (language.name == code) return language;
    }
    return null;
  }
}
