import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'break_screen.dart';
import 'home_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the screens.
class FocusApp extends StatefulWidget {
  const FocusApp({
    super.key,
    required this.timer,
    required this.settings,
    this.clock = DateTime.now,
  });

  /// Runs and stores focus sessions.
  final FocusTimer timer;

  /// Stores the Pomodoro rhythm.
  final SettingsRepository settings;

  /// Source of the current time for every screen.
  final Clock clock;

  @override
  State<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends State<FocusApp> {
  var _pomodoro = const PomodoroSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pomodoro = await widget.settings.loadPomodoro();
    if (!mounted) return;
    setState(() => _pomodoro = pomodoro);
  }

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
          clock: widget.clock,
          focusDuration: _pomodoro.focus,
          onStart: () => _startSession(context),
          onOpenSettings: () => _openSettings(context),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(settings: widget.settings),
      ),
    );
    await _loadSettings();
  }

  Future<void> _startSession(BuildContext context) async {
    final navigator = Navigator.of(context);
    await widget.timer.start(_pomodoro.focus);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => SessionScreen(
          timer: widget.timer,
          clock: widget.clock,
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
        final pomodoro = _pomodoro;
        final kind = breakAfter(
          completedToday: await widget.timer.completedToday(),
          settings: pomodoro,
        );
        await navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => BreakScreen(
              kind: kind,
              duration: breakDuration(kind, pomodoro),
              clock: widget.clock,
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        );
    }
  }
}
