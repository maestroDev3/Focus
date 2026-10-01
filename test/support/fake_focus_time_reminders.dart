import 'package:focus_timer/domain/focus_time_reminders.dart';

/// Records reminder calls for tests.
class FakeFocusTimeReminders implements FocusTimeReminders {
  final rescheduled = <ReminderTexts>[];
  var permissionRequests = 0;

  @override
  Future<void> reschedule(ReminderTexts texts) async => rescheduled.add(texts);

  @override
  Future<void> requestPermission() async => permissionRequests++;
}
