import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/ui/focus_week_screen.dart';

import '../support/fake_focus_time_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('FocusWeekScreen', () {
    // 2026-10-28 is a Wednesday; outside every seeded range by default.
    final quietNow = DateTime(2026, 10, 28, 20);

    Future<FakeFocusTimeRepository> pumpWeek(
      WidgetTester tester, {
      List<FocusTime> times = const [],
      ValueChanged<FocusTime>? onOpenFocusTime,
      ValueChanged<FocusTimeRange>? onPlanGap,
      DateTime? now,
    }) async {
      final repository = FakeFocusTimeRepository(times);
      await tester.pumpApp(
        FocusWeekScreen(
          focusTimes: repository,
          onOpenFocusTime: onOpenFocusTime,
          onPlanGap: onPlanGap,
          clock: () => now ?? quietNow,
        ),
      );
      await tester.pump();
      return repository;
    }

    Color? entryColor(WidgetTester tester, String key) => tester
        .widget<Material>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(Material),
          ),
        )
        .color;

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

    testWidgets('marks today, the current time and the running entry', (
      tester,
    ) async {
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'running',
            weekdays: {DateTime.wednesday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
          FocusTime(
            id: 'other',
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
        now: DateTime(2026, 10, 28, 10),
      );

      expect(find.byKey(const Key('week-today-3')), findsOneWidget);
      expect(find.byKey(const Key('week-now-line')), findsOneWidget);
      expect(
        entryColor(tester, 'week-entry-3-running-540'),
        isNot(entryColor(tester, 'week-entry-1-other-540')),
      );
    });

    testWidgets('highlights no entry while nothing runs', (tester) async {
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'morning',
            weekdays: {DateTime.wednesday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
          FocusTime(
            id: 'other',
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
      );

      expect(find.byKey(const Key('week-today-3')), findsOneWidget);
      expect(
        entryColor(tester, 'week-entry-3-morning-540'),
        entryColor(tester, 'week-entry-1-other-540'),
      );
    });

    testWidgets('plans a focus time from a long-pressed gap', (tester) async {
      final planned = <FocusTimeRange>[];
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'morning',
            weekdays: {DateTime.wednesday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
        onPlanGap: planned.add,
      );

      // Hours 8-13 are visible; press Wednesday at 12:30 (56 px per hour).
      final day = tester.getTopLeft(find.byKey(const Key('week-day-3')));
      final width = tester
          .getSize(find.byKey(const Key('week-day-3')))
          .width;
      await tester.longPressAt(day + Offset(width / 2, 4.5 * 56));
      await tester.pump();

      expect(planned, hasLength(1));
      expect(planned.single.weekdays, {DateTime.wednesday});
      expect(planned.single.startMinute, 12 * 60);
      expect(planned.single.endMinute, 13 * 60);
    });

    testWidgets('does not plan from a long-pressed entry', (tester) async {
      final planned = <FocusTimeRange>[];
      await pumpWeek(
        tester,
        times: [
          FocusTime(
            id: 'morning',
            weekdays: {DateTime.wednesday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
        onPlanGap: planned.add,
      );

      await tester.longPress(
        find.byKey(const Key('week-entry-3-morning-540')),
      );
      await tester.pump();

      expect(planned, isEmpty);
    });

    testWidgets('says the week is still free without focus times', (
      tester,
    ) async {
      await pumpWeek(tester);

      expect(find.text('The week is still free.'), findsOneWidget);
    });
  });
}
