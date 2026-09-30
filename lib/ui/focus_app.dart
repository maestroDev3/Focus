import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/app_blocker.dart';
import '../domain/block_list_repository.dart';
import '../domain/clock.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../domain/installed_apps_source.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'blocked_apps_screen.dart';
import 'blocked_screen.dart';
import 'blocker_onboarding_screen.dart';
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
    required this.blockList,
    required this.installedApps,
    required this.appBlocker,
    this.clock = DateTime.now,
  });

  /// Runs and stores focus sessions.
  final FocusTimer timer;

  /// Stores the Pomodoro rhythm.
  final SettingsRepository settings;

  /// The apps paused during sessions.
  final BlockListRepository blockList;

  /// The apps on the phone that can be paused.
  final InstalledAppsSource installedApps;

  /// The native app blocker.
  final AppBlocker appBlocker;

  /// Source of the current time for every screen.
  final Clock clock;

  @override
  State<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends State<FocusApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  var _pomodoro = const PomodoroSettings();
  var _blockedAppCount = 0;
  var _blockerEnabled = true;
  StreamSubscription<String>? _blockedApps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _blockedApps = widget.appBlocker.blockedAppOpened.listen(_showBlocked);
    _loadState();
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blockedApps?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have enabled the blocker in the system settings.
    if (state == AppLifecycleState.resumed) _loadState();
  }

  Future<void> _loadState() async {
    final pomodoro = await widget.settings.loadPomodoro();
    final blockList = await widget.blockList.loadBlockList();
    final blockerEnabled = await widget.appBlocker.isBlockerEnabled();
    if (!mounted) return;
    setState(() {
      _pomodoro = pomodoro;
      _blockedAppCount = blockList.length;
      _blockerEnabled = blockerEnabled;
    });
  }

  /// Continues a session that was running when Focus was closed, and shows
  /// the blocked screen if Focus was launched for a paused app.
  Future<void> _restore() async {
    final session = await widget.timer.restore();
    final blockedPackage = await widget.appBlocker.initialBlockedPackage();
    if (!mounted || session == null) return;
    _pushSession();
    if (blockedPackage != null) await _showBlocked(blockedPackage);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: focusTheme(Brightness.light),
      darkTheme: focusTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        clock: widget.clock,
        focusDuration: _pomodoro.focus,
        onStart: _startSession,
        onOpenSettings: _openSettings,
        blockedAppCount: _blockedAppCount,
        onOpenBlockedApps: _openBlockedApps,
        blockerNeedsPermission: _blockedAppCount > 0 && !_blockerEnabled,
        onAllowBlocking: _openBlockerOnboarding,
      ),
    );
  }

  Future<void> _push(WidgetBuilder builder) async {
    await _navigator.currentState?.push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  Future<void> _openSettings() async {
    await _push((context) => SettingsScreen(settings: widget.settings));
    await _loadState();
  }

  Future<void> _openBlockedApps() async {
    await _push(
      (context) => BlockedAppsScreen(
        apps: widget.installedApps,
        blockList: widget.blockList,
        activeSession: widget.timer.current,
      ),
    );
    await widget.timer.refreshBlocking();
    await _loadState();
  }

  Future<void> _openBlockerOnboarding() async {
    await _push(
      (context) => BlockerOnboardingScreen(
        onOpenSettings: widget.appBlocker.openBlockerSettings,
      ),
    );
    await _loadState();
  }

  Future<void> _startSession() async {
    await widget.timer.start(_pomodoro.focus);
    _pushSession();
  }

  void _pushSession() {
    _push(
      (context) => SessionScreen(
        timer: widget.timer,
        clock: widget.clock,
        onDone: (outcome) => _afterSession(context, outcome),
      ),
    );
  }

  /// Shows the calm “resting” screen over the session for a paused app.
  Future<void> _showBlocked(String packageName) async {
    final session = widget.timer.current;
    if (session == null) return;
    final apps = await widget.installedApps.installedApps();
    final label = [
      for (final app in apps)
        if (app.packageName == packageName) app.label,
    ].firstOrNull;
    final now = widget.clock();
    await _push(
      (context) => BlockedScreen(
        appLabel: label ?? packageName,
        remaining: session.isPaused ? null : session.remaining(now),
        onReturn: () => Navigator.of(context).pop(),
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
