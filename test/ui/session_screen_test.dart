import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/ui/session_screen.dart';

import '../support/fake_session_repository.dart';
import '../support/pump_app.dart';

void main() {
  late DateTime now;
  late FakeSessionRepository repository;
  late FocusTimer timer;
  late int doneCalls;

  setUp(() {
    now = DateTime(2026, 9, 29, 10);
    repository = FakeSessionRepository();
    timer = FocusTimer(repository: repository, clock: () => now);
    doneCalls = 0;
  });

  Future<void> pumpSession(WidgetTester tester) async {
    await timer.start(const Duration(minutes: 25));
    await tester.pumpApp(
      SessionScreen(timer: timer, clock: () => now, onDone: () => doneCalls++),
    );
  }

  Future<void> elapse(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
    await tester.pump();
  }

  group('SessionScreen', () {
    testWidgets('counts down every second', (tester) async {
      await pumpSession(tester);
      expect(find.text('25:00'), findsOneWidget);

      await elapse(tester, const Duration(seconds: 1));

      expect(find.text('24:59'), findsOneWidget);
    });

    testWidgets('pauses and resumes', (tester) async {
      await pumpSession(tester);

      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(find.text('Resume'), findsOneWidget);

      await elapse(tester, const Duration(seconds: 5));
      expect(find.text('25:00'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();
      await elapse(tester, const Duration(seconds: 1));
      expect(find.text('24:59'), findsOneWidget);
    });

    testWidgets('ends the session after confirmation', (tester) async {
      await pumpSession(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('End this session?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.finished.single.outcome, isA<SessionCancelled>());
      expect(timer.current, isNull);
      expect(doneCalls, 1);
    });

    testWidgets('keeps the session when the dialog is dismissed', (
      tester,
    ) async {
      await pumpSession(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Keep focusing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(timer.current, isNotNull);
      expect(repository.finished, isEmpty);
      expect(doneCalls, 0);
    });

    testWidgets('completes the session when the time is up', (tester) async {
      await pumpSession(tester);

      await elapse(tester, const Duration(minutes: 25));

      expect(repository.finished.single.outcome, isA<SessionCompleted>());
      expect(doneCalls, 1);
    });
  });
}
