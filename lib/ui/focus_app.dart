import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_label.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../domain/label_repository.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'break_screen.dart';
import 'home_screen.dart';
import 'label_sheet.dart';
import 'labels_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the screens.
class FocusApp extends StatefulWidget {
  const FocusApp({
    super.key,
    required this.timer,
    required this.settings,
    required this.labels,
    this.clock = DateTime.now,
  });

  /// Runs and stores focus sessions.
  final FocusTimer timer;

  /// Stores the Pomodoro rhythm.
  final SettingsRepository settings;

  /// The user's labels.
  final LabelRepository labels;

  /// Source of the current time for every screen.
  final Clock clock;

  @override
  State<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends State<FocusApp> {
  var _pomodoro = const PomodoroSettings();
  var _dailyGoal = const DailyGoal();
  var _focusedToday = Duration.zero;
  var _labels = const <FocusLabel>[];
  String? _selectedLabelId;
  StreamSubscription<List<FocusLabel>>? _labelChanges;

  @override
  void initState() {
    super.initState();
    _labelChanges = widget.labels.watchLabels().listen((labels) {
      if (mounted) setState(() => _labels = labels);
    });
    _loadSettings();
  }

  @override
  void dispose() {
    _labelChanges?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final pomodoro = await widget.settings.loadPomodoro();
    final selectedLabelId = await widget.settings.loadSelectedLabelId();
    final dailyGoal = await widget.settings.loadDailyGoal();
    final focusedToday = await widget.timer.focusedToday();
    if (!mounted) return;
    setState(() {
      _pomodoro = pomodoro;
      _dailyGoal = dailyGoal;
      _focusedToday = focusedToday;
      _selectedLabelId = selectedLabelId;
    });
  }

  /// The chosen label, if it still exists.
  FocusLabel? get _selectedLabel => [
    for (final label in _labels)
      if (label.id == _selectedLabelId) label,
  ].firstOrNull;

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
          labelName: _selectedLabel?.name,
          hasLabels: _labels.isNotEmpty,
          onChooseLabel: () => _chooseLabel(context),
          focusedToday: _focusedToday,
          dailyGoal: _dailyGoal,
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

  Future<void> _chooseLabel(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => LabelSheet(
        labels: _labels,
        selectedId: _selectedLabel?.id,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          setState(() => _selectedLabelId = id);
          widget.settings.saveSelectedLabelId(id);
        },
        onManage: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => LabelsScreen(labels: widget.labels),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startSession(BuildContext context) async {
    final navigator = Navigator.of(context);
    final label = _selectedLabel;
    await widget.timer.start(_pomodoro.focus, labelId: label?.id);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => SessionScreen(
          timer: widget.timer,
          clock: widget.clock,
          labelName: label?.name,
          onDone: (outcome) => _afterSession(context, outcome),
        ),
      ),
    );
    await _loadSettings();
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
