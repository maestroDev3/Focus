import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/domain/settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.pomodoro = const PomodoroSettings()]);

  PomodoroSettings pomodoro;
  String? selectedLabelId;
  DailyGoal dailyGoal = const DailyGoal();
  bool showOnLockScreen = true;
  bool mindfulOpening = false;

  @override
  Future<PomodoroSettings> loadPomodoro() async => pomodoro;

  @override
  Future<void> savePomodoro(PomodoroSettings settings) async =>
      pomodoro = settings;

  @override
  Future<String?> loadSelectedLabelId() async => selectedLabelId;

  @override
  Future<void> saveSelectedLabelId(String? id) async => selectedLabelId = id;

  @override
  Future<DailyGoal> loadDailyGoal() async => dailyGoal;

  @override
  Future<void> saveDailyGoal(DailyGoal goal) async => dailyGoal = goal;

  @override
  Future<bool> loadShowOnLockScreen() async => showOnLockScreen;

  @override
  Future<void> saveShowOnLockScreen(bool show) async => showOnLockScreen = show;

  @override
  Future<bool> loadMindfulOpening() async => mindfulOpening;

  @override
  Future<void> saveMindfulOpening(bool on) async => mindfulOpening = on;
}
