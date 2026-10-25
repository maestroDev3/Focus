import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/ui/statistics_screen.dart';

import '../support/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 30, 20);
  FocusSession completed(DateTime start, int minutes, [String? labelId]) =>
      FocusSession(
        start: start,
        planned: Duration(minutes: minutes),
        labelId: labelId,
      ).complete();
  final labels = [
    FocusLabel(id: 'study', name: 'Study'),
    FocusLabel(id: 'work', name: 'Work'),
  ];

  Future<void> pumpStatistics(
    WidgetTester tester,
    List<FocusSession> sessions, {
    DailyGoal dailyGoal = const DailyGoal(),
    List<FocusLabel>? labelList,
    List<FocusTime> focusTimes = const [],
    int pausedAppCount = 3,
    Set<String> defaultApps = const {},
    Map<String, Set<String>> listApps = const {},
    Map<String, String> appNames = const {},
  }) async {
    await tester.pumpApp(
      StatisticsScreen(
        finishedSessions: Stream.value(sessions),
        labels: Stream.value(labelList ?? labels),
        focusTimes: Stream.value(focusTimes),
        pausedAppCount: pausedAppCount,
        defaultApps: defaultApps,
        listApps: listApps,
        appNames: appNames,
        dailyGoal: dailyGoal,
        clock: () => now,
      ),
    );
    await tester.pump();
  }

  /// [finder] inside the card with [key] (“by-label”, “all-time”).
  Finder inCard(String key, Finder finder) =>
      find.descendant(of: find.byKey(Key(key)), matching: finder);

  /// Scrolls the label breakdown into view; it lies below the insights.
  Future<void> showByLabel(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.byKey(const Key('by-label')), 200);
  }

  group('StatisticsScreen', () {
    testWidgets('shows today and this week', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 30, 9), 30, 'study'),
        completed(DateTime(2026, 9, 30, 11), 30, 'work'),
        completed(DateTime(2026, 9, 28, 9), 140, 'study'),
        completed(DateTime(2026, 9, 21, 9), 45, 'study'),
      ]);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('3h 20'), findsOneWidget);
    });

    testWidgets('shows a bar for every weekday', (tester) async {
      await pumpStatistics(tester, [completed(DateTime(2026, 9, 30, 9), 30)]);

      for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('day-bar-2')), findsOneWidget);
    });

    testWidgets('shows zero without sessions', (tester) async {
      await pumpStatistics(tester, []);

      expect(find.text('0 min'), findsNWidgets(2));
    });

    testWidgets('breaks this week down by label, largest first', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 28, 9), 25, 'study'),
        completed(DateTime(2026, 9, 29, 9), 50, 'study'),
        completed(DateTime(2026, 9, 29, 14), 40, 'work'),
      ]);
      await showByLabel(tester);

      expect(find.text('By label'), findsOneWidget);
      expect(find.text('1h 15'), findsOneWidget);
      expect(find.text('40 min'), findsOneWidget);
      expect(
        tester.getTopLeft(inCard('by-label', find.text('Study'))).dy,
        lessThan(tester.getTopLeft(inCard('by-label', find.text('Work'))).dy),
      );
    });

    testWidgets('includes earlier sessions of the month on Month', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 3, 9), 25, 'study'),
        completed(DateTime(2026, 9, 29, 9), 40, 'work'),
      ]);
      await showByLabel(tester);
      expect(inCard('by-label', find.text('Study')), findsNothing);

      await tester.scrollUntilVisible(find.text('Month'), -200);
      await tester.tap(find.text('Month'));
      await tester.pump();
      await showByLabel(tester);

      expect(inCard('by-label', find.text('Study')), findsOneWidget);
      expect(inCard('by-label', find.text('Work')), findsOneWidget);
    });

    testWidgets('shows sessions without label as Unlabeled', (tester) async {
      await pumpStatistics(tester, [completed(DateTime(2026, 9, 29, 9), 35)]);
      await showByLabel(tester);

      expect(find.text('Unlabeled'), findsOneWidget);
    });

    testWidgets('shows the current and the best streak', (tester) async {
      await pumpStatistics(tester, [
        for (final day in [20, 21, 22, 23, 28, 29, 30])
          completed(DateTime(2026, 9, day, 9), 60, 'study'),
      ], dailyGoal: DailyGoal.validated(60));

      expect(find.text('Current streak · 3 days'), findsOneWidget);
      expect(find.text('Best · 4 days'), findsOneWidget);
    });

    testWidgets('uses the singular for one day', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 30, 9), 60, 'study'),
      ], dailyGoal: DailyGoal.validated(60));

      expect(find.text('Current streak · 1 day'), findsOneWidget);
      expect(find.text('Best · 1 day'), findsOneWidget);
    });

    testWidgets('shows zero without a streak', (tester) async {
      await pumpStatistics(tester, []);

      expect(find.text('Current streak · 0 days'), findsOneWidget);
    });
  
    testWidgets('shows today with the daily goal by default', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 30, 9), 30, 'study'),
      ]);

      expect(find.text('Wed, Sep 30 · 30 min of 2h'), findsOneWidget);
    });

    testWidgets('shows the focus of a tapped day', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 28, 9), 140, 'study'),
      ]);

      await tester.tap(find.byKey(const ValueKey('day-bar-0')));
      await tester.pump();

      expect(find.text('Mon, Sep 28 · 2h 20 of 2h'), findsOneWidget);
    });

    testWidgets('shows every day of the month on Month', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 2, 9), 45, 'study'),
        completed(DateTime(2026, 9, 30, 9), 30, 'study'),
      ]);

      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(find.byKey(const ValueKey('day-bar-29')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-bar-30')), findsNothing);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('1h 15'), findsWidgets);
    });

    testWidgets('places the period switch above the chart', (tester) async {
      await pumpStatistics(tester, const []);

      expect(
        tester.getTopLeft(find.text('Month')).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('day-bar-0'))).dy),
      );
      expect(
        tester.getTopLeft(find.text('Week')).dy,
        lessThan(tester.getTopLeft(find.text('Today')).dy),
      );
    });

    testWidgets('lists the sessions of the selected day with their ritual', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        FocusSession(
          start: DateTime(2026, 9, 30, 9),
          planned: const Duration(minutes: 25),
          labelId: 'study',
          intention: 'Chapter 3',
        ).complete().withReflection(SessionReflection.flowing),
        completed(DateTime(2026, 9, 29, 9), 30),
      ]);
      final intention = find.text('Chapter 3');
      await tester.scrollUntilVisible(intention, 200);

      expect(intention, findsOneWidget);
      expect(find.text('09:00 · 25 min · Study · Flowing'), findsOneWidget);
    });

    testWidgets('lists every label with its all-time total, largest first', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2025, 1, 5, 9), 25, 'study'),
        completed(DateTime(2026, 9, 29, 9), 50, 'work'),
        completed(DateTime(2026, 9, 30, 9), 40, 'work'),
      ]);
      final card = find.byKey(const Key('all-time'));
      await tester.scrollUntilVisible(card, 200);

      expect(inCard('all-time', find.text('All time')), findsOneWidget);
      expect(inCard('all-time', find.text('1h 30 in total')), findsOneWidget);
      expect(inCard('all-time', find.text('25 min in total')), findsOneWidget);
      expect(
        tester.getTopLeft(inCard('all-time', find.text('Work'))).dy,
        lessThan(tester.getTopLeft(inCard('all-time', find.text('Study'))).dy),
      );
    });

    testWidgets('shows the goal progress in the all-time card', (
      tester,
    ) async {
      await pumpStatistics(
        tester,
        [
          for (var day = 1; day <= 12; day++)
            completed(DateTime(2026, 8, day, 9), 60, 'exam'),
        ],
        labelList: [
          FocusLabel(
            id: 'exam',
            name: 'Exam',
            goal: const Duration(hours: 20),
          ),
        ],
      );
      final card = find.byKey(const Key('all-time'));
      await tester.scrollUntilVisible(card, 200);

      expect(inCard('all-time', find.text('12h of 20h')), findsOneWidget);
      expect(
        inCard('all-time', find.byType(LinearProgressIndicator)),
        findsOneWidget,
      );
    });

    testWidgets('keeps the all-time card when switching the period', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2025, 1, 5, 9), 25, 'study'),
      ]);

      await tester.tap(find.text('Month'));
      await tester.pump();
      final card = find.byKey(const Key('all-time'));
      await tester.scrollUntilVisible(card, 200);

      expect(inCard('all-time', find.text('25 min in total')), findsOneWidget);
    });

    testWidgets('shows how long the paused apps rested this week', (
      tester,
    ) async {
      await pumpStatistics(
        tester,
        [completed(DateTime(2026, 9, 28, 9), 50)],
        focusTimes: [
          FocusTime(
            id: 'tuesday',
            weekdays: const {2},
            startMinute: 7 * 60,
            endMinute: 10 * 60,
          ),
        ],
      );
      await tester.scrollUntilVisible(find.byKey(const Key('insights')), 200);

      expect(inCard('insights', find.text('Insights')), findsOneWidget);
      expect(
        inCard('insights', find.text('Your paused apps rested 3h 50')),
        findsOneWidget,
      );
    });

    testWidgets('shows on how many days of the week I focused', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 28, 9), 25),
        completed(DateTime(2026, 9, 30, 9), 25),
      ]);
      await tester.scrollUntilVisible(find.byKey(const Key('insights')), 200);

      expect(
        inCard('insights', find.text('Focused on 2 of 3 days')),
        findsOneWidget,
      );
    });

    testWidgets('covers the month after switching to Month', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 3, 9), 50),
        completed(DateTime(2026, 9, 28, 9), 25),
        completed(DateTime(2026, 9, 30, 9), 25),
      ]);

      await tester.tap(find.text('Month'));
      await tester.pump();
      await tester.scrollUntilVisible(find.byKey(const Key('insights')), 200);

      expect(
        inCard('insights', find.text('Focused on 3 of 30 days')),
        findsOneWidget,
      );
      expect(
        inCard('insights', find.text('Your paused apps rested 1h 40')),
        findsOneWidget,
      );
    });

    testWidgets('invites to pause apps without any', (tester) async {
      await pumpStatistics(
        tester,
        [completed(DateTime(2026, 9, 28, 9), 25)],
        pausedAppCount: 0,
      );
      await tester.scrollUntilVisible(find.byKey(const Key('insights')), 200);

      expect(
        inCard('insights', find.text('Pause apps to protect your focus time.')),
        findsOneWidget,
      );
    });

    group('paused apps', () {
      final studyEvening = FocusTime(
        id: 'tuesday',
        weekdays: const {2},
        startMinute: 7 * 60,
        endMinute: 10 * 60,
        blockListId: 'study',
      );

      Future<void> pumpApps(
        WidgetTester tester,
        List<FocusSession> sessions,
      ) async {
        await pumpStatistics(
          tester,
          sessions,
          focusTimes: [studyEvening],
          defaultApps: const {'insta', 'tiktok'},
          listApps: const {
            'study': {'insta'},
          },
          appNames: const {'insta': 'Instagram'},
        );
      }

      testWidgets('lists paused apps with their rest time, largest first', (
        tester,
      ) async {
        await pumpApps(tester, [completed(DateTime(2026, 9, 28, 9), 50)]);
        await tester.scrollUntilVisible(
          find.byKey(const Key('paused-apps')),
          200,
        );

        expect(inCard('paused-apps', find.text('Paused apps')), findsOneWidget);
        expect(inCard('paused-apps', find.text('3h 50')), findsOneWidget);
        expect(
          inCard('paused-apps', find.text('3h focus time · 50 min sessions')),
          findsOneWidget,
        );
        expect(
          inCard('paused-apps', find.text('50 min sessions')),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(inCard('paused-apps', find.text('Instagram'))).dy,
          lessThan(
            tester.getTopLeft(inCard('paused-apps', find.text('tiktok'))).dy,
          ),
        );
      });

      testWidgets('covers the month after switching to Month', (
        tester,
      ) async {
        await pumpApps(tester, [
          completed(DateTime(2026, 9, 3, 9), 25),
          completed(DateTime(2026, 9, 28, 9), 50),
        ]);

        await tester.tap(find.text('Month'));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const Key('paused-apps')),
          200,
        );

        expect(inCard('paused-apps', find.text('1h 15')), findsOneWidget);
      });

      testWidgets('is hidden without any rest time', (tester) async {
        await pumpStatistics(tester, [
          completed(DateTime(2026, 9, 28, 9), 50),
        ]);
        await tester.scrollUntilVisible(find.byKey(const Key('by-label')), 200);

        expect(find.byKey(const Key('paused-apps')), findsNothing);
      });
    });
  });
}
