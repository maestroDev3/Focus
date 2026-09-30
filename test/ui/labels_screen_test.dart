import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/ui/labels_screen.dart';

import '../support/fake_label_repository.dart';
import '../support/pump_app.dart';

void main() {
  late FakeLabelRepository repository;

  Future<void> pumpLabels(WidgetTester tester) async {
    await tester.pumpApp(LabelsScreen(labels: repository));
    await tester.pump();
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), name);
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() => repository = FakeLabelRepository());

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
  });
}
