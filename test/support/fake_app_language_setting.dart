import 'package:focus_timer/domain/app_language.dart';

/// Keeps the chosen app language in memory.
class FakeAppLanguageSetting implements AppLanguageSetting {
  FakeAppLanguageSetting([this.language = AppLanguage.system]);

  AppLanguage language;

  /// How often the language was loaded, e.g. again after a resume.
  var loads = 0;

  @override
  Future<AppLanguage> load() async {
    loads++;
    return language;
  }

  @override
  Future<void> save(AppLanguage language) async => this.language = language;
}
