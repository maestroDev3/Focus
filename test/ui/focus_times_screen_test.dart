import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/ui/focus_times_screen.dart';

import '../support/fake_focus_time_repository.dart';
import '../support/pump_app.dart';

void main() {
  late FakeFocusTimeRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(FocusTimesScreen(focusTimes: repository));
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

  setUp(() => repository = FakeFocusTimeRepository());

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
  });
}
