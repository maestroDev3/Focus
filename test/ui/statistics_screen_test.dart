import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_session.dart';
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
  }) async {
    await tester.pumpApp(
      StatisticsScreen(
        finishedSessions: Stream.value(sessions),
        labels: Stream.value(labels),
        dailyGoal: dailyGoal,
        clock: () => now,
      ),
    );
    await tester.pump();
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

      expect(find.text('By label'), findsOneWidget);
      expect(find.text('1h 15'), findsOneWidget);
      expect(find.text('40 min'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Study')).dy,
        lessThan(tester.getTopLeft(find.text('Work')).dy),
      );
    });

    testWidgets('includes earlier sessions of the month on Month', (
      tester,
    ) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 3, 9), 25, 'study'),
        completed(DateTime(2026, 9, 29, 9), 40, 'work'),
      ]);
      expect(find.text('Study'), findsNothing);

      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('shows sessions without label as Unlabeled', (tester) async {
      await pumpStatistics(tester, [completed(DateTime(2026, 9, 29, 9), 35)]);

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
});
}
