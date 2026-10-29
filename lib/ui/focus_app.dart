import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/ambient.dart';
import '../domain/app_blocker.dart';
import '../domain/app_language.dart';
import '../domain/background_style.dart';
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
import '../domain/home_widget.dart';
import '../domain/installed_apps_source.dart';
import '../domain/label_repository.dart';
import '../domain/named_block_list.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'ambient_sheet.dart';
import 'app_locale.dart';
import 'block_lists_screen.dart';
import 'breath_screen.dart';
import 'blocked_screen.dart';
import 'break_screen.dart';
import 'focus_times_screen.dart';
import 'home_screen.dart';
import 'intro_screen.dart';
import 'label_sheet.dart';
import 'labels_screen.dart';
import 'permission_onboarding_screen.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'theme.dart';
import 'widgets/calm_motion.dart';
import 'widgets/duration_wheel.dart';
import 'widgets/focus_background.dart';

/// Root widget of Focus: wires theme, localization and the screens.
class FocusApp extends StatefulWidget {
  const FocusApp({
    super.key,
    required this.timer,
    required this.settings,
    required this.labels,
    required this.backupFiles,
    required this.blockList,
    required this.namedBlockLists,
    required this.installedApps,
    required this.appBlocker,
    required this.focusTimes,
    required this.reminders,
    this.homeWidget,
    this.language,
    this.onLanguageChanged,
    this.mindfulApps,
    this.ambientPlayer,
    this.clock = DateTime.now,
    this.showIntro = false,
    this.motion = true,
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

  /// Block lists with a name, next to the default list.
  final NamedBlockListRepository namedBlockLists;

  /// The apps on the phone that can be paused.
  final InstalledAppsSource installedApps;

  /// The native app blocker.
  final AppBlocker appBlocker;

  /// Recurring focus times.
  final FocusTimeRepository focusTimes;

  /// Notifications when a focus time starts.
  final FocusTimeReminders reminders;

  /// The home screen widget; optional because not every test needs it.
  final HomeWidgetBridge? homeWidget;

  /// The chosen app language; optional because not every test needs it.
  final AppLanguageSetting? language;

  /// Called when the language changed in the settings, so texts sent to
  /// native code follow it.
  final ValueChanged<AppLanguage>? onLanguageChanged;

  /// The apps that get the breathing pause; optional because not every
  /// test needs it.
  final BlockListRepository? mindfulApps;

  /// Previews ambient sounds while choosing one; optional for tests.
  final AmbientPlayer? ambientPlayer;

  /// Source of the current time for every screen.
  final Clock clock;

  /// Whether to show the short intro before home (on cold start).
  final bool showIntro;

  /// Lets the ring breathe and the background pulse (#306); tests turn it
  /// off so `pumpAndSettle` can settle.
  final bool motion;

  @override
  State<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends State<FocusApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();

  /// Selected place in the bottom bar: Home, Week, Statistics, Settings
  /// (#393). Tabs keep their state in an IndexedStack.
  var _tab = 0;
  var _pomodoro = const PomodoroSettings();
  late var _introDone = !widget.showIntro;
  var _dailyGoal = const DailyGoal();
  var _focusedToday = Duration.zero;
  var _labels = const <FocusLabel>[];
  String? _selectedLabelId;
  var _blockedAppCount = 0;
  var _blockerEnabled = true;
  var _notificationGateEnabled = true;
  var _language = AppLanguage.system;
  var _ambient = AmbientChoice.initial;
  var _background = BackgroundStyle.initial;

  /// False while apps are paused but the blocker is switched off; the
  /// session screen warns then.
  final _blockingActive = ValueNotifier(true);
  StreamSubscription<List<FocusLabel>>? _labelChanges;
  StreamSubscription<String>? _blockedApps;
  StreamSubscription<MindfulRequest>? _mindfulRequests;

  /// The open breathing pause, if any: a new request or leaving Focus
  /// removes it, so it never stays with a ready “Open” (#254).
  Route<void>? _breathRoute;

  /// The open blocked screen, if any: a new attempt replaces it, so they
  /// never pile up (#273).
  Route<void>? _blockedRoute;

  /// The sentence typed on the home screen for the next session.
  final _intention = TextEditingController();
  StreamSubscription<void>? _startRequests;
  StreamSubscription<FocusSession?>? _sessionChanges;

  /// Whether the session screen is open, so it is never pushed twice.
  var _sessionShown = false;
  var _focusTimes = const <FocusTime>[];
  StreamSubscription<List<FocusTime>>? _focusTimeChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _labelChanges = widget.labels.watchLabels().listen((labels) {
      if (mounted) setState(() => _labels = labels);
      _publishWidget();
    });
    // Today's focus time changes when a session ends.
    _sessionChanges = widget.timer.changes.listen((_) => _loadState());
    _focusTimeChanges = widget.focusTimes.watchFocusTimes().listen(
      _onFocusTimesChanged,
    );
    _blockedApps = widget.appBlocker.blockedAppOpened.listen(_showBlocked);
    _mindfulRequests = widget.appBlocker.mindfulOpenRequested.listen(
      _showBreath,
    );
    _startRequests = widget.reminders.startRequested.listen(
      (_) => _startFromReminder(),
    );
    _loadState();
    _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _labelChanges?.cancel();
    _blockedApps?.cancel();
    _mindfulRequests?.cancel();
    _startRequests?.cancel();
    _sessionChanges?.cancel();
    _focusTimeChanges?.cancel();
    _blockingActive.dispose();
    _intention.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have granted a permission in the system settings.
    if (state == AppLifecycleState.resumed) {
      _loadState();
      _adoptWidgetStart();
    }
    // Left without deciding: the pause must start over next time.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _closeBreath();
    }
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
    final language = await widget.language?.load() ?? _language;
    final ambient = await widget.settings.loadAmbient();
    final background = await widget.settings.loadBackground();
    if (!mounted) return;
    final languageChanged = language != _language;
    setState(() {
      _pomodoro = pomodoro;
      _selectedLabelId = selectedLabelId;
      _dailyGoal = dailyGoal;
      _focusedToday = focusedToday;
      _blockedAppCount = blockList.length;
      _blockerEnabled = blockerEnabled;
      _notificationGateEnabled = notificationGateEnabled;
      _language = language;
      _ambient = ambient;
      _background = background;
    });
    _blockingActive.value = blockerEnabled || blockList.length == 0;
    if (languageChanged) {
      // E.g. changed in the Android settings while Focus was away.
      widget.onLanguageChanged?.call(language);
      await _publishReminders();
    }
    await _publishWidget();
  }

  /// The settings saved a new language: switch now and republish the texts
  /// shown by native code.
  Future<void> _onLanguageChanged(AppLanguage language) async {
    setState(() => _language = language);
    widget.onLanguageChanged?.call(language);
    await _publishReminders();
    await _publishWidget();
  }

  /// Hands the widget the defaults for a one-tap start and today's progress.
  Future<void> _publishWidget() async {
    final bridge = widget.homeWidget;
    if (bridge == null) return;
    final label = _labelWithId(_selectedLabelId);
    await bridge.publish(
      WidgetSnapshot(
        focus: _pomodoro.focus,
        labelId: label?.id,
        labelName: label?.name,
        focusedToday: _focusedToday,
        dailyGoal: _dailyGoal.duration,
      ),
    );
  }

  /// Takes over a session the widget started while Focus was closed and
  /// shows it; returns whether one was adopted.
  Future<bool> _adoptWidgetStart() async {
    final bridge = widget.homeWidget;
    if (bridge == null || widget.timer.current != null) return false;
    final pending = await bridge.takePendingStart();
    if (pending == null || widget.timer.current != null) return false;
    await widget.timer.adopt(pending);
    if (!mounted || widget.timer.current == null) return false;
    setState(() => _introDone = true);
    if (!_sessionShown) await _pushSession();
    return true;
  }

  /// Continues a session that was running when Focus was closed, and shows
  /// the blocked screen if Focus was launched for a paused app.
  Future<void> _restore() async {
    final session = await widget.timer.restore();
    final blockedPackage = await widget.appBlocker.initialBlockedPackage();
    final startRequested = await widget.reminders.initialStartRequest();
    final mindful = await widget.appBlocker.initialMindfulRequest();
    if (!mounted) return;
    if (session == null) {
      if (mindful != null) {
        await _showBreath(mindful);
        return;
      }
      if (await _adoptWidgetStart()) return;
      if (startRequested) await _startFromReminder();
      return;
    }
    _pushSession();
    if (blockedPackage != null) await _showBlocked(blockedPackage);
  }

  /// The focus time reminder was tapped: start focusing with the default
  /// duration, or show the session that already runs.
  Future<void> _startFromReminder() async {
    if (widget.timer.current != null) {
      if (!_sessionShown) await _pushSession();
      return;
    }
    final pomodoro = await widget.settings.loadPomodoro();
    if (!mounted || widget.timer.current != null) return;
    setState(() => _introDone = true);
    await widget.timer.start(
      pomodoro.focus,
      labelId: _labelWithId(_selectedLabelId)?.id,
    );
    await _pushSession();
  }

  /// Publishes focus times to the native side: the blocker enforces them on
  /// its own and reminders are scheduled from the published state.
  Future<void> _onFocusTimesChanged(List<FocusTime> times) async {
    if (mounted) setState(() => _focusTimes = times);
    await widget.timer.refreshBlocking();
    await _publishReminders();
    if (times.isNotEmpty) await widget.reminders.requestPermission();
  }

  /// Schedules the focus time reminders with texts in the app language.
  Future<void> _publishReminders() async {
    final l10n = localizationsFor(_language);
    await widget.reminders.reschedule((
      channelName: l10n.focusTimeReminderChannel,
      title: l10n.focusTimeUntil('{time}'),
      body: l10n.focusTimeReminderBody,
    ));
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
      locale: localeOf(_language),
      builder: (context, child) => CalmMotion(
        enabled: widget.motion,
        child: BackgroundChoice(
          style: _background,
          child: child ?? const SizedBox(),
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _introDone
            ? Builder(builder: (context) => _places(context))
            : IntroScreen(onDone: () => setState(() => _introDone = true)),
      ),
    );
  }

  /// The four places under one bar (#393): system back returns to Home
  /// first; focused screens are pushed routes and never show the bar.
  Widget _places(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            Builder(builder: _home),
            FocusTimesScreen(
              focusTimes: widget.focusTimes,
              namedLists: widget.namedBlockLists,
              clock: widget.clock,
            ),
            _StatisticsTab(
              blockList: widget.blockList,
              namedBlockLists: widget.namedBlockLists,
              installedApps: widget.installedApps,
              builder: (defaultApps, listApps, appNames) => StatisticsScreen(
                finishedSessions: widget.timer.watchFinished(),
                labels: widget.labels.watchLabels(),
                dailyGoal: _dailyGoal,
                clock: widget.clock,
                focusTimes: widget.focusTimes.watchFocusTimes(),
                pausedAppCount: _blockedAppCount,
                defaultApps: defaultApps,
                listApps: listApps,
                appNames: appNames,
              ),
            ),
            SettingsScreen(
              settings: widget.settings,
              focusTimes: widget.focusTimes,
              backupFiles: widget.backupFiles,
              namedBlockLists: widget.namedBlockLists,
              language: widget.language,
              onLanguageChanged: _onLanguageChanged,
              onLockScreenChanged: widget.timer.refreshCountdown,
              onBackgroundChanged: (style) =>
                  setState(() => _background = style),
              onMindfulChanged: widget.timer.refreshBlocking,
              installedApps: widget.installedApps,
              mindfulApps: widget.mindfulApps,
              restoreLock: () => widget.timer.current != null
                  ? RestoreLock.session
                  : activeFocusTime(_focusTimes, widget.clock()) != null
                  ? RestoreLock.focusTime
                  : RestoreLock.none,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            setState(() => _tab = index);
            // Settings and focus times may have changed what home shows.
            _loadState();
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_view_week_outlined),
              selectedIcon: const Icon(Icons.calendar_view_week),
              label: l10n.viewWeek,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l10n.statistics,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _home(BuildContext homeContext) => HomeScreen(
                  clock: widget.clock,
                  focusDuration: _pomodoro.focus,
                  onStart: _startSession,
                  onChooseDuration: () => _chooseDuration(homeContext),
                  onChooseDailyGoal: () => _chooseDailyGoal(homeContext),
                  intention: _intention,
                  soundName: ambientSoundName(
                    AppLocalizations.of(homeContext),
                    _ambient.sound,
                  ),
                  onChooseSound: () => _chooseSound(homeContext),
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
                  activeFocusTime: activeFocusTime(_focusTimes, widget.clock()),
                  nextFocusTimeStart: nextFocusTimeStart(
                    _focusTimes,
                    widget.clock(),
                  ),
                );

  Future<void> _push(WidgetBuilder builder) async {
    await _navigator.currentState?.push(
      MaterialPageRoute<void>(builder: builder),
    );
  }




  Future<void> _openBlockedApps() async {
    await _push(
      (context) => BlockListsScreen(
        apps: widget.installedApps,
        defaultList: widget.blockList,
        namedLists: widget.namedBlockLists,
        activeSession: widget.timer.current,
        activeFocusTime: activeFocusTime(_focusTimes, widget.clock()),
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
        consentLabel: l10n.agreeAndOpenSettings,
        onOpenSettings: widget.appBlocker.openBlockerSettings,
        onOpenAppInfo: widget.appBlocker.openAppInfo,
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
        onOpenAppInfo: widget.appBlocker.openAppInfo,
      );
    });
    await _loadState();
  }

  /// Sound and volume for sessions; without a session the choice is
  /// previewed while the sheet is open.
  Future<void> _chooseSound(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => AmbientSheet(
        initial: _ambient,
        onChanged: (choice) async {
          setState(() => _ambient = choice);
          await widget.settings.saveAmbient(choice);
          if (widget.timer.current != null) {
            await widget.timer.refreshAmbient();
          } else if (!choice.sound.isBundled) {
            // Off, or the music app – which mustn't start just for a preview.
            await widget.ambientPlayer?.stop();
          } else {
            await widget.ambientPlayer?.play(
              choice.sound,
              volume: choice.volume,
            );
          }
        },
      ),
    );
    if (widget.timer.current == null) await widget.ambientPlayer?.stop();
  }

  /// The session length from the wheel; saved as the Pomodoro focus length,
  /// so home and settings always show the same value (#287).
  Future<void> _chooseDuration(BuildContext context) async {
    final chosen = await showDurationWheel(
      context,
      title: AppLocalizations.of(context).sessionLength,
      initial: _pomodoro.focus,
      min: const Duration(minutes: 5),
      max: Duration(minutes: PomodoroField.focus.max),
    );
    if (chosen == null || !mounted) return;
    final next = _pomodoro.withValue(PomodoroField.focus, chosen.inMinutes);
    setState(() => _pomodoro = next);
    await widget.settings.savePomodoro(next);
  }

  /// The daily goal from the wheel, opened by holding the goal ring (#288,
  /// #303).
  Future<void> _chooseDailyGoal(BuildContext context) async {
    final chosen = await showDurationWheel(
      context,
      title: AppLocalizations.of(context).settingsDailyGoal,
      initial: _dailyGoal.duration,
      min: const Duration(minutes: DailyGoal.minMinutes),
      max: const Duration(minutes: DailyGoal.maxMinutes),
    );
    if (chosen == null || !mounted) return;
    final goal = DailyGoal.validated(chosen.inMinutes);
    setState(() => _dailyGoal = goal);
    await widget.settings.saveDailyGoal(goal);
    await _publishWidget();
  }

  Future<void> _chooseLabel(BuildContext context) async {
    final sessions = await widget.timer.watchFinished().first;
    if (!context.mounted) return;
    final ids = {for (final label in _labels) label.id};
    final totals = labelTotals(sessions, labelIds: ids);
    final weekTotals = labelWeekTotals(
      sessions,
      labelIds: ids,
      today: widget.clock(),
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => LabelSheet(
        labels: _labels,
        totals: totals,
        weekTotals: weekTotals,
        selectedId: _labelWithId(_selectedLabelId)?.id,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          setState(() => _selectedLabelId = id);
          widget.settings.saveSelectedLabelId(id);
        },
        onManage: () {
          Navigator.of(sheetContext).pop();
          _push(
            (context) => LabelsScreen(
              labels: widget.labels,
              sessions: widget.timer.watchFinished(),
              clock: widget.clock,
            ),
          );
        },
      ),
    );
  }

  Future<void> _startSession() async {
    final intention = _intention.text;
    await widget.timer.start(
      _pomodoro.focus,
      labelId: _labelWithId(_selectedLabelId)?.id,
      intention: intention,
    );
    _intention.clear();
    await _pushSession();
  }

  /// Shows the running session; home is refreshed once it is done.
  Future<void> _pushSession() async {
    final labelName = _labelWithId(widget.timer.current?.labelId)?.name;
    // A blocked screen from a focus time would return after the session.
    _closeBlocked();
    _sessionShown = true;
    await _push(
      (context) => SessionScreen(
        timer: widget.timer,
        clock: widget.clock,
        labelName: labelName,
        blockingActive: _blockingActive,
        onTurnBlockingOn: widget.appBlocker.openBlockerSettings,
        onDone: (outcome) => _afterSession(context, outcome),
      ),
    );
    _sessionShown = false;
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
    final lists = await widget.namedBlockLists.watchLists().first;
    final listName = [
      for (final list in lists)
        if (list.id == focusTime?.blockListId) list.name,
    ].firstOrNull;
    final apps = await widget.installedApps.installedApps();
    final label = [
      for (final app in apps)
        if (app.packageName == packageName) app.label,
    ].firstOrNull;
    final now = widget.clock();
    if (!mounted) return;
    _closeBlocked();
    final route = MaterialPageRoute<void>(
      builder: (context) => BlockedScreen(
        appLabel: label ?? packageName,
        remaining: switch (session) {
          final session? when !session.isPaused => session.remaining(now),
          _ => null,
        },
        focusTime: focusTime,
        blockListName: listName,
        clock: widget.clock,
        onReturn: () => Navigator.of(context).pop(),
      ),
    );
    _blockedRoute = route;
    await _navigator.currentState?.push(route);
    if (_blockedRoute == route) _blockedRoute = null;
  }

  /// Removes the open blocked screen, e.g. before showing a newer one.
  void _closeBlocked() {
    final route = _blockedRoute;
    _blockedRoute = null;
    if (route != null && route.isActive) {
      _navigator.currentState?.removeRoute(route);
    }
  }

  /// A paused app was opened with mindful opening on: breathe first, then
  /// open it or go back to the home screen.
  Future<void> _showBreath(MindfulRequest request) async {
    _closeBreath();
    final apps = await widget.installedApps.installedApps();
    final pause = await widget.settings.loadMindfulPause();
    if (!mounted) return;
    final label = [
      for (final app in apps)
        if (app.packageName == request.packageName) app.label,
    ].firstOrNull;
    // A newer request may have opened its pause in the meantime.
    _closeBreath();
    final route = MaterialPageRoute<void>(
      builder: (context) => BreathScreen(
        appLabel: label ?? request.packageName,
        openedToday: request.openedToday,
        pause: pause,
        onOpen: () {
          widget.appBlocker.openMindfully(request.packageName);
          Navigator.of(context).pop();
        },
        onGoBack: () {
          widget.appBlocker.goHome();
          Navigator.of(context).pop();
        },
      ),
    );
    _breathRoute = route;
    await _navigator.currentState?.push(route);
    if (_breathRoute == route) _breathRoute = null;
  }

  /// Removes the open breathing pause without opening the app.
  void _closeBreath() {
    final route = _breathRoute;
    _breathRoute = null;
    if (route != null && route.isActive) {
      _navigator.currentState?.removeRoute(route);
    }
  }

  /// Stores the reflection on the session that just ended.
  Future<void> _reflectOnLastSession(SessionReflection reflection) async {
    final last = (await widget.timer.watchFinished().first).lastOrNull;
    if (last != null) await widget.timer.reflect(last, reflection);
  }

  /// A completed session is followed by the right break; a cancelled one
  /// returns home.
  Future<void> _afterSession(
    BuildContext context,
    SessionOutcome outcome,
  ) async {
    final navigator = Navigator.of(context);
    // The apps are free again; the session screen must be on top.
    _closeBlocked();
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
              onReflect: _reflectOnLastSession,
            ),
          ),
        );
    }
  }
}

/// Statistics as a tab: loads the app names and block lists it needs once,
/// instead of the old load-then-push route (#393). The live parts come in
/// through streams.
class _StatisticsTab extends StatefulWidget {
  const _StatisticsTab({
    required this.blockList,
    required this.namedBlockLists,
    required this.installedApps,
    required this.builder,
  });

  final BlockListRepository blockList;
  final NamedBlockListRepository namedBlockLists;
  final InstalledAppsSource installedApps;
  final Widget Function(
    Set<String> defaultApps,
    Map<String, Set<String>> listApps,
    Map<String, String> appNames,
  )
  builder;

  @override
  State<_StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<_StatisticsTab> {
  late final Future<
    (Set<String>, Map<String, Set<String>>, Map<String, String>)
  >
  _lookups = _load();

  Future<(Set<String>, Map<String, Set<String>>, Map<String, String>)>
  _load() async {
    final defaultList = await widget.blockList.loadBlockList();
    final lists = await widget.namedBlockLists.watchLists().first;
    final apps = await widget.installedApps.installedApps();
    return (
      defaultList.packageNames,
      {for (final list in lists) list.id: list.apps.packageNames},
      {for (final app in apps) app.packageName: app.label},
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _lookups,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      final (defaultApps, listApps, appNames) = data;
      return widget.builder(defaultApps, listApps, appNames);
    },
  );
}
