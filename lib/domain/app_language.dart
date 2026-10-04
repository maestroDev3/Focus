/// The language Focus shows, chosen in the settings; [system] follows the
/// phone language.
enum AppLanguage {
  system(null),
  english('en'),
  german('de'),
  russian('ru');

  const AppLanguage(this.languageCode);

  /// ISO 639-1 code of the translation; null for [system].
  final String? languageCode;

  /// The language with [code]; [system] for no or an unknown code.
  static AppLanguage fromLanguageCode(String? code) => values.firstWhere(
    (language) => language.languageCode == code,
    orElse: () => system,
  );
}

/// Keeps the chosen app language, also across restarts.
abstract interface class AppLanguageSetting {
  Future<AppLanguage> load();

  Future<void> save(AppLanguage language);
}
