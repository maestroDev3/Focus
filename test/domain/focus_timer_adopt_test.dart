import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/domain/home_widget.dart';

import '../support/fake_session_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 10, 3, 10);
  const planned = Duration(minutes: 25);
  late FakeSessionRepository repository;
  late FocusTimer timer;

  setUp(() {
    repository = FakeSessionRepository();
    timer = FocusTimer(repository: repository, clock: () => tenOClock);
  });

  group('FocusTimer.adopt', () {
    test('makes the widget-started session active with its start', () async {
      final start = tenOClock.subtract(const Duration(minutes: 5));

      await timer.adopt(
        ExternalStart(start: start, planned: planned, labelId: 'study'),
      );

      final expected = FocusSession(
        start: start,
        planned: planned,
        labelId: 'study',
      );
      expect(timer.current, expected);
      expect(repository.active, expected);
    });

    test('stores a session whose time is over as completed', () async {
      final start = tenOClock.subtract(const Duration(minutes: 40));

      await timer.adopt(ExternalStart(start: start, planned: planned));

      expect(timer.current, isNull);
      expect(repository.active, isNull);
      expect(repository.finished.single.outcome, const SessionCompleted());
    });

    test('throws a StateError while a session runs', () async {
      await timer.start(planned);

      expect(
        () => timer.adopt(ExternalStart(start: tenOClock, planned: planned)),
        throwsStateError,
      );
    });
  });
}
