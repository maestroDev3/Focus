import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/domain/settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.pomodoro = const PomodoroSettings()]);

  PomodoroSettings pomodoro;
  String? selectedLabelId;

  @override
  Future<PomodoroSettings> loadPomodoro() async => pomodoro;

  @override
  Future<void> savePomodoro(PomodoroSettings settings) async =>
      pomodoro = settings;

  @override
  Future<String?> loadSelectedLabelId() async => selectedLabelId;

  @override
  Future<void> saveSelectedLabelId(String? id) async => selectedLabelId = id;
}
