import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/pomodoro.dart';

import '../support/fake_label_repository.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/sample_sessions.dart';

void main() {
  final now = DateTime(2026, 9, 30, 21);
  late FakeSessionRepository sessions;
  late FakeLabelRepository labels;
  late FakeSettingsRepository settings;
  late BackupService service;

  setUp(() {
    sessions = FakeSessionRepository()..finished.add(completedSample());
    labels = FakeLabelRepository([FocusLabel(id: 'label-1', name: 'Study')]);
    settings = FakeSettingsRepository(
      const PomodoroSettings(focus: Duration(minutes: 50)),
    )..dailyGoal = DailyGoal.validated(180);
    service = BackupService(
      sessions: sessions,
      labels: labels,
      settings: settings,
      clock: () => now,
    );
  });

  group('BackupService', () {
    test('collects all data into a backup', () async {
      expect(
        await service.create(),
        Backup(
          createdAt: now,
          sessions: [completedSample()],
          labels: [FocusLabel(id: 'label-1', name: 'Study')],
          pomodoro: const PomodoroSettings(focus: Duration(minutes: 50)),
          dailyGoal: DailyGoal.validated(180),
        ),
      );
    });

    test('restores a backup by replacing the data', () async {
      await service.restore(
        Backup(
          createdAt: now,
          sessions: [cancelledSample()],
          labels: [FocusLabel(id: 'label-9', name: 'Work')],
          pomodoro: const PomodoroSettings(),
          dailyGoal: DailyGoal.validated(60),
        ),
      );

      expect(sessions.finished, [cancelledSample()]);
      expect(labels.labels, [FocusLabel(id: 'label-9', name: 'Work')]);
      expect(settings.pomodoro, const PomodoroSettings());
      expect(settings.dailyGoal, DailyGoal.validated(60));
    });
  });
}
