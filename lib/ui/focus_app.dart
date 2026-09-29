import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the first screen.
class FocusApp extends StatelessWidget {
  const FocusApp({super.key, this.clock = DateTime.now});

  /// Source of the current time for every screen.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: focusTheme(Brightness.light),
      darkTheme: focusTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        clock: clock,
        focusDuration: const Duration(minutes: 25),
        onStart: () {},
      ),
    );
  }
}
