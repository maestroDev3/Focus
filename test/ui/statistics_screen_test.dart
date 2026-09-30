import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    List<FocusSession> sessions,
  ) async {
    await tester.pumpApp(
      StatisticsScreen(
        finishedSessions: Stream.value(sessions),
        labels: Stream.value(labels),
        clock: () => now,
      ),
    );
    await tester.pump();
  }

  group('StatisticsScreen', () {
    testWidgets('shows today and this week', (tester) async {
      await pumpStatistics(tester, [
        completed(DateTime(2026, 9, 30, 9), 30),
        completed(DateTime(2026, 9, 30, 11), 30),
        completed(DateTime(2026, 9, 28, 9), 140),
        completed(DateTime(2026, 9, 21, 9), 45),
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
      expect(find.byKey(const ValueKey('week-bar-2')), findsOneWidget);
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
  });
}
