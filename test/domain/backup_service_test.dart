import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/named_block_list.dart';
import 'package:focus_timer/domain/pomodoro.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_focus_time_repository.dart';
import '../support/fake_label_repository.dart';
import '../support/fake_named_block_list_repository.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/sample_sessions.dart';

void main() {
  final now = DateTime(2026, 9, 30, 21);
  late FakeSessionRepository sessions;
  late FakeLabelRepository labels;
  late FakeSettingsRepository settings;
  late FakeBlockListRepository blockList;
  late FakeNamedBlockListRepository namedLists;
  late FakeFocusTimeRepository focusTimes;
  late BackupService service;
  final morning = NamedBlockList(
    id: 'list-1',
    name: 'Morning',
    apps: const BlockList({'com.whatsapp'}),
  );
  final weekdays = FocusTime(
    id: 'focus-time-1',
    weekdays: const {1, 2, 3, 4, 5},
    startMinute: 480,
    endMinute: 720,
    blockListId: 'list-1',
  );

  setUp(() {
    blockList = FakeBlockListRepository(
      const BlockList({'com.instagram.android'}),
    );
    namedLists = FakeNamedBlockListRepository([morning]);
    focusTimes = FakeFocusTimeRepository([weekdays]);
    sessions = FakeSessionRepository()..finished.add(completedSample());
    labels = FakeLabelRepository([FocusLabel(id: 'label-1', name: 'Study')]);
    settings = FakeSettingsRepository(
      const PomodoroSettings(focus: Duration(minutes: 50)),
    )..dailyGoal = DailyGoal.validated(180);
    service = BackupService(
      sessions: sessions,
      labels: labels,
      settings: settings,
      blockList: blockList,
      namedLists: namedLists,
      focusTimes: focusTimes,
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
          blocking: BlockingBackup(
            defaultList: const BlockList({'com.instagram.android'}),
            lists: [morning],
            focusTimes: [weekdays],
          ),
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

    test('restores block lists and focus times', () async {
      final evening = NamedBlockList(id: 'list-4', name: 'Evening');
      final weekend = FocusTime(
        id: 'focus-time-9',
        weekdays: const {6, 7},
        startMinute: 600,
        endMinute: 720,
        blockListId: 'list-4',
      );

      await service.restore(
        Backup(
          createdAt: now,
          sessions: const [],
          labels: const [],
          pomodoro: const PomodoroSettings(),
          dailyGoal: const DailyGoal(),
          blocking: BlockingBackup(
            defaultList: const BlockList({'org.telegram'}),
            lists: [evening],
            focusTimes: [weekend],
          ),
        ),
      );

      expect(blockList.blockList, const BlockList({'org.telegram'}));
      expect(namedLists.lists, [evening]);
      expect(focusTimes.times, [weekend]);
    });

    test('keeps blocking as it is for a backup without it', () async {
      await service.restore(
        Backup(
          createdAt: now,
          sessions: const [],
          labels: const [],
          pomodoro: const PomodoroSettings(),
          dailyGoal: const DailyGoal(),
        ),
      );

      expect(blockList.blockList, const BlockList({'com.instagram.android'}));
      expect(namedLists.lists, [morning]);
      expect(focusTimes.times, [weekdays]);
    });
  });
}
