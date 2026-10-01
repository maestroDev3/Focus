import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/app_blocker.dart';
import '../domain/backup.dart';
import '../domain/block_list_repository.dart';
import '../domain/clock.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_time.dart';
import '../domain/focus_time_reminders.dart';
import '../domain/focus_time_repository.dart';
import '../domain/focus_label.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../domain/installed_apps_source.dart';
import '../domain/label_repository.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'blocked_apps_screen.dart';
import 'blocked_screen.dart';
import 'break_screen.dart';
import 'home_screen.dart';
import 'intro_screen.dart';
import 'label_sheet.dart';
import 'labels_screen.dart';
import 'permission_onboarding_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'theme.dart';

/// Root widget of Focus: wires theme, localization and the screens.
class FocusApp extends StatefulWidget {
  const FocusApp({
    super.key,
    required this.timer,
    required this.settings,
    required this.labels,
    required this.backupFiles,
    required this.blockList,
    required this.installedApps,
    required this.appBlocker,
    required this.focusTimes,
    required this.reminders,
    this.clock = DateTime.now,
    this.showIntro = false,
  });

  /// Runs and stores focus sessions.
  final FocusTimer timer;

  /// Stores the Pomodoro rhythm, daily goal and chosen label.
  final SettingsRepository settings;

  /// The user's labels.
  final LabelRepository labels;

  /// Exports and restores backups.
  final BackupFiles backupFiles;

  /// The apps paused during sessions.
  final BlockListRepository blockList;

  /// The apps on the phone that can be paused.
  final InstalledAppsSource installedApps;

  /// The native app blocker.
  final AppBlocker appBlocker;

  /// Recurring focus times.
  final FocusTimeRepository focusTimes;

  /// Notifications when a focus time starts.
  final FocusTimeReminders reminders;

  /// Source of the current time for every screen.
  final Clock clock;

  /// Whether to show the short intro before home (on cold start).
  final bool showIntro;

  @override
  State<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends State<FocusApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  var _pomodoro = const PomodoroSettings();
  late var _introDone = !widget.showIntro;
  var _dailyGoal = const DailyGoal();
  var _focusedToday = Duration.zero;
  var _labels = const <FocusLabel>[];
  String? _selectedLabelId;
  var _blockedAppCount = 0;
  var _blockerEnabled = true;
  var _notificationGateEnabled = true;
  StreamSubscription<List<FocusLabel>>? _labelChanges;
  StreamSubscription<String>? _blockedApps;
  var _focusTimes = const <FocusTime>[];
  StreamSubscription<List<FocusTime>>? _focusTimeChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _labelChanges = widget.labels.watchLabels().listen((labels) {
      if (mounted) setState(() => _labels = labels);
    });
    _focusTimeChanges = widget.focusTimes.watchFocusTimes().listen(
      _onFocusTimesChanged,
    );
    _blockedApps = widget.appBlocker.blockedAppOpened.listen(_showBlocked);
    _loadState();
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _labelChanges?.cancel();
    _blockedApps?.cancel();
    _focusTimeChanges?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have granted a permission in the system settings.
    if (state == AppLifecycleState.resumed) _loadState();
  }

  Future<void> _loadState() async {
    final pomodoro = await widget.settings.loadPomodoro();
    final selectedLabelId = await widget.settings.loadSelectedLabelId();
    final dailyGoal = await widget.settings.loadDailyGoal();
    final focusedToday = await widget.timer.focusedToday();
    final blockList = await widget.blockList.loadBlockList();
    final blockerEnabled = await widget.appBlocker.isBlockerEnabled();
    final notificationGateEnabled = await widget.appBlocker
        .isNotificationGateEnabled();
    if (!mounted) return;
    setState(() {
      _pomodoro = pomodoro;
      _selectedLabelId = selectedLabelId;
      _dailyGoal = dailyGoal;
      _focusedToday = focusedToday;
      _blockedAppCount = blockList.length;
      _blockerEnabled = blockerEnabled;
      _notificationGateEnabled = notificationGateEnabled;
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

  /// Publishes focus times to the native side: the blocker enforces them on
  /// its own and reminders are scheduled from the published state.
  Future<void> _onFocusTimesChanged(List<FocusTime> times) async {
    if (mounted) setState(() => _focusTimes = times);
    await widget.timer.refreshBlocking();
    final l10n = lookupAppLocalizations(
      basicLocaleListResolution(
        WidgetsBinding.instance.platformDispatcher.locales,
        AppLocalizations.supportedLocales,
      ),
    );
    await widget.reminders.reschedule((
      channelName: l10n.focusTimeReminderChannel,
      title: l10n.focusTimeUntil('{time}'),
      body: l10n.focusTimeReminderBody,
    ));
    if (times.isNotEmpty) await widget.reminders.requestPermission();
  }

  /// The label with [id], if it still exists.
  FocusLabel? _labelWithId(String? id) => [
    for (final label in _labels)
      if (label.id == id) label,
  ].firstOrNull;

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
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _introDone
            ? Builder(
                builder: (homeContext) => HomeScreen(
                  clock: widget.clock,
                  focusDuration: _pomodoro.focus,
                  onStart: _startSession,
                  onOpenSettings: _openSettings,
                  blockedAppCount: _blockedAppCount,
                  onOpenBlockedApps: _openBlockedApps,
                  blockerNeedsPermission:
                      _blockedAppCount > 0 && !_blockerEnabled,
                  onAllowBlocking: _openBlockerOnboarding,
                  notificationsNeedPermission:
                      _blockedAppCount > 0 && !_notificationGateEnabled,
                  onAllowNotifications: _openNotificationOnboarding,
                  labelName: _labelWithId(_selectedLabelId)?.name,
                  hasLabels: _labels.isNotEmpty,
                  onChooseLabel: () => _chooseLabel(homeContext),
                  focusedToday: _focusedToday,
                  dailyGoal: _dailyGoal,
                  onOpenStatistics: _openStatistics,
                  activeFocusTime: activeFocusTime(_focusTimes, widget.clock()),
                  nextFocusTimeStart: nextFocusTimeStart(
                    _focusTimes,
                    widget.clock(),
                  ),
                ),
              )
            : IntroScreen(onDone: () => setState(() => _introDone = true)),
      ),
    );
  }

  Future<void> _push(WidgetBuilder builder) async {
    await _navigator.currentState?.push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  Future<void> _openSettings() async {
    await _push(
      (context) => SettingsScreen(
        settings: widget.settings,
        focusTimes: widget.focusTimes,
        backupFiles: widget.backupFiles,
      ),
    );
    await _loadState();
  }

  Future<void> _openStatistics() async {
    await _push(
      (context) => StatisticsScreen(
        finishedSessions: widget.timer.watchFinished(),
        labels: widget.labels.watchLabels(),
        dailyGoal: _dailyGoal,
        clock: widget.clock,
      ),
    );
  }

  Future<void> _openBlockedApps() async {
    await _push(
      (context) => BlockedAppsScreen(
        apps: widget.installedApps,
        blockList: widget.blockList,
        activeSession: widget.timer.current,
        inFocusTime: activeFocusTime(_focusTimes, widget.clock()) != null,
      ),
    );
    await widget.timer.refreshBlocking();
    await _loadState();
  }

  Future<void> _openBlockerOnboarding() async {
    await _push((context) {
      final l10n = AppLocalizations.of(context);
      return PermissionOnboardingScreen(
        title: l10n.blockerOnboardingTitle,
        body: l10n.blockerOnboardingBody,
        onOpenSettings: widget.appBlocker.openBlockerSettings,
      );
    });
    await _loadState();
  }

  Future<void> _openNotificationOnboarding() async {
    await _push((context) {
      final l10n = AppLocalizations.of(context);
      return PermissionOnboardingScreen(
        title: l10n.notificationOnboardingTitle,
        body: l10n.notificationOnboardingBody,
        onOpenSettings: widget.appBlocker.openNotificationGateSettings,
      );
    });
    await _loadState();
  }

  Future<void> _chooseLabel(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => LabelSheet(
        labels: _labels,
        selectedId: _labelWithId(_selectedLabelId)?.id,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          setState(() => _selectedLabelId = id);
          widget.settings.saveSelectedLabelId(id);
        },
        onManage: () {
          Navigator.of(sheetContext).pop();
          _push((context) => LabelsScreen(labels: widget.labels));
        },
      ),
    );
  }

  Future<void> _startSession() async {
    await widget.timer.start(
      _pomodoro.focus,
      labelId: _labelWithId(_selectedLabelId)?.id,
    );
    await _pushSession();
  }

  /// Shows the running session; home is refreshed once it is done.
  Future<void> _pushSession() async {
    final labelName = _labelWithId(widget.timer.current?.labelId)?.name;
    await _push(
      (context) => SessionScreen(
        timer: widget.timer,
        clock: widget.clock,
        labelName: labelName,
        onDone: (outcome) => _afterSession(context, outcome),
      ),
    );
    await _loadState();
  }

  /// Shows the calm “resting” screen over the session for a paused app.
  Future<void> _showBlocked(String packageName) async {
    final session = widget.timer.current;
    // Without a session the app is blocked by a focus time, if one runs.
    final focusTime = session == null
        ? activeFocusTime(
            await widget.focusTimes.watchFocusTimes().first,
            widget.clock(),
          )
        : null;
    if (session == null && focusTime == null) return;
    final apps = await widget.installedApps.installedApps();
    final label = [
      for (final app in apps)
        if (app.packageName == packageName) app.label,
    ].firstOrNull;
    final now = widget.clock();
    await _push(
      (context) => BlockedScreen(
        appLabel: label ?? packageName,
        remaining: switch (session) {
          final session? when !session.isPaused => session.remaining(now),
          _ => null,
        },
        focusTime: focusTime,
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
