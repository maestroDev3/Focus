import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/app_language.dart';
import '../domain/backup.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_time_repository.dart';
import '../domain/named_block_list.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'app_locale.dart';
import 'focus_time_text.dart';
import 'focus_times_screen.dart';

/// Why restoring a backup is not possible right now: blocking is strict
/// during a session or focus time, and a restore could shrink the lists.
enum RestoreLock { none, session, focusTime }

RestoreLock _unlocked() => RestoreLock.none;

/// Lets the user tune the Pomodoro rhythm; every change is saved at once.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.focusTimes,
    required this.backupFiles,
    this.namedBlockLists,
    this.language,
    this.onLanguageChanged,
    this.restoreLock = _unlocked,
    this.onLockScreenChanged,
  });

  /// Called after “Show on lock screen” changed, so a running countdown
  /// follows at once.
  final VoidCallback? onLockScreenChanged;

  /// Asked on every build and before restoring, so a focus time that starts
  /// while the settings are open still locks the restore.
  final RestoreLock Function() restoreLock;

  /// The chosen app language; without it the settings offer no language.
  final AppLanguageSetting? language;

  /// Called after a new language was saved, so the app switches at once.
  final ValueChanged<AppLanguage>? onLanguageChanged;

  /// Named block lists focus times can use.
  final NamedBlockListRepository? namedBlockLists;

  final SettingsRepository settings;

  /// Recurring focus times, edited on their own screen.
  final FocusTimeRepository focusTimes;

  /// Exports and restores backups.
  final BackupFiles backupFiles;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PomodoroSettings? _pomodoro;
  var _dailyGoal = const DailyGoal();
  AppLanguage? _language;
  var _showOnLockScreen = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pomodoro = await widget.settings.loadPomodoro();
    final dailyGoal = await widget.settings.loadDailyGoal();
    final language = await widget.language?.load();
    final showOnLockScreen = await widget.settings.loadShowOnLockScreen();
    if (!mounted) return;
    setState(() {
      _pomodoro = pomodoro;
      _dailyGoal = dailyGoal;
      _language = language;
      _showOnLockScreen = showOnLockScreen;
    });
  }

  Future<void> _setShowOnLockScreen(bool show) async {
    setState(() => _showOnLockScreen = show);
    await widget.settings.saveShowOnLockScreen(show);
    widget.onLockScreenChanged?.call();
  }

  Future<void> _chooseLanguage() async {
    final setting = widget.language;
    if (setting == null) return;
    final l10n = AppLocalizations.of(context);
    final chosen = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          for (final language in AppLanguage.values)
            ListTile(
              title: Text(languageName(l10n, language)),
              trailing: language == _language ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(language),
            ),
        ],
      ),
    );
    if (chosen == null || chosen == _language) return;
    await setting.save(chosen);
    if (!mounted) return;
    setState(() => _language = chosen);
    widget.onLanguageChanged?.call(chosen);
  }

  Future<void> _step(PomodoroField field, {required bool up}) async {
    final current = _pomodoro;
    if (current == null) return;
    final next = current.step(field, up: up);
    if (next == current) return;
    setState(() => _pomodoro = next);
    await widget.settings.savePomodoro(next);
  }

  /// Lets the user type the value of [field]; saves it within its limits.
  Future<void> _edit(PomodoroField field, String name) async {
    final current = _pomodoro;
    if (current == null) return;
    final typed = await showDialog<int>(
      context: context,
      builder: (context) => _ValueDialog(
        title: name,
        initial: current.valueOf(field),
        min: field.min,
        max: field.max,
      ),
    );
    if (typed == null) return;
    final next = current.withValue(field, typed);
    await widget.settings.savePomodoro(next);
    if (!mounted) return;
    setState(() => _pomodoro = next);
  }

  Future<void> _stepGoal({required bool up}) async {
    final next = _dailyGoal.step(up: up);
    if (next == _dailyGoal) return;
    setState(() => _dailyGoal = next);
    await widget.settings.saveDailyGoal(next);
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (await widget.backupFiles.export()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupSaved)));
    }
  }

  Future<void> _restore() async {
    if (widget.restoreLock() != RestoreLock.none) {
      setState(() {});
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final Backup? picked;
    try {
      picked = await widget.backupFiles.pick();
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.notABackup)));
      return;
    }
    if (picked == null || !mounted) return;
    final backup = picked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreBackup),
        content: Text(
          l10n.restoreBackupQuestion(
            backup.sessions.length,
            DateFormat.yMMMd(locale).format(backup.createdAt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.backupFiles.restore(backup);
    await _load();
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupRestored)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pomodoro = _pomodoro;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: pomodoro == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final (field, name, value) in [
                  (
                    PomodoroField.focus,
                    l10n.settingsFocus,
                    l10n.durationMinutes(pomodoro.focus.inMinutes),
                  ),
                  (
                    PomodoroField.shortBreak,
                    l10n.settingsShortBreak,
                    l10n.durationMinutes(pomodoro.shortBreak.inMinutes),
                  ),
                  (
                    PomodoroField.longBreak,
                    l10n.settingsLongBreak,
                    l10n.durationMinutes(pomodoro.longBreak.inMinutes),
                  ),
                  (
                    PomodoroField.sessionsBeforeLongBreak,
                    l10n.settingsLongBreakAfter,
                    l10n.sessionsCount(pomodoro.sessionsBeforeLongBreak),
                  ),
                ])
                  _StepperRow(
                    keyName: field.name,
                    name: name,
                    value: value,
                    onStep: ({required up}) => _step(field, up: up),
                    onEdit: () => _edit(field, name),
                  ),
                _StepperRow(
                  keyName: 'dailyGoal',
                  name: l10n.settingsDailyGoal,
                  value: focusTimeText(l10n, _dailyGoal.duration),
                  onStep: _stepGoal,
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(l10n.focusTimes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          FocusTimesScreen(
                            focusTimes: widget.focusTimes,
                            namedLists: widget.namedBlockLists,
                          ),
                    ),
                  ),
                ),
                SwitchListTile(
                  key: const Key('show-on-lock-screen'),
                  secondary: const Icon(Icons.screen_lock_portrait_outlined),
                  title: Text(l10n.showOnLockScreen),
                  subtitle: Text(l10n.showOnLockScreenDetails),
                  value: _showOnLockScreen,
                  onChanged: _setShowOnLockScreen,
                ),
                const Divider(height: 32),
                if (_language case final language?)
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l10n.language),
                    subtitle: Text(languageName(l10n, language)),
                    onTap: _chooseLanguage,
                  ),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: Text(l10n.exportBackup),
                  onTap: _export,
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(l10n.restoreBackup),
                  subtitle: switch (widget.restoreLock()) {
                    RestoreLock.none => null,
                    RestoreLock.session => Text(l10n.lockedDuringSession),
                    RestoreLock.focusTime => Text(l10n.lockedDuringFocusTime),
                  },
                  enabled: widget.restoreLock() == RestoreLock.none,
                  onTap: _restore,
                ),
              ],
            ),
    );
  }
}

/// One setting with its current value and − / + buttons.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.keyName,
    required this.name,
    required this.value,
    required this.onStep,
    this.onEdit,
  });

  /// Prefix of the button keys, e.g. `focus` → `focus-increase`.
  final String keyName;
  final String name;
  final String value;
  final void Function({required bool up}) onStep;

  /// Opens the dialog for typing the value; null if it can only be stepped.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final edit = onEdit;
    return ListTile(
      onTap: edit,
      title: Text(name),
      subtitle: Text(
        value,
        semanticsLabel: edit == null
            ? null
            : '$value, ${l10n.editSetting(name)}',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('$keyName-decrease'),
            tooltip: l10n.decreaseSetting(name),
            onPressed: () => onStep(up: false),
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            key: Key('$keyName-increase'),
            tooltip: l10n.increaseSetting(name),
            onPressed: () => onStep(up: true),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Asks for a whole number; returns it on Save, null on Cancel or empty input.
class _ValueDialog extends StatefulWidget {
  const _ValueDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final int initial;
  final int min;
  final int max;

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.of(context).pop(int.tryParse(_controller.text.trim()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          helperText: l10n.settingRange(widget.min, widget.max),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
