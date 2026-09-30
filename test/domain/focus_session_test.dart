import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';

void main() {
  final tenOClock = DateTime(2026, 9, 29, 10);
  DateTime at(int minute, [int second = 0]) =>
      tenOClock.add(Duration(minutes: minute, seconds: second));
  FocusSession started() =>
      FocusSession(start: tenOClock, planned: const Duration(minutes: 25));

  group('FocusSession.remaining', () {
    test('is the planned time minus the elapsed time', () {
      expect(started().remaining(at(10)), const Duration(minutes: 15));
    });

    test('never goes below zero', () {
      expect(started().remaining(at(40)), Duration.zero);
    });

    test('does not change while paused and continues after resume', () {
      final paused = started().pause(at(5));

      expect(paused.remaining(at(5)), const Duration(minutes: 20));
      expect(paused.remaining(at(9)), const Duration(minutes: 20));

      final resumed = paused.resume(at(9));
      expect(resumed.remaining(at(10)), const Duration(minutes: 19));
    });

    test('subtracts every pause', () {
      final session = started()
          .pause(at(5))
          .resume(at(7))
          .pause(at(10))
          .resume(at(13));

      expect(session.remaining(at(20)), const Duration(minutes: 10));
    });
  });

  group('FocusSession state changes', () {
    test('pausing a paused session throws a StateError', () {
      expect(() => started().pause(at(1)).pause(at(2)), throwsStateError);
    });

    test('pausing a finished session throws a StateError', () {
      expect(() => started().cancel(at(1)).pause(at(2)), throwsStateError);
    });

    test('resuming a running session throws a StateError', () {
      expect(() => started().resume(at(1)), throwsStateError);
    });

    test('reports paused and finished', () {
      expect(started().isPaused, isFalse);
      expect(started().pause(at(1)).isPaused, isTrue);
      expect(started().isFinished, isFalse);
      expect(started().cancel(at(1)).isFinished, isTrue);
    });
  });

  group('FocusSession.cancel', () {
    test('ends now as cancelled with the active time as focused time', () {
      final cancelled = started().pause(at(5)).resume(at(8)).cancel(at(12));

      expect(cancelled.end, at(12));
      expect(cancelled.outcome, isA<SessionCancelled>());
      expect(cancelled.focusedTime(at(30)), const Duration(minutes: 9));
    });

    test('closes an open pause', () {
      final cancelled = started().pause(at(5)).cancel(at(8));

      expect(cancelled.isPaused, isFalse);
      expect(cancelled.focusedTime(at(30)), const Duration(minutes: 5));
    });
  });

  group('FocusSession.complete', () {
    test('ends when the planned time was reached, including pauses', () {
      final completed = started().pause(at(5)).resume(at(10)).complete();

      expect(completed.end, at(30));
      expect(completed.outcome, isA<SessionCompleted>());
      expect(completed.focusedTime(at(45)), const Duration(minutes: 25));
    });

    test('completing a paused session throws a StateError', () {
      expect(() => started().pause(at(5)).complete(), throwsStateError);
    });
  });

  group('FocusSession validation', () {
    test('rejects a planned duration of zero or less', () {
      expect(
        () => FocusSession(start: tenOClock, planned: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => FocusSession(
          start: tenOClock,
          planned: const Duration(minutes: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('FocusSession label', () {
    test('keeps the label through pause, resume, cancel and complete', () {
      final labelled = FocusSession(
        start: tenOClock,
        planned: const Duration(minutes: 25),
        labelId: 'study',
      );

      expect(labelled.pause(at(1)).resume(at(2)).labelId, 'study');
      expect(labelled.cancel(at(3)).labelId, 'study');
      expect(labelled.complete().labelId, 'study');
    });

    test('is part of equality', () {
      expect(
        FocusSession(start: tenOClock, planned: const Duration(minutes: 25)),
        isNot(
          FocusSession(
            start: tenOClock,
            planned: const Duration(minutes: 25),
            labelId: 'study',
          ),
        ),
      );
    });
  });
}
