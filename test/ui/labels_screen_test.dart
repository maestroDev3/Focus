import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/ui/labels_screen.dart';

import '../support/fake_label_repository.dart';
import '../support/pump_app.dart';

void main() {
  late FakeLabelRepository repository;
  var sessions = <FocusSession>[];

  /// [count] completed sessions of [minutes] each with [labelId].
  List<FocusSession> sessionsFor(String labelId, int count, int minutes) => [
    for (var day = 1; day <= count; day++)
      FocusSession(
        start: DateTime(2026, 9, day, 9),
        planned: Duration(minutes: minutes),
        labelId: labelId,
      ).complete(),
  ];

  Future<void> pumpLabels(WidgetTester tester) async {
    await tester.pumpApp(
      LabelsScreen(labels: repository, sessions: Stream.value(sessions)),
    );
    await tester.pump();
  }

  Future<void> enterGoal(WidgetTester tester, String goal) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('label-goal')), goal);
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('label-name')), name);
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() {
    repository = FakeLabelRepository();
    sessions = [];
  });

  group('LabelsScreen', () {
    testWidgets('adds a label', (tester) async {
      await pumpLabels(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add label'));
      await enterName(tester, 'Study');

      expect(find.text('Study'), findsOneWidget);
      expect(repository.labels.single.name, 'Study');
    });

    testWidgets('renames a label', (tester) async {
      repository.labels.add(FocusLabel(id: 'study', name: 'Study'));
      await pumpLabels(tester);

      await tester.tap(find.text('Study'));
      await enterName(tester, 'Deep work');

      expect(find.text('Deep work'), findsOneWidget);
      expect(repository.labels.single.name, 'Deep work');
    });

    testWidgets('deletes a label', (tester) async {
      repository.labels.add(FocusLabel(id: 'study', name: 'Study'));
      await pumpLabels(tester);

      await tester.tap(find.byTooltip('Delete Study'));
      await tester.pump();

      expect(find.text('Study'), findsNothing);
      expect(repository.labels, isEmpty);
    });

    testWidgets('explains a duplicate name', (tester) async {
      repository.labels.add(FocusLabel(id: 'study', name: 'Study'));
      await pumpLabels(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add label'));
      await enterName(tester, 'study');

      expect(
        find.text('Please use a new name with 1–30 characters.'),
        findsOneWidget,
      );
      expect(repository.labels, hasLength(1));
    });

    testWidgets('shows the total and the progress towards the goal', (
      tester,
    ) async {
      repository.labels.add(
        FocusLabel(id: 'exam', name: 'Exam', goal: const Duration(hours: 20)),
      );
      sessions = sessionsFor('exam', 12, 60);
      await pumpLabels(tester);

      expect(find.text('12h of 20h'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.6, 0.001));
    });

    testWidgets('shows only the total without a goal', (tester) async {
      repository.labels.add(FocusLabel(id: 'uni', name: 'Uni'));
      sessions = sessionsFor('uni', 2, 50);
      await pumpLabels(tester);

      expect(find.text('1h 40 in total'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('says when the goal is reached', (tester) async {
      repository.labels.add(
        FocusLabel(id: 'exam', name: 'Exam', goal: const Duration(hours: 1)),
      );
      sessions = sessionsFor('exam', 3, 30);
      await pumpLabels(tester);

      expect(find.text('1h 30 · Goal reached'), findsOneWidget);
    });

    testWidgets('sets and clears the goal in the dialog', (tester) async {
      repository.labels.add(FocusLabel(id: 'exam', name: 'Exam'));
      await pumpLabels(tester);

      await tester.tap(find.text('Exam'));
      await enterGoal(tester, '20');
      expect(repository.labels.single.goal, const Duration(hours: 20));
      expect(repository.labels.single.name, 'Exam');

      await tester.tap(find.text('Exam'));
      await enterGoal(tester, '');
      expect(repository.labels.single.goal, isNull);
    });

    testWidgets('adds a label with a goal', (tester) async {
      await pumpLabels(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add label'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byKey(const Key('label-name')), 'Exam');
      await enterGoal(tester, '20');

      expect(repository.labels.single.name, 'Exam');
      expect(repository.labels.single.goal, const Duration(hours: 20));
    });

    testWidgets('explains an invalid goal', (tester) async {
      repository.labels.add(FocusLabel(id: 'exam', name: 'Exam'));
      await pumpLabels(tester);

      await tester.tap(find.text('Exam'));
      await enterGoal(tester, '0');

      expect(
        find.text('Please enter a goal of 1–999 hours or leave it empty.'),
        findsOneWidget,
      );
      expect(repository.labels.single.goal, isNull);
    });
  });
}
