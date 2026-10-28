import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/named_block_list.dart';
import 'package:focus_timer/ui/focus_times_screen.dart';
import 'package:focus_timer/ui/focus_week_screen.dart';

import '../support/fake_focus_time_repository.dart';
import '../support/fake_named_block_list_repository.dart';
import '../support/pump_app.dart';

void main() {
  late FakeFocusTimeRepository repository;

  // 2026-09-30 is a Wednesday.
  var now = DateTime(2026, 9, 30, 20);

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      FocusTimesScreen(focusTimes: repository, clock: () => now),
    );
    await tester.pump();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Add focus time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() {
    repository = FakeFocusTimeRepository();
    now = DateTime(2026, 9, 30, 20);
  });

  group('FocusTimesScreen', () {
    testWidgets('opens the week calendar from the app bar', (tester) async {
      await repository.addFocusTime(
        ranges: [
          FocusTimeRange(
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
        ],
      );
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Week calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(FocusWeekScreen), findsOneWidget);
    });

    testWidgets('lists focus times with weekdays and times', (tester) async {
      repository.times.addAll([
        FocusTime(
          id: 'a',
          weekdays: const {1, 2, 3, 4, 5},
          startMinute: 540,
          endMinute: 720,
        ),
        FocusTime(
          id: 'b',
          weekdays: const {6, 7},
          startMinute: 600,
          endMinute: 690,
        ),
      ]);
      await pumpScreen(tester);

      expect(find.text('Mon–Fri · 09:00–12:00'), findsOneWidget);
      expect(find.text('Sat, Sun · 10:00–11:30'), findsOneWidget);
    });

    testWidgets('adds a focus time with the chosen weekdays', (tester) async {
      await pumpScreen(tester);

      await openEditor(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Sat'));
      await tester.pump();
      await save(tester);

      final added = repository.times.single;
      expect(added.ranges.single.weekdays, {1, 2, 3, 4, 5, 6});
      expect(
        (added.ranges.single.startMinute, added.ranges.single.endMinute),
        (540, 720),
      );
      expect(find.text('Mon–Sat · 09:00–12:00'), findsOneWidget);
    });

    testWidgets('deletes a focus time', (tester) async {
      repository.times.add(
        FocusTime(
          id: 'a',
          weekdays: const {1},
          startMinute: 540,
          endMinute: 720,
        ),
      );
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Delete focus time'));
      await tester.pump();

      expect(repository.times, isEmpty);
    });

    testWidgets('explains an overlapping focus time', (tester) async {
      repository.times.add(
        FocusTime(
          id: 'a',
          weekdays: const {1, 2, 3, 4, 5},
          startMinute: 540,
          endMinute: 720,
        ),
      );
      await pumpScreen(tester);

      await openEditor(tester);
      await save(tester);

      expect(find.text('This overlaps another focus time.'), findsOneWidget);
      expect(repository.times, hasLength(1));
    });

    testWidgets('locks a running focus time but keeps the others editable', (
      tester,
    ) async {
      now = DateTime(2026, 9, 30, 10);
      repository.times.addAll([
        FocusTime(
          id: 'a',
          weekdays: const {1, 2, 3, 4, 5},
          startMinute: 540,
          endMinute: 720,
        ),
        FocusTime(
          id: 'b',
          weekdays: const {6, 7},
          startMinute: 600,
          endMinute: 690,
        ),
      ]);
      await pumpScreen(tester);

      expect(
        find.text("Running focus times can't be changed."),
        findsOneWidget,
      );
      final deletes = tester
          .widgetList<IconButton>(
            find.widgetWithIcon(IconButton, Icons.delete_outline),
          )
          .toList();
      expect(deletes.first.onPressed, isNull);
      expect(deletes.last.onPressed, isNotNull);

      await tester.tap(find.text('Mon–Fri · 09:00–12:00'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Save'), findsNothing);

      await tester.tap(find.text('Sat, Sun · 10:00–11:30'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('FocusTimesScreen block lists', () {
    late FakeNamedBlockListRepository lists;

    setUp(() {
      lists = FakeNamedBlockListRepository([
        NamedBlockList(
          id: 'list-1',
          name: 'Morning',
          apps: const BlockList().add('com.instagram.android'),
        ),
      ]);
    });

    Future<void> pumpWithLists(WidgetTester tester) async {
      await tester.pumpApp(
        FocusTimesScreen(
          focusTimes: repository,
          namedLists: lists,
          clock: () => now,
        ),
      );
      await tester.pump();
    }

    testWidgets('saves the chosen block list with a new focus time', (
      tester,
    ) async {
      await pumpWithLists(tester);
      await openEditor(tester);

      await tester.tap(find.text('Default list'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning').last);
      await tester.pumpAndSettle();
      await save(tester);

      expect(repository.times.single.blockListId, 'list-1');
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('keeps the default list without a choice', (tester) async {
      await pumpWithLists(tester);
      await openEditor(tester);
      await save(tester);

      expect(repository.times.single.blockListId, isNull);
    });

    group('time ranges', () {
      testWidgets('lists every range of a focus time', (tester) async {
        repository.times.add(
          FocusTime.withRanges(
            id: 'a',
            ranges: [
              FocusTimeRange(weekdays: const {1, 2, 3, 5}, startMinute: 420, endMinute: 600),
              FocusTimeRange(weekdays: const {6}, startMinute: 420, endMinute: 720),
            ],
          ),
        );
        await pumpScreen(tester);

        expect(
          find.text('Mon–Wed, Fri 07:00–10:00 · Sat 07:00–12:00'),
          findsOneWidget,
        );
      });

      testWidgets('adds a second range with other days', (tester) async {
        await pumpScreen(tester);
        await openEditor(tester);

        await tester.tap(find.text('Add time range'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('range-1-day-6')));
        await tester.pump();
        await save(tester);

        expect(repository.times.single.ranges, [
          FocusTimeRange(weekdays: const {1, 2, 3, 4, 5}, startMinute: 540, endMinute: 720),
          FocusTimeRange(weekdays: const {6}, startMinute: 540, endMinute: 720),
        ]);
      });

      testWidgets('removes a range again', (tester) async {
        repository.times.add(
          FocusTime.withRanges(
            id: 'a',
            ranges: [
              FocusTimeRange(weekdays: const {1}, startMinute: 420, endMinute: 600),
              FocusTimeRange(weekdays: const {6}, startMinute: 420, endMinute: 720),
            ],
          ),
        );
        await pumpScreen(tester);
        await tester.tap(find.text('Mon 07:00–10:00 · Sat 07:00–12:00'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.byTooltip('Remove time range').last);
        await tester.pump();
        await save(tester);

        expect(repository.times.single.ranges, [
          FocusTimeRange(weekdays: const {1}, startMinute: 420, endMinute: 600),
        ]);
      });

      testWidgets('does not save ranges that overlap', (tester) async {
        await pumpScreen(tester);
        await openEditor(tester);

        await tester.tap(find.text('Add time range'));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('range-1-day-1')));
        await tester.pump();
        await save(tester);

        expect(find.text('This overlaps another focus time.'), findsOneWidget);
        expect(repository.times, isEmpty);
      });
    });
  });
}
