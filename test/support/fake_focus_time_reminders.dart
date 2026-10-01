import 'dart:async';

import 'package:focus_timer/domain/focus_time_reminders.dart';

/// Records reminder calls for tests and simulates taps on the reminder.
class FakeFocusTimeReminders implements FocusTimeReminders {
  FakeFocusTimeReminders({this.initialStart = false});

  final rescheduled = <ReminderTexts>[];
  var permissionRequests = 0;

  /// Whether Focus was launched by tapping the reminder (consumed once).
  bool initialStart;
  final _starts = StreamController<void>.broadcast();

  /// Simulates tapping the reminder while Focus runs.
  void emitStart() => _starts.add(null);

  @override
  Future<void> reschedule(ReminderTexts texts) async => rescheduled.add(texts);

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<bool> initialStartRequest() async {
    final start = initialStart;
    initialStart = false;
    return start;
  }

  @override
  Stream<void> get startRequested => _starts.stream;
}
