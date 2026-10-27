import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/clock.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/statistics.dart';

void main() {
  FocusSession completed(DateTime start, {int minutes = 25}) => FocusSession(
    start: start,
    planned: Duration(minutes: minutes),
  ).complete();

  group('focusByDay', () {
    test('sums focus per day and keeps empty days at zero', () {
      final sessions = [
        completed(DateTime(2026, 9, 28, 9)),
        completed(DateTime(2026, 9, 28, 11)),
        completed(DateTime(2026, 9, 30, 9), minutes: 50),
      ];

      expect(
        focusByDay(
          sessions,
          from: DateTime(2026, 9, 28),
          to: DateTime(2026, 9, 30),
        ),
        {
          dayOf(DateTime(2026, 9, 28)): const Duration(minutes: 50),
          dayOf(DateTime(2026, 9, 29)): Duration.zero,
          dayOf(DateTime(2026, 9, 30)): const Duration(minutes: 50),
        },
      );
    });

    test('counts a session for the day it ended', () {
      final lateNight = completed(DateTime(2026, 9, 29, 23, 50));

      final days = focusByDay(
        [lateNight],
        from: DateTime(2026, 9, 29),
        to: DateTime(2026, 9, 30),
      );

      expect(days[dayOf(DateTime(2026, 9, 29))], Duration.zero);
      expect(days[dayOf(DateTime(2026, 9, 30))], const Duration(minutes: 25));
    });

    test('ignores running sessions', () {
      final running = FocusSession(
        start: DateTime(2026, 9, 30, 9),
        planned: const Duration(minutes: 25),
      );

      expect(
        focusByDay(
          [running],
          from: DateTime(2026, 9, 30),
          to: DateTime(2026, 9, 30),
        ).values.single,
        Duration.zero,
      );
    });
  });

  group('weekFocus', () {
    test('covers Monday to Sunday of the current week', () {
      final sessions = [
        completed(DateTime(2026, 9, 27, 9)),
        completed(DateTime(2026, 9, 28, 9)),
        completed(DateTime(2026, 10, 4, 9)),
        completed(DateTime(2026, 10, 5, 9)),
      ];

      final week = weekFocus(sessions, today: DateTime(2026, 9, 30, 12));

      expect(week, hasLength(7));
      expect(week.first, const Duration(minutes: 25));
      expect(week.last, const Duration(minutes: 25));
      expect(week.sublist(1, 6), everyElement(Duration.zero));
    });

    test('starts the week on Monday', () {
      final monday = dayOf(DateTime(2026, 9, 28));

      expect(weekStart(DateTime(2026, 9, 30, 12)), monday);
      expect(weekStart(DateTime(2026, 10, 4, 23)), monday);
      expect(weekStart(DateTime(2026, 9, 28)), monday);
    });
  });

  group('monthFocus', () {
    test('has one value per day of the current month', () {
      final october = monthFocus(const [], today: DateTime(2026, 10, 4));
      final february = monthFocus(const [], today: DateTime(2026, 2, 10));

      expect(october, hasLength(31));
      expect(february, hasLength(28));
      expect(october.every((day) => day == Duration.zero), isTrue);
    });

    test('puts focus on its day of the month', () {
      final session = FocusSession(
        start: DateTime(2026, 10, 3, 9),
        planned: const Duration(minutes: 31),
      ).complete();

      final october = monthFocus([session], today: DateTime(2026, 10, 4));

      expect(october[2], const Duration(minutes: 31));
      expect(october[3], Duration.zero);
    });
  });

  group('focusByLabel', () {
    FocusSession labelled(DateTime start, int minutes, String? labelId) =>
        FocusSession(
          start: start,
          planned: Duration(minutes: minutes),
          labelId: labelId,
        ).complete();
    final from = DateTime(2026, 9, 28);
    final to = DateTime(2026, 10, 4);

    test('sums per label, sorted by focus time', () {
      final sessions = [
        labelled(DateTime(2026, 9, 28, 9), 25, 'study'),
        labelled(DateTime(2026, 9, 29, 9), 50, 'work'),
        labelled(DateTime(2026, 9, 30, 9), 50, 'study'),
        labelled(DateTime(2026, 9, 30, 11), 30, null),
      ];

      expect(
        focusByLabel(
          sessions,
          from: from,
          to: to,
          labelIds: {'study', 'work'},
        ),
        [
          (labelId: 'study', focused: const Duration(minutes: 75)),
          (labelId: 'work', focused: const Duration(minutes: 50)),
          (labelId: null, focused: const Duration(minutes: 30)),
        ],
      );
    });

    test('counts sessions of deleted labels as unlabeled', () {
      final sessions = [
        labelled(DateTime(2026, 9, 28, 9), 25, 'deleted'),
        labelled(DateTime(2026, 9, 28, 11), 25, null),
      ];

      expect(
        focusByLabel(sessions, from: from, to: to, labelIds: {'study'}),
        [(labelId: null, focused: const Duration(minutes: 50))],
      );
    });

    test('only counts sessions that ended in the period', () {
      final sessions = [
        labelled(DateTime(2026, 9, 27, 9), 25, 'study'),
        labelled(DateTime(2026, 10, 5, 9), 25, 'study'),
        labelled(DateTime(2026, 10, 4, 9), 25, 'study'),
      ];

      expect(
        focusByLabel(sessions, from: from, to: to, labelIds: {'study'}),
        [(labelId: 'study', focused: const Duration(minutes: 25))],
      );
    });
  });

  group('labelTotals', () {
    FocusSession labelled(DateTime start, int minutes, String? labelId) =>
        FocusSession(
          start: start,
          planned: Duration(minutes: minutes),
          labelId: labelId,
        ).complete();

    test('sums all finished sessions per label regardless of the date', () {
      final sessions = [
        labelled(DateTime(2025, 1, 5, 9), 60, 'exam'),
        labelled(DateTime(2026, 9, 29, 9), 50, 'exam'),
        labelled(DateTime(2026, 9, 30, 9), 25, 'uni'),
        labelled(DateTime(2026, 9, 30, 11), 30, null),
        FocusSession(
          start: DateTime(2026, 10, 1, 9),
          planned: const Duration(minutes: 25),
          labelId: 'exam',
        ),
      ];

      expect(labelTotals(sessions, labelIds: {'exam', 'uni', 'empty'}), {
        'exam': const Duration(minutes: 110),
        'uni': const Duration(minutes: 25),
        'empty': Duration.zero,
      });
    });

    test('ignores sessions of deleted labels', () {
      final sessions = [labelled(DateTime(2026, 9, 29, 9), 50, 'gone')];

      expect(labelTotals(sessions, labelIds: {'exam'}), {
        'exam': Duration.zero,
      });
    });
  });

  group('protectedTime', () {
    // 2026-09-28 is a Monday.
    final monday = DateTime(2026, 9, 28);
    final nextMonday = DateTime(2026, 10, 5);
    FocusSession between(DateTime start, DateTime end) =>
        FocusSession(start: start, planned: const Duration(hours: 3))
            .cancel(end);
    final weekdayMornings = FocusTime(
      id: 'mornings',
      weekdays: const {1, 2, 3, 4, 5},
      startMinute: 7 * 60,
      endMinute: 10 * 60,
    );

    test('counts a session overlapping a focus time once', () {
      final tuesdayMorning = FocusTime(
        id: 'tuesday',
        weekdays: const {2},
        startMinute: 7 * 60,
        endMinute: 10 * 60,
      );

      expect(
        protectedTime(
          [between(DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 11))],
          [tuesdayMorning],
          from: monday,
          to: nextMonday,
          now: DateTime(2026, 9, 29, 20),
        ),
        const Duration(hours: 4),
      );
    });

    test('counts pauses inside a session as protected', () {
      final session = FocusSession(
        start: DateTime(2026, 9, 29, 14),
        planned: const Duration(minutes: 30),
      )
          .pause(DateTime(2026, 9, 29, 14, 10))
          .resume(DateTime(2026, 9, 29, 14, 20))
          .cancel(DateTime(2026, 9, 29, 14, 40));

      expect(
        protectedTime(
          [session],
          const [],
          from: monday,
          to: nextMonday,
          now: DateTime(2026, 9, 29, 20),
        ),
        const Duration(minutes: 40),
      );
    });

    test('counts focus times on their weekdays up to now', () {
      expect(
        protectedTime(
          const [],
          [weekdayMornings],
          from: monday,
          to: nextMonday,
          now: DateTime(2026, 9, 30, 8),
        ),
        const Duration(hours: 7),
      );
    });

    test('clips to the period and counts a running session up to now', () {
      final overnight = between(
        DateTime(2026, 9, 27, 23),
        DateTime(2026, 9, 28, 1),
      );
      final running = FocusSession(
        start: DateTime(2026, 9, 30, 12),
        planned: const Duration(minutes: 50),
      );

      expect(
        protectedTime(
          [overnight, running],
          const [],
          from: monday,
          to: nextMonday,
          now: DateTime(2026, 9, 30, 12, 30),
        ),
        const Duration(minutes: 90),
      );
    });
  });

  group('focusDays', () {
    test('counts days with a finished session and the days so far', () {
      final sessions = [
        completed(DateTime(2026, 9, 28, 9)),
        completed(DateTime(2026, 9, 28, 15)),
        completed(DateTime(2026, 9, 30, 9)),
        completed(DateTime(2026, 9, 25, 9)),
      ];

      expect(
        focusDays(
          sessions,
          from: DateTime(2026, 9, 28),
          today: DateTime(2026, 10, 1),
        ),
        (focused: 2, days: 4),
      );
    });
  });

  group('appRestTimes', () {
    // 2026-09-28 is a Monday; now is Tuesday 20:00.
    final monday = DateTime(2026, 9, 28);
    final nextMonday = DateTime(2026, 10, 5);
    final now = DateTime(2026, 9, 29, 20);
    FocusSession between(DateTime start, DateTime end) =>
        FocusSession(start: start, planned: const Duration(hours: 3))
            .cancel(end);
    final mornings = FocusTime(
      id: 'mornings',
      weekdays: const {1, 2},
      startMinute: 7 * 60,
      endMinute: 10 * 60,
    );
    final evenings = FocusTime(
      id: 'evenings',
      weekdays: const {2},
      startMinute: 18 * 60,
      endMinute: 19 * 60,
      blockListId: 'study',
    );

    List<AppRest> rests(List<FocusSession> sessions, List<FocusTime> times) =>
        appRestTimes(
          sessions,
          times,
          defaultApps: const {'insta', 'tiktok'},
          listApps: const {
            'study': {'youtube'},
          },
          from: monday,
          to: nextMonday,
          now: now,
        );

    test('lets default apps rest in sessions and default focus times', () {
      final result = rests(
        [between(DateTime(2026, 9, 29, 12), DateTime(2026, 9, 29, 13))],
        [mornings],
      );

      final insta = result.firstWhere((rest) => rest.packageName == 'insta');
      expect(insta.total, const Duration(hours: 7));
      expect(insta.focusTimes, const Duration(hours: 6));
      expect(insta.sessions, const Duration(hours: 1));
    });

    test('lets a named list app rest only in its focus time', () {
      final result = rests(const [], [evenings]);

      expect(result.map((rest) => rest.packageName), ['youtube']);
      expect(result.single.total, const Duration(hours: 1));
      expect(result.single.sessions, Duration.zero);
    });

    test('counts a session inside a focus time once', () {
      final result = rests(
        [between(DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 11))],
        [mornings],
      );

      final insta = result.firstWhere((rest) => rest.packageName == 'insta');
      expect(insta.total, const Duration(hours: 7));
      expect(insta.focusTimes, const Duration(hours: 6));
      expect(insta.sessions, const Duration(hours: 1));
    });

    test('sorts by rest time and leaves out apps that never rested', () {
      final result = rests(
        [between(DateTime(2026, 9, 29, 12), DateTime(2026, 9, 29, 13))],
        [evenings],
      );

      expect(result.map((rest) => rest.packageName), [
        'insta',
        'tiktok',
        'youtube',
      ]);
      expect(result.first.total, const Duration(hours: 1));
      expect(
        appRestTimes(
          const [],
          const [],
          defaultApps: const {'insta'},
          listApps: const {},
          from: monday,
          to: nextMonday,
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('labelWeekTotals', () {
    FocusSession labelled(DateTime start, String labelId) => FocusSession(
      start: start,
      planned: const Duration(minutes: 60),
      labelId: labelId,
    ).complete();

    test('counts finished sessions from Monday until today', () {
      // 2026-09-30 is a Wednesday.
      final sessions = [
        labelled(DateTime(2026, 9, 27, 9), 'uni'),
        labelled(DateTime(2026, 9, 28, 9), 'uni'),
        labelled(DateTime(2026, 9, 30, 9), 'uni'),
        labelled(DateTime(2026, 9, 30, 11), 'work'),
      ];

      expect(
        labelWeekTotals(
          sessions,
          labelIds: {'uni', 'work', 'idle'},
          today: DateTime(2026, 9, 30, 20),
        ),
        {
          'uni': const Duration(hours: 2),
          'work': const Duration(hours: 1),
          'idle': Duration.zero,
        },
      );
    });
  });
}
