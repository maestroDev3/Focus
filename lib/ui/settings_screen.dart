import 'package:flutter/material.dart';

import '../domain/daily_goal.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_text.dart';

/// Lets the user tune the Pomodoro rhythm; every change is saved at once.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final SettingsRepository settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PomodoroSettings? _pomodoro;
  var _dailyGoal = const DailyGoal();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pomodoro = await widget.settings.loadPomodoro();
    final dailyGoal = await widget.settings.loadDailyGoal();
    if (!mounted) return;
    setState(() {
      _pomodoro = pomodoro;
      _dailyGoal = dailyGoal;
    });
  }

  Future<void> _step(PomodoroField field, {required bool up}) async {
    final current = _pomodoro;
    if (current == null) return;
    final next = current.step(field, up: up);
    if (next == current) return;
    setState(() => _pomodoro = next);
    await widget.settings.savePomodoro(next);
  }

  Future<void> _stepGoal({required bool up}) async {
    final next = _dailyGoal.step(up: up);
    if (next == _dailyGoal) return;
    setState(() => _dailyGoal = next);
    await widget.settings.saveDailyGoal(next);
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
                  ),
                _StepperRow(
                  keyName: 'dailyGoal',
                  name: l10n.settingsDailyGoal,
                  value: focusTimeText(l10n, _dailyGoal.duration),
                  onStep: _stepGoal,
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
  });

  /// Prefix of the button keys, e.g. `focus` → `focus-increase`.
  final String keyName;
  final String name;
  final String value;
  final void Function({required bool up}) onStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      title: Text(name),
      subtitle: Text(
        value,
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
