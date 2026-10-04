import 'package:flutter/widgets.dart';

import '../domain/app_language.dart';
import '../l10n/app_localizations.dart';

/// The locale Focus is forced to, or null to follow the device.
Locale? localeOf(AppLanguage language) => switch (language.languageCode) {
  final code? => Locale(code),
  null => null,
};

/// Texts in [language] for code outside the widget tree, e.g. those sent to
/// native notifications.
AppLocalizations localizationsFor(AppLanguage language) =>
    lookupAppLocalizations(
      basicLocaleListResolution([
        ?localeOf(language),
        ...WidgetsBinding.instance.platformDispatcher.locales,
      ], AppLocalizations.supportedLocales),
    );

/// The name of [language] in the settings; each language is named in
/// itself, so it can be found from any language.
String languageName(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.german => l10n.languageGerman,
      AppLanguage.russian => l10n.languageRussian,
    };
