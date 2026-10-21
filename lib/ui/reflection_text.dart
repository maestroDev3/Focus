import '../domain/focus_session.dart';
import '../l10n/app_localizations.dart';

/// The calm name of a reflection level.
String reflectionText(AppLocalizations l10n, SessionReflection reflection) =>
    switch (reflection) {
      SessionReflection.heavy => l10n.reflectionHeavy,
      SessionReflection.steady => l10n.reflectionSteady,
      SessionReflection.flowing => l10n.reflectionFlowing,
    };
