import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/ui/break_screen.dart';

import '../support/pump_app.dart';

void main() {
  late DateTime now;
  late int doneCalls;

  setUp(() {
    now = DateTime(2026, 9, 29, 10, 25);
    doneCalls = 0;
  });

  Future<void> pumpBreak(
    WidgetTester tester, {
    BreakKind kind = BreakKind.short,
    Duration duration = const Duration(minutes: 5),
  }) {
    return tester.pumpApp(
      BreakScreen(
        kind: kind,
        duration: duration,
        clock: () => now,
        onDone: () => doneCalls++,
      ),
    );
  }

  Future<void> elapse(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
    await tester.pump();
  }

  group('BreakScreen', () {
    testWidgets('offers a short or long break', (tester) async {
      await pumpBreak(tester);
      expect(find.text('Short break · 5 min'), findsOneWidget);

      await pumpBreak(
        tester,
        kind: BreakKind.long,
        duration: const Duration(minutes: 15),
      );
      expect(find.text('Long break · 15 min'), findsOneWidget);
    });

    testWidgets('counts the break down and finishes at the end', (
      tester,
    ) async {
      await pumpBreak(tester);

      await tester.tap(find.text('Start break'));
      await tester.pump();
      expect(find.text('05:00'), findsOneWidget);

      await elapse(tester, const Duration(seconds: 1));
      expect(find.text('04:59'), findsOneWidget);

      await elapse(tester, const Duration(minutes: 5));
      expect(doneCalls, 1);
    });

    testWidgets('skip finishes immediately', (tester) async {
      await pumpBreak(tester);

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(doneCalls, 1);
    });

    testWidgets('a running break can be ended', (tester) async {
      await pumpBreak(tester);
      await tester.tap(find.text('Start break'));
      await tester.pump();

      await tester.tap(find.text('End break'));
      await tester.pump();

      expect(doneCalls, 1);
    });
  });
}
