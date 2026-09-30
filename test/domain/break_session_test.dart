import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/break_session.dart';
import 'package:focus_timer/domain/pomodoro.dart';

void main() {
  final start = DateTime(2026, 9, 29, 10, 25);
  final breakSession = BreakSession(
    start: start,
    kind: BreakKind.short,
    duration: const Duration(minutes: 5),
  );

  group('BreakSession', () {
    test('counts down from the planned duration', () {
      expect(breakSession.remaining(start), const Duration(minutes: 5));
      expect(
        breakSession.remaining(start.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
    });

    test('never goes below zero and is over at the end', () {
      final later = start.add(const Duration(minutes: 7));

      expect(breakSession.remaining(later), Duration.zero);
      expect(breakSession.isOver(later), isTrue);
      expect(breakSession.isOver(start), isFalse);
    });
  });
}
