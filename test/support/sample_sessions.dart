import 'package:focus_timer/domain/focus_session.dart';

/// Fixed sessions for repository and codec tests.
final sampleStart = DateTime(2026, 9, 29, 10);

FocusSession runningSample() =>
    FocusSession(start: sampleStart, planned: const Duration(minutes: 25));

FocusSession pausedSample() =>
    runningSample().pause(sampleStart.add(const Duration(minutes: 5)));

FocusSession completedSample() => runningSample()
    .pause(sampleStart.add(const Duration(minutes: 5)))
    .resume(sampleStart.add(const Duration(minutes: 7)))
    .complete();

FocusSession cancelledSample() =>
    runningSample().cancel(sampleStart.add(const Duration(minutes: 12)));
