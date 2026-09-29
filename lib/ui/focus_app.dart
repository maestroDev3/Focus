import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/focus_timer.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'session_screen.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the screens.
class FocusApp extends StatelessWidget {
  const FocusApp({super.key, required this.timer, this.clock = DateTime.now});

  /// Runs and stores focus sessions.
  final FocusTimer timer;

  /// Source of the current time for every screen.
  final Clock clock;

  static const _focusDuration = Duration(minutes: 25);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: focusTheme(Brightness.light),
      darkTheme: focusTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => HomeScreen(
          clock: clock,
          focusDuration: _focusDuration,
          onStart: () => _startSession(context),
        ),
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final navigator = Navigator.of(context);
    await timer.start(_focusDuration);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => SessionScreen(
          timer: timer,
          clock: clock,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
