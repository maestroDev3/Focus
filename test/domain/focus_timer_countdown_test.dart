import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/domain/session_countdown.dart';

import '../support/fake_label_repository.dart';
import '../support/fake_session_countdown.dart';
import '../support/fake_session_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 10, 3, 10);
  const planned = Duration(minutes: 25);
  late FakeSessionRepository repository;
  late FakeSessionCountdown countdown;
  late DateTime now;
  late FocusTimer timer;

  void advance(Duration duration) => now = now.add(duration);

  setUp(() {
    repository = FakeSessionRepository();
    countdown = FakeSessionCountdown();
    now = tenOClock;
    timer = FocusTimer(
      repository: repository,
      clock: () => now,
      countdown: countdown,
      labels: FakeLabelRepository([FocusLabel(id: 'study', name: 'Study')]),
    );
  });

  group('FocusTimer countdown notice', () {
    test('shows the planned end and the label when a session starts', () async {
      await timer.start(planned, labelId: 'study');

      expect(
        countdown.shown,
        CountdownRunning(end: tenOClock.add(planned), labelName: 'Study'),
      );
    });

    test('shows no label name for a session without label', () async {
      await timer.start(planned);

      expect(
        countdown.shown,
        CountdownRunning(end: tenOClock.add(planned)),
      );
    });

    test('shows the remaining time while paused and the new end on resume',
        () async {
      await timer.start(planned, labelId: 'study');
      advance(const Duration(minutes: 5));

      await timer.pause();
      expect(
        countdown.shown,
        const CountdownPaused(
          remaining: Duration(minutes: 20),
          labelName: 'Study',
        ),
      );

      advance(const Duration(minutes: 3));
      await timer.resume();
      expect(
        countdown.shown,
        CountdownRunning(
          end: now.add(const Duration(minutes: 20)),
          labelName: 'Study',
        ),
      );
    });

    test('is hidden when the session is cancelled', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 12));

      await timer.cancel();

      expect(countdown.shown, isNull);
    });

    test('is hidden when the session completes', () async {
      await timer.start(planned);
      advance(planned);

      await timer.completeIfDue();

      expect(countdown.shown, isNull);
    });

    test('is shown for a restored running session', () async {
      repository.active = FocusSession(
        start: tenOClock.subtract(const Duration(minutes: 10)),
        planned: planned,
        labelId: 'study',
      );

      await timer.restore();

      expect(
        countdown.shown,
        CountdownRunning(
          end: tenOClock.add(const Duration(minutes: 15)),
          labelName: 'Study',
        ),
      );
    });
  });
}
