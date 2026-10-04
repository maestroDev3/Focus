import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/app_language.dart';

void main() {
  group('AppLanguage', () {
    test('follows the system without a language code', () {
      expect(AppLanguage.system.languageCode, isNull);
    });

    test('maps the language codes of the translations', () {
      expect(AppLanguage.fromLanguageCode('en'), AppLanguage.english);
      expect(AppLanguage.fromLanguageCode('de'), AppLanguage.german);
      expect(AppLanguage.fromLanguageCode('ru'), AppLanguage.russian);
    });

    test('falls back to the system for no or an unknown code', () {
      expect(AppLanguage.fromLanguageCode(null), AppLanguage.system);
      expect(AppLanguage.fromLanguageCode('fr'), AppLanguage.system);
    });
  });
}
