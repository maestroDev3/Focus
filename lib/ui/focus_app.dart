import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the first screen.
class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: focusTheme(Brightness.light),
      darkTheme: focusTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary first screen until the real home screen (#3) exists.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}
