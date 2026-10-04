import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/app_language.dart';
import 'package:focus_timer/l10n/app_localizations.dart';

void main() {
  test('offers exactly one app language per translation', () {
    final codes = [
      for (final language in AppLanguage.values) ?language.languageCode,
    ];

    expect(codes.toSet(), hasLength(codes.length));
    expect(codes.toSet(), {
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode,
    });
  });
}
