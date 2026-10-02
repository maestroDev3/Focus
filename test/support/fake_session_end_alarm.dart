import 'package:focus_timer/domain/session_end_alarm.dart';

/// Records the scheduled session end; null when nothing is scheduled.
class FakeSessionEndAlarm implements SessionEndAlarm {
  DateTime? scheduledAt;

  @override
  Future<void> scheduleAt(DateTime end) async => scheduledAt = end;

  @override
  Future<void> cancel() async => scheduledAt = null;
}
