import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/json_backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/ui/settings_screen.dart';

import '../support/backup_files_for_tests.dart';
import '../support/fake_document_store.dart';
import '../support/fake_focus_time_repository.dart';
import '../support/fake_label_repository.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

void main() {
  late FakeSessionRepository sessions;
  late FakeDocumentStore documents;

  setUp(() {
    sessions = FakeSessionRepository();
    documents = FakeDocumentStore();
  });

  group('SettingsScreen', () {
    Future<FakeSettingsRepository> pumpSettings(
      WidgetTester tester, [
      PomodoroSettings pomodoro = const PomodoroSettings(),
    ]) async {
      final repository = FakeSettingsRepository(pomodoro);
      await tester.pumpApp(
        SettingsScreen(
          settings: repository,
          focusTimes: FakeFocusTimeRepository(),
          backupFiles: backupFilesForTests(
            sessions: sessions,
            labels: FakeLabelRepository(),
            settings: repository,
            documents: documents,
          ),
        ),
      );
      await tester.pump();
      return repository;
    }

    testWidgets('shows the stored values', (tester) async {
      await pumpSettings(
        tester,
        const PomodoroSettings(
          focus: Duration(minutes: 50),
          shortBreak: Duration(minutes: 10),
          longBreak: Duration(minutes: 30),
          sessionsBeforeLongBreak: 3,
        ),
      );

      expect(find.text('50 min'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('3 sessions'), findsOneWidget);
    });

    testWidgets('increases the focus duration and saves it', (tester) async {
      final repository = await pumpSettings(tester);

      await tester.tap(find.byKey(const Key('focus-increase')));
      await tester.pump();

      expect(find.text('30 min'), findsOneWidget);
      expect(repository.pomodoro.focus, const Duration(minutes: 30));
    });

    testWidgets('does nothing below the minimum', (tester) async {
      final repository = await pumpSettings(
        tester,
        const PomodoroSettings(shortBreak: Duration(minutes: 1)),
      );

      await tester.tap(find.byKey(const Key('shortBreak-decrease')));
      await tester.pump();

      expect(find.text('1 min'), findsOneWidget);
      expect(repository.pomodoro.shortBreak, const Duration(minutes: 1));
    });

    testWidgets('labels the steppers for screen readers', (tester) async {
      await pumpSettings(tester);

      expect(find.byTooltip('Increase Focus'), findsOneWidget);
      expect(find.byTooltip('Decrease Long break after'), findsOneWidget);
    });

    testWidgets('changes the daily goal in 10 minute steps', (tester) async {
      final repository = await pumpSettings(tester);
      expect(find.text('2h'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dailyGoal-increase')));
      await tester.pump();

      expect(find.text('2h 10'), findsOneWidget);
      expect(repository.dailyGoal.minutes, 130);
    });

    testWidgets('exports a backup', (tester) async {
      await pumpSettings(tester);

      await tester.scrollUntilVisible(find.text('Export backup'), 100);
      await tester.tap(find.text('Export backup'));
      await tester.pump();
      await tester.pump();

      expect(documents.savedText, isNotNull);
      expect(find.text('Backup saved.'), findsOneWidget);
    });

    testWidgets('restores a backup after confirmation', (tester) async {
      final repository = await pumpSettings(tester);
      documents.textToOpen = const JsonBackupCodec().encode(
        Backup(
          createdAt: DateTime(2026, 9, 29),
          sessions: [
            for (var hour = 8; hour < 11; hour++)
              FocusSession(
                start: DateTime(2026, 9, 29, hour),
                planned: const Duration(minutes: 25),
              ).complete(),
          ],
          labels: const [],
          pomodoro: const PomodoroSettings(focus: Duration(minutes: 45)),
          dailyGoal: DailyGoal.validated(90),
        ),
      );

      await tester.scrollUntilVisible(find.text('Restore backup'), 100);
      await tester.tap(find.text('Restore backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Replace your data with 3 sessions from Sep 29, 2026?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Replace'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sessions.finished, hasLength(3));
      expect(repository.pomodoro.focus, const Duration(minutes: 45));
      expect(find.text('Backup restored.'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('changes nothing when the restore is cancelled', (
      tester,
    ) async {
      final repository = await pumpSettings(tester);
      documents.textToOpen = const JsonBackupCodec().encode(
        Backup(
          createdAt: DateTime(2026, 9, 29),
          sessions: const [],
          labels: const [],
          pomodoro: const PomodoroSettings(focus: Duration(minutes: 45)),
          dailyGoal: const DailyGoal(),
        ),
      );

      await tester.scrollUntilVisible(find.text('Restore backup'), 100);
      await tester.tap(find.text('Restore backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.pomodoro, const PomodoroSettings());
    });

    testWidgets('explains a file that is not a backup', (tester) async {
      await pumpSettings(tester);
      documents.textToOpen = '{"hello":"world"}';

      await tester.scrollUntilVisible(find.text('Restore backup'), 100);
      await tester.tap(find.text('Restore backup'));
      await tester.pump();
      await tester.pump();

      expect(find.text('This file is not a Focus backup.'), findsOneWidget);
    });

    testWidgets('opens the focus times', (tester) async {
      await pumpSettings(tester);

      await tester.scrollUntilVisible(find.text('Focus times'), 100);
      await tester.tap(find.text('Focus times'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add focus time'), findsOneWidget);
    });
  });
}
