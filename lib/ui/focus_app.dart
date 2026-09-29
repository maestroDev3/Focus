import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../domain/pomodoro.dart';
import '../l10n/app_localizations.dart';
import 'break_screen.dart';
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

  static const _pomodoro = PomodoroSettings();

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
          focusDuration: _pomodoro.focus,
          onStart: () => _startSession(context),
        ),
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final navigator = Navigator.of(context);
    await timer.start(_pomodoro.focus);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => SessionScreen(
          timer: timer,
          clock: clock,
          onDone: (outcome) => _afterSession(context, outcome),
        ),
      ),
    );
  }

  /// A completed session is followed by the right break; a cancelled one
  /// returns home.
  Future<void> _afterSession(
    BuildContext context,
    SessionOutcome outcome,
  ) async {
    final navigator = Navigator.of(context);
    switch (outcome) {
      case SessionCancelled():
        navigator.pop();
      case SessionCompleted():
        final kind = breakAfter(
          completedToday: await timer.completedToday(),
          settings: _pomodoro,
        );
        await navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => BreakScreen(
              kind: kind,
              duration: breakDuration(kind, _pomodoro),
              clock: clock,
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        );
    }
  }
}
