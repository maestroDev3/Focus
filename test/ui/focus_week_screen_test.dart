import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/ui/focus_week_screen.dart';

import '../support/fake_focus_time_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('FocusWeekScreen', () {
    Future<FakeFocusTimeRepository> pumpWeek(
      WidgetTester tester, {
      List<FocusTime> times = const [],
      ValueChanged<FocusTime>? onOpenFocusTime,
    }) async {
      final repository = FakeFocusTimeRepository(times);
      await tester.pumpApp(
        FocusWeekScreen(
          focusTimes: repository,
          onOpenFocusTime: onOpenFocusTime,
        ),
      );
      await tester.pump();
      return repository;
    }

    testWidgets('shows every range on its weekdays', (tester) async {
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'morning',
            weekdays: {DateTime.monday, DateTime.wednesday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
      );

      expect(find.byKey(const Key('week-entry-1-morning-540')), findsOneWidget);
      expect(find.byKey(const Key('week-entry-3-morning-540')), findsOneWidget);
      expect(find.byKey(const Key('week-entry-2-morning-540')), findsNothing);
    });

    testWidgets('shows overlapping entries side by side', (tester) async {
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'first',
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 11 * 60,
          ),
          FocusTime(
            id: 'second',
            weekdays: {DateTime.monday},
            startMinute: 10 * 60,
            endMinute: 12 * 60,
          ),
        ],
      );

      final first = tester.getRect(
        find.byKey(const Key('week-entry-1-first-540')),
      );
      final second = tester.getRect(
        find.byKey(const Key('week-entry-1-second-600')),
      );
      expect(first.overlaps(second), isFalse);
    });

    testWidgets('opens the focus time when an entry is tapped', (
      tester,
    ) async {
      final opened = <FocusTime>[];
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'morning',
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
        onOpenFocusTime: opened.add,
      );

      await tester.tap(find.byKey(const Key('week-entry-1-morning-540')));
      await tester.pump();

      expect(opened.map((time) => time.id), ['morning']);
    });

    testWidgets('says the week is still free without focus times', (
      tester,
    ) async {
      await pumpWeek(tester);

      expect(find.text('The week is still free.'), findsOneWidget);
    });
  });
}
