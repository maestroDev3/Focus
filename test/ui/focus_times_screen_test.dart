import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/ui/focus_times_screen.dart';

import '../support/fake_focus_time_repository.dart';
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
      expect(added.weekdays, {1, 2, 3, 4, 5, 6});
      expect((added.startMinute, added.endMinute), (540, 720));
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
}
